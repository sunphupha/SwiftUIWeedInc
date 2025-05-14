//
//  OrderViewModel.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import Foundation
import FirebaseFirestore

struct OrderItem: Codable {
    var strainId: String
    var quantity: Double
    var price: Double
    var name: String
}

struct Order: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var items: [OrderItem]
    var total: Double
    var orderDate: Date
    var status: String
}

class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    private let db = Firestore.firestore()

    /// Fetch all orders for the given user, ordered by date descending.
    func fetchOrders(for userId: String) {
        db.collection("orders")
          .whereField("userId", isEqualTo: userId)
          .order(by: "orderDate", descending: true)
          .addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching orders: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            self.orders = documents.compactMap { doc in
                try? doc.data(as: Order.self)
            }
        }
    }

    /// Create a new order document.
    func addOrder(_ order: Order, completion: ((Error?) -> Void)? = nil) {
        do {
            _ = try db.collection("orders").addDocument(from: order)
            completion?(nil)
        } catch {
            print("Error saving order: \(error.localizedDescription)")
            completion?(error)
        }
    }

    /// Place a new order and return its Firestore-assigned document ID
    func placeOrder(_ order: Order, completion: @escaping (String?) -> Void) {
        do {
            // Add document and capture its reference
            let ref = try db.collection("orders").addDocument(from: order)
            // Return the generated document ID
            completion(ref.documentID)
        } catch {
            print("❌ Error placing order:", error.localizedDescription)
            completion(nil)
        }
    }
}
