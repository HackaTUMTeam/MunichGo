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
    
    var body: some View {
        ZStack {
            Map(position: $viewModel.position, selection: $viewModel.selection) {
                UserAnnotation()
                
                MapPolygon(viewModel.fogOverlay)
                    .foregroundStyle(.gray.opacity(0.7))
                
                MapPolygon(viewModel.worldOverlay)
                    .foregroundStyle(.black.opacity(0.7))
                
                ForEach(viewModel.fadingPolygons) { fp in
                    MapPolygon(fp.polygon)
                        .foregroundStyle(.gray.opacity(fp.opacity))
                }
            }
            .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .including(viewModel.pointsOfInterest)))
            .mapControls({
                MapUserLocationButton()
                MapCompass()
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all, edges: [.leading, .trailing, .bottom])
        }
        .onChange(of: viewModel.selection) { _, newValue in
            viewModel.handleFeatureSelection(newValue?.feature)
        }
        .sheet(isPresented: $viewModel.isSheetPresented,
               onDismiss: { viewModel.clearSelection() }) {
            if let item = viewModel.selectedMapItem {
                PlaceSheet(item: item)
                    .presentationDetents([.height(200), .medium],
                                         selection: $viewModel.sheetDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
            }
        }
       .toolbar {
           MapToolbar(viewModel: viewModel)
       }
       .onChange(of: viewModel.store.cells) { _, newCells in
           viewModel.updateFromCells(newCells)
       }
    }
}
