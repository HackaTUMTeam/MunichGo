//
//  CategoryBadge.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import MapKit

struct CategoryBadge: View {
    let category: MKPointOfInterestCategory
    
    var body: some View {
        Text("\(category.rawValue.replacingOccurrences(of: "MKPOICategory", with: ""))")
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.green)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    CategoryBadge(category: .airport)
}
