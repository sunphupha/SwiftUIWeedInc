import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?   // FirebaseAuth.User

    private let auth = Auth.auth()
    private let db   = Firestore.firestore()

    init() {
        // ฟังการเปลี่ยนสถานะล็อกอิน/สมัคร
        auth.addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            if let u = user {
                self?.createUserProfileIfNeeded(
                    uid: u.uid,
                    email: u.email,
                    displayName: u.displayName
                )
            }
        }
    }

    // MARK: - Sign Up
    func signUp(email: String,
                password: String,
                displayName: String,
                completion: @escaping (Error?)->Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] res, err in
            if let err = err { completion(err); return }
            guard let user = res?.user else { return }

            // อัพเดต displayName ใน Auth
            let change = user.createProfileChangeRequest()
            change.displayName = displayName
            change.commitChanges { _ in
                // สร้าง profile ใน Firestore
                self?.createUserProfileIfNeeded(
                    uid: user.uid,
                    email: user.email,
                    displayName: displayName
                )
                completion(nil)
            }
        }
    }

    // MARK: - Sign In
    func signIn(email: String,
                password: String,
                completion: @escaping (Error?)->Void) {
        auth.signIn(withEmail: email, password: password) { _, err in
            completion(err)
        }
    }

    // MARK: - Sign Out
    func signOut() {
        try? auth.signOut()
    }

    // MARK: - Create / Update User Profile in Firestore
    private func createUserProfileIfNeeded(
        uid: String,
        email: String?,
        displayName: String?
    ) {
        let ref = db.collection("users").document(uid)
        ref.getDocument { snap, _ in
            if snap?.exists == false {
                // สร้างใหม่
                ref.setData([
                    "email"        : email ?? "",
                    "displayName"  : displayName ?? "",
                    "phone"        : "",
                    "photoURL"     : "",
                    "createdAt"    : FieldValue.serverTimestamp(),
                    "lastLogin"    : FieldValue.serverTimestamp(),
                    "favorites"    : [],
                    "diaryRefs"    : [],
                    "orderHistory" : []
                ], merge: true)
            } else {
                // อัพเดต lastLogin
                ref.updateData([
                    "lastLogin": FieldValue.serverTimestamp()
                ])
            }
        }
    }
}
