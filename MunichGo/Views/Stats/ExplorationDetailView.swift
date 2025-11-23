//
//  ExplorationDetailView.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI

struct ExplorationDetailView: View {
    @State var viewModel: StatsViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                CircularProgressBar(progress: viewModel.cityExploration, color: .blue, title: "Exploration", systemImageName: "map", appendix: " %", max: 1.0)
                    .frame(width: 150, height: 150)
                    .padding(.horizontal, 5)
                Divider()
                ForEach(viewModel.districtDetector.locationCoverage, id: \.id) { locationCoverage in
                    StatBar(title: locationCoverage.key, value: locationCoverage.coverage, color: .blue)
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .navigationTitle("Locations")
    }
}
