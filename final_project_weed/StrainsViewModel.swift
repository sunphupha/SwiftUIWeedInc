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
    @Published var allStrains: [Strain] = []
    @Published var isFiltering: Bool = false
    private let db = Firestore.firestore()
    
    func fetchStrains() {
        db.collection("strains")
          .limit(to: 10)
          .getDocuments { snap, error in
            if let error = error {
              print("❌ fetch error:", error)
              return
            }
            let list = snap?.documents.compactMap { try? $0.data(as: Strain.self) } ?? []
            DispatchQueue.main.async {
                self.allStrains = list
                self.strains = list
            }
        }
    }
    
    /// Filter the current list by a given effect; pass nil to clear filtering.
    func filterStrains(by effect: String?) {
        guard let eff = effect, !eff.isEmpty else {
            isFiltering = false
            strains = allStrains
            return
        }
        isFiltering = true
        strains = allStrains.filter { $0.effect.contains(eff) }
    }
}
