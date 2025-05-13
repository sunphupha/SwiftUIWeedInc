//
//  Diary.swift
//  final_project_weed
//
//  Created by Sun Phupha on 12/5/2568 BE.
//

import SwiftUI

struct DiaryPage: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    DiaryPage()
}

//
//  Diary.swift
//  final_project_weed
//
//  Created by Sun Phupha on 12/5/2568 BE.
//

import Foundation
import FirebaseFirestore

struct Diary: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var strainId: String
    var orderDate: Date
    var useDate: Date
    var whyUse: [String]
    var feelings: [String]
    var duration: Double
    var rating: Double
    var notes: String?
}
