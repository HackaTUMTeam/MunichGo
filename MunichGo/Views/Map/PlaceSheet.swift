//
//  PlaceSheet.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import MapKit

struct PlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let item: MKMapItem
    let onVisited: () -> Void
    let onWishlist: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let name = item.name {
                Text(name)
                    .font(.largeTitle)
            }

            HStack {
                if let cat = item.pointOfInterestCategory {
                    CategoryBadge(category: cat)
                }
                
                Button {
                    item.openInMaps()
                } label: {
                    Text("Open in Maps")
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.gray)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            HStack {
                Button {
                    onWishlist()
                    dismiss()
                } label: {
                    Text("Speichern")
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.blue)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Button {
                    onVisited()
                    dismiss()
                } label: {
                    Text("Besucht")
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.green)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
