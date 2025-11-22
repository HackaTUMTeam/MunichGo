//
//  CategoryBadge.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import MapKit

struct PlaceStatusBadge: View {
    let status: PlaceListType
    
    var body: some View {
        if status == .visited {
            Text("Besucht")
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Text("Gespeichert")
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    CategoryBadge(category: .airport)
}
