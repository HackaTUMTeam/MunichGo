//
//  StatsView.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI

struct StatsView: View {
    @Environment(MapViewModel.self) var mapViewModel
    
    // 1. Define the grid layout: 4 columns
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    
    // Mock badges
    let badges: [Badge] = [
        Badge(name: "Explorer", icon: "map.fill", description: "Explore 10% of the city.", unlocked: true, level: 2, maxLevel: 5),
        Badge(name: "Green Thumb", icon: "leaf.fill", description: "Achieve a green score of 50.", unlocked: true, level: 3, maxLevel: 5),
        Badge(name: "Night Owl", icon: "moon.fill", description: "Explore at night.", unlocked: false, level: 0, maxLevel: 3),
        Badge(name: "Early Bird", icon: "sun.max.fill", description: "Explore in the morning.", unlocked: false, level: 1, maxLevel: 3),
        // Added a few duplicates just so you can see the grid effect in Preview
        Badge(name: "Walker", icon: "figure.walk", description: "Walk 10km", unlocked: true, level: 4, maxLevel: 10),
        Badge(name: "Cyclist", icon: "bicycle", description: "Ride 20km", unlocked: false, level: 0, maxLevel: 10)
    ]
    
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
                    CircularProgressBar(progress: Double(mapViewModel.cityExploration) / 100.0, color: .blue, title: "Exploration", systemImageName: "map", appendix: " %", max: 1.0)
                        .frame(width: 150, height: 150).padding(.horizontal, 5)
                    
                    CircularProgressBar(progress: Double(mapViewModel.greenScore) / 100.0, color: .green, title: "Green Score", systemImageName: "leaf", appendix: "", max: 1.0)
                        .frame(width: 150, height: 150).padding(.horizontal, 5)
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
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(badges) { badge in
                        BadgeView(badge: badge)
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    StatsView()
        .environment(MapViewModel())
}

