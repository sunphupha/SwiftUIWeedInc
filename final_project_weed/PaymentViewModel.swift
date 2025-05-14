//
//  PaymentViewModel.swift
//  final_project_weed
//
//  Created by Sun Phupha on 14/5/2568 BE.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class PaymentViewModel: ObservableObject {
    @Published var methods: [PaymentMethod] = []
    private let db = Firestore.firestore()

    /// Load payment methods for the current user
    func loadMethods() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        self.db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("❌ Failed to load paymentMethods:", error.localizedDescription)
                return
            }
            guard let snapshot = snapshot else { return }
            do {
                let user = try snapshot.data(as: UserModel.self)
                DispatchQueue.main.async {
                    self.methods = user.paymentMethods
                }
            } catch {
                print("❌ Failed to decode UserModel:", error)
            }
        }
    }

    /// Load payment methods for the specified user ID
    func loadMethods(for uid: String) {
        self.db.collection("users")
            .document(uid)
            .getDocument { snapshot, error in
                if let error = error {
                    print("❌ Failed to load paymentMethods for uid=\(uid):", error.localizedDescription)
                    return
                }
                guard let snapshot = snapshot else { return }
                do {
                    let user = try snapshot.data(as: UserModel.self)
                    DispatchQueue.main.async {
                        self.methods = user.paymentMethods
                    }
                } catch {
                    print("❌ Failed to decode UserModel:", error)
                }
            }
    }

    /// Add a new payment method to the current user
    func addMethod(_ method: PaymentMethod) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let data = try Firestore.Encoder().encode(method)
            self.db.collection("users").document(uid).updateData([
                "paymentMethods": FieldValue.arrayUnion([data])
            ])
        } catch {
            print("❌ Failed to encode paymentMethod:", error)
        }
    }

    /// Set the given payment method as default
    func setDefaultMethod(_ id: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        self.db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("❌ Failed to load userModel:", error.localizedDescription)
                return
            }
            guard let snapshot = snapshot else { return }
            do {
                var user = try snapshot.data(as: UserModel.self)
                user.paymentMethods = user.paymentMethods.map { pm in
                    var m = pm
                    m.isDefault = (pm.id == id)
                    return m
                }
                try self.db.collection("users").document(uid).setData(from: user)
            } catch {
                print("❌ Failed to update paymentMethods:", error)
            }
        }
    }
}
