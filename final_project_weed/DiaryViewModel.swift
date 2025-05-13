//
//  DiaryViewModel.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class DiaryViewModel: ObservableObject {
    @Published var diaries: [Diary] = []
    private let db = Firestore.firestore()

    /// Fetch all diary entries for the given user, ordered by useDate descending.
    func fetchDiaries(for userId: String) {
        db.collection("diaries")
          .whereField("userId", isEqualTo: userId)
          .order(by: "useDate", descending: true)
          .addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching diaries: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            self.diaries = documents.compactMap { doc in
                try? doc.data(as: Diary.self)
            }
        }
    }

    /// Add or update a diary entry in Firestore.
    func addDiary(_ diary: Diary, completion: ((Error?) -> Void)? = nil) {
        do {
            if let id = diary.id {
                // Update existing
                try db.collection("diaries").document(id).setData(from: diary)
                completion?(nil)
            } else {
                // Add new
                _ = try db.collection("diaries").addDocument(from: diary)
                completion?(nil)
            }
        } catch {
            print("Error saving diary: \(error.localizedDescription)")
            completion?(error)
        }
    }
}
