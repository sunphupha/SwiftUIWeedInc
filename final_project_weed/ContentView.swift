//
//  ContentView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 29/4/2568 BE.
//

//  ContentView.swift
//  final_project_weed

import SwiftUI

// ไม่ต้องประกาศ Strain ซ้ำที่นี่
// import FirebaseFirestoreSwift  // ถ้าคุณ decode Firestore ใน ViewModel

// MARK: - Row View

struct StrainRow: View {
    let strain: Strain  // จากไฟล์โมเดลของคุณ
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ชื่อสายพันธุ์
            Text(strain.name)
                .font(.title3).bold()
            
            // รูป background + flower
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: strain.main_url)) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else if phase.error != nil {
                        Color.red.overlay(Image(systemName: "exclamationmark.triangle"))
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 100, height: 60).clipped().cornerRadius(6)
                
                AsyncImage(url: URL(string: strain.image_url)) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else if phase.error != nil {
                        Color.red.overlay(Image(systemName: "exclamationmark.triangle"))
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 60, height: 60).clipped().cornerRadius(6)
            }
            
            // ช่วง THC / CBD
            HStack {
                Text("THC \(strain.THC_min, specifier: "%.1f")–\(strain.THC_max, specifier: "%.1f")")
                Spacer()
                Text("CBD \(strain.CBD_min, specifier: "%.1f")–\(strain.CBD_max, specifier: "%.1f")")
            }
            .font(.subheadline)
            
            // ราคา + ประเภท
            HStack {
                Text("Price: \(strain.price) ฿")
                Spacer()
                Text(strain.type)
            }
            .font(.caption)
            
            // พ่อแม่สายพันธุ์
            Text("Parents: " + strain.parents.joined(separator: ", "))
                .font(.caption2)
            
            // รสและกลิ่น
            Text("Smell: " + strain.smell_flavour.joined(separator: ", "))
                .font(.caption2)
            
            // ผลลัพธ์ (effects)
            HStack {
                ForEach(strain.effect, id: \.self) { e in
                    Text(e.capitalized)
                        .font(.caption2)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            // คำอธิบายย่อ
            Text(strain.description)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Main ContentView

struct ContentView: View {
    @StateObject private var vm = StrainsViewModel()  // จากไฟล์ ViewModel ของคุณ
    
    var body: some View {
        NavigationView {
            List(vm.strains) { strain in
                StrainRow(strain: strain)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Cannabis Strains")
        }
        .onAppear {
            vm.fetchStrains()
        }
    }
}
