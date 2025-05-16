//
//  MainView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 10/5/2568 BE.
//
import SwiftUI

struct MainView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var orderVM: OrderViewModel
    @EnvironmentObject var paymentVM: PaymentViewModel
    @EnvironmentObject var diaryVM: DiaryViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if authVM.user == nil {
                LoginView()
                    .environmentObject(authVM)
            } else {
                TabView(selection: $appState.selectedTab) {
                    
                    // Tab 1: HomePage
                    HomePage()
                        .environmentObject(authVM)
                        .environmentObject(userVM)
                        .environmentObject(cartManager)
                        .tabItem {
                            Label("หน้าหลัก", systemImage: "house.fill")
                        }
                        .tag(0)

                    NavigationView {
                        DiaryListView()
                            .environmentObject(diaryVM)
                            .environmentObject(userVM)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Label("ไดอารี่", systemImage: "book.fill")
                    }
                    .tag(1)

                    NavigationView {
                        UserPage()
                            .environmentObject(authVM)
                            .environmentObject(userVM)
                            .environmentObject(paymentVM)
                            .environmentObject(orderVM)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Label("โปรไฟล์", systemImage: "person.fill")
                    }
                    .tag(2)
                }
                .onAppear {
                    print("MainView appeared. Current selected tab from AppState: \(appState.selectedTab)")
                    if authVM.user != nil && userVM.user == nil {
                        userVM.fetchUserData()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        // สร้าง Mock Instances สำหรับ Preview
        let mockAuthVM = AuthViewModel()
        // สมมติว่าผู้ใช้ login แล้วสำหรับ Preview
        // mockAuthVM.user = ... // คุณอาจจะต้องสร้าง Mock User object หรือ instance ของ FirebaseAuth.User

        let mockUserVM = UserViewModel()
        let mockCartManager = CartManager()
        let mockOrderVM = OrderViewModel()
        let mockPaymentVM = PaymentViewModel()
        let mockDiaryVM = DiaryViewModel()
        let mockAppState = AppState()
        // mockAppState.selectedTab = 0 // สามารถตั้งค่า Tab เริ่มต้นสำหรับ Preview ได้

        return MainView()
            .environmentObject(mockAuthVM)
            .environmentObject(mockUserVM)
            .environmentObject(mockCartManager)
            .environmentObject(mockOrderVM)
            .environmentObject(mockPaymentVM)
            .environmentObject(mockDiaryVM)
            .environmentObject(mockAppState)
    }
}
#endif
