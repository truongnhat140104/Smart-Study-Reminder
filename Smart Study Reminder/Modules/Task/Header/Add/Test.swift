//
//  Test.swift
//  Smart Study Reminder
//
//  Created by Truong Nhat on 5/5/26.
//

import SwiftUI
import SwiftData

struct Test: View {
    @Query(sort: \TaskItem.startAt) private var tasks: [TaskItem]
    
    var body: some View {
        List {
           ForEach(tasks) { task in
                VStack(alignment: .leading) {
                   Text(task.title)
                       .font(.headline)
               }
            }
        }
    }
}

#Preview {
    Test()
        .modelContainer(for: AppModelContainer.models)

}
