//
//  ExplorationDetailView.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import MapKit

struct LocationsDetailView: View {
    @State var viewModel: StatsViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                CircularProgressBar(progress: viewModel.cityExploration * 100, color: .orange, title: "Locations", systemImageName: "mappin.and.ellipse", appendix: "", max: 1.0, count: viewModel.locationCount)
                    .frame(width: 150, height: 150).padding(.horizontal, 5)
                Divider()
                ForEach(viewModel.categoryStats) { stats in
                    StatBar(title: stats.category.categoryName, value: stats.coveragePercent, color: stats.category.categoryColor)
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .navigationTitle("Locations")
    }
}
