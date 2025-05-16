//
//  DiaryViewModel.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//
import Foundation
import FirebaseFirestore 
import FirebaseAuth

struct Diary: Identifiable, Codable, Equatable {
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

class DiaryViewModel: ObservableObject {
    @Published var diaries: [Diary] = []
    
    private let db = Firestore.firestore()
    
    private var listenerRegistration: ListenerRegistration?

    init() {
        print("DEBUG (DiaryViewModel): Initialized.")
    }

    func fetchDiaries(for uid: String) {
        listenerRegistration?.remove()
        print("DEBUG (DiaryViewModel): Attempting to fetch diaries for UID: \(uid)")

        listenerRegistration = db.collection("diaries")
            .whereField("userId", isEqualTo: uid)
            .order(by: "useDate", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }

                if let error = error {
                    print("❌ ERROR (DiaryViewModel): Failed to fetch diaries for UID \(uid): \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("⚠️ WARNING (DiaryViewModel): No diary documents found for UID \(uid).")
                    DispatchQueue.main.async {
                        self.diaries = []
                    }
                    return
                }

                print("DEBUG (DiaryViewModel): Fetched \(documents.count) diary documents from Firestore for UID \(uid).")
                
                let fetchedDiaries = documents.compactMap { document -> Diary? in
                    do {
                        return try document.data(as: Diary.self)
                    } catch {
                        print("❌ ERROR (DiaryViewModel): Failed to decode diary document \(document.documentID): \(error.localizedDescription)")
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    self.diaries = fetchedDiaries
                    print("DEBUG (DiaryViewModel): Diaries array updated with \(fetchedDiaries.count) items.")
                }
            }
    }

    func loadDiaries() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("❌ ERROR (DiaryViewModel): No authenticated user found. Cannot load diaries.")
            DispatchQueue.main.async {
                self.diaries = []
            }
            return
        }
        print("DEBUG (DiaryViewModel): loadDiaries() called for current user UID: \(currentUserID)")
        fetchDiaries(for: currentUserID)
    }

    func addDiary(_ diary: Diary) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("❌ ERROR (DiaryViewModel): No authenticated user. Cannot add diary.")
            return
        }
        
        var diaryToAdd = diary
        if diaryToAdd.userId != currentUserID {
            print("⚠️ WARNING (DiaryViewModel): Diary's userId (\(diary.userId)) does not match current user's UID (\(currentUserID)). Overwriting diary.userId.")
            diaryToAdd.userId = currentUserID
        }

        do {
            _ = try db.collection("diaries").addDocument(from: diaryToAdd) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ ERROR (DiaryViewModel): Failed to add diary: \(error.localizedDescription)")
                } else {
                    print("✅ SUCCESS (DiaryViewModel): Diary added successfully. Reloading diaries.")
                    self.loadDiaries()
                }
            }
        } catch {
            print("❌ ERROR (DiaryViewModel): Failed to encode diary for adding: \(error.localizedDescription)")
        }
    }

    func upsertDiary(_ diary: Diary) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("❌ ERROR (DiaryViewModel): No authenticated user. Cannot upsert diary.")
            return
        }

        var diaryToUpsert = diary
        if diaryToUpsert.userId != currentUserID {
            print("⚠️ WARNING (DiaryViewModel): Diary's userId (\(diary.userId)) for upsert does not match current user's UID (\(currentUserID)). Overwriting diary.userId.")
            diaryToUpsert.userId = currentUserID
        }

        if let documentID = diaryToUpsert.id, !documentID.isEmpty {
            // If ID exists, update the existing document
            print("DEBUG (DiaryViewModel): Attempting to update diary with ID: \(documentID)")
            do {
                try db.collection("diaries").document(documentID).setData(from: diaryToUpsert, merge: true) { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        print("❌ ERROR (DiaryViewModel): Failed to update diary \(documentID): \(error.localizedDescription)")
                    } else {
                        print("✅ SUCCESS (DiaryViewModel): Diary \(documentID) updated successfully. Reloading diaries.")
                    }
                }
            } catch {
                print("❌ ERROR (DiaryViewModel): Failed to encode diary for updating \(documentID): \(error.localizedDescription)")
            }
        } else {
            print("DEBUG (DiaryViewModel): Diary ID is nil or empty. Calling addDiary instead.")
            addDiary(diaryToUpsert)
        }
    }
    
    deinit {
        print("DEBUG (DiaryViewModel): Deinitializing. Removing Firestore listener.")
        listenerRegistration?.remove()
    }
}
