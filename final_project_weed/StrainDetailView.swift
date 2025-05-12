//
//  StrainDetailView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import SwiftUI

// Note: Strain model and CartViewModel singleton are assumed to be defined elsewhere.
// Strain model should have properties:
//   name: String
//   type: String
//   price: Double
//   THC_min: Double
//   THC_max: Double
//   CBD_min: Double
//   CBD_max: Double
//   parents: String
//   smell: String
//   description: String
//   imageURLs: [String]

// Note: ReviewViewModel and review model are assumed to be defined elsewhere.

struct StrainDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var strain: Strain
    
    @State private var quantity: Double = 3.5
    @State private var isFavorited: Bool = false
    @State private var showBuyNowAlert: Bool = false
    
    @StateObject private var reviewVM = ReviewViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Button(action: {
                        // Cart action (not specified)
                    }) {
                        Image(systemName: "cart")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Carousel
                TabView {
                    // Use both flower and background URLs
                    let galleryURLs = [strain.image_url, strain.main_url]
                    ForEach(galleryURLs, id: \.self) { urlString in
                        AsyncImage(url: URL(string: urlString)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 250)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipped()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 250)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .frame(height: 250)
                .tabViewStyle(PageTabViewStyle())
                
                // Badge for type
                Text(strain.type)
                    .font(.caption)
                    .bold()
                    .padding(8)
                    .background(Circle().fill(Color.green.opacity(0.2)))
                    .foregroundColor(.green)
                
                // Name
                Text(strain.name)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Price line
                Text("\(strain.price, specifier: "%.0f")฿ / \(quantity, specifier: "%.1f")g")
                    .font(.headline)
                    .padding(.horizontal)
                
                // THC and CBD line
                Text("THC: \(strain.THC_min, specifier: "%.1f") - \(strain.THC_max, specifier: "%.1f")  CBD: \(strain.CBD_min, specifier: "%.1f") - \(strain.CBD_max, specifier: "%.1f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Parents
                HStack {
                    Text("Parents:")
                        .bold()
                    Text(strain.parents.joined(separator: " × "))
                    Spacer()
                }
                .padding(.horizontal)
                
                // Smell
                HStack {
                    Text("Smell:")
                        .bold()
                    Text(strain.smell_flavour.joined(separator: ", "))
                    Spacer()
                }
                .padding(.horizontal)
                
                // Quantity selector
                HStack(spacing: 20) {
                    Button(action: {
                        if quantity > 3.5 {
                            quantity -= 3.5
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .font(.title2)
                    }
                    Text("\(quantity, specifier: "%.1f") g")
                        .font(.headline)
                        .frame(minWidth: 80)
                    Button(action: {
                        if quantity < 28.0 {
                            quantity += 3.5
                        }
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Favorite button
                Button(action: {
                    isFavorited.toggle()
                }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.title)
                        .foregroundColor(isFavorited ? .red : .gray)
                }
                
                // Add to Cart and Buy Now buttons
//                HStack(spacing: 20) {
//                    Button(action: {
//                        CartViewModel.shared.add(strain: strain, quantity: quantity)
//                    }) {
//                        Text("Add to Cart")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .frame(maxWidth: .infinity)
//                            .background(Color.blue)
//                            .cornerRadius(10)
//                    }
//                    Button(action: {
//                        showBuyNowAlert = true
//                    }) {
//                        Text("Buy Now")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .frame(maxWidth: .infinity)
//                            .background(Color.orange)
//                            .cornerRadius(10)
//                    }
//                }
//                .padding(.horizontal)
                
                // DisclosureGroups
                DisclosureGroup("Details") {
                    Text(strain.description)
                        .padding(.top, 5)
                        .padding(.bottom, 10)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                DisclosureGroup("Reviews") {
                    if reviewVM.reviews.isEmpty {
                        Text("No reviews yet.")
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                            .padding(.bottom, 10)
                    } else {
                        ForEach(reviewVM.reviews) { review in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(review.reviewerName)
                                    .font(.headline)
                                Text(review.comment)
                                    .font(.body)
                            }
                            .padding(.vertical, 5)
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
        }
        .alert(isPresented: $showBuyNowAlert) {
            Alert(
                title: Text("Buy Now"),
                message: Text("Proceed to buy \(strain.name) \(quantity, specifier: "%.1f")g?"),
                primaryButton: .default(Text("Confirm")) {
                    // Implement buy now action here
                },
                secondaryButton: .cancel()
            )
        }
    }
}
