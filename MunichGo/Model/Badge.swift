import SwiftUI

struct Badge: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    var unlocked: Bool

    // New: level support
    var level: Int
    var maxLevel: Int

    // Convenience computed values
    var isMaxed: Bool { level >= maxLevel }
    var levelDisplay: String { "Lv \(min(level, maxLevel))/\(maxLevel)" }
}

