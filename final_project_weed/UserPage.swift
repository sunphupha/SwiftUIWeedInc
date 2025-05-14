//
//  UserPage.swift
//  final_project_weed
//
//  Created by Sun Phupha on 14/5/2568 BE.
//

import SwiftUI

struct UserPage: View {
    @EnvironmentObject var userVM: UserViewModel
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    NavigationLink(destination: SettingPage()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .padding()
                    }
                }
                if let urlString = userVM.user?.photoURL,
                   let url = URL(string: urlString) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Color.gray
                                        }
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .padding(.bottom, 8)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100,height: 100)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                }
                if let user = userVM.user {
                    Text(user.displayName)
                        .font(.title)
                        .bold()
                } else {
                    ProgressView()
                }
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            userVM.fetchUserData()
        }
    }
}

#Preview {
    UserPage()
        .environmentObject(UserViewModel())
}
