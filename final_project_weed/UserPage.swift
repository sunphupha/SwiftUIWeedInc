//
//  UserPage.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import SwiftUI
import Charts

// MARK: - Main UserPage (Dashboard View)
struct UserPage: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var diaryVM: DiaryViewModel
    @EnvironmentObject var strainsVM: StrainsViewModel

    @State private var selectedTimeFilter: TimeFilterOption = .past7Days
    @State private var processedChartData: [RatingDataPoint] = []
    @State private var commonEffectsData: [CommonEffectData] = []
    @State private var triedStrainsData: [Strain] = []
    @State private var recommendedStrainsData: [Strain] = []

    enum TimeFilterOption: String, CaseIterable, Identifiable {
        case past7Days = "Past 7 Days"
        case past30Days = "Past 30 Days"
        case allTime = "All Time"
        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("My Dashboard")
                                .font(.largeTitle.bold())
                            Text(userVM.user?.displayName ?? "Your Cannabis Experience")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 4)

                    FeelingChartView(
                        chartData: processedChartData,
                        selectedTimeFilter: $selectedTimeFilter
                    )

                    CommonEffectsView(effects: commonEffectsData)
                    TriedStrainsView(strains: triedStrainsData)
                    RecommendedStrainsView(strains: recommendedStrainsData)

                    Spacer(minLength: 30)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingPage()
                                                .environmentObject(userVM)
                                                .environmentObject(authVM)
                    ) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.black) // <<<< เปลี่ยนสีไอคอน Settings เป็นสีดำ
                    }
                }
            }
            .onAppear {
                print("DEBUG (UserPage): onAppear. User UID: \(authVM.user?.uid ?? "nil").")
                if strainsVM.allStrains.isEmpty {
                    print("DEBUG (UserPage): StrainsVM is empty, fetching strains.")
                    strainsVM.fetchStrains()
                }
                if authVM.user != nil && diaryVM.diaries.isEmpty {
                     print("DEBUG (UserPage): User is logged in but diaryVM.diaries is empty. Triggering diaryVM.loadDiaries().")
                     diaryVM.loadDiaries()
                }
                processDashboardData()
            }
            .onChange(of: diaryVM.diaries) { newDiaries in
                print("DEBUG (UserPage): diaryVM.diaries changed. New count: \(newDiaries.count). Reprocessing dashboard data.")
                processDashboardData()
            }
            .onChange(of: selectedTimeFilter) { newFilter in
                print("DEBUG (UserPage): selectedTimeFilter changed to \(newFilter.rawValue). Reprocessing dashboard data (including chart).")
                processDashboardData()
            }
            .onChange(of: authVM.user) { newUser in
                print("DEBUG (UserPage): authVM.user changed (New UID: \(newUser?.uid ?? "nil")). Reprocessing dashboard data.")
                if newUser != nil {
                    diaryVM.loadDiaries()
                }
                processDashboardData()
            }
        }
    }

    private func processDashboardData() {
        guard let currentUserID = authVM.user?.uid else {
            print("DEBUG (UserPage processDashboardData): No authenticated user. Clearing dashboard data.")
            processedChartData = []
            commonEffectsData = []
            triedStrainsData = []
            recommendedStrainsData = []
            return
        }
        
        let userSpecificDiaries = diaryVM.diaries.filter { $0.userId == currentUserID }
        
        print("DEBUG (UserPage processDashboardData): Processing for UID: \(currentUserID). Found \(userSpecificDiaries.count) user-specific diaries. Total diaries in VM: \(diaryVM.diaries.count). Strains in VM: \(strainsVM.allStrains.count)")

        processChartData(for: userSpecificDiaries)
        calculateCommonEffects(from: userSpecificDiaries)
        loadTriedStrains(from: userSpecificDiaries)
        generateRecommendations(basedOn: userSpecificDiaries)
        
        print("DEBUG (UserPage processDashboardData): Finished. Chart: \(processedChartData.count), Effects: \(commonEffectsData.count), Tried: \(triedStrainsData.count), Recommended: \(recommendedStrainsData.count)")
    }

    private func processChartData(for userDiaries: [Diary]) {
        let calendar = Calendar.current
        let now = Date()
        var filteredForTimePeriod: [Diary] = []

        switch selectedTimeFilter {
        case .past7Days:
            guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else { processedChartData = []; return }
            filteredForTimePeriod = userDiaries.filter { $0.useDate >= startDate && $0.useDate <= now }
        case .past30Days:
            guard let startDate = calendar.date(byAdding: .day, value: -30, to: now) else { processedChartData = []; return }
            filteredForTimePeriod = userDiaries.filter { $0.useDate >= startDate && $0.useDate <= now }
        case .allTime:
            filteredForTimePeriod = userDiaries
        }
        
        print("DEBUG (UserPage processChartData): Filtered \(filteredForTimePeriod.count) diaries for chart (TimeFilter: '\(selectedTimeFilter.rawValue)').")

        if filteredForTimePeriod.isEmpty {
            self.processedChartData = []
            return
        }
        
        let groupedByDay = Dictionary(grouping: filteredForTimePeriod) { diary -> Date in
            calendar.startOfDay(for: diary.useDate)
        }

        self.processedChartData = groupedByDay.map { (date, diariesOnDay) -> RatingDataPoint in
            guard !diariesOnDay.isEmpty else { return RatingDataPoint(date: date, rating: 0) }
            let averageRating = diariesOnDay.map { $0.rating }.reduce(0, +) / Double(diariesOnDay.count)
            return RatingDataPoint(date: date, rating: averageRating)
        }.sorted(by: { $0.date < $1.date })
    }

    private func calculateCommonEffects(from userDiaries: [Diary]) {
        var effectCounts: [String: Int] = [:]
        for diary in userDiaries {
            for feeling in diary.feelings {
                effectCounts[feeling, default: 0] += 1
            }
        }
        self.commonEffectsData = effectCounts.map { CommonEffectData(name: $0.key, count: $0.value) }
                                       .sorted { $0.count > $1.count }
                                       .prefix(6).map{$0}
    }

    private func loadTriedStrains(from userDiaries: [Diary]) {
        let triedStrainIDs = Set(userDiaries.map { $0.strainId })
        
        if strainsVM.allStrains.isEmpty {
            print("WARNING (UserPage loadTriedStrains): strainsVM.allStrains is empty. 'What You've Tried' will be empty or show only IDs.")
        }
        
        self.triedStrainsData = triedStrainIDs.compactMap { strainId in
            strainsVM.allStrains.first { $0.id == strainId }
        }
        print("DEBUG (UserPage loadTriedStrains): Loaded \(self.triedStrainsData.count) tried strains from \(triedStrainIDs.count) unique IDs.")
    }

    private func generateRecommendations(basedOn userDiaries: [Diary]) {
        let triedStrainIDs = Set(userDiaries.map { $0.strainId })
        let availableStrainsToRecommend = strainsVM.allStrains.filter { strain in
            guard let strainId = strain.id else { return false }
            return !triedStrainIDs.contains(strainId)
        }

        guard !availableStrainsToRecommend.isEmpty else {
            self.recommendedStrainsData = []
            print("DEBUG (UserPage generateRecommendations): No available strains to recommend (all strains tried or no strains loaded).")
            return
        }
        
        guard !userDiaries.isEmpty else {
            self.recommendedStrainsData = Array(availableStrainsToRecommend.shuffled().prefix(3))
            print("DEBUG (UserPage generateRecommendations): No user diaries, recommending randomly: \(self.recommendedStrainsData.map { $0.name })")
            return
        }

        let highlyRatedDiaries = userDiaries.filter { $0.rating >= 4.0 }
        var preferredEffectCounts: [String: Int] = [:]
        for diary in highlyRatedDiaries {
            for feeling in diary.feelings {
                preferredEffectCounts[feeling, default: 0] += 1
            }
        }
        let topPreferredEffects = preferredEffectCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key.lowercased() }

        if topPreferredEffects.isEmpty {
            self.recommendedStrainsData = Array(availableStrainsToRecommend.shuffled().prefix(3))
            print("DEBUG (UserPage generateRecommendations): No top preferred effects, recommending randomly: \(self.recommendedStrainsData.map { $0.name })")
            return
        }
        print("DEBUG (UserPage generateRecommendations): Top preferred effects: \(topPreferredEffects)")

        var potentialRecommendations: [(strain: Strain, score: Int)] = []
        for strain in availableStrainsToRecommend {
            let strainEffects = Set(strain.effect.map { $0.lowercased() })
            var matchScore = 0
            for preferredEffect in topPreferredEffects {
                if strainEffects.contains(preferredEffect) {
                    matchScore += 2
                }
            }
            if matchScore > 0 {
                potentialRecommendations.append((strain, matchScore))
            }
        }
        
        self.recommendedStrainsData = potentialRecommendations
            .sorted { $0.score > $1.score }
            .map { $0.strain }
            .prefix(3).map{$0}
        
        if self.recommendedStrainsData.isEmpty {
            self.recommendedStrainsData = Array(availableStrainsToRecommend.shuffled().prefix(3))
            print("DEBUG (UserPage generateRecommendations): No recommendations from logic, recommending randomly: \(self.recommendedStrainsData.map { $0.name })")
        } else {
            print("DEBUG (UserPage generateRecommendations): Found recommendations: \(self.recommendedStrainsData.map { $0.name })")
        }
    }
}

