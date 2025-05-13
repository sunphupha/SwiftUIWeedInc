import Foundation
import Firebase
import SwiftUI

struct StrainDetailView: View {
    @StateObject private var reviewVM = ReviewViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var quantity: Double = 3.5
    @State private var isFavorited = false
    @State private var showBuyNowAlert = false
    let strain: Strain
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 1) Top navigation
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Button(action: {
                        // TODO: navigate to cart
                    }) {
                        Image(systemName: "cart.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // 2) Hero image
                TabView {
                    AsyncImage(url: URL(string: strain.main_url)) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.2)
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Image(systemName: "photo").resizable().scaledToFit()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .tag(0)
                    AsyncImage(url: URL(string: strain.image_url)) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.2)
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Image(systemName: "photo").resizable().scaledToFit()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .tag(1)
                }
                .frame(height: 260)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .tabViewStyle(PageTabViewStyle())
                
                // 3) Title + type badge
                HStack(alignment: .firstTextBaseline) {
                    Text(strain.name)
                        .font(.title2).bold()
                    Spacer()
                    Text(strain.type)
                        .font(.subheadline).bold()
                        .padding(.vertical, 4).padding(.horizontal, 8)
                        .background(Color("AccentGreen").opacity(0.2))
                        .foregroundColor(Color("AccentGreen"))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                
                // New: Potency and Smell capsules
                HStack(spacing: 8) {
                    Text(String(
                        format: "THC: %.1f–%.1f%%   CBD: %.1f–%.1f%%",
                        strain.THC_min, strain.THC_max,
                        strain.CBD_min, strain.CBD_max
                    ))
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color("AccentGreen").opacity(0.1))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                    
                    Text("Smell: " + strain.smell_flavour.joined(separator: ", "))
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color("AccentGreen").opacity(0.1))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                // 4) Price & pack size
                HStack {
                    Text("$\(Int(strain.price))")
                        .font(.headline)
                    Spacer()
                    Text("Pack: 500 ฿ / \(Int(quantity)) g")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                
                /*
                // 5) Potency + aroma
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("THC").font(.caption).foregroundColor(.secondary)
                        Text("\(strain.THC_min, specifier: "%.0f")–\(strain.THC_max, specifier: "%.0f")%")
                            .font(.subheadline)
                    }
                    Divider().frame(height: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CBD").font(.caption).foregroundColor(.secondary)
                        Text("\(strain.CBD_min, specifier: "%.1f")–\(strain.CBD_max, specifier: "%.1f")%")
                            .font(.subheadline)
                    }
                    Divider().frame(height: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smell").font(.caption).foregroundColor(.secondary)
                        Text(strain.smell_flavour.joined(separator: ", "))
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                */
                
                // 6) Parents
                HStack {
                    Text("Parents:")
                        .font(.subheadline).bold()
                    Text(strain.parents.joined(separator: " × "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                // 7) Quantity selector + favorite
                HStack(spacing: 16) {
                    // Quantity selector
                    HStack {
                        Button(action: {
                            if quantity > 3.5 {
                                quantity -= 3.5
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Text(String(format: "%.1f g", quantity))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {
                            if quantity < 28 {
                                quantity += 3.5
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity)

                    // Favorite button
                    Button(action: {
                        isFavorited.toggle()
                    }) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(isFavorited ? .red : .secondary)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
                
                // 8) Add to Cart & Buy Now
                HStack(spacing: 12) {
                    Button("Add to Cart") {
                        // TODO: add to cart
                    }
                    .font(.subheadline).bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color("AccentGreen"))
                    .cornerRadius(10)
                    
                    Button("Buy Now") {
                        showBuyNowAlert = true
                    }
                    .font(.subheadline).bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color("AccentGreen"))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // 9) Details & Reviews
                Group {
                    DisclosureGroup("Details") {
                        Text(strain.description).font(.body).padding(.top, 8)
                    }
                    DisclosureGroup("Reviews") {
                        if reviewVM.reviews.isEmpty {
                            Text("No reviews yet").foregroundColor(.secondary)
                        } else {
                            ForEach(reviewVM.reviews) { rv in
                                HStack {
                                    Text(rv.comment).font(.body)
                                    Spacer()
                                    Text("\(rv.rating)★").foregroundColor(Color("AccentGreen"))
                                }
                                .padding(.vertical, 4)
                                Divider()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                
                Spacer(minLength: 20)
            }
            .alert("Buy Now", isPresented: $showBuyNowAlert) {
                Button("Confirm") { /* handle buy */ }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Proceed to buy \(strain.name) \(quantity, specifier: "%.1f")g?")
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
