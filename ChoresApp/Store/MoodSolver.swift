import Foundation

/// Pure function that turns the user's mood into a filtered + ranked list of
/// occurrences. The flagship feature of the product — see PRD §6.9.
///
/// MVP is presentation-only: we never mutate assignments. We just surface the
/// tasks the user is most willing to tackle first.
enum MoodSolver {
    /// Minutes threshold under which a task is considered "quick".
    static let quickThresholdMinutes: Int = 15

    static func apply(
        to occurrences: [Occurrence],
        mood: MoodPreset,
        now: Date = .now
    ) -> [Occurrence] {
        let base = occurrences.sorted { $0.dueDate < $1.dueDate }

        let filtered: [Occurrence] = base.filter { occ in
            switch mood {
            case .none: return true
            case .lowEnergy: return occ.effort.rawValue <= EffortLevel.medium.rawValue
            case .quickOnly: return occ.effort.estimatedMinutes <= quickThresholdMinutes
            case .avoid(let categoryID): return occ.categoryID != categoryID
            }
        }

        switch mood {
        case .none:
            return base
        case .lowEnergy, .quickOnly:
            // Surface the lightest first — honours "meet the user where they are".
            return filtered.sorted { lhs, rhs in
                if lhs.effort.rawValue != rhs.effort.rawValue {
                    return lhs.effort.rawValue < rhs.effort.rawValue
                }
                return lhs.dueDate < rhs.dueDate
            }
        case .avoid:
            return filtered
        }
    }

    /// When a mood hides tasks, we still want the user to know what's there.
    static func hidden(from occurrences: [Occurrence], mood: MoodPreset) -> [Occurrence] {
        let visible = Set(apply(to: occurrences, mood: mood).map(\.id))
        return occurrences.filter { !visible.contains($0.id) }
    }
}
