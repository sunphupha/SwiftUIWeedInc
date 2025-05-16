//
//  AppDelegate.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import UIKit
import FirebaseCore 


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure() // ตั้งค่า Firebase ที่นี่
        print("Firebase configured successfully in AppDelegate.")

        #if DEBUG
         UserDefaults.standard.removeObject(forKey: "ageConfirmed")
         UserDefaults.standard.removeObject(forKey: "onboardComplete")
        #endif
        
        return true
    }
}
