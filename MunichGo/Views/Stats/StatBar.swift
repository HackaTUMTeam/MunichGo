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
    
    /// Normalisierter Wert zwischen 0 und 1
    private var normalizedValue: Double {
        // Behandle ungültige Werte
        guard value.isFinite else { return 0 }
        
        // Wenn Wert > 1, interpretiere als Prozent (0-100) und konvertiere
        if value > 1.0 {
            return min(max(value / 100.0, 0), 1)
        }
        
        // Ansonsten direkt verwenden, aber auf 0-1 begrenzen
        return min(max(value, 0), 1)
    }

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
                        .frame(width: max(geo.size.width * normalizedValue, 0))
                }
            }
            .frame(height: 12)
        }
    }
}


#Preview {
    StatBar(title: "Test", value: 0.5, color: Color.green)
}
