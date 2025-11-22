//
//  PokedexView.swift
//  MunichGo
//
//  Created by Assistant on 22.11.25.
//

import SwiftUI
import SwiftData

struct PokedexView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \PokedexEntry.displayName, order: .forward)
    private var entries: [PokedexEntry]
    
    // Adaptive grid: minimum 120pt tile width; adjusts columns automatically
    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(entries, id: \.districtId) { entry in
                        PokedexCard(entry: entry)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .task {
                PokedexSeeder.seedIfNeeded(modelContext: modelContext)
            }
            .navigationTitle("Pokédex")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title2)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

private struct PokedexCard: View {
    let entry: PokedexEntry
    
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .frame(height: 90)
                    
                    Image(systemName: entry.symbolName ?? "book.closed.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                
                Text(entry.displayName ?? entry.districtId)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.primary)
                    .frame(height: 50)
                
                if let lat = entry.latitude, let lon = entry.longitude {
                    Text(String(format: "%.4f, %.4f", lat, lon))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
            //.blur(radius: entry.discovered ? 0 : 6)
            .opacity((entry.discovered) ? 1.0 : 0.7)
            
            if !(entry.discovered) {
                // Lock overlay with subtle glass effect
                ZStack {
                    // Semi-transparent background
                    Rectangle()
                        .fill(.ultraThinMaterial).opacity(0.93)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Lock content
                    
                    
                }
            }
        }
    }
}

#Preview {
    PokedexView()
}

