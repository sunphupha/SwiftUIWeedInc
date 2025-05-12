//
//  Setting.swift
//  final_project_weed
//
//  Created by Phatcharakiat Thailek on 12/5/2568 BE.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingPage: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var editableName = ""
    @State private var editablePhone = ""
    @State private var showSaveAlert = false
    @State private var isEditing = false
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPasswordUpdateAlert = false
    @State private var passwordUpdateMessage = ""
    
    func updateEditableFields(with user: UserModel) {
        editableName = user.displayName
        editablePhone = user.phone
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Setting")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                if let user = viewModel.user {
                    VStack(spacing: 10) {
                        if !user.photoURL.isEmpty, let url = URL(string: user.photoURL) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    ProgressView()
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }
                        
                        Text(user.displayName)
                            .font(.title2)
                        Text(user.email)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Spacer()
                            Button(action: {
                                isEditing.toggle()
                            }) {
                                Text(isEditing ? "Cancel" : "Edit")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("Display Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if isEditing {
                            TextField("Enter name", text: $editableName)
                        } else {
                            Text(editableName)
                        }
                        Divider()
                        
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(user.email)
                        Divider()
                        
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.gray)
                        SecureField("************", text: .constant(user.passwordEncrypted))
                            .disabled(true)
                        Divider()
                        
                        if isEditing {
                            Text("New Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            SecureField("Enter new password", text: $newPassword)
                            Divider()
                            
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            SecureField("Confirm new password", text: $confirmPassword)
                            Divider()
                        }
                        
                        Text("Phone")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if isEditing {
                            TextField("Enter phone number", text: $editablePhone)
                        } else {
                            Text(editablePhone)
                        }
                        Divider()
                        
                        Text("Favorite Strains")
                            .font(.caption)
                            .foregroundColor(.gray)
                        ForEach(user.favorites, id: \.self) { strain in
                            Text("• \(strain)")
                        }

                        // Linked Account Section
                        Text("Linked Account")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack(alignment: .center, spacing: 24) {
                            Image(systemName: "globe") // placeholder for Google
                                .resizable()
                                .frame(width: 24, height: 24)
                            Image(systemName: "xmark") // placeholder for Apple/X
                                .resizable()
                                .frame(width: 24, height: 24)
                            Image(systemName: "f.cursive.circle.fill") // more modern style
                                .resizable()
                                .frame(width: 24, height: 24)
                            if isEditing {
                                Button(action: {
                                    // Handle editing linked accounts
                                }) {
                                    Image(systemName: "pencil")
                                }
                            }
                        }

                        // Add Logout and Deactivate Account buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                do {
                                    try Auth.auth().signOut()
                                    // Handle navigation or state change after logout
                                } catch {
                                    print("Logout failed: \(error.localizedDescription)")
                                }
                            }) {
                                Text("Logout")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black, lineWidth: 1)
                                    )
                            }

                            Button(action: {
                                guard let user = Auth.auth().currentUser else { return }
                                let uid = user.uid
                                let db = Firestore.firestore()

                                // Delete Firestore user document
                                db.collection("users").document(uid).delete { error in
                                    if let error = error {
                                        print("Failed to delete user document: \(error.localizedDescription)")
                                    } else {
                                        // Delete user authentication
                                        user.delete { error in
                                            if let error = error {
                                                print("Failed to delete user account: \(error.localizedDescription)")
                                            } else {
                                                print("Account deactivated successfully.")
                                                // Optionally: navigate back to login screen
                                            }
                                        }
                                    }
                                }
                            }) {
                                Text("Deactivate Account")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top)
                        
                        if isEditing {
                            Button(action: {
                                if let uid = Auth.auth().currentUser?.uid {
                                    let db = Firestore.firestore()
                                    db.collection("users").document(uid).updateData([
                                        "displayName": editableName,
                                        "phone": editablePhone
                                    ]) { error in
                                        if let error = error {
                                            print("Error updating user: \(error)")
                                        } else {
                                            self.showSaveAlert = true
                                            self.viewModel.user?.displayName = self.editableName
                                            self.viewModel.user?.phone = self.editablePhone
                                            isEditing = false
                                        }
                                    }
                                }
                            }) {
                                Text("Save")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.top)
                            
                            Button(action: {
                                guard newPassword == confirmPassword else {
                                    passwordUpdateMessage = "Passwords do not match"
                                    showPasswordUpdateAlert = true
                                    return
                                }
                                
                                Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                                    if let error = error {
                                        passwordUpdateMessage = "Error: \(error.localizedDescription)"
                                    } else {
                                        passwordUpdateMessage = "Password updated successfully"
                                        newPassword = ""
                                        confirmPassword = ""
                                    }
                                    showPasswordUpdateAlert = true
                                }
                            }) {
                                Text("Change Password")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .onAppear {
                        updateEditableFields(with: user)
                    }
                } else {
                    ProgressView("Loading...")
                        .onAppear {
                            viewModel.fetchUserData()
                        }
                }
                
                Spacer()
            }
            .padding()
            .alert(isPresented: $showSaveAlert) {
                Alert(
                    title: Text("Saved"),
                    message: Text("Your changes have been saved successfully."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showPasswordUpdateAlert) {
                Alert(
                    title: Text("Password Update"),
                    message: Text(passwordUpdateMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}
