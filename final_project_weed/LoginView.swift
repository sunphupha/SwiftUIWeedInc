//
//  LoginView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 10/5/2568 BE.
//


import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email       = ""
    @State private var password    = ""
    @State private var isCreating  = false
    @State private var displayName = ""
    @State private var errorMsg    = ""
    
    @FocusState private var focusedField: Field?
    private enum Field { case email, password }
    @State private var showingSignUp = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("HerbCare")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 40)
                    
                    Text("Log In")
                        .font(.title2)
                    
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color(.sRGB, red: 250/255, green: 247/255, blue: 239/255, opacity: 1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 185/255, green: 152/255, blue: 125/255), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.sRGB, red: 250/255, green: 247/255, blue: 239/255, opacity: 1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 185/255, green: 152/255, blue: 125/255), lineWidth: 1)
                            )
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { handleAuth() }
                        
                        // show error message
                        if !errorMsg.isEmpty {
                            Text(errorMsg)
                                .foregroundColor(.red)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Button(action: {
                        // No action specified
                    }) {
                        Text("Forget Your Password?")
                            .foregroundColor(Color(red: 184/255, green: 224/255, blue: 194/255))
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button(action: handleAuth) {
                        Text("Login")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 184/255, green: 224/255, blue: 194/255))
                            .cornerRadius(10)
                    }
                    
                    Button("Sign Up") {
                        showingSignUp = true
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .sheet(isPresented: $showingSignUp) {
                        SignUpView()
                            .environmentObject(authVM)
                    }
                }
                .padding(.horizontal, 24)
            }
            .background(Color(red: 255/255, green: 249/255, blue: 240/255).ignoresSafeArea())
        }
    }

    private func handleAuth() {
        errorMsg = ""
        if isCreating {
            authVM.signUp(
                email: email,
                password: password,
                displayName: displayName
            ) { err in
                if let err = err {
                    errorMsg = err.localizedDescription
                }
            }
        } else {
            authVM.signIn(
                email: email,
                password: password
            ) { err in
                if let err = err {
                    errorMsg = err.localizedDescription
                }
            }
        }
    }
}
