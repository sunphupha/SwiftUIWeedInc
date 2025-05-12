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
    
    var body: some View {
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
            } else {
                ProgressView("Loading...")
                    .onAppear {
                        viewModel.fetchUserData()
                    }
            }
            
            Spacer()
        }
        .padding()
    }
}
