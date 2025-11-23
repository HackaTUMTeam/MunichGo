//
//  LiveLocationToolbar.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import SwiftData
import MapKit

struct LiveLocationBar: View {
    @Bindable var viewModel: MapViewModel
    let modelContext: ModelContext
    
    private var currentStatus: PlaceListType? {
        if let place = viewModel.nearbyPlace {
            return viewModel.poiService.status(for: place, modelContext: modelContext)
        } else {
            return nil
        }
    }
    
    var body: some View {
        if let place = viewModel.nearbyPlace {
            HStack(spacing: 12) {
                // Location Icon
                if let category = place.pointOfInterestCategory {
                    ZStack {
                        Circle()
                            .fill(category.categoryColor.gradient)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: category.categoryIcon)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .fontWeight(.medium)
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name ?? "Unbekannt")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if let category = place.pointOfInterestCategory {
                        Text(category.categoryName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer(minLength: 8)
                
                // Action Buttons (nur Icons)
                HStack(spacing: 12) {
                    Button {
                        viewModel.mark(item: place, as: .wishlist, modelContext: modelContext)
                        viewModel.nearbyPlace = nil
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    
                    Button {
                        viewModel.mark(item: place, as: .visited, modelContext: modelContext)
                        viewModel.nearbyPlace = nil
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            .onAppear {
                print(place)
            }
        }
        
    }
}
