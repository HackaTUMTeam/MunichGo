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
                    .font(.title)
                    .bold()
                    .padding()
                
                // --- Progress Bars ---
                HStack(spacing: 30) {
                    NavigationLink {
                        ExplorationDetailView(viewModel: viewModel)
                    } label: {
                        CircularProgressBar(progress: viewModel.cityExploration, color: .blue, title: "Exploration", systemImageName: "map", appendix: " %", max: 1.0)
                            .frame(width: 150, height: 150)
                            .padding(.horizontal, 5)
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        GreenScoreDetailView(viewModel: viewModel)
                    } label: {
                        CircularProgressBar(progress: viewModel.greenScore, color: .green, title: "Green Score", systemImageName: "leaf", appendix: "", max: 1.0)
                            .frame(width: 150, height: 150)
                            .padding(.horizontal, 5)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 15)
                .padding(.bottom, 15)
                
                HStack(spacing: 30) {
                    NavigationLink {
                        LocationsDetailView(viewModel: viewModel)
                    } label: {
                        CircularProgressBar(progress: viewModel.cityExploration, color: .orange, title: "Locations", systemImageName: "mappin.and.ellipse", appendix: "", max: 1.0, count: viewModel.locationCount)
                            .frame(width: 150, height: 150).padding(.horizontal, 5)
                    }
                    .buttonStyle(.plain)
                    
                    CircularProgressBar(progress: 1.0/3.0, color: .purple, title: "Ranking", systemImageName: "person.2.fill", appendix: "", max: 1.0)
                        .frame(width: 150, height: 150).padding(.horizontal, 5)
                }
                .padding(.vertical, 5).padding(.bottom, 25)
                
                // --- Badges Grid ---
                Text("Your Badges")
                    .font(.title)
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
        .onAppear {
            viewModel.reloadStats()
        }
    }
}
/*
#Preview {
    StatsView()
        .environment(MapViewModel())
}
 */

