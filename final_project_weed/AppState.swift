//
//  AppState.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
}
