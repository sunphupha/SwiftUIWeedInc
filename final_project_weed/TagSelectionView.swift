//
//  TagSelectionView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import SwiftUI

struct TagSelectionView: View {
    let title: String
    let options: [String]
    @Binding var selection: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = selection.contains(option)
                        Text(option)
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(isSelected ? Color.green.opacity(0.7) : Color.gray.opacity(0.2))
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(12)
                            .onTapGesture {
                                if isSelected {
                                    selection.remove(option)
                                } else {
                                    selection.insert(option)
                                }
                            }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct TagSelectionView_Previews: PreviewProvider {
    @State static var selected = Set<String>()
    static var previews: some View {
        TagSelectionView(title: "Why did you use it?", options: ["Sleep","Focus","Anxiety"], selection: $selected)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
