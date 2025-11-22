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
                viewModel.handleSelection(newValue)
            }
            .sheet(isPresented: $viewModel.isSheetPresented,
                   onDismiss: { viewModel.clearSelection() }) {
                placeSheetContent
            }
            // Present the real Pokédex view now
            .sheet(isPresented: $viewModel.isDexPresented) {
                PokedexView()
            }
            .toolbar {
                MapToolbar(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    if let place = viewModel.nearbyPlace {
                        LiveLocationToolbarItem(
                            viewModel: viewModel,
                            place: place,
                            modelContext: modelContext
                        )
                    }
                }
            }
            .onChange(of: viewModel.store.cells) { _, newCells in
                viewModel.updateFromCells(newCells)
            }
            .task {
                viewModel.reloadSaved(modelContext: modelContext)
                viewModel.startLocationTracking()
            }
            .onDisappear {
                viewModel.stopLocationTracking()
            }
    }
    
    @ViewBuilder
    private var mapContent: some View {
        ZStack {
            Map(position: $viewModel.position, selection: $viewModel.selection) {
                mapAnnotations
            }
            .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .including(Array(MKPointOfInterestCategory.trackedCategories))))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all, edges: [.leading, .trailing])
            
            FloatingDexButton {
                viewModel.isDexPresented = true
            }
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
                    .tint(viewModel.poiService.status(for: item, modelContext: modelContext) == PlaceListType.visited ? .green : .blue)
                    .tag(MapSelection(item))
            }
        }
    }
    
    @ViewBuilder
    private var placeSheetContent: some View {
        if let item = viewModel.selectedMapItem {
            PlaceSheet(
                item: item,
                type: viewModel.poiService.status(for: item, modelContext: modelContext),
                onVisited: {
                    viewModel.mark(item: item, as: .visited, modelContext: modelContext)
                },
                onWishlist: { 
                    viewModel.mark(item: item, as: .wishlist, modelContext: modelContext)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
        }
    }
}

