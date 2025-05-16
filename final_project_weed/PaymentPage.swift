//
//  PaymentPage.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import SwiftUI

struct PaymentPage: View {
    // MARK: - Properties
    
    let order: Order

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var paymentVM: PaymentViewModel
    @EnvironmentObject var orderVM: OrderViewModel
    @EnvironmentObject var diaryVM: DiaryViewModel

    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedMethodID: String? = nil
    @State private var showPaymentSuccessAlert: Bool = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            if !paymentVM.methods.isEmpty {
                Text("เลือกวิธีการชำระเงิน:")
                    .font(.headline)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("จำนวนบัตรที่โหลด: \(paymentVM.methods.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("ยังไม่มีวิธีการชำระเงินที่บันทึกไว้")
                    .font(.callout)
                    .foregroundColor(.orange)
                    .padding(.top)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    NavigationLink(destination: AddCardView().environmentObject(paymentVM)) {
                        CardViewPlaceholderNavigation()
                    }
                    ForEach(paymentVM.methods) { method in
                        PaymentCardView(method: method, isSelected: selectedMethodID == method.id)
                            .onTapGesture {
                                selectedMethodID = method.id
                                print("DEBUG (PaymentPage): เลือกบัตร ID = \(selectedMethodID ?? "nil")")
                            }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 210)

            Spacer()

            Button(action: processPaymentAndShowConfirmation) { // <--- เปลี่ยนชื่อ action
                Text(String(format: "ชำระเงิน ฿%.2f", order.total))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedMethodID == nil ? Color.gray.opacity(0.5) : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedMethodID == nil)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("การชำระเงิน")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let uid = authVM.user?.uid {
                paymentVM.loadMethods(for: uid)
            }
            if selectedMethodID == nil, let defaultCard = paymentVM.methods.first(where: { $0.isDefault }) {
                selectedMethodID = defaultCard.id
            } else if selectedMethodID == nil, let firstCard = paymentVM.methods.first {
                 selectedMethodID = firstCard.id
            }
        }
        .alert(isPresented: $showPaymentSuccessAlert) {
            Alert(
                title: Text("การสั่งซื้อสำเร็จ"),
                message: Text("คำสั่งซื้อของคุณได้รับการยืนยันแล้ว และข้อมูลได้ถูกบันทึกลงในไดอารี่เรียบร้อย"),
                dismissButton: .default(Text("ตกลง")) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    // MARK: - Private Methods
    
    private func processPaymentAndShowConfirmation() {
        guard let currentUserID = authVM.user?.uid, selectedMethodID != nil else {
            print("ERROR (PaymentPage): User ID หรือ Payment Method ไม่ถูกต้อง กรุณาตรวจสอบ")
            // TODO: ควรแสดง Alert ข้อผิดพลาดให้ผู้ใช้ทราบ (อาจจะใช้ State อีกตัวสำหรับ Error Alert)
            return
        }

        print("DEBUG (PaymentPage): เริ่มกระบวนการสั่งซื้อสำหรับผู้ใช้ UID: \(currentUserID) ด้วยบัตร ID: \(selectedMethodID!)")

        orderVM.placeOrder(order) { newOrderID in
            guard let generatedOrderID = newOrderID else {
                print("❌ (PaymentPage): ไม่สามารถสร้าง Order ID ได้จาก Firestore")
                // TODO: ควรแสดง Alert ข้อผิดพลาด
                return
            }

            print("DEBUG (PaymentPage): สร้าง Order สำเร็จ ID: \(generatedOrderID)")

            for item in order.items {
                let diaryEntryID = "\(generatedOrderID)-\(item.strainId)"
                let newDiary = Diary(
                    id: diaryEntryID,
                    userId: currentUserID,
                    orderId: generatedOrderID,
                    strainId: item.strainId,
                    orderDate: order.orderDate,
                    useDate: Date(),
                    duration: item.quantity,
                    rating: 0.0,
                    feelings: [],
                    whyUse: [],
                    notes: ""
                )
                diaryVM.upsertDiary(newDiary)
            }
            if !order.items.isEmpty {
                print("DEBUG (PaymentPage): สร้าง Diary entries เสร็จสิ้น")
            }

            DispatchQueue.main.async {
                print("DEBUG (PaymentPage): กำลังจะแสดง Alert ยืนยันการสั่งซื้อ")
                self.showPaymentSuccessAlert = true
            }
        }
    }
}

// MARK: - Helper Views (CardViewPlaceholderNavigation, PaymentCardView)

private struct CardViewPlaceholderNavigation: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
                .frame(width: 280, height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                )
            VStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(Color.green)
                Text("เพิ่มบัตรใหม่")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary.opacity(0.8))
            }
        }
    }
}

