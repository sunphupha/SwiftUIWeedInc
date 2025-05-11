//
//  OnboardingView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboardComplete") private var onboardComplete = false
    @State private var currentPage = 0
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack {

            TabView(selection: $currentPage) {
                OnboardingPageView(
                    title: "Welcome to HerbCare",
                    description: "Discover cannabis-related content tailored for you.",
                    imageName: "leaf.arrow.circlepath"
                )
                .tag(0)

                OnboardingPageView(
                    title: "Stay Informed",
                    description: "Learn about products and legal regulations.",
                    imageName: "book"
                )
                .tag(1)

                OnboardingPageView(
                    title: "Get Started",
                    description: "Enjoy the app safely and responsibly.",
                    imageName: "checkmark.seal"
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == currentPage ? Color.green : Color.gray.opacity(0.5))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 16)

            if currentPage == 2 {
                Button("Get Started") {
                    authVM.signOut()
                    onboardComplete = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 24)
            }

            Spacer()
        }
    }
}

struct OnboardingPageView: View {
    let title: String
    let description: String
    let imageName: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.green)
            Text(title)
                .font(.title)
                .bold()
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
