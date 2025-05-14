//
//  DiaryListView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import SwiftUI

struct DiaryListView: View {
    @EnvironmentObject var vm: DiaryViewModel

    var body: some View {
        NavigationView {
            List(vm.diaries) { diary in
                NavigationLink(destination: DiaryDetailView(diary: diary)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(diary.strainId.capitalized)
                            .bold()
                        Text("Order: \(diary.orderDate.formatted(.dateTime.year().month().day()))")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Diaries")
            .onAppear {
                print("DEBUG: DiaryListView appeared, loading diaries. Current count before load: \(vm.diaries.count)")
                vm.loadDiaries()
                print("DEBUG: DiaryListView called loadDiaries()")
            }
        }
    }
}

struct DiaryListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DiaryListView()
                .environmentObject(DiaryViewModel())
        }
    }
}
