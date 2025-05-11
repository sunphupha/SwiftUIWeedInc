//
//  GreenCartHomePage.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI

struct GreenCartHomePage: View {
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
                
                // Featured Section
                Text("Featured")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FeaturedItemView(name: "Purple Punch", type: "Indica", price: "$45")
                        FeaturedItemView(name: "Sour Diesel", type: "Sativa", price: "$50")
                        FeaturedItemView(name: "Blue Dream", type: "Hybrid", price: "$55")
                        FeaturedItemView(name: "Cannatonic", type: "CBD", price: "$40")
                    }
                    .padding(.horizontal)
                }

                // Effect Filters
                LazyVGrid(columns: [GridItem(), GridItem()]) {
                    EffectFilterView(name: "Relaxing", icon: "leaf")
                    EffectFilterView(name: "Energizing", icon: "sun.max")
                    EffectFilterView(name: "Focus", icon: "scope")
                    EffectFilterView(name: "Sleepy", icon: "moon")
                }
                .padding()

                // Categories
                Text("Categories")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(), GridItem()]) {
                    CategoryView(name: "Flower", icon: "leaf")
                    CategoryView(name: "Pre-Rolls", icon: "pencil.tip")
                    CategoryView(name: "Edibles", icon: "cube.box")
                    CategoryView(name: "Vapes", icon: "bolt.fill")
                }
                .padding()

                Text("VIEW ALL")
                    .foregroundColor(.green)
                    .font(.subheadline)
                    .padding(.horizontal)
            }
        }
    }
}

// Reusable Views
struct FeaturedItemView: View {
    var name: String
    var type: String
    var price: String
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
                .frame(width: 100, height: 100)
            
            Text(name)
                .font(.subheadline)
            Text(type)
                .font(.caption)
                .foregroundColor(.gray)
            Text(price)
                .font(.subheadline)
                .foregroundColor(.green)
        }
        .frame(width: 120)
    }
}

struct EffectFilterView: View {
    var name: String
    var icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(name)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CategoryView: View {
    var name: String
    var icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(name)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    GreenCartHomePage()
}
