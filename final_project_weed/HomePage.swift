//
//  GreenCartHomePage.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI
import Foundation

import FirebaseCore
import FirebaseStorage

class CartManager: ObservableObject {
    @Published var items: [Strain] = []

    func add(_ item: Strain) {
        items.append(item)
    }

    func remove(_ item: Strain) {
        items.removeAll { $0.id == item.id }
    }
}

struct HomePage: View {
    @StateObject private var vm = StrainsViewModel()
    @State private var selectedEffect: String? = nil
    let effectOptions = ["Relaxing", "Happy", "Euphoric", "Creative",  "Energizing", "Focused", "Stress-relieving", "Pain-relieving"]
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                
                // Header
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                    Text("GreenCart")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    NavigationLink(destination: CartPage()) {
                        Image(systemName: "cart")
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Text("High quality. Higher convenience.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                // Search Bar
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.green.opacity(0.1))
                    .frame(height: 40)
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            Text("Search")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                            .padding(.horizontal)
                    )
                    .padding()
                
                // Hot Deal Section
                Text("Hot Deal")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(vm.strains.prefix(10)) { deal in
                            HotDealItemView(
                                name: deal.name,
                                thc: String(format: "%.1f–%.1f", deal.THC_min, deal.THC_max),
                                cbd: String(format: "%.1f", deal.CBD_min),
                                parents: deal.parents.joined(separator: " × "),
                                smell: deal.smell_flavour.joined(separator: ", "),
                                tags: deal.effect,
                                imageURL: deal.main_url
                            )
                            .frame(width: 200)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Effects Filter Section
                Text("Effects")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(effectOptions, id: \.self) { effect in
                            Text(effect)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(selectedEffect == effect ? Color.green.opacity(0.7) : Color.green.opacity(0.2))
                                .foregroundColor(selectedEffect == effect ? .white : .green)
                                .cornerRadius(20)
                                .onTapGesture {
                                    if selectedEffect == effect {
                                        selectedEffect = nil
                                    } else {
                                        selectedEffect = effect
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - Filtered Strains List
                let filteredStrains: [Strain] = {
                    guard let eff = selectedEffect, !eff.isEmpty else {
                        return vm.strains
                    }
                    return vm.strains.filter { strain in
                        strain.effect.contains { tag in
                            tag.lowercased() == eff.lowercased()
                        }
                    }
                }()

                VStack(spacing: 16) {
                    ForEach(filteredStrains) { strain in
                        NavigationLink(destination: StrainDetailView(strain: strain)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 16) {
                                    // 1. รูป thumbnail
                                    AsyncImage(url: URL(string: strain.main_url)) { phase in
                                        if let img = phase.image {
                                            img.resizable()
                                               .scaledToFill()
                                               .frame(width: 80, height: 80)
                                               .cornerRadius(8)
                                        } else if phase.error != nil {
                                            Color.gray
                                              .frame(width: 80, height: 80)
                                              .cornerRadius(8)
                                        } else {
                                            ProgressView()
                                              .frame(width: 80, height: 80)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        // 2. ชื่อและปุ่มตะกร้า
                                        HStack {
                                            Text(strain.name)
                                                .font(.headline)
                                            Spacer()
                                            Button {
                                                cartManager.add(strain)
                                            } label: {
                                                Image(systemName: "cart.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }

                                        // 3. THC / CBD (บน)
                                        Text("THC: \(String(format: "%.1f–%.1f", strain.THC_min, strain.THC_max))    CBD: \(String(format: "%.1f–%.1f", strain.CBD_min, strain.CBD_max))")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)

                                        // 4. Smell (ล่าง)
                                        Text("Smell: " + strain.smell_flavour.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)

                                        // 5. Tags (effect) เป็นกรอบๆ
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(strain.effect, id: \.self) { tag in
                                                    Text(tag.capitalized)
                                                        .font(.caption)
                                                        .padding(.vertical, 4)
                                                        .padding(.horizontal, 8)
                                                        .background(Color.green.opacity(0.2))
                                                        .cornerRadius(8)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Divider()
                    }
                }
                .padding(.top, 8)
            }
        }
            }
            .onAppear {
                vm.fetchStrains()
            }
        }
    }
    
    struct HotDealItemView: View {
        var name: String
        var thc: String
        var cbd: String
        var parents: String
        var smell: String
        var tags: [String]
        var imageURL: String
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                AsyncImage(url: URL(string: imageURL)) { phase in
                    if let img = phase.image {
                        img.resizable()
                           .scaledToFit()
                           .frame(width: 150, height: 150)
                           .cornerRadius(8)
                    } else if phase.error != nil {
                        Color.gray.frame(width: 150, height: 150).cornerRadius(8)
                    } else {
                        ProgressView().frame(width: 150, height: 150)
                    }
                }
                
                Text("THC : \(thc)   CBD : \(cbd)")
                    .font(.subheadline)
                Text("Parents : \(parents)")
                    .font(.subheadline)
                Text("Smell : \(smell)")
                    .font(.subheadline)
                
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<4) { idx in
                        if idx < tags.count {
                            Text(tags[idx])
                                .frame(maxWidth: .infinity)
                                .padding(6)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(6)
                                .font(.caption)
                        } else {
                            Color.clear
                                .frame(height: 24)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }

    struct CartPage: View {
        @EnvironmentObject var cartManager: CartManager

        var body: some View {
            VStack(alignment: .leading) {
                Text("Your Cart")
                    .font(.largeTitle)
                    .padding()

                List {
                    ForEach(cartManager.items) { item in
                        HStack(alignment: .top, spacing: 16) {
                            // Thumbnail
                            AsyncImage(url: URL(string: item.main_url)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                } else if phase.error != nil {
                                    Color.gray
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                } else {
                                    ProgressView()
                                        .frame(width: 60, height: 60)
                                }
                            }

                            // Details
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text("THC: \(String(format: "%.1f–%.1f", item.THC_min, item.THC_max))  CBD: \(String(format: "%.1f–%.1f", item.CBD_min, item.CBD_max))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Smell: " + item.smell_flavour.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            // Remove button
                            Button {
                                cartManager.remove(item)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
//
#Preview {
    HomePage().environmentObject(CartManager())
}
