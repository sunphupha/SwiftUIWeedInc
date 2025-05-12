//
//  Review.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?          // Firestore document ID
    let strainId: String                 // ID of the strain this review refers to
    let reviewerName: String             // Name of the reviewer
    let date: Date                       // Review date
    let rating: Int                      // Rating from 1 to 5
    let comment: String                  // Review text
}
