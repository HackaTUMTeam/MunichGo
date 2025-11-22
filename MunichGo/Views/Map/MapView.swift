//
//  MapView.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State var viewModel: MapViewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        mapContent
            .onChange(of: viewModel.selection) { _, newValue in
                viewModel.handleFeatureSelection(newValue?.feature)
            }
            .sheet(isPresented: $viewModel.isSheetPresented,
                   onDismiss: { viewModel.clearSelection() }) {
                placeSheetContent
            }
            .toolbar {
                MapToolbar(viewModel: viewModel)
            }
            .onChange(of: viewModel.store.cells) { _, newCells in
                viewModel.updateFromCells(newCells)
            }
            .task {
                viewModel.reloadSaved(modelContext: modelContext)
            }
    }
    
    @ViewBuilder
    private var mapContent: some View {
        ZStack {
            Map(position: $viewModel.position, selection: $viewModel.selection) {
                mapAnnotations
            }
            .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .including(Array(trackedCategories))))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all, edges: [.leading, .trailing, .bottom])
        }
    }
    
    @MapContentBuilder
    private var mapAnnotations: some MapContent {
        UserAnnotation()
        
        MapPolygon(viewModel.fogOverlay)
            .foregroundStyle(.gray.opacity(0.7))
        
        MapPolygon(viewModel.worldOverlay)
            .foregroundStyle(.black.opacity(0.7))
        
        ForEach(viewModel.fadingPolygons) { fp in
            MapPolygon(fp.polygon)
                .foregroundStyle(.gray.opacity(fp.opacity))
        }
        
        if viewModel.showSaved {
            ForEach(viewModel.savedItems, id: \.self) { item in
                Marker(item.name ?? "", coordinate: item.location.coordinate)
            }
        }
    }
    
    @ViewBuilder
    private var placeSheetContent: some View {
        if let item = viewModel.selectedMapItem {
            PlaceSheet(
                item: item,
                onVisited: { 
                    viewModel.mark(item: item, as: .visited, modelContext: modelContext)
//                    viewModel.reloadSaved(modelContext: modelContext)
                },
                onWishlist: { 
                    viewModel.mark(item: item, as: .wishlist, modelContext: modelContext)
//                    viewModel.reloadSaved(modelContext: modelContext)
                }
            )
            .presentationDetents([.medium],
                                 selection: $viewModel.sheetDetent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
        }
    }
}
