//
//  AgeConfirmationView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//


import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AgeConfirmationView: View {
    // เก็บสถานะยืนยันอายุใน UserDefaults
    @AppStorage("ageConfirmed") private var ageConfirmed = false
    
    @State private var selectedDay = 14
    @State private var selectedMonth = 5
    @State private var selectedYear = 2025
    @State private var isChecked = false
    @State private var showError  = false
    
    var body: some View {
        ZStack {
            // กำหนดสีพื้นหลังด้วยโค้ดสี HEX
            Color(hex: "#B8E0C2")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // โลโก้ + ชื่อแอป
                Image("HClogo")
                  .resizable()
                  .scaledToFit()
                  .frame(width: 60, height: 60)
                Text("HerbCare")
                  .font(.largeTitle).bold()
                
                // คำอธิบาย
                Text("Please confirm your age")
                  .font(.title2).bold()
                Text("This app contains cannabis-related content and products, restricted to users aged 20 or older under Thai law.")
                  .font(.body)
                  .multilineTextAlignment(.center)
                  .padding(.horizontal)
                
                // ช่องกรอก วัน เดือน ปี
                HStack(spacing: 16) {
                    // Day Picker
                    Picker("Day", selection: $selectedDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)")
                                .foregroundColor(.black)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.black)
                    .frame(width: 80)

                    // Month Picker
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text("\(month)")
                                .foregroundColor(.black)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.black)
                    .frame(width: 80)

                    // Year Picker
                    Picker("Year", selection: $selectedYear) {
                        ForEach(Array(stride(from: 2025, through: 1900, by: -1)), id: \.self) { year in
                            Text(String(year))
                                .foregroundColor(.black)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.black)
                    .frame(width: 100)
                }
                
                // Checkbox ยืนยัน
                Toggle(isOn: $isChecked) {
                  Text("I confirm that I am at least 20 years old and understand the legal terms of accessing cannabis content.")
                    .font(.caption)
                }
                .toggleStyle(CheckboxToggleStyle())
                .padding(.horizontal)
                
                // ปุ่ม Confirm
                HStack {
                    Button("Confirm") {
                        if validateAge() {
                            ageConfirmed = true
                        } else {
                            showError = true
                        }
                    }
//                    .frame(maxWidth: .infinity, minHeight: 44)
//                    .buttonStyle(.borderedProminent)
                    .disabled(!isChecked)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(isChecked ? Color(hex: "#B8E0C2") : Color.gray.opacity(0.5))
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .alert("You must be at least 20 years old to continue.", isPresented: $showError) {
                        Button("OK", role: .cancel) {}
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer()
            }
            // กำหนดสีการ์ดด้วยโค้ดสี HEX
            .background(Color(hex: "#FFF9F0"))
            .cornerRadius(20)
            .padding(.horizontal, 32)
        }
    }
    
    /// คำนวณอายุจากวันที่กรอก โดยใช้วันที่อ้างอิง 14/5/2025
    private func validateAge() -> Bool {
        // สมมติว่าต้องการใช้วันที่ตั้งต้น 14/5/2025
        guard
            let birth = Calendar.current.date(from: DateComponents(
                year: selectedYear,
                month: selectedMonth,
                day: selectedDay)),
            let referenceDate = Calendar.current.date(from: DateComponents(
                year: 2025,
                month: 5,
                day: 14))
        else {
            return false
        }
        // คำนวณอายุ ณ วันที่ referenceDate
        let ageComponents = Calendar.current.dateComponents([.year], from: birth, to: referenceDate)
        return (ageComponents.year ?? 0) >= 20
    }
}

struct AgeConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        AgeConfirmationView()
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
