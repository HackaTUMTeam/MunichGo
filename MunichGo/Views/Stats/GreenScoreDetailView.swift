//
//  ExplorationDetailView.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI

struct GreenScoreDetailView: View {
    @State var viewModel: StatsViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            CircularProgressBar(progress: viewModel.greenScore, color: .green, title: "Green Score", systemImageName: "leaf", appendix: "", max: 1.0)
                .frame(width: 150, height: 150)
                .padding(.horizontal, 5)
            Divider()
            StatBar(title: "Auto", value: viewModel.transportDetection.autoPercent, color: Color.red)
            StatBar(title: "ÖPNV", value: viewModel.transportDetection.publicPercent, color: Color.green)
            StatBar(title: "Fahrrad", value: viewModel.transportDetection.cyclingPercent, color: Color.green)
            StatBar(title: "Laufen", value: viewModel.transportDetection.walkingPercent, color: Color.green)
            StatBar(title: "Rennen", value: viewModel.transportDetection.runningPercent, color: Color.green)
        }
        .padding()
        .padding(.horizontal)
        .navigationTitle(Text("Green Score"))
    }
}
