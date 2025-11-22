//
//  PlaceSheet.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import MapKit

struct PlaceSheet: View {
    let item: MKMapItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let name = item.name {
                Text(name)
                    .font(.headline)
            }
            /*
            if let address = item.address?.shortAddress {
                Text(address)
            }
             */

            if let cat = item.pointOfInterestCategory {
                CategoryBadge(category: cat)
            }
            
            Button {
                item.openInMaps()
            } label: {
                Text("Open in Maps")
            }

            Spacer(minLength: 0)
        }
        .padding()
    }
}