private struct PaymentCardView: View {
    let method: PaymentMethod
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 1. พื้นหลังของการ์ด (RoundedRectangle และ Gradient)
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: isSelected ? [Color.green.opacity(0.75), Color.green.opacity(0.95)] : [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: Color.black.opacity(isSelected ? 0.3 : 0.2), radius: isSelected ? 7 : 5, x: 0, y: isSelected ? 4 : 2)

            // 2. Content VStack: จัดการเนื้อหาทั้งหมดบนการ์ด
            VStack(alignment: .leading, spacing: 0) {
                // ส่วนบน: Brand และ ไอคอนบัตร
                HStack {
                    Text(method.brand.isEmpty ? "Unknown Card" : method.brand)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: cardIconName(for: method.brand))
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 10)

                // ส่วนกลาง: หมายเลขบัตร
                Text("•••• \(method.last4)")
                    .font(.system(size: 26, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(3)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 5)

                // Spacer หลัก: ดันส่วนล่าง (Card Holder, Expires) ลงไป
                Spacer(minLength: 12)

                // ส่วนล่าง: Card Holder และ Expires
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CARD HOLDER")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        Text(method.cardholderName.isEmpty ? "N/A" : method.cardholderName.uppercased())
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    Spacer()
                    // ข้อมูล Expires
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("EXPIRES")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        Text(method.expiryDateFormatted)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))

            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow, lineWidth: 3.5)
            }
        }
        .frame(width: 280, height: 180)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
    }
    
    private func cardIconName(for brand: String) -> String {
        switch brand.lowercased() {
        case "visa":
            return "creditcard.circle.fill"
        case "mastercard":
            return "creditcard.circle.fill"
        case "american express":
            return "creditcard.circle.fill"
        default:
            return "creditcard"
        }
    }
}

// MARK: - Extensions
private extension PaymentMethod {
    var expiryDateFormatted: String {
        let yearString = (expYear >= 2000) ? String(expYear % 100) : String(format: "%02d", expYear)
        return String(format: "%02d/%@", expMonth, yearString)
    }
}

// MARK: - Preview
#if DEBUG
struct PaymentPage_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthVM = AuthViewModel()
        // mockAuthVM.user = ... // Mock user if needed

        let mockPaymentVM = PaymentViewModel()
        mockPaymentVM.methods = [
            PaymentMethod(id: "pm_1", brand: "Visa", last4: "1234", expMonth: 12, expYear: 2025, cardholderName: "PREVIEW USER ONE", token: "tok_preview1", isDefault: true),
            PaymentMethod(id: "pm_2", brand: "Mastercard", last4: "5678", expMonth: 10, expYear: 2026, cardholderName: "TEST ACCOUNT TWO", token: "tok_preview2", isDefault: false)
        ]
        
        let mockOrder = Order(
            id: "previewOrder123",
            userId: "previewUID",
            items: [OrderItem(strainId: "ogkush", quantity: 3.5, price: 500, name: "OG Kush")],
            total: 500.00,
            orderDate: Date(),
            status: "pending"
        )
        
        // let mockAppState = AppState() // ไม่จำเป็นต้องใช้ AppState ใน Preview นี้แล้ว

        return NavigationView {
            PaymentPage(order: mockOrder)
                .environmentObject(mockAuthVM)
                .environmentObject(mockPaymentVM)
                .environmentObject(OrderViewModel())
                .environmentObject(DiaryViewModel())
                // .environmentObject(mockAppState) // ไม่ต้อง inject AppState แล้ว
        }
    }
}
#endif
