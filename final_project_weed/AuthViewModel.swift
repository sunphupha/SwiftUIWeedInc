//
//  AuthViewModel.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var favorites: [String] = []

    private let auth = Auth.auth()
    private let db   = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            self.user = user
            
            if let firebaseUser = user {
                // ผู้ใช้ login เข้าระบบ (หรือ session ค้างอยู่)
                print("DEBUG (AuthViewModel listener): User is signed IN - UID: \(firebaseUser.uid)")
                self.fetchFavorites(uid: firebaseUser.uid)
                self.createUserProfileIfNeeded(
                    uid: firebaseUser.uid,
                    email: firebaseUser.email,
                    displayName: firebaseUser.displayName
                )
            } else {
                // ผู้ใช้ออกจากระบบ หรือยังไม่ได้ login
                print("DEBUG (AuthViewModel listener): User is signed OUT.")
                self.favorites = [] 
            }
        }
        print("DEBUG (AuthViewModel init): AuthStateDidChangeListener added. Firebase will now manage user session persistence.")
    }

    // MARK: - Sign Up
    func signUp(email: String,
                password: String,
                displayName: String,
                completion: @escaping (Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ ERROR (AuthViewModel signUp): \(error.localizedDescription)")
                completion(error)
                return
            }
            
            guard let firebaseUser = authResult?.user else {
                let noUserError = NSError(domain: "AuthViewModelError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User object not found after creation."])
                print("❌ ERROR (AuthViewModel signUp): \(noUserError.localizedDescription)")
                completion(noUserError)
                return
            }
            
            print("✅ SUCCESS (AuthViewModel signUp): User created with UID: \(firebaseUser.uid)")

            let changeRequest = firebaseUser.createProfileChangeRequest()
            let nameToSet = displayName.isEmpty ? (email.components(separatedBy: "@").first ?? "New User") : displayName
            changeRequest.displayName = nameToSet
            
            changeRequest.commitChanges { error in
                if let error = error {
                    print("❌ ERROR (AuthViewModel signUp): Failed to update display name: \(error.localizedDescription)")
                } else {
                    print("DEBUG (AuthViewModel signUp): Display name updated to '\(nameToSet)' for UID: \(firebaseUser.uid)")
                }
                // createUserProfileIfNeeded จะถูกเรียกโดย listener เมื่อ user state เปลี่ยนเป็น non-nil
                completion(nil)
            }
        }
    }

    // MARK: - Sign In
    func signIn(email: String,
                password: String,
                completion: @escaping (Error?) -> Void) {
        auth.signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("❌ ERROR (AuthViewModel signIn): \(error.localizedDescription)")
                completion(error)
                return
            }
            guard authResult?.user != nil else {
                let noUserError = NSError(domain: "AuthViewModelError", code: -2, userInfo: [NSLocalizedDescriptionKey: "User object not found after sign in."])
                print("❌ ERROR (AuthViewModel signIn): \(noUserError.localizedDescription)")
                completion(noUserError)
                return
            }
            print("✅ SUCCESS (AuthViewModel signIn): User signed in UID: \(authResult!.user.uid)")
            completion(nil)
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try auth.signOut()
            print("✅ SUCCESS (AuthViewModel signOut): User signed out via method call.")
            // self.user จะกลายเป็น nil โดยอัตโนมัติผ่าน authStateListenerHandle
            // และ listener จะเคลียร์ favorites และข้อมูล user อื่นๆ ที่จำเป็น
        } catch let signOutError as NSError {
            print("❌ ERROR (AuthViewModel signOut): %@", signOutError)
        }
    }

    // MARK: - Create / Update User Profile in Firestore
    private func createUserProfileIfNeeded(
        uid: String,
        email: String?,
        displayName: String?
    ) {
        let userDocumentRef = db.collection("users").document(uid)
        
        userDocumentRef.getDocument { documentSnapshot, error in
            if let error = error {
                print("❌ ERROR (AuthViewModel createUserProfile): Failed to get user document \(uid): \(error.localizedDescription)")
                return
            }
            
            let effectiveDisplayName = displayName?.isEmpty ?? true ? (email?.components(separatedBy: "@").first ?? "WeedLover") : displayName!

            if documentSnapshot?.exists == false {
                print("DEBUG (AuthViewModel createUserProfile): User document for \(uid) does not exist. Creating new profile.")
                userDocumentRef.setData([
                    "email"             : email ?? "",
                    "displayName"       : effectiveDisplayName,
                    "phone"             : "",
                    "photoURL"          : "",
                    "paymentMethods"    : [],
                    "passwordEncrypted" : "", // Should not store actual password
                    "createdAt"         : FieldValue.serverTimestamp(),
                    "lastLogin"         : FieldValue.serverTimestamp(),
                    "favorites"         : [],
                ], merge: false) { err in
                    if let err = err {
                        print("❌ ERROR (AuthViewModel createUserProfile): Failed to create user profile for \(uid): \(err.localizedDescription)")
                    } else {
                        print("✅ SUCCESS (AuthViewModel createUserProfile): User profile created for \(uid) with display name: \(effectiveDisplayName)")
                    }
                }
            } else {
                print("DEBUG (AuthViewModel createUserProfile): User document for \(uid) exists. Updating lastLogin and potentially displayName.")
                var updateData: [String: Any] = ["lastLogin": FieldValue.serverTimestamp()]
                
                let firestoreDisplayName = documentSnapshot?.data()?["displayName"] as? String
                if effectiveDisplayName != firestoreDisplayName { // Update if different or if Firestore name is nil
                    updateData["displayName"] = effectiveDisplayName
                     print("DEBUG (AuthViewModel createUserProfile): Updating displayName for \(uid) to '\(effectiveDisplayName)'")
                }

                if !updateData.isEmpty && updateData.count > 1 { // Only update if there's more than just lastLogin or if displayName changed
                    userDocumentRef.updateData(updateData) { err in
                        if let err = err {
                            print("❌ ERROR (AuthViewModel createUserProfile): Failed to update user profile for \(uid): \(err.localizedDescription)")
                        } else {
                            print("✅ SUCCESS (AuthViewModel createUserProfile): User profile updated for \(uid).")
                        }
                    }
                } else {
                     userDocumentRef.updateData(["lastLogin": FieldValue.serverTimestamp()]) // Just update lastLogin
                }
            }
        }
    }

    // MARK: - Favorites
    private func fetchFavorites(uid: String) {
        db.collection("users").document(uid)
          .addSnapshotListener { [weak self] documentSnapshot, error in
              guard let self = self else { return }
              if let error = error {
                  print("❌ ERROR (AuthViewModel fetchFavorites): Failed to fetch favorites for \(uid): \(error.localizedDescription)")
                  return
              }
              guard let data = documentSnapshot?.data(),
                    let favs = data["favorites"] as? [String] else {
                  print("DEBUG (AuthViewModel fetchFavorites): No favorites data found for \(uid) or data format incorrect.")
                  DispatchQueue.main.async { if self.favorites.isEmpty == false { self.favorites = [] } }
                  return
              }
              DispatchQueue.main.async {
                  if self.favorites != favs {
                      self.favorites = favs
                      print("DEBUG (AuthViewModel fetchFavorites): Favorites updated for \(uid). Count: \(favs.count)")
                  }
              }
          }
    }

    func toggleFavorite(strainId: String) {
        guard let uid = auth.currentUser?.uid else {
            print("❌ ERROR (AuthViewModel toggleFavorite): No authenticated user.")
            return
        }
        let userRef = db.collection("users").document(uid)
        if favorites.contains(strainId) {
            userRef.updateData(["favorites": FieldValue.arrayRemove([strainId])]) { error in
                if let error = error { print("❌ ERROR removing favorite: \(error.localizedDescription)") }
            }
        } else {
            userRef.updateData(["favorites": FieldValue.arrayUnion([strainId])]) { error in
                if let error = error { print("❌ ERROR adding favorite: \(error.localizedDescription)") }
            }
        }
    }
    
    // MARK: - Deinitializer
    deinit {
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
            print("DEBUG (AuthViewModel deinit): AuthStateDidChangeListener removed.")
        }
    }
}
