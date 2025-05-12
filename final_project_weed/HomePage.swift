//
//  GreenCartHomePage.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI
import Foundation

struct HomePage: View {
    @StateObject private var vm = StrainsViewModel()
    @State private var selectedEffect: String? = nil
    let effectOptions = ["Relaxed", "Happy", "Euphoric", "Creative", "Sleepy", "Hungry", "Energetic", "Focused"]
    
    var body: some View {
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
                
                // Filtered Strains List
                let filteredStrains = selectedEffect == nil ? vm.strains : vm.strains.filter { $0.effect.contains(selectedEffect!) }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredStrains) { strain in
                        HotDealItemView(
                            name: strain.name,
                            thc: String(format: "%.1f–%.1f", strain.THC_min, strain.THC_max),
                            cbd: String(format: "%.1f", strain.CBD_min),
                            parents: strain.parents.joined(separator: " × "),
                            smell: strain.smell_flavour.joined(separator: ", "),
                            tags: strain.effect,
                            imageURL: strain.main_url
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .onAppear {
            vm.fetchStrains()
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
}
//
#Preview {
    HomePage()
}
