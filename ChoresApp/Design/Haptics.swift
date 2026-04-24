import SwiftUI
import UIKit

/// Haptic helpers. Prefer `.sensoryFeedback` modifier in SwiftUI where possible
/// — this is for imperative call sites (completion flow, swipe actions).
enum Haptics {
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    static func warning() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
    }

    static func selection() {
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }

    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.impactOccurred()
    }
}
