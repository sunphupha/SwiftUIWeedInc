//
//  RatingView.swift
//  final_project_weed
//
//  Created by Sun Phupha on 13/5/2568 BE.
//

import SwiftUI

struct RatingView: View {
    @Binding var rating: Double    // Bound to parent view’s rating
    
    // Maximum number of stars
    private let maxRating = 5
    
    // Body
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName:
                    rating >= Double(index) ? "star.fill" :
                    rating >= Double(index) - 0.5 ? "star.leadinghalf.fill" :
                    "star"
                )
                    .foregroundColor(.yellow)
                    .font(.title3)
                    .onTapGesture {
                        // Tapping sets rating to the tapped star value
                        withAnimation {
                            rating = Double(index)
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.2) {
                        // Long press sets half-star
                        withAnimation {
                            rating = Double(index) - 0.5
                        }
                    }
            }
        }
    }
}

struct RatingView_Previews: PreviewProvider {
    @State static var rating = 3.5
    static var previews: some View {
        RatingView(rating: $rating)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
