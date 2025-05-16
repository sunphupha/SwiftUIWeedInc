//
//  WeedApp.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import SwiftUI
import FirebaseCore

@main
struct WeedApp: App {
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // MARK: - State Objects (ViewModels and Global State)
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var userVM = UserViewModel()
    @StateObject private var cartManager = CartManager()
    @StateObject private var orderVM = OrderViewModel()
    @StateObject private var paymentVM = PaymentViewModel()
    @StateObject private var diaryVM = DiaryViewModel()
    @StateObject private var strainsVM = StrainsViewModel()
    @StateObject private var appState = AppState()

    // MARK: - App Storage
    @AppStorage("ageConfirmed") private var ageConfirmed = false
    @AppStorage("onboardComplete") private var onboardComplete = false

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            Group {
                if !ageConfirmed {
                    AgeConfirmationView()
                } else if !onboardComplete {
                    OnboardingView()
                } else {
                    MainView()
                }
            }
            .environmentObject(authVM)
            .environmentObject(userVM)
            .environmentObject(cartManager)
            .environmentObject(orderVM)
            .environmentObject(paymentVM)
            .environmentObject(diaryVM)
            .environmentObject(strainsVM)
            .environmentObject(appState)
            .onAppear {
                print("DEBUG (WeedApp): Root view appeared. Fetching initial strains data if needed.")
            }
        }
    }
}

