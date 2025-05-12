//
//  UserModel.swift
//  final_project_weed
//
//  Created by Phatcharakiat Thailek on 12/5/2568 BE.
//

import Foundation

struct UserModel: Identifiable {
    var id: String
    var displayName: String
    var email: String
    var photoURL: String
    var passwordEncrypted: String
    var phone: String
    var favorites: [String]
}
