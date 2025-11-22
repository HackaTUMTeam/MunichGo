//
//  StatBar.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI

struct StatBar: View {
    let title: String
    let value: Double   // 0.0 – 1.0
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: geo.size.width * value)
                }
            }
            .frame(height: 12)
        }
    }
}


#Preview {
    StatBar(title: "Test", value: 0.5, color: Color.green)
}
