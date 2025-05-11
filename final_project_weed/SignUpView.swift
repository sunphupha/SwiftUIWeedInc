//
//  SignUpView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isCreatingAccount: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    
    @FocusState private var focusedField: Field?
    private enum Field { case email, password, confirm }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("HerbCare")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Sign Up")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    VStack(spacing: 15) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .confirm }
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .focused($focusedField, equals: .confirm)
                            .submitLabel(.go)
                            .onSubmit { createAccount() }
                    }
                    Button {
                        createAccount()
                    } label: {
                        Text(isCreatingAccount ? "Creating Account..." : "Sign Up")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.green : Color.green.opacity(0.5))
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isCreatingAccount)
                    
                    Button("Already have an account? Log In") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func createAccount() {
        guard isFormValid else {
            errorMessage = password != confirmPassword
                ? "Passwords do not match."
                : "Password must be at least 8 characters."
            showingError = true
            return
        }
        isCreatingAccount = true
        authVM.signUp(email: email, password: password, displayName: "") { err in
            isCreatingAccount = false
            if let err = err {
                errorMessage = err.localizedDescription
                showingError = true
            } else {
                presentationMode.wrappedValue.dismiss()
                authVM.signOut()
            }
        }
    }
}
