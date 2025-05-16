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
    // Now stores tuples of (Strain, Double)
    @Published var items: [(Strain, Double)] = []

    func add(_ item: Strain, quantity: Double) {
        if let idx = items.firstIndex(where: { $0.0.id == item.id }) {
            items[idx].1 += quantity
        } else {
            items.append((item, quantity))
        }
    }

    func remove(_ item: Strain) {
        items.removeAll { $0.0.id == item.id }
    }

    func update(_ item: Strain, quantity: Double) {
        if let idx = items.firstIndex(where: { $0.0.id == item.id }) {
            if quantity <= 0 {
                remove(item)
            } else {
                items[idx].1 = quantity
            }
        }
    }
}

struct HomePage: View {
    @StateObject private var vm = StrainsViewModel()
    @State private var selectedEffect: String? = nil
    let effectOptions = ["Relaxing", "Happy", "Euphoric", "Creative",  "Energizing", "Focused", "Stress-relieving", "Pain-relieving"]
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var authVM: AuthViewModel
    // Removed quantities state since Stepper is gone
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                
                // Header
                HStack {
                    Image("HClogo")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                    Text("HerbCare")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Spacer()
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
                                        // 2. ชื่อและปุ่มตะกร้า/หัวใจในแนวตั้ง
                                        HStack(alignment: .center, spacing: 8) {             Text(strain.name)
                                                .font(.headline)
                                            Spacer()
//                                            Stepper(value: Binding(
//                                                get: { quantities[strain.id!] ?? 3.5 },
//                                                set: { quantities[strain.id!] = $0 }
//                                            ), in: 3.5...28, step: 3.5) {
//                                                Text("\(quantities[strain.id!] ?? 3.5, specifier: "%.1f") g")
//                                                    .font(.subheadline)
//                                            }
//                                            .frame(width: 120)
                                            // Only the cart button remains
                                            Button {
                                                let grams = 3.5
                                                cartManager.add(strain, quantity: grams)
                                            } label: {
                                                let count = cartManager.items.filter { $0.0.id == strain.id }.reduce(0) { $0 + Int($1.1 / 3.5) }
                                                ZStack(alignment: .topTrailing) {
                                                    Image(systemName: "cart.fill")
                                                        .font(.title2)
                                                        .foregroundColor(count > 0 ? .green : .gray)
                                                    if count > 0 {
                                                        Text("\(count)")
                                                            .font(.caption2)
                                                            .foregroundColor(.white)
                                                            .padding(4)
                                                            .background(Color.green)
                                                            .clipShape(Circle())
                                                            .offset(x: 8, y: -8)
                                                    }
                                                }
                                            }
                                        }

                                        // 3. THC / CBD (บน)
                                        Text("THC: \(String(format: "%.1f–%.1f", strain.THC_min, strain.THC_max))    CBD: \(String(format: "%.1f–%.1f", strain.CBD_min, strain.CBD_max))")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)

                                        // 4. Smell (ล่าง) with heart button
                                        HStack {
                                            Text("Smell: " + strain.smell_flavour.joined(separator: ", "))
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Button(action: {
                                                authVM.toggleFavorite(strainId: strain.id!)
                                            }) {
                                                Image(systemName: authVM.favorites.contains(strain.id!) ? "heart.fill" : "heart")
                                                    .foregroundColor(authVM.favorites.contains(strain.id!) ? .red : .gray)
                                                    .font(.title3)
                                            }
                                        }

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

        // Total price of cart items
        private var cartTotal: Double {
            cartManager.items
                .map { let perGram = $0.0.price / 3.5; return perGram * $0.1 }
                .reduce(0, +)
        }

        var body: some View {
            VStack(alignment: .leading) {
                Text("Your Cart")
                    .font(.largeTitle)
                    .padding()

                List {
                    ForEach(cartManager.items, id: \.0.id) { item, qty in
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
                                Text("Qty: \(qty, specifier: "%.1f") g")
                                    .font(.subheadline)
                                
//                                Text(String(format: "฿ %.0f", item.price))
                                // Calculate per-gram price from default pack (3.5 g)
                                let perGram = item.price / 3.5
                                let total = perGram * qty
                                Text(String(format: "฿ %.0f", total))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                
                                Stepper(value: Binding(
                                    get: { qty },
                                    set: { cartManager.update(item, quantity: $0) }
                                ), in: 0...28, step: 3.5) {
                                    Text("Adjust: \(qty, specifier: "%.1f") g")
                                        .font(.caption)
                                }
                                .frame(width: 180)
                                Text("THC: \(String(format: "%.1f–%.1f", item.THC_min, item.THC_max))  CBD: \(String(format: "%.1f–%.1f", item.CBD_min, item.CBD_max))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Smell: " + item.smell_flavour.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                cartManager.remove(item)
                            } label: {
                                Text("Delete")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Display cart total
                HStack {
                    Text("Total:")
                        .font(.headline)
                    Spacer()
                    Text("฿\(cartTotal, specifier: "%.2f")")
                        .font(.headline)
                }
                .padding(.horizontal)

                // Checkout button
                NavigationLink(destination: OrderDetailView()) {
                    Text("Check Out")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
    }
//
#Preview {
    HomePage()
        .environmentObject(CartManager())
        .environmentObject(AuthViewModel())
}

//เหลือแสดงราคาคา
