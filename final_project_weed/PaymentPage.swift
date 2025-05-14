//
//  PaymentPage.swift
//  final_project_weed
//
//  Created by Sun Phupha on 14/5/2568 BE.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PaymentPage: View {
    let order: Order

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var paymentVM: PaymentViewModel
    @EnvironmentObject var orderVM: OrderViewModel
    @EnvironmentObject var diaryVM: DiaryViewModel
    @Environment(\.presentationMode) private var presentation

    @State private var showingAddCardForm = false
    @State private var selectedMethodID: String?
    @State private var navigateToDiaryDetail = false
    @State private var createdDiary: Diary?

    // Form fields for adding a new card
    @State private var cardNumber = ""
    @State private var cardHolder = ""
    @State private var expiryDate = ""
    @State private var securityCode = ""

    var body: some View {
        VStack(spacing: 16) {
            // Debug: show loaded methods count
            Text("DEBUG: Loaded cards = \(paymentVM.methods.count)")
                .font(.caption)
                .foregroundColor(.red)

            // Debug: show current user ID
            if let uid = authVM.user?.uid {
                Text("DEBUG: authVM.user.uid = \(uid)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            // Card selection carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    CardViewPlaceholder {
                        showingAddCardForm = true
                    }
                    ForEach(paymentVM.methods) { method in
                        PaymentCardView(method: method, isSelected: selectedMethodID == method.id)
                            .onTapGesture {
                                selectedMethodID = method.id
                                print("DEBUG: selected card id = \(selectedMethodID ?? "nil")")
                            }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 200)

            // Navigate to DiaryDetailView when a diary is created
            if let diary = createdDiary {
                NavigationLink(
                    destination: DiaryDetailView(diary: diary),
                    isActive: $navigateToDiaryDetail
                ) {
                    EmptyView()
                }
                .hidden()
            }

            Spacer()

            // Pay button
            Button {
                guard let uid = authVM.user?.uid else {
                    print("ERROR: authVM.user?.uid is nil")
                    return
                }
                // Place order and retrieve its Firestore-assigned ID
                orderVM.placeOrder(order) { newOrderID in
                    guard let oid = newOrderID, let uid = authVM.user?.uid else {
                        print("❌ Failed to get order ID or user ID")
                        return
                    }
                    // Upsert one Diary per strain in this order
                    var firstDiary: Diary?
                    for item in order.items {
                        let docId = "\(oid)-\(item.strainId)"   // unique per order & strain
                        let diary = Diary(
                            id: docId,
                            userId: uid,
                            orderId: oid,
                            strainId: item.strainId,
                            orderDate: order.orderDate,
                            useDate: Date(),
                            duration: item.quantity,
                            rating: 0.0,
                            feelings: [],
                            whyUse: [],
                            notes: ""
                        )
                        diaryVM.upsertDiary(diary)
                        if firstDiary == nil { firstDiary = diary }   // keep first for navigation
                    }
                    print("DEBUG: order placed with ID \(oid), navigating to diary detail")
                    DispatchQueue.main.async {
                        self.createdDiary = firstDiary
                        self.navigateToDiaryDetail = true
                    }
                }
            } label: {
                Text(String(format: "Pay ฿%.2f", order.total))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedMethodID == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(selectedMethodID == nil)
            .padding(.horizontal)
        }
        .navigationTitle("Payment")
        .sheet(isPresented: $showingAddCardForm) {
            NavigationView {
                Form {
                    Section(header: Text("Card Information")) {
                        TextField("Card Number", text: $cardNumber)
                            .keyboardType(.numberPad)
                        TextField("Card Holder", text: $cardHolder)
                        TextField("Expiry (MM/YY)", text: $expiryDate)
                            .keyboardType(.numbersAndPunctuation)
                        TextField("Security Code", text: $securityCode)
                            .keyboardType(.numberPad)
                    }
                    Button("Save Card") {
                        let newMethod = PaymentMethod(
                            id: UUID().uuidString,
                            brand: "Custom",
                            last4: String(cardNumber.suffix(4)),
                            expMonth: Int(expiryDate.prefix(2)) ?? 0,
                            expYear: Int(expiryDate.suffix(2)) ?? 0,
                            cardholderName: cardHolder,
                            token: "token_placeholder",
                            isDefault: paymentVM.methods.isEmpty
                        )
                        print("DEBUG: saving new card = \(newMethod)")
                        paymentVM.addMethod(newMethod)
                        showingAddCardForm = false
                    }
                    .disabled(cardNumber.count < 12 ||
                              cardHolder.isEmpty ||
                              expiryDate.count < 4 ||
                              securityCode.count < 3)
                }
                .navigationTitle("Add New Card")
                .navigationBarItems(leading: Button("Cancel") {
                    showingAddCardForm = false
                })
            }
        }
        .onAppear {
            if let uid = authVM.user?.uid {
                print("DEBUG: onAppear loadMethods(for: \(uid))")
                paymentVM.loadMethods(for: uid)
            } else {
                print("ERROR: onAppear authVM.user?.uid is nil")
            }
        }
    }
}

// Placeholder view for the Add Card card
private struct CardViewPlaceholder: View {
    let action: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 280, height: 180)
            Button(action: action) {
                VStack {
                    Image(systemName: "plus")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Add Card")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// Individual payment card view
private struct PaymentCardView: View {
    let method: PaymentMethod
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 4)
                .frame(width: 280, height: 180)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(method.brand).font(.headline)
                    Spacer()
                    Text(method.expiryDateFormatted).font(.subheadline)
                }
                Text("•••• \(method.last4)")
                    .font(.title2)
                    .monospacedDigit()
                Spacer()
                Text(method.cardholderName).font(.subheadline)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 3)
            )
        }
    }
}

// Format expiry date as MM/YY
private extension PaymentMethod {
    var expiryDateFormatted: String {
        String(format: "%02d/%02d", expMonth, expYear % 100)
    }
}

struct PaymentPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PaymentPage(order: Order(
                id: nil,
                userId: "uid",
                items: [],
                total: 0,
                orderDate: Date(),
                status: "pending"
            ))
            .environmentObject(AuthViewModel())
            .environmentObject(PaymentViewModel())
            .environmentObject(OrderViewModel())
        }
    }
}
