//
//  MapView.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var viewModel = MapViewModel()
    
    var body: some View {
        Map(position: $viewModel.position, selection: $viewModel.selection) {
            UserAnnotation()
        }
        .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .including(viewModel.pointsOfInterest)))
        .mapControls({
            MapUserLocationButton()
            MapCompass()
            MapPitchToggle()
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all, edges: [.leading, .trailing, .bottom])
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
    }
}

#Preview {
    MapView()
}
