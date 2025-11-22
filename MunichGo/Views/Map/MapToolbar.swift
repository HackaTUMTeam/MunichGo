//
//  MapToolbar.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI

struct MapToolbar: ToolbarContent {
    @State var viewModel: MapViewModel
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Text("\(viewModel.cityExploration) %")
                .frame(width: 70)
        }
        
        ToolbarItem(placement: .topBarLeading) {
            HStack {
                Image(systemName: "leaf.fill")
                
                Text("\(viewModel.greenScore)")
            }
            .foregroundStyle(.green)
            .frame(width: 90)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation {
                    viewModel.showSaved.toggle()
                }
            } label: {
                if viewModel.showSaved {
                    Image(systemName: "pin.slash.fill")
                } else {
                    Image(systemName: "pin.fill")

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
        
    }
}

