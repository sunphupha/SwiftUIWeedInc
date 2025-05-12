
//
//  ReviewViewModel.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import Foundation
import FirebaseFirestore
import Combine

class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    /// Fetch reviews for a specific strain ID
    func fetchReviews(for strainId: String) {
        // Detach any existing listener
        listener?.remove()

        listener = db.collection("reviews")
            .whereField("strainId", isEqualTo: strainId)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching reviews: \(error)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("No reviews found")
                    return
                }
                self?.reviews = documents.compactMap { doc in
                    try? doc.data(as: Review.self)
                }
            }
    }

    /// Add a new review for a strain
    func addReview(_ review: Review) {
        do {
            let _ = try db.collection("reviews").addDocument(from: review)
        } catch {
            print("Error adding review: \(error)")
        }
    }

    deinit {
        listener?.remove()
    }
}