// MARK: - Data Structures for Dashboard
struct RatingDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rating: Double
}

struct CommonEffectData: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

// MARK: - Subviews for Dashboard Sections

struct FeelingChartView: View {
    let chartData: [RatingDataPoint]
    @Binding var selectedTimeFilter: UserPage.TimeFilterOption

    var body: some View {
        VStack(alignment: .leading) {
            Text("How You've Been Feeling")
                .font(.title2.bold())
                .padding(.bottom, 5)

            Picker("Time Filter", selection: $selectedTimeFilter) {
                ForEach(UserPage.TimeFilterOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 10)

            if chartData.isEmpty {
                Text("No rating data available for the selected period. Try logging your experiences in your diary!")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 200, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(chartData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date, unit: .day),
                            y: .value("Average Rating", dataPoint.rating)
                        )
                        .foregroundStyle(Color("AccentGreen"))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", dataPoint.date, unit: .day),
                            y: .value("Average Rating", dataPoint.rating)
                        )
                        .foregroundStyle(Color("AccentGreen").opacity(0.7))
                        .symbolSize(dataPoint.rating > 0 ? 60 : 0)
                    }
                }
                .chartYScale(domain: 0...5)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: chartData.count > 14 ? 7 : (chartData.count > 7 ? 2 : 1) )) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day(), centered: chartData.count <= 7)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct CommonEffectsView: View {
    let effects: [CommonEffectData]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Your Most Common Effects")
                .font(.title2.bold())
                .padding(.bottom, 5)

            if effects.isEmpty {
                Text("Record your feelings in your diary to see common effects here.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(minHeight: 100, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)], spacing: 10) {
                    ForEach(effects) { effect in
                        HStack {
                            Text(effect.name.capitalized)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            Spacer()
                            Text("\(effect.count)")
                                .font(.subheadline.bold())
                                .foregroundColor(Color("AccentGreen"))
                        }
                        .padding(12)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct TriedStrainsView: View {
    let strains: [Strain]

    var body: some View {
        VStack(alignment: .leading) {
            Text("What You've Tried")
                .font(.title2.bold())
                .padding(.bottom, 5)

            if strains.isEmpty {
                Text("Strains you try and log in your diary will appear here.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(minHeight: 100, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 180))], spacing: 15) {
                    ForEach(strains.prefix(6)) { strain in
                        TriedStrainCard(strain: strain)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct TriedStrainCard: View {
    let strain: Strain
    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: strain.main_url)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo.fill").font(.largeTitle).foregroundColor(Color(UIColor.systemGray3))
                default: ProgressView()
                }
            }
            .frame(height: 100)
            .clipped()
            .background(Color(UIColor.systemGray5))
            .cornerRadius(8)
            
            Text(strain.name)
                .font(.caption.bold())
                .lineLimit(1)
                .truncationMode(.tail)
            Text(strain.type.capitalized)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct RecommendedStrainsView: View {
    let strains: [Strain]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Strains You Might Love")
                .font(.title2.bold())
                .padding(.bottom, 10)

            if strains.isEmpty {
                Text("We're learning about your preferences! More recommendations coming soon as you log more experiences.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 150, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(strains) { strain in
                            RecommendedStrainCard(strain: strain)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct RecommendedStrainCard: View {
    let strain: Strain
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var diaryVM: DiaryViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var strainsVM: StrainsViewModel


    var body: some View {
        NavigationLink(destination: StrainDetailView(strain: strain)
                                    .environmentObject(authVM)
                                    .environmentObject(cartManager)
                                    .environmentObject(diaryVM)
                                    .environmentObject(userVM)
                                    .environmentObject(strainsVM)
        ) {
            VStack(alignment: .leading, spacing: 6) {
                AsyncImage(url: URL(string: strain.main_url)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo.fill").font(.largeTitle).foregroundColor(Color(UIColor.systemGray3))
                    default: ProgressView()
                    }
                }
                .frame(width: 150, height: 110)
                .background(Color(UIColor.systemGray5))
                .clipped()
                .cornerRadius(8)
                
                Text(strain.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(Color(UIColor.label))
                Text(strain.type.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color("AccentGreen"))
                Text("Effects: \(strain.effect.prefix(2).joined(separator: ", "))...")
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
                
                Text("Try Now")
                    .font(.caption.bold())
                    .foregroundColor(.black) // <<<< เปลี่ยนสีตัวอักษรเป็นสีดำ
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color("AccentGreen").opacity(0.85)) // << ปรับ Alpha ของพื้นหลังเล็กน้อย
                    .cornerRadius(6)
                    .padding(.top, 4)
            }
            .padding(12)
            .frame(width: 170)
            .background(Color(UIColor.tertiarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Preview
#if DEBUG
struct UserPage_Previews: PreviewProvider {
    static var previews: some View {
        let calendar = Calendar.current
        let today = Date()

        let mockAuthVM = AuthViewModel()
        let mockUserVM = UserViewModel()
        let mockDiaryVM = DiaryViewModel()
        let mockStrainsVM = StrainsViewModel()
        
        let previewUserID = "testUser123"
        mockUserVM.user = UserModel(id: previewUserID, displayName: "Dashboard Preview User", email: "preview@example.com", photoURL: "", passwordEncrypted: "", phone: "", favorites: ["ogk", "bd"], paymentMethods: [])

        mockStrainsVM.allStrains = [
            Strain(id: "ogk", name: "OG Kush", THC_min: 19, THC_max: 24, CBD_min: 0.1, CBD_max: 0.3, main_url: "https://placehold.co/100x100/E8F5E9/333?text=OGK", image_url: "", price: 650, type: "Indica", parents: ["Chemdawg", "Hindu Kush"], smell_flavour: ["Earthy", "Pine", "Woody"], effect: ["Relaxed", "Happy", "Euphoric", "Sleepy", "Hungry"], description: "OG Kush is an American marijuana classic..."),
            Strain(id: "bd", name: "Blue Dream", THC_min: 17, THC_max: 24, CBD_min: 0.1, CBD_max: 0.2, main_url: "https://placehold.co/100x100/BBDEFB/333?text=BD", image_url: "", price: 700, type: "Sativa", parents: ["Blueberry", "Haze"], smell_flavour: ["Sweet", "Berry", "Blueberry"], effect: ["Euphoric", "Creative", "Uplifted", "Relaxed", "Happy"], description: "Blue Dream, a sativa-dominant hybrid..."),
            Strain(id: "gg4", name: "Gorilla Glue #4", THC_min: 25, THC_max: 30, CBD_min: 0.1, CBD_max: 0.1, main_url: "https://placehold.co/100x100/A5D6A7/333?text=GG4", image_url: "", price: 720, type: "Hybrid", parents: ["Chem's Sister", "Sour Dubb", "Chocolate Diesel"], smell_flavour: ["Pungent", "Earthy", "Diesel"], effect: ["Relaxed", "Euphoric", "Happy", "Uplifted", "Sleepy", "Pain Relief"], description: "GG4, developed by GG Strains..."),
            Strain(id: "slh", name: "Super Lemon Haze", THC_min: 16, THC_max: 25, CBD_min: 0.1, CBD_max: 0.2, main_url: "https://placehold.co/100x100/FFF59D/333?text=SLH", image_url: "", price: 680, type: "Sativa", parents: ["Lemon Skunk", "Super Silver Haze"], smell_flavour: ["Lemon", "Citrus", "Sweet"], effect: ["Energetic", "Uplifted", "Happy", "Creative", "Focused"], description: "Super Lemon Haze is a sativa-dominant hybrid...")
        ]
        
        mockDiaryVM.diaries = [
            Diary(id: "d1", userId: previewUserID, orderId: "o1", strainId: "ogk", orderDate: today, useDate: today, duration: 2, rating: 4.5, feelings: ["Relaxed", "Happy"], whyUse: ["Evening"], notes: "Good for winding down."),
            Diary(id: "d2", userId: previewUserID, orderId: "o2", strainId: "bd", orderDate: today, useDate: calendar.date(byAdding: .day, value: -1, to: today)!, duration: 3, rating: 4.0, feelings: ["Creative", "Uplifted"], whyUse: ["Work"], notes: "Helped with focus."),
            Diary(id: "d3", userId: previewUserID, orderId: "o3", strainId: "ogk", orderDate: today, useDate: calendar.date(byAdding: .day, value: -2, to: today)!, duration: 2, rating: 5.0, feelings: ["Relaxed", "Sleepy"], whyUse: ["Sleep"], notes: "Slept like a baby."),
            Diary(id: "d4", userId: previewUserID, orderId: "o4", strainId: "gg4", orderDate: today, useDate: calendar.date(byAdding: .day, value: -5, to: today)!, duration: 2, rating: 3.5, feelings: ["Relaxed", "Pain Relief"], whyUse: ["Pain"], notes: "Okay for pain."),
            Diary(id: "d5", userId: previewUserID, orderId: "o5", strainId: "bd", orderDate: today, useDate: calendar.date(byAdding: .day, value: -8, to: today)!, duration: 3, rating: 4.2, feelings: ["Happy", "Uplifted"], whyUse: ["Social"], notes: "Good for social gatherings."),
            Diary(id: "d6", userId: previewUserID, orderId: "o6", strainId: "ogk", orderDate: today, useDate: calendar.date(byAdding: .day, value: -10, to: today)!, duration: 2.5, rating: 4.8, feelings: ["Relaxed", "Euphoric"], whyUse: ["Stress Relief"], notes: "Excellent stress buster."),
            Diary(id: "d7", userId: previewUserID, orderId: "o7", strainId: "slh", orderDate: today, useDate: calendar.date(byAdding: .day, value: -15, to: today)!, duration: 2.5, rating: 3.0, feelings: ["Energetic", "Focused"], whyUse: ["Productivity"], notes: "A bit too racy for me."),
            Diary(id: "d8", userId: previewUserID, orderId: "o8", strainId: "gg4", orderDate: today, useDate: calendar.date(byAdding: .day, value: -32, to: today)!, duration: 2.5, rating: 4.0, feelings: ["Relaxed", "Euphoric"], whyUse: ["Evening"], notes: "Strong stuff!"),
        ]
        
        return UserPage()
            .environmentObject(mockAuthVM)
            .environmentObject(mockUserVM)
            .environmentObject(mockDiaryVM)
            .environmentObject(mockStrainsVM)
    }
}
#endif
