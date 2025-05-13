//
//  OrderDetailView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import SwiftUI
import FirebaseFirestore

struct OrderDetailView: View {
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showPayment = false

    // Unique strains in cart (without requiring Strain to be Hashable)
    private var uniqueStrains: [Strain] {
        var seenIds = Set<String>()
        return cartManager.items.compactMap { tuple in
            let strain = tuple.0
            // Ensure id is non-nil
            guard let id = strain.id, !seenIds.contains(id) else { return nil }
            seenIds.insert(id)
            return strain
        }
    }

    // Quantities per strain
    private var strainQuantities: [(strain: Strain, quantity: Double)] {
        uniqueStrains.map { strain in
            let totalQty = cartManager.items
                .filter { $0.0.id == strain.id }
                .map { $0.1 }
                .reduce(0, +)
            return (strain, totalQty)
        }
    }

    // Compute total price
    private var totalPrice: Double {
        strainQuantities.reduce(0) { sum, entry in
            let perGram = entry.strain.price / 3.5
            return sum + (perGram * entry.quantity)
        }
    }

    var body: some View {
        VStack {
            List {
                ForEach(strainQuantities, id: \.strain.id) { entry in
                    HStack {
                        Text(entry.strain.name)
                        Spacer()
                        Text("x\(entry.quantity, specifier: "%.1f") g")
                        Text("฿\((entry.strain.price/3.5) * entry.quantity, specifier: "%.2f")")
                    }
                }
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text("฿\(totalPrice, specifier: "%.2f")")
                        .font(.headline)
                }
            }
            .listStyle(.insetGrouped)

            NavigationLink(destination: PaymentView(), isActive: $showPayment) {
                Button("Check Bill") {
                    showPayment = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
        }
        .navigationTitle("Order Details")
    }
}

struct OrderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OrderDetailView()
                .environmentObject(CartManager())
                .environmentObject(AuthViewModel())
        }
    }
}
