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
    let type: PlaceListType?
    let onVisited: () -> Void
    let onWishlist: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Bereich
                    VStack(alignment: .leading, spacing: 12) {
                        if let name = item.name {
                            Text(name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        
                        HStack(spacing: 8) {
                            if let cat = item.pointOfInterestCategory {
                                CategoryBadge(category: cat)
                            }
                            
                            if let type = type {
                                PlaceStatusBadge(status: type)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if item.address != nil {
                        Divider()
                        
                        // Adresse und Details
                        VStack(alignment: .leading, spacing: 12) {
                            // Address information
                            if let address = item.address {
                                Label {
                                    VStack(alignment: .leading, spacing: 4) {
                                        // Use the formatted address string
                                        if let formattedAddress = address.shortAddress {
                                            Text(formattedAddress)
                                                .font(.body)
                                        }
                                    }
                                } icon: {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.title2)
                                }
                            }
                            
                            if let phoneNumber = item.phoneNumber {
                                Label {
                                    Text(phoneNumber)
                                        .font(.body)
                                } icon: {
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(.green)
                                        .font(.title3)
                                }
                            }
                            
                            if let url = item.url {
                                Label {
                                    Text(url.absoluteString)
                                        .font(.body)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                } icon: {
                                    Image(systemName: "globe")
                                        .foregroundStyle(.blue)
                                        .font(.title3)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Divider()
                    
                    // Open in Maps Button
                    Button {
                        item.openInMaps()
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                                .font(.title3)
                            Text("In Karten öffnen")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        if type == nil {
                            Button {
                                onWishlist()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                        .font(.title3)
                                    Text("Speichern")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        if type != .visited {
                            Button {
                                onVisited()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    Text("Besucht")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
