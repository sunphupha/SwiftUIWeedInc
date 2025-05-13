//
//  WeedApp.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI
import FirebaseCore

@main
struct WeedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authVM = AuthViewModel()
    @AppStorage("ageConfirmed") private var ageConfirmed = false
    @AppStorage("onboardComplete") private var onboardComplete = false

    @StateObject private var cartManager = CartManager() // ✅ เพิ่มตรงนี้
    
    var body: some Scene {
        WindowGroup {
            if !ageConfirmed {
                AgeConfirmationView()
                  .environmentObject(authVM)
                  .environmentObject(cartManager) // ✅ inject
            } else if !onboardComplete {
                OnboardingView()
                  .environmentObject(authVM)
                  .environmentObject(cartManager) // ✅ inject
            } else {
                MainView()
                    .environmentObject(authVM)
                    .environmentObject(cartManager) // ✅ inject
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        #if DEBUG
        // DEBUG: reset onboarding/age flags for testing
//        UserDefaults.standard.removeObject(forKey: "ageConfirmed")
//        UserDefaults.standard.removeObject(forKey: "onboardComplete")
        #endif
        return true
    }
}
