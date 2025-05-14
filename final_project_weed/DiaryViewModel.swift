//
//  DiaryViewModel.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Model สำหรับ Diary entry
struct Diary: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var orderId: String
    var strainId: String
    var orderDate: Date
    var useDate: Date
    var duration: Double
    var rating: Double
    var feelings: [String]
    var whyUse: [String]
    var notes: String?
}

/// ViewModel สำหรับโหลด–บันทึก Diary
class DiaryViewModel: ObservableObject {
    @Published var diaries: [Diary] = []
    private let db = Firestore.firestore()

    /// Fetch diaries ของ user ที่ระบุ
    func fetchDiaries(for uid: String) {
        db.collection("diaries")
          .whereField("userId", isEqualTo: uid)
          .order(by: "orderDate", descending: true)
          .addSnapshotListener { snapshot, error in
              print("DEBUG: fetchDiaries() snapshot listener triggered")
              if let error = error {
                  print("❌ Failed to fetch diaries:", error.localizedDescription)
                  return
              }
              guard let docs = snapshot?.documents else {
                  print("⚠️ No diary documents found")
                  return
              }
              print("DEBUG: fetched \(docs.count) documents from Firestore")
              let list = docs.compactMap { try? $0.data(as: Diary.self) }
              DispatchQueue.main.async {
                  self.diaries = list
              }
          }
    }

    /// Convenience loader ใช้ UID ของ user ที่ล็อกอินอยู่
    func loadDiaries() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("ERROR: No authenticated user UID")
            return
        }
        print("DEBUG: loadDiaries() called for uid: \(uid)")
        fetchDiaries(for: uid)
    }

    /// เพิ่ม diary entry ใหม่และรีโหลด list
    func addDiary(_ diary: Diary) {
        do {
            _ = try db.collection("diaries").addDocument(from: diary) { error in
                print("DEBUG: addDiary() callback, error: \(error?.localizedDescription ?? "none")")
                if let error = error {
                    print("❌ Failed to add diary:", error.localizedDescription)
                } else {
                    self.loadDiaries()
                }
            }
        } catch {
            print("❌ Failed to encode diary:", error.localizedDescription)
        }
    }

    /// Upsert (add or update) a diary entry using its document ID
    func upsertDiary(_ diary: Diary) {
        guard let docId = diary.id else {
            print("❌ Cannot upsert diary without an ID")
            return
        }
        do {
            try db.collection("diaries")
                .document(docId)
                .setData(from: diary) { error in
                    print("DEBUG: upsertDiary() callback, error: \(error?.localizedDescription ?? "none")")
                    if let error = error {
                        print("❌ Failed to upsert diary:", error.localizedDescription)
                    } else {
                        self.loadDiaries()
                    }
                }
        } catch {
            print("❌ Encoding diary failed:", error.localizedDescription)
        }
    }
}
