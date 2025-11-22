//
//  StatsView.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI

struct StatsView: View {
    @State var viewModel: StatsViewModel
    
    var body: some View {
        // 2. Main ScrollView allows the whole page to scroll vertically
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                Text("Your Stats")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                // --- Progress Bars ---
                HStack(spacing: 20) {
                    NavigationLink {
                        ExplorationDetailView(viewModel: viewModel)
                    } label: {
                        CircularProgressBar(progress: Double(viewModel.cityExploration) / 100.0, color: .blue, title: "Exploration", systemImageName: "map", appendix: " %", max: 1.0)
                            .frame(width: 150, height: 150).padding(.horizontal, 5)
                    }
                    
                    NavigationLink {
                        ExplorationDetailView(viewModel: viewModel)
                    } label: {
                        CircularProgressBar(progress: Double(viewModel.greenScore) / 100.0, color: .green, title: "Green Score", systemImageName: "leaf", appendix: "", max: 1.0)
                            .frame(width: 150, height: 150).padding(.horizontal, 5)
                    }
                }
                .padding(.vertical, 15)
                
                HStack(spacing: 20) {
                    CircularProgressBar(progress: 55.0 / 100.0, color: .orange, title: "Locations", systemImageName: "mappin.and.ellipse", appendix: "", max: 1.0)
                        .frame(width: 150, height: 150).padding(.horizontal, 5)
                    
                    CircularProgressBar(progress: 1.0/3.0, color: .purple, title: "Friend Rank", systemImageName: "person.2.fill", appendix: "", max: 1.0)
                        .frame(width: 150, height: 150).padding(.horizontal, 5)
                }
                .padding(.vertical, 5).padding(.bottom, 25)
                
                // --- Badges Grid ---
                Text("Your Badges")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                
                LazyVGrid(columns: viewModel.columns, spacing: 20) {
                    ForEach(viewModel.badges) { badge in
                        BadgeView(badge: badge)
                    }
                }
                .padding()
            }
        }
    }
}
/*
#Preview {
    StatsView()
        .environment(MapViewModel())
}
 */

