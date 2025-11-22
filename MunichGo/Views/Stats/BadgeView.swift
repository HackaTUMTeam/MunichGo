import SwiftUI

struct BadgeView: View {
    let badge: Badge
    
    private var progress: CGFloat {
        guard badge.maxLevel > 0 else { return 0 }
        return CGFloat(min(max(badge.level, 0), badge.maxLevel)) / CGFloat(badge.maxLevel)
    }

    // Ring styling
    private let ringSize: CGFloat = 56
    private let ringLineWidth: CGFloat = 6
    private let ringBaseColor: Color = .gray.opacity(0.25)
    private let ringProgressColor: Color = .yellow

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Base ring
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: ringLineWidth))
                    .foregroundStyle(ringBaseColor)
                    .frame(width: ringSize, height: ringSize)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                    .foregroundStyle(ringProgressColor)
                    .rotationEffect(.degrees(-90)) // start at top
                    .animation(.easeInOut(duration: 0.4), value: progress)
                    .frame(width: ringSize, height: ringSize)

                // Icon with partial fill
                ZStack {
                    Image(systemName: badge.icon)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(.gray.opacity(0.4))

                    Image(systemName: badge.icon)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(ringProgressColor)
                        .mask(
                            GeometryReader { geo in
                                let height = geo.size.height
                                let filledHeight = height * progress
                                Rectangle()
                                    .frame(width: geo.size.width, height: filledHeight)
                                    .position(x: geo.size.width / 2, y: height - filledHeight / 2)
                            }
                        )
                }
            }
            .frame(maxWidth: .infinity)

            // Name
            Text(badge.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)

            // Level pill
            Text("Lv \(min(badge.level, badge.maxLevel))/\(badge.maxLevel)")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.12))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
