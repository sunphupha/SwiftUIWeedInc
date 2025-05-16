//
//  AddCardView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI

struct AddCardView: View {
    @Environment(\.presentationMode) var presentationMode // สำหรับการย้อนกลับเมื่อบันทึกเสร็จ
    @EnvironmentObject var paymentVM: PaymentViewModel // ViewModel สำหรับจัดการ Payment Methods

    // State สำหรับเก็บข้อมูลในฟอร์ม
    @State private var cardNumber: String = ""
    @State private var cardHolderName: String = ""
    @State private var expiryDateString: String = "" // เก็บเป็น MM/YY string
    @State private var securityCode: String = ""
    @State private var cardBrand: String = "Unknown" // สามารถเพิ่ม logic ตรวจจับ brand ได้

    //คำนวณเดือนและปีจาก expiryDateString
    private var parsedExpiry: (month: Int, year: Int) {
        let components = expiryDateString.split(separator: "/").map(String.init)
        guard components.count == 2,
              let month = Int(components[0]),
              let yearSuffix = Int(components[1])
        else {
            return (0, 0)
        }
        // สมมติว่าปีที่ใส่เป็น YY (เช่น 25 หมายถึง 2025)
        // คุณอาจจะต้องปรับ logic นี้ตามความต้องการ (เช่น รับเป็น YYYY)
        let currentYearPrefix = Calendar.current.component(.year, from: Date()) / 100
        return (month, currentYearPrefix * 100 + yearSuffix)
    }

    // ตรวจสอบความถูกต้องของฟอร์มคร่าวๆ
    private var isFormValid: Bool {
        !cardNumber.isEmpty && cardNumber.filter(\.isNumber).count >= 12 && cardNumber.filter(\.isNumber).count <= 19 &&
        !cardHolderName.isEmpty &&
        expiryDateString.matches(try! NSRegularExpression(pattern: #"^(0[1-9]|1[0-2])\/?([0-9]{2})$"#)) && // MM/YY format
        !securityCode.isEmpty && securityCode.filter(\.isNumber).count >= 3 && securityCode.filter(\.isNumber).count <= 4
    }

    var body: some View {
        Form {
            Section(header: Text("กรอกข้อมูลบัตรเครดิต/เดบิต")) {
                TextField("หมายเลขบัตร (Card Number)", text: $cardNumber)
                    .keyboardType(.numberPad)
                TextField("ชื่อผู้ถือบัตร (Cardholder Name)", text: $cardHolderName)
                    .autocapitalization(.words)
                TextField("วันหมดอายุ (MM/YY)", text: $expiryDateString)
                    .keyboardType(.numbersAndPunctuation)
                TextField("รหัสความปลอดภัย (CVV/CVC)", text: $securityCode)
                    .keyboardType(.numberPad)
            }

            Button(action: saveCard) {
                Text("บันทึกบัตร")
                    .frame(maxWidth: .infinity)
            }
            .disabled(!isFormValid) // ปิดการใช้งานปุ่มถ้าฟอร์มไม่ถูกต้อง
        }
        .navigationTitle("เพิ่มบัตรใหม่")
        .navigationBarTitleDisplayMode(.inline)
        // อาจจะเพิ่มปุ่ม Cancel ที่ NavigationBarItem ถ้าต้องการ
        // .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
    }

    private func saveCard() {
        guard isFormValid else { return }

        let expiry = parsedExpiry
        // TODO: เพิ่ม logic ในการตรวจสอบ brand ของบัตรจากหมายเลขบัตร
        // ปัจจุบันใช้ "Custom" หรือค่าที่ผู้ใช้เลือก (ถ้ามี UI ให้เลือก)
        // สำหรับตัวอย่างนี้จะใช้ "Visa" หรือ "Mastercard" แบบสุ่มถ้าไม่ทราบ
        let detectedBrand = detectCardBrand(cardNumber: cardNumber)


        let newMethod = PaymentMethod(
            id: UUID().uuidString, // สร้าง ID ใหม่เสมอ
            brand: detectedBrand,
            last4: String(cardNumber.suffix(4)),
            expMonth: expiry.month,
            expYear: expiry.year, // ส่งเป็นปีเต็ม YYYY
            cardholderName: cardHolderName,
            token: "tok_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())", // สร้าง token จำลอง
            isDefault: paymentVM.methods.isEmpty // ตั้งเป็น default ถ้าเป็นบัตรใบแรก
        )

        paymentVM.addMethod(newMethod) // เรียก ViewModel ให้เพิ่มบัตร
        presentationMode.wrappedValue.dismiss() // กลับไปหน้า PaymentPage
    }

    // ฟังก์ชันจำลองการตรวจสอบประเภทบัตร (ควรใช้ library จริง)
    private func detectCardBrand(cardNumber: String) -> String {
        let num = cardNumber.filter(\.isNumber)
        if num.hasPrefix("4") { return "Visa" }
        if num.hasPrefix("51") || num.hasPrefix("52") || num.hasPrefix("53") || num.hasPrefix("54") || num.hasPrefix("55") { return "Mastercard" }
        if num.hasPrefix("34") || num.hasPrefix("37") { return "American Express" }
        // เพิ่มเติมสำหรับ brand อื่นๆ
        return "Unknown" // หรือ "Generic"
    }
}

// Extension สำหรับ String เพื่อช่วย validate MM/YY (ตัวอย่าง)
extension String {
    func matches(_ regex: NSRegularExpression) -> Bool {
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

struct AddCardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddCardView()
                .environmentObject(PaymentViewModel()) // ต้องมีสำหรับ Preview
        }
    }
}

