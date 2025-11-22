//
//  FloatingDexButton.swift
//  MunichGo
//
//  Created by Assistant on 22.11.25.
//

import SwiftUI

struct FloatingDexButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        action()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.closed.fill")
                            .font(.headline)
                        Text("Dex")
                            .font(.headline)
                            .bold()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .padding(.bottom, 24)
                .accessibilityLabel("Open Pokédex")
            }
        }
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.1).ignoresSafeArea()
        FloatingDexButton {
            // preview action
        }
    }
}

