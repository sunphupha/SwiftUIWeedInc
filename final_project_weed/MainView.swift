//
//  MainView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI

struct MainView: View {
    @StateObject var userVM = UserViewModel()
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.user == nil {
                // Not signed in → show login screen
                LoginView()
            } else {
                // Signed in → show strains list
                TabView {
                    HomePage()
                        .environmentObject(userVM)
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }
                    NavigationView {
                        DiaryListView()
                    }
                    .environmentObject(userVM)
                    .tabItem {
                        Label("Diary", systemImage: "book")
                    }
                    UserPage()
                        .environmentObject(userVM)
                        .tabItem {
                            Label("User", systemImage: "person.circle")
                        }
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
          .environmentObject(AuthViewModel())
          .environmentObject(CartManager())
          .environmentObject(OrderViewModel())
          .environmentObject(PaymentViewModel())
          .environmentObject(DiaryViewModel()) // ถ้าใช้ @EnvironmentObject
    }
}
