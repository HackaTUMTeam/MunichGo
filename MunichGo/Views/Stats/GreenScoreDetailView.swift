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
            CircularProgressBar(progress: Double(viewModel.greenScore) / 100.0, color: .green, title: "Green Score", systemImageName: "leaf", appendix: "", max: 1.0)
                .frame(width: 150, height: 150)
                .padding(.horizontal, 5)
            Divider()
            StatBar(title: "Auto", value: viewModel.transportDetection.minutesAutomotive, color: Color.red)
            StatBar(title: "ÖPNV", value: viewModel.transportDetection.minutesPublicTransportation, color: Color.green)
            StatBar(title: "Fahrrad", value: viewModel.transportDetection.minutesCycling, color: Color.green)
            StatBar(title: "Laufen", value: viewModel.transportDetection.minutesWalking, color: Color.green)
            StatBar(title: "Rennen", value: viewModel.transportDetection.minutesRunning, color: Color.green)
        }
        .padding()
        .padding(.horizontal)
        .navigationTitle(Text("Green Score"))
    }
}
