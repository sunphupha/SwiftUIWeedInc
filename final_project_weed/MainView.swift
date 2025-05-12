//
//  MainView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI

struct MainView: View {
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
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }
                    DiaryPage()
                        .tabItem {
                            Label("Diary", systemImage: "book")
                        }
                    SettingPage()
                        .tabItem {
                            Label("Setting", systemImage: "gearshape")
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
    }
}
