//
//  UserViewModel.swift
//  final_project_weed
//
//  Created by Phatcharakiat Thailek on 12/5/2568 BE.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

class UserViewModel: ObservableObject {
    @Published var user: UserModel?
    
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No logged in user")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let name = data?["displayName"] as? String ?? "Unknown"
                let email = data?["email"] as? String ?? ""
                let photoURL = data?["photoURL"] as? String ?? ""
                
                DispatchQueue.main.async {
                    let passwordEncrypted = data?["passwordEncrypted"] as? String ?? "********"
                    let phone = data?["phone"] as? String ?? "-"
                    let favorites = data?["favorites"] as? [String] ?? []

                    self.user = UserModel(id: uid, displayName: name, email: email, photoURL: photoURL, passwordEncrypted: passwordEncrypted, phone: phone, favorites: favorites)
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}
