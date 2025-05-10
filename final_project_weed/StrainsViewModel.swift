//
//  StrainsViewModel.swift
//  final_project_weed
//
//  Created by Sun Phupha on 30/4/2568 BE.
//

import Firebase
import FirebaseFirestore

struct Strain: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var THC_min: Double
    var THC_max: Double
    var CBD_min: Double
    var CBD_max: Double
    var main_url: String
    var image_url: String
    var price: Double
    var type: String
    var parents: [String]
    var smell_flavour: [String]
    var effect: [String]
    var description: String
    // … เพิ่ม field อื่นๆ ตามต้องการ
}

class StrainsViewModel: ObservableObject {
    @Published var strains: [Strain] = []
    private let db = Firestore.firestore()
    
    func fetchStrains() {
        db.collection("strains")
          .getDocuments { snap, error in
            if let error = error {
              print("❌ fetch error:", error)
              return
            }
            self.strains = snap?.documents.compactMap {
              try? $0.data(as: Strain.self)
            } ?? []
            print("✅ Loaded \(self.strains.count) strains")
        }
    }
}

