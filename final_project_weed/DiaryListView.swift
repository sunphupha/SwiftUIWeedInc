//
//  DiaryListView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 11/5/2568 BE.
//

import SwiftUI

struct DiaryListView: View {
    @EnvironmentObject var diaryVM: DiaryViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var strainsVM: StrainsViewModel
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {

        Group {
            if diaryVM.diaries.isEmpty {
                emptyDiaryView
            } else {
                diaryList
            }
        }
        .navigationTitle("My Diary")
        .toolbar {
   
        }
        .onAppear {
            if let currentFirebaseUser = authVM.user {
                print("DEBUG (DiaryListView): Appearing. User is logged in (UID: \(currentFirebaseUser.uid)). Current diary count in VM: \(diaryVM.diaries.count).")
                diaryVM.loadDiaries()
            } else {
                print("DEBUG (DiaryListView): Appearing. No Firebase user logged in. Diaries will likely be empty.")
                diaryVM.diaries = []
            }
        }
    }

    // MARK: - Subviews

    private var diaryList: some View {
        List {
            ForEach(diaryVM.diaries) { diary in
                ZStack {
                    DiaryCardView(diary: diary)
                        .environmentObject(strainsVM)
                    
                    NavigationLink(destination: DiaryDetailView(diary: diary)
                                                .environmentObject(userVM)
                                                .environmentObject(diaryVM)
                                                .environmentObject(authVM)
                                                .environmentObject(strainsVM)
                    ) {
                        EmptyView()
                    }
                    .opacity(0)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
            .padding(.horizontal, 16)            .padding(.top, 0)
        }
    }

    private var emptyDiaryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.gray.opacity(0.4))
            Text("No Diary Entries Yet")
                .font(.title3.weight(.medium))
                .foregroundColor(Color(UIColor.secondaryLabel))
            Text("Record your cannabis experiences after trying a strain to see them here.")
                .font(.subheadline)
                .foregroundColor(Color(UIColor.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Diary Card View (Helper View for displaying each diary entry)

struct DiaryCardView: View {
    let diary: Diary
    @EnvironmentObject var strainsVM: StrainsViewModel

    private var strain: Strain? {
        strainsVM.allStrains.first { $0.id == diary.strainId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) { // Adjusted spacing and alignment
                if let strain = strain, let imageUrl = URL(string: strain.main_url) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray5)).frame(width: 60, height: 60).overlay(ProgressView())
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill).frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray5)).frame(width: 60, height: 60).overlay(Image(systemName: "photo.fill").foregroundColor(Color(UIColor.systemGray3)))
                        @unknown default: EmptyView()
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray5)).frame(width: 60, height: 60).overlay(Image(systemName: "leaf.fill").font(.title2).foregroundColor(Color(UIColor.systemGray3)))
                }

                VStack(alignment: .leading, spacing: 2) { // Reduced spacing
                    Text(strain?.name ?? "Strain \(diary.strainId.prefix(6))")
                        .font(.headline.weight(.semibold)) // Slightly bolder
                        .foregroundColor(Color(UIColor.label))
                        .lineLimit(1)
                    Text("Used on: \(diary.useDate, formatter: Self.dateFormatter)")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                Spacer() // Push rating to the right if space allows
            }

            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Image(systemName: index < Int(diary.rating.rounded(.up)) ? "star.fill" : "star")
                        .foregroundColor(index < Int(diary.rating.rounded(.up)) ? .orange : Color(UIColor.systemGray3))
                        .font(.callout)
                }
                Text(String(format: "(%.1f)", diary.rating))
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .padding(.top, -4)

            if let notes = diary.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.label).opacity(0.8)) // Slightly less prominent
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .padding(.top, 4)
            }

            if !diary.feelings.isEmpty || !diary.whyUse.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(diary.feelings, id: \.self) { feeling in
                            DiaryTagView(text: feeling, color: .purple)
                        }
                        ForEach(diary.whyUse, id: \.self) { why in
                            DiaryTagView(text: why, color: .teal)
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(15)
        .background(Material.thin)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.07), radius: 5, x: 0, y: 3)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private struct DiaryTagView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(color.opacity(0.1))
            .foregroundColor(color.opacity(0.9))
            .clipShape(Capsule())
    }
}


// MARK: - Preview
#if DEBUG
struct DiaryListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockDiaryVM = DiaryViewModel()
        let mockUserVM = UserViewModel()
        let mockStrainsVM = StrainsViewModel()
        let mockAuthVM = AuthViewModel()

        // Simulate a logged-in user by setting a mock Firebase User in AuthViewModel if possible,
        // or ensure that DiaryViewModel's loadDiaries can work with a default UID for previews
        // For this example, we'll assume DiaryViewModel can fetch with a known previewUserID
        // or that authVM.user might provide one.
        let previewUserID = "previewTestUser123" // Example UID
        
        // If your AuthViewModel.user is a Firebase.User, mocking can be tricky.
        // If it's a custom struct, you can set it:
        // mockAuthVM.user = YourAppUser(uid: previewUserID, ...)
        // mockUserVM.user = UserModel(id: previewUserID, displayName: "Preview User", ...)


        mockStrainsVM.allStrains = [
            Strain(id: "strainA", name: "Cosmic Haze", THC_min: 18, THC_max: 22, CBD_min: 0.1, CBD_max: 0.5, main_url: "https://placehold.co/100x100/A9DEF9/333?text=CH", image_url: "", price: 600, type: "Sativa", parents: [], smell_flavour: [], effect: [], description: ""),
            Strain(id: "strainB", name: "Purple Dream", THC_min: 20, THC_max: 25, CBD_min: 0.2, CBD_max: 0.8, main_url: "https://placehold.co/100x100/E0BBE4/333?text=PD", image_url: "", price: 700, type: "Indica", parents: [], smell_flavour: [], effect: [], description: "")
        ]
        
        mockDiaryVM.diaries = [
            Diary(id: "d1", userId: previewUserID, orderId: "o1", strainId: "strainA", orderDate: Date(), useDate: Date().addingTimeInterval(-86400 * 2), duration: 2.5, rating: 4.5, feelings: ["Creative", "Uplifted"], whyUse: ["Daytime Focus"], notes: "Felt very inspired and energetic. Great for creative work sessions during the day. Smooth smoke."),
            Diary(id: "d2", userId: previewUserID, orderId: "o2", strainId: "strainB", orderDate: Date(), useDate: Date().addingTimeInterval(-86400 * 5), duration: 3.0, rating: 4.0, feelings: ["Relaxed", "Sleepy"], whyUse: ["Evening Wind-down"], notes: "Perfect for relaxing before bed. Helped with my insomnia. Would recommend for nighttime use."),
            Diary(id: "d3", userId: previewUserID, orderId: "o3", strainId: "unknownStrain", orderDate: Date(), useDate: Date().addingTimeInterval(-86400 * 1), duration: 1.5, rating: 3.0, feelings: ["Okay"], whyUse: ["Curiosity"], notes: "Didn't feel much from this one. Maybe need a higher dose or different strain next time.")
        ]

        // DiaryListView is typically presented within a NavigationView that's part of a TabView
        // So, for the preview, we wrap it in a NavigationView.
        return NavigationView {
            DiaryListView()
                .environmentObject(mockDiaryVM)
                .environmentObject(mockUserVM)
                .environmentObject(mockStrainsVM)
                .environmentObject(mockAuthVM) // << Inject mockAuthVM
        }
    }
}
#endif
