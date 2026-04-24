import Foundation
import SwiftUI

// MARK: - Effort

enum EffortLevel: Int, Codable, CaseIterable, Identifiable, Hashable {
    case trivial = 1, light = 2, medium = 3, heavy = 4, intense = 5

    var id: Int { rawValue }
    var points: Int { rawValue }

    var label: String {
        switch self {
        case .trivial: "Trivial"
        case .light: "Light"
        case .medium: "Medium"
        case .heavy: "Heavy"
        case .intense: "Intense"
        }
    }

    var symbolName: String {
        switch self {
        case .trivial: "leaf"
        case .light: "sparkles"
        case .medium: "scalemass"
        case .heavy: "dumbbell"
        case .intense: "flame"
        }
    }

    var tint: Color {
        switch self {
        case .trivial: .mint
        case .light: .teal
        case .medium: .blue
        case .heavy: .orange
        case .intense: .pink
        }
    }

    /// Rough estimate used by the "quick tasks only" mood filter. User-overridable later.
    var estimatedMinutes: Int {
        switch self {
        case .trivial: 5
        case .light: 10
        case .medium: 20
        case .heavy: 40
        case .intense: 75
        }
    }
}

// MARK: - Recurrence

enum RecurrenceKind: Codable, Hashable {
    case none
    case daily
    /// weekdays: 1 = Sunday … 7 = Saturday (matches `Calendar.component(.weekday:)`).
    case weekly(Set<Int>)

    var label: String {
        switch self {
        case .none: return "One-time"
        case .daily: return "Every day"
        case .weekly(let days):
            if days.count == 7 { return "Every day" }
            let sorted = days.sorted()
            let names = sorted.map { RecurrenceKind.dayShortName($0) }
            return names.joined(separator: " · ")
        }
    }

    static func dayShortName(_ weekday: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        guard weekday >= 1, weekday <= symbols.count else { return "?" }
        return symbols[weekday - 1]
    }
}

// MARK: - Category

struct Category: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var symbolName: String
    var tintHex: String

    var tint: Color { Color(hex: tintHex) }
}

// MARK: - Member

struct Member: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var emoji: String
    var tintHex: String
    var isAdmin: Bool = false

    var tint: Color { Color(hex: tintHex) }
}

// MARK: - Job template

struct Job: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var categoryID: UUID
    var effort: EffortLevel
    var recurrence: RecurrenceKind
    /// First due date (already includes the user-chosen reminder time).
    var startDate: Date
    /// nil means open-pool.
    var defaultAssigneeID: UUID?
    var archived: Bool = false
}

// MARK: - Occurrence

struct Occurrence: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var jobID: UUID
    var dueDate: Date
    var assigneeID: UUID?
    var completedAt: Date?
    var completedByID: UUID?
    var skipped: Bool = false

    // Denormalized for fast filtering / rendering / mood solver.
    var title: String
    var notes: String
    var categoryID: UUID
    var effort: EffortLevel

    var isCompleted: Bool { completedAt != nil }
    var isOpen: Bool { !isCompleted && !skipped }
}

// MARK: - Mood

enum MoodPreset: Codable, Equatable, Hashable, Identifiable {
    case none
    case lowEnergy
    case quickOnly
    case avoid(UUID)

    var id: String {
        switch self {
        case .none: "none"
        case .lowEnergy: "lowEnergy"
        case .quickOnly: "quickOnly"
        case .avoid(let cat): "avoid-\(cat.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .none: "All tasks"
        case .lowEnergy: "Low energy"
        case .quickOnly: "Quick only"
        case .avoid: "Avoid…"
        }
    }

    var symbolName: String {
        switch self {
        case .none: "circle.grid.2x2"
        case .lowEnergy: "moon.zzz"
        case .quickOnly: "bolt"
        case .avoid: "nosign"
        }
    }

    var isActive: Bool {
        if case .none = self { return false } else { return true }
    }
}

struct MoodState: Codable, Equatable {
    var preset: MoodPreset = .none
    var setAt: Date = .now
    /// Optional hard expiry — if set and in the past, treat as `.none`.
    var expiresAt: Date? = nil

    func resolved(now: Date = .now) -> MoodPreset {
        if let expiresAt, expiresAt <= now { return .none }
        return preset
    }
}

// MARK: - Household

struct Household: Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var timezoneID: String = TimeZone.current.identifier
    var effortScaleMax: Int = 5
    /// Default reminder hour for newly created jobs (24h).
    var defaultReminderHour: Int = 9
}
