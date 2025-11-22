//
//  CircularProgressBar.swift
//  MunichGo
//
//  Created by on 22.11.25.
//

import SwiftUI

struct CircularProgressBar: View {
    var progress: Double
    var color: Color
    var title: String
    var systemImageName: String
    var appendix: String
    var max: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20.0)
                .opacity(0.3)
                .foregroundColor(color)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, max)))
                .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
            
            VStack {
                Image(systemName: systemImageName)
                    .font(.largeTitle)
                    .foregroundColor(color)
                Text(String(format: "%.0f%@", min(self.progress, 1.0) * 100.0, appendix))
                    .font(.title)
                    .bold()
                Text(title)
                    .font(.headline)
            }
        }
    }
}
