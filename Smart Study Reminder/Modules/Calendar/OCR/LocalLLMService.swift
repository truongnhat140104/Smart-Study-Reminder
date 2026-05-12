////
////  LocalLLMService.swift
////  Smart Study Reminder
////
//
//import Foundation
//import llama
//
//enum LocalLLMError: LocalizedError {
//    case modelNotFound
//    case modelLoadFailed
//    case contextCreateFailed
//    case tokenizeFailed
//    case decodeFailed
//    case samplerCreateFailed
//    case emptyResponse
//    
//    var errorDescription: String? {
//        switch self {
//        case .modelNotFound:
//            return "Không tìm thấy file model .gguf trong app bundle."
//        case .modelLoadFailed:
//            return "Không load được model local."
//        case .contextCreateFailed:
//            return "Không tạo được context cho model local."
//        case .tokenizeFailed:
//            return "Không tokenize được prompt."
//        case .decodeFailed:
//            return "Model local không decode được dữ liệu."
//        case .samplerCreateFailed:
//            return "Không tạo được sampler cho model local."
//        case .emptyResponse:
//            return "Model local không trả về nội dung."
//        }
//    }
//}
//
//actor LocalLLMService {
//    static let shared = LocalLLMService()
//    
//    private var model: OpaquePointer?
//    private var context: OpaquePointer?
//    private var didInitBackend = false
//    
//    private let modelFileName = "qwen2.5-1.5b-instruct.Q4_K_M"
//    private let modelFileExtension = "gguf"
//    
//    private let contextSize: UInt32 = 2048
//    private let batchSize: UInt32 = 128
//    
//    private init() {}
//    
//    deinit {
//        if let context {
//            llama_free(context)
//        }
//        
//        if let model {
//            llama_model_free(model)
//        }
//        
//        if didInitBackend {
//            llama_backend_free()
//        }
//    }
//    
//    func sendMessage(
//        _ prompt: String,
//        maxNewTokens: Int32 = 512,
//        temperature: Float = 0.2
//    ) async throws -> String {
//        try loadModelIfNeeded()
//        
//        guard let model, let context else {
//            throw LocalLLMError.modelLoadFailed
//        }
//        
//        clearMemory(context)
//        
//        let vocab = llama_model_get_vocab(model)
//        let promptTokens = try tokenize(prompt, vocab: vocab)
//        
//        try decode(
//            tokens: promptTokens,
//            startPosition: 0,
//            context: context
//        )
//        
//        let sampler = try makeSampler(temperature: temperature)
//        
//        defer {
//            llama_sampler_free(sampler)
//        }
//        
//        var output = ""
//        var currentPosition = Int32(promptTokens.count)
//        
//        for _ in 0..<maxNewTokens {
//            let nextToken = llama_sampler_sample(
//                sampler,
//                context,
//                -1
//            )
//            
//            if llama_vocab_is_eog(vocab, nextToken) {
//                break
//            }
//            
//            llama_sampler_accept(sampler, nextToken)
//            
//            let piece = tokenToString(
//                token: nextToken,
//                vocab: vocab
//            )
//            
//            output += piece
//            
//            try decode(
//                tokens: [nextToken],
//                startPosition: currentPosition,
//                context: context
//            )
//            
//            currentPosition += 1
//        }
//        
//        let cleaned = cleanOutput(output)
//        
//        guard !cleaned.isEmpty else {
//            throw LocalLLMError.emptyResponse
//        }
//        
//        return cleaned
//    }
//    
//    func generateJSONFromOCRText(_ rawText: String) async throws -> String {
//        let prompt = PromptBuilder.buildPrompt(from: rawText)
//        
//        return try await sendMessage(
//            prompt,
//            maxNewTokens: 768,
//            temperature: 0.1
//        )
//    }
//    
//    private func loadModelIfNeeded() throws {
//        if model != nil, context != nil {
//            return
//        }
//        
//        if !didInitBackend {
//            llama_backend_init()
//            didInitBackend = true
//        }
//        
//        guard let modelURL = Bundle.main.url(
//            forResource: modelFileName,
//            withExtension: modelFileExtension
//        ) else {
//            throw LocalLLMError.modelNotFound
//        }
//        
//        var modelParams = llama_model_default_params()
//        modelParams.n_gpu_layers = 0
//        
//        guard let loadedModel = llama_model_load_from_file(
//            modelURL.path,
//            modelParams
//        ) else {
//            throw LocalLLMError.modelLoadFailed
//        }
//        
//        var contextParams = llama_context_default_params()
//        contextParams.n_ctx = contextSize
//        contextParams.n_batch = batchSize
//        
//        guard let loadedContext = llama_new_context_with_model(
//            loadedModel,
//            contextParams
//        ) else {
//            llama_model_free(loadedModel)
//            throw LocalLLMError.contextCreateFailed
//        }
//        
//        self.model = loadedModel
//        self.context = loadedContext
//    }
//    
//    private func clearMemory(_ context: OpaquePointer) {
//        let memory = llama_get_memory(context)
//        llama_memory_clear(memory, true)
//    }
//    
//    private func tokenize(
//        _ text: String,
//        vocab: OpaquePointer?
//    ) throws -> [llama_token] {
//        let utf8Count = Int32(text.utf8.count)
//        
//        let tokenCount = -llama_tokenize(
//            vocab,
//            text,
//            utf8Count,
//            nil,
//            0,
//            true,
//            true
//        )
//        
//        guard tokenCount > 0 else {
//            throw LocalLLMError.tokenizeFailed
//        }
//        
//        var tokens = [llama_token](
//            repeating: 0,
//            count: Int(tokenCount)
//        )
//        
//        let actualCount = llama_tokenize(
//            vocab,
//            text,
//            utf8Count,
//            &tokens,
//            tokenCount,
//            true,
//            true
//        )
//        
//        guard actualCount > 0 else {
//            throw LocalLLMError.tokenizeFailed
//        }
//        
//        return Array(tokens.prefix(Int(actualCount)))
//    }
//    
//    private func decode(
//        tokens: [llama_token],
//        startPosition: Int32,
//        context: OpaquePointer
//    ) throws {
//        guard !tokens.isEmpty else {
//            return
//        }
//        
//        var batch = llama_batch_init(
//            Int32(tokens.count),
//            0,
//            1
//        )
//        
//        defer {
//            llama_batch_free(batch)
//        }
//        
//        batch.n_tokens = Int32(tokens.count)
//        
//        for index in tokens.indices {
//            let i = Int(index)
//            
//            batch.token[i] = tokens[index]
//            batch.pos[i] = startPosition + Int32(index)
//            batch.n_seq_id[i] = 1
//            batch.seq_id[i]![0] = 0
//            batch.logits[i] = index == tokens.count - 1 ? 1 : 0
//        }
//        
//        let result = llama_decode(context, batch)
//        
//        guard result == 0 else {
//            throw LocalLLMError.decodeFailed
//        }
//    }
//    
//    private func makeSampler(
//        temperature: Float
//    ) throws -> UnsafeMutablePointer<llama_sampler> {
//        var samplerParams = llama_sampler_chain_default_params()
//        samplerParams.no_perf = false
//        
//        guard let sampler = llama_sampler_chain_init(samplerParams) else {
//            throw LocalLLMError.samplerCreateFailed
//        }
//        
//        if let topK = llama_sampler_init_top_k(40) {
//            llama_sampler_chain_add(sampler, topK)
//        }
//        
//        if let topP = llama_sampler_init_top_p(0.9, 1) {
//            llama_sampler_chain_add(sampler, topP)
//        }
//        
//        if let temp = llama_sampler_init_temp(temperature) {
//            llama_sampler_chain_add(sampler, temp)
//        }
//        
//        if let dist = llama_sampler_init_dist(UInt32.random(in: 0...UInt32.max)) {
//            llama_sampler_chain_add(sampler, dist)
//        }
//        
//        return sampler
//    }
//    
//    private func tokenToString(
//        token: llama_token,
//        vocab: OpaquePointer?
//    ) -> String {
//        var buffer = [CChar](
//            repeating: 0,
//            count: 256
//        )
//        
//        var length = llama_token_to_piece(
//            vocab,
//            token,
//            &buffer,
//            Int32(buffer.count),
//            0,
//            true
//        )
//        
//        if length < 0 {
//            buffer = [CChar](
//                repeating: 0,
//                count: Int(-length)
//            )
//            
//            length = llama_token_to_piece(
//                vocab,
//                token,
//                &buffer,
//                Int32(buffer.count),
//                0,
//                true
//            )
//        }
//        
//        guard length > 0 else {
//            return ""
//        }
//        
//        let bytes = buffer
//            .prefix(Int(length))
//            .map { UInt8(bitPattern: $0) }
//        
//        return String(
//            bytes: bytes,
//            encoding: .utf8
//        ) ?? ""
//    }
//    
//    private func cleanOutput(_ text: String) -> String {
//        var output = text
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        output = output
//            .replacingOccurrences(of: "```json", with: "")
//            .replacingOccurrences(of: "```", with: "")
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        if let start = output.firstIndex(of: "{"),
//           let end = output.lastIndex(of: "}") {
//            output = String(output[start...end])
//        }
//        
//        return output
//    }
//}
