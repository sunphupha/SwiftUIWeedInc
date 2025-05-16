//
//  StrainDetailView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import Foundation
import Firebase
import SwiftUI

struct StrainDetailView: View {
    // MARK: - Properties
    let strain: Strain

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var diaryVM: DiaryViewModel
    @EnvironmentObject var userVM: UserViewModel

    @State private var quantity: Double = 3.5
    @State private var didAddToCart: Bool = false

    @State private var strainSpecificDiaryEntries: [Diary] = []
    
    @State private var isDetailsExpanded: Bool = false
    @State private var isReviewsExpanded: Bool = true

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TabView {
                    ProductImageView(url: strain.main_url)
                    if let extraUrl = URL(string: strain.image_url), strain.image_url != strain.main_url {
                        ProductImageView(url: strain.image_url)
                    }
                }
                .frame(height: 260)
                .tabViewStyle(PageTabViewStyle())
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 8)

                HStack(alignment: .firstTextBaseline) {
                    Text(strain.name)
                        .font(.title2.bold())
                    Spacer()
                    StrainTypeBadge(type: strain.type)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 6) {
                    InfoRow(label: "THC:", value: String(format: "%.1f–%.1f%%", strain.THC_min, strain.THC_max))
                    InfoRow(label: "CBD:", value: String(format: "%.1f–%.1f%%", strain.CBD_min, strain.CBD_max))
                    InfoRow(label: "Smell:", value: strain.smell_flavour.joined(separator: ", "))
                    InfoRow(label: "Parents:", value: strain.parents.joined(separator: " × "))
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                HStack {
                    Text(String(format: "฿%.0f", strain.price))
                        .font(.headline)
                        .foregroundColor(Color("AccentGreen"))
                    Text(String(format: "per %.1fg", 3.5))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                HStack(spacing: 16) {
                    QuantitySelector(quantity: $quantity)
                    FavoriteButton(strainId: strain.id ?? "unknown", authVM: authVM)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                VStack {
                    ActionButton(
                        title: "Add to Cart",
                        systemImage: "cart.badge.plus",
                        style: .primary,
                        foregroundColorOverride: .black
                    ) {
                        cartManager.add(strain, quantity: quantity)
                        withAnimation { didAddToCart = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { didAddToCart = false }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .overlay(
                    Text("Added to Cart!")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Capsule())
                        .offset(y: didAddToCart ? -30 : 20)
                        .opacity(didAddToCart ? 1 : 0)
                        .animation(.spring(), value: didAddToCart)
                )
                
                Group {
                    DisclosureGroup("Details", isExpanded: $isDetailsExpanded) {
                        Text(strain.description).font(.body).padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    DisclosureGroup("Reviews (\(strainSpecificDiaryEntries.count))", isExpanded: $isReviewsExpanded) {
                        if strainSpecificDiaryEntries.isEmpty {
                            Text("No reviews yet for \(strain.name).\nWrite a diary entry to add your review!")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 10) {
                                ForEach(strainSpecificDiaryEntries) { diaryEntry in
                                    DiaryEntryReviewCard(diary: diaryEntry)
                                        .environmentObject(userVM)
                                    if diaryEntry.id != strainSpecificDiaryEntries.last?.id {
                                        Divider().padding(.leading)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                Spacer(minLength: 20)
            }
        }
        .navigationTitle(strain.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("AccentGreen"))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: CartPage()) {
                    FinalCartIconView(itemCount: cartManager.items.count)
                }
            }
        }
        .onAppear(perform: loadAndFilterDiaryEntries)
        .onChange(of: diaryVM.diaries) { _ in
            print("DEBUG (StrainDetailView): diaryVM.diaries array has changed. Reloading/filtering entries.")
            loadAndFilterDiaryEntries()
        }
    }

    private func loadAndFilterDiaryEntries() {
        guard let strainId = strain.id, let currentUserID = authVM.user?.uid else {
            print("DEBUG (StrainDetailView): Strain ID or User ID is nil. Cannot load diary entries.")
            if !self.strainSpecificDiaryEntries.isEmpty { self.strainSpecificDiaryEntries = [] }
            return
        }
        
        if diaryVM.diaries.isEmpty && authVM.user != nil {
             print("DEBUG (StrainDetailView): diaryVM.diaries is empty for user \(currentUserID). Ensure DiaryViewModel is loading data. Current diary count in VM: \(diaryVM.diaries.count)")
        }

        let filtered = diaryVM.diaries.filter { diary in
            diary.strainId == strainId &&
            diary.userId == currentUserID &&
            !(diary.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }.sorted(by: { $0.useDate > $1.useDate })

        if self.strainSpecificDiaryEntries != filtered {
            self.strainSpecificDiaryEntries = filtered
            print("DEBUG (StrainDetailView): Updated strainSpecificDiaryEntries. Count: \(self.strainSpecificDiaryEntries.count)")
        } else {
            print("DEBUG (StrainDetailView): strainSpecificDiaryEntries data is already up-to-date. Count: \(self.strainSpecificDiaryEntries.count)")
        }
    }
}

// MARK: - Helper Subviews (Kept from original user's version with minor tweaks)

private struct FinalCartIconView: View {
    let itemCount: Int
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "cart.fill")
                .font(.title3)
                .foregroundColor(Color("AccentGreen"))
            if itemCount > 0 {
                Text("\(itemCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }
}

private struct ProductImageView: View {
    let url: String?
    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { phase in
            switch phase {
            case .empty: Color.gray.opacity(0.1).overlay(ProgressView())
            case .success(let image): image.resizable().scaledToFill()
            case .failure: Image(systemName: "photo.fill").resizable().scaledToFit().padding(40).foregroundColor(.gray.opacity(0.5))
            @unknown default: EmptyView()
            }
        }
        .clipped()
    }
}

private struct StrainTypeBadge: View {
    let type: String
    var body: some View {
        Text(type.capitalized)
            .font(.subheadline.bold())
            .padding(.vertical, 4).padding(.horizontal, 8)
            .background(Color("AccentGreen").opacity(0.2))
            .foregroundColor(Color("AccentGreen"))
            .clipShape(Capsule())
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }
}

private struct QuantitySelector: View {
    @Binding var quantity: Double
    private let step: Double = 3.5
    private let minQuantity: Double = 3.5
    private let maxQuantity: Double = 28.0

    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                if quantity > minQuantity { quantity -= step }
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(quantity <= minQuantity ? .gray.opacity(0.5) : Color.primary)
            }
            .disabled(quantity <= minQuantity)

            Text(String(format: "%.1f g", quantity))
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.primary)
                .frame(minWidth: 70, alignment: .center)

            Button(action: {
                if quantity < maxQuantity { quantity += step }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(quantity >= maxQuantity ? .gray.opacity(0.5) : Color.primary)
            }
            .disabled(quantity >= maxQuantity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct FavoriteButton: View {
    let strainId: String
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        Button(action: {
            authVM.toggleFavorite(strainId: strainId)
        }) {
            Image(systemName: authVM.favorites.contains(strainId) ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundColor(authVM.favorites.contains(strainId) ? .red : .secondary)
                .padding(10)
                .background(Color(UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

private enum ActionButtonStyle { case primary, secondary }

private struct ActionButton: View {
    let title: String
    let systemImage: String?
    let style: ActionButtonStyle
    var foregroundColorOverride: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.subheadline.bold())
            // Use override color if provided, else use style-based color
            .foregroundColor(foregroundColorOverride ?? (style == .primary ? .white : Color("AccentGreen")))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(style == .primary ? Color("AccentGreen") : Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
    }
}

private struct DiaryEntryReviewCard: View {
    let diary: Diary
    @EnvironmentObject var userVM: UserViewModel
    @State private var reviewerName: String = "User"

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(reviewerName)
                    .font(.caption.bold())
                Spacer()
                Text(diary.useDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 1) {
                ForEach(0..<5) { i in
                    Image(systemName: i < Int(diary.rating.rounded(.up)) ? "star.fill" : "star")
                        .foregroundColor(i < Int(diary.rating.rounded(.up)) ? .orange : .gray.opacity(0.4))
                        .font(.caption2)
                }
            }
            .padding(.bottom, 2)
            if let notes = diary.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(3)
                    .truncationMode(.tail)
            }
            if !diary.feelings.isEmpty || !diary.whyUse.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(diary.feelings, id: \.self) { feeling in
                            ReviewTagCard(text: feeling, color: .blue)
                        }
                        ForEach(diary.whyUse, id: \.self) { why in
                            ReviewTagCard(text: why, color: .green)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(8)
        .background(Color(UIColor.systemGray6).opacity(0.7))
        .cornerRadius(8)
        .onAppear {
            if diary.userId == userVM.user?.id {
                reviewerName = userVM.user?.displayName ?? "You"
            } else {
                reviewerName = "User \(diary.userId.prefix(4)).."
            }
        }
    }
}

private struct ReviewTagCard: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .padding(.vertical, 2)
            .padding(.horizontal, 5)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(5)
    }
}

// MARK: - Preview
#if DEBUG
struct StrainDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStrain = Strain(
            id: "acdcPreview", name: "ACDC", THC_min: 1.0, THC_max: 6.0,
            CBD_min: 15.0, CBD_max: 24.0,
            main_url: "https://placehold.co/600x400/aaffaa/333333?text=ACDC+Main",
            image_url: "https://placehold.co/600x400/aaccaa/333333?text=ACDC+Extra",
            price: 550, type: "CBD",
            parents: ["Ruderalis", "Cannatonic"],
            smell_flavour: ["earthy", "woody", "mild", "pine"],
            effect: ["Focused", "Relaxed", "Pain-Relief"],
            description: "ACDC is a sativa-dominant phenotype of the high-CBD cannabis strain Cannatonic..."
        )
        let mockAuthVM = AuthViewModel()
        let previewUserID = "previewUser123"
        let mockUserVM = UserViewModel()
        let mockDiaryVM = DiaryViewModel()

        if let strainId = mockStrain.id {
             mockDiaryVM.diaries = [
                Diary(id: "diary1", userId: previewUserID, orderId: "order1", strainId: strainId, orderDate: Date().addingTimeInterval(-86400*3), useDate: Date().addingTimeInterval(-86400*2), duration: 3.0, rating: 4.0, feelings: ["Relaxed", "Focused"], whyUse: ["Pain Relief"], notes: "Really helped with my back pain. Felt calm and focused without any high."),
                Diary(id: "diary2", userId: previewUserID, orderId: "order2", strainId: strainId, orderDate: Date().addingTimeInterval(-86400*5), useDate: Date().addingTimeInterval(-86400*4), duration: 2.0, rating: 5.0, feelings: ["Calm"], whyUse: ["Anxiety"], notes: "Excellent for anxiety, very mild effects otherwise. Will use again.")
            ]
        }

        return NavigationView {
            StrainDetailView(strain: mockStrain)
                .environmentObject(mockAuthVM)
                .environmentObject(CartManager())
                .environmentObject(mockDiaryVM)
                .environmentObject(mockUserVM)
        }
    }
}
#endif
