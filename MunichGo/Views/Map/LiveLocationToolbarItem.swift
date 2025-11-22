//
//  LiveLocationToolbar.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import SwiftData
import MapKit

struct LiveLocationToolbarItem: View {
    @Bindable var viewModel: MapViewModel
    let place: MKMapItem
    let modelContext: ModelContext
    
    private var currentStatus: PlaceListType? {
        viewModel.poiService.status(for: place, modelContext: modelContext)
    }
    
    var body: some View {
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
            HStack(spacing: 16) {
                // Visited Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.mark(item: place, as: .visited, modelContext: modelContext)
                    }
                    Task {
                        await viewModel.refreshNearbyPlace()
                    }
                } label: {
                    Image(systemName: currentStatus == .visited ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(currentStatus == .visited ? .green : .primary)
                        .contentTransition(.symbolEffect(.replace))
                }
                
                // Wishlist Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.mark(item: place, as: .wishlist, modelContext: modelContext)
                    }
                    Task {
                        await viewModel.refreshNearbyPlace()
                    }
                } label: {
                    Image(systemName: currentStatus == .wishlist ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(currentStatus == .wishlist ? .pink : .primary)
                        .contentTransition(.symbolEffect(.replace))
                }
                
                // Dismiss Button
                Button {
                    withAnimation {
                        viewModel.dismissNearbyPlace()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}
