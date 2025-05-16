//
//  UserModel.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import Foundation
import Firebase
import FirebaseFirestore

struct UserModel: Identifiable, Codable {
  @DocumentID var id: String?
  var displayName: String
  var email: String
  var photoURL: String
  var passwordEncrypted: String
  var phone: String
  var favorites: [String]
  var paymentMethods: [PaymentMethod]
}

struct PaymentMethod: Identifiable, Codable {
    var id: String
    var brand: String
    var last4: String
    var expMonth: Int
    var expYear: Int
    var cardholderName: String
    var token: String
    var isDefault: Bool
}

