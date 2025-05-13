//
//  DiaryDetailView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DiaryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = DiaryViewModel()
    
    // Incoming diary for edit, or new placeholder
    @State var diary: Diary
    
    // Local form state
    @State private var useDate: Date = Date()
    @State private var whyUse: Set<String> = []
    @State private var feelings: Set<String> = []
    @State private var duration: Double = 3.5
    @State private var rating: Double = 3.0
    @State private var notes: String = ""
    
    // Options
    private let whyOptions = ["Sleep","Focus","Anxiety","Creativity","Other"]
    private let feelingOptions = ["Relaxed","Happy","Euphoric","Calming","Pain-relieving"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Strain info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strain info").font(.caption).bold()
                    Text(diary.strainId.capitalized)
                        .font(.title3)
                    Text("Ordered on \(diary.orderDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                
                // 2. Time of use
                DatePicker("Time of Use", selection: $useDate, displayedComponents: [.date, .hourAndMinute])
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                
                // 3. Why did you use it?
                TagSelectionView(title: "Why did you use it?", options: whyOptions, selection: $whyUse)
                
                // 4. What did you feel?
                TagSelectionView(title: "What did you feel?", options: feelingOptions, selection: $feelings)
                
                // 5. Duration
                HStack {
                    Text("Duration (hrs)").bold()
                    Spacer()
                    Button("-") { duration = max(0.5, duration - 0.5) }
                    Text("\(duration, specifier: "%.1f")")
                    Button("+") { duration = min(28, duration + 0.5) }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
                // 6. Overall rating
                RatingView(rating: $rating)
                
                // 7. Notes
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                // 8. Save button
                Button(action: saveEntry) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .onAppear(perform: populateFields)
        }
        .navigationTitle("Log Your Experience")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func populateFields() {
        useDate = diary.useDate
        whyUse = Set(diary.whyUse)
        feelings = Set(diary.feelings)
        duration = diary.duration
        rating = diary.rating
        notes = diary.notes ?? ""
    }
    
    private func saveEntry() {
        guard let uid = authVM.user?.uid else { return }
        diary.useDate = useDate
        diary.whyUse = Array(whyUse)
        diary.feelings = Array(feelings)
        diary.duration = duration
        diary.rating = rating
        diary.notes = notes
        diary.userId = uid
        vm.addDiary(diary)
        dismiss()
    }
}

// DateFormatter for display
private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .long
    return f
}()
