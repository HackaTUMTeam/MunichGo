//
//  MapToolbar.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI

struct MapToolbar: ToolbarContent {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: MapViewModel
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink {
                ExplorationDetailView(viewModel: StatsViewModel(store: viewModel.store, modelContext: modelContext))
            } label: {
                Text("\(viewModel.cityExploration) %")
                    .bold()
                    .frame(width: 60)
            }
        }
        
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink {
                GreenScoreDetailView(viewModel: StatsViewModel(store: viewModel.store, modelContext: modelContext))
            } label: {
                HStack {
                    Image(systemName: "leaf.fill")
                    
                    Text("\(viewModel.greenScore)")
                        .bold()
                }
                .foregroundStyle(.green)
                .frame(width: 70)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation {
                    viewModel.showSaved.toggle()
                }
            } label: {
                if viewModel.showSaved {
                    Image(systemName: "pin.fill")
                } else {
                    Image(systemName: "pin.slash.fill")
                }
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation {
                    viewModel.changeZoom()
                }
            } label: {
                if viewModel.isZoomedOut {
                    Image(systemName: "arrow.up.forward.and.arrow.down.backward")
                } else {
                    Image(systemName: "arrow.down.backward.and.arrow.up.forward")

                }
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation {
                    viewModel.resetToMunich()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
        }
        
        // New: Pokédex button
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation {
                    viewModel.isDexPresented = true
                }
            } label: {
                Image(systemName: "book.closed.fill") // represents a 'dex'
            }
            .accessibilityLabel("Open Pokédex")
        }
    }
}

