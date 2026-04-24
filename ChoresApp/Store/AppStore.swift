import Foundation
import Observation
import SwiftUI

/// Single source of truth for the household. Keeps its state Codable and
/// persists to a JSON file under Documents — deliberately simple for MVP.
@Observable
final class AppStore {
    // MARK: - Persisted state

    var household: Household
    var members: [Member]
    var categories: [Category]
    var jobs: [Job]
    var occurrences: [Occurrence]
    var moodByMember: [UUID: MoodState]
    var currentMemberID: UUID?

    // MARK: - Derived "current" convenience

    var currentMember: Member? {
        guard let id = currentMemberID else { return members.first }
        return members.first(where: { $0.id == id })
    }

    var isOnboarded: Bool {
        !household.name.isEmpty && !members.isEmpty && currentMemberID != nil
    }

    // MARK: - Storage

    private let fileURL: URL

    init(fileName: String = "chores.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent(fileName)

        if let data = try? Data(contentsOf: fileURL),
           let snap = try? JSONDecoder().decode(Snapshot.self, from: data) {
            self.household = snap.household
            self.members = snap.members
            self.categories = snap.categories
            self.jobs = snap.jobs
            self.occurrences = snap.occurrences
            self.moodByMember = snap.moodByMember
            self.currentMemberID = snap.currentMemberID
        } else {
            self.household = Household(name: "")
            self.members = []
            self.categories = AppStore.seedCategories()
            self.jobs = []
            self.occurrences = []
            self.moodByMember = [:]
            self.currentMemberID = nil
        }
    }

    // MARK: - Codable snapshot

    private struct Snapshot: Codable {
        var household: Household
        var members: [Member]
        var categories: [Category]
        var jobs: [Job]
        var occurrences: [Occurrence]
        var moodByMember: [UUID: MoodState]
        var currentMemberID: UUID?
    }

    func save() {
        let snap = Snapshot(
            household: household,
            members: members,
            categories: categories,
            jobs: jobs,
            occurrences: occurrences,
            moodByMember: moodByMember,
            currentMemberID: currentMemberID
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snap)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // In production, log via a privacy-preserving sink.
            assertionFailure("Failed to save store: \(error)")
        }
    }

    // MARK: - Onboarding

    func bootstrap(householdName: String, firstMember: Member) {
        var admin = firstMember
        admin.isAdmin = true
        household.name = householdName
        household.timezoneID = TimeZone.current.identifier
        members = [admin]
        currentMemberID = admin.id
        save()
    }

    // MARK: - Members

    @discardableResult
    func addMember(name: String, emoji: String, tintHex: String, isAdmin: Bool = false) -> Member {
        let m = Member(name: name, emoji: emoji, tintHex: tintHex, isAdmin: isAdmin)
        members.append(m)
        save()
        return m
    }

    func updateMember(_ member: Member) {
        if let idx = members.firstIndex(where: { $0.id == member.id }) {
            members[idx] = member
            save()
        }
    }

    func deleteMember(_ id: UUID) {
        guard members.count > 1 else { return }
        members.removeAll { $0.id == id }
        for i in occurrences.indices where occurrences[i].assigneeID == id {
            occurrences[i].assigneeID = nil
        }
        for i in jobs.indices where jobs[i].defaultAssigneeID == id {
            jobs[i].defaultAssigneeID = nil
        }
        if currentMemberID == id { currentMemberID = members.first?.id }
        moodByMember.removeValue(forKey: id)
        save()
    }

    // MARK: - Categories

    func addCategory(name: String, symbolName: String, tintHex: String) {
        categories.append(Category(name: name, symbolName: symbolName, tintHex: tintHex))
        save()
    }

    func updateCategory(_ cat: Category) {
        if let idx = categories.firstIndex(where: { $0.id == cat.id }) {
            categories[idx] = cat
            save()
        }
    }

    func deleteCategory(_ id: UUID, reassignTo: UUID?) {
        guard categories.count > 1 else { return }
        let fallback = reassignTo ?? categories.first(where: { $0.id != id })?.id
        guard let fallback else { return }
        for i in jobs.indices where jobs[i].categoryID == id {
            jobs[i].categoryID = fallback
        }
        for i in occurrences.indices where occurrences[i].categoryID == id {
            occurrences[i].categoryID = fallback
        }
        categories.removeAll { $0.id == id }
        save()
    }

    func category(_ id: UUID) -> Category? {
        categories.first(where: { $0.id == id })
    }

    func member(_ id: UUID?) -> Member? {
        guard let id else { return nil }
        return members.first(where: { $0.id == id })
    }

    // MARK: - Jobs

    @discardableResult
    func upsertJob(_ job: Job) -> Job {
        if let idx = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[idx] = job
        } else {
            jobs.append(job)
        }
        rebuildOccurrences(for: job)
        save()
        return job
    }

    func archiveJob(_ id: UUID) {
        if let idx = jobs.firstIndex(where: { $0.id == id }) {
            jobs[idx].archived = true
            occurrences.removeAll { $0.jobID == id && $0.isOpen }
            save()
        }
    }

    func deleteJob(_ id: UUID) {
        jobs.removeAll { $0.id == id }
        occurrences.removeAll { $0.jobID == id }
        save()
    }

    // MARK: - Occurrence generation

    /// Wipes open future occurrences for this job and regenerates from the
    /// template. Completed/skipped ones are preserved for history.
    func rebuildOccurrences(for job: Job) {
        occurrences.removeAll { $0.jobID == job.id && $0.isOpen }
        guard !job.archived else { return }

        let horizon: Int = 30
        let dates = nextDueDates(for: job, horizonDays: horizon)
        for d in dates {
            occurrences.append(
                Occurrence(
                    jobID: job.id,
                    dueDate: d,
                    assigneeID: job.defaultAssigneeID,
                    title: job.title,
                    notes: job.notes,
                    categoryID: job.categoryID,
                    effort: job.effort
                )
            )
        }
    }

    /// Periodic housekeeping — call on launch and when app foregrounds.
    func regenerateAllOccurrences(horizonDays: Int = 30) {
        let calendar = Calendar.current
        let horizonEnd = calendar.date(byAdding: .day, value: horizonDays, to: .now) ?? .now
        for job in jobs where !job.archived {
            // Drop obsolete open occurrences (past horizon or before latest completed).
            occurrences.removeAll { occ in
                occ.jobID == job.id && occ.isOpen && (occ.dueDate > horizonEnd)
            }

            let existing = Set(
                occurrences
                    .filter { $0.jobID == job.id }
                    .map { calendar.startOfDay(for: $0.dueDate) }
            )
            for date in nextDueDates(for: job, horizonDays: horizonDays) {
                let key = calendar.startOfDay(for: date)
                guard !existing.contains(key) else { continue }
                occurrences.append(
                    Occurrence(
                        jobID: job.id,
                        dueDate: date,
                        assigneeID: job.defaultAssigneeID,
                        title: job.title,
                        notes: job.notes,
                        categoryID: job.categoryID,
                        effort: job.effort
                    )
                )
            }
        }
        save()
    }

    private func nextDueDates(for job: Job, horizonDays: Int) -> [Date] {
        let calendar = Calendar.current
        let start = max(job.startDate, calendar.startOfDay(for: .now).addingTimeInterval(-60))
        guard let end = calendar.date(byAdding: .day, value: horizonDays, to: .now) else {
            return [job.startDate]
        }

        switch job.recurrence {
        case .none:
            return job.startDate >= calendar.startOfDay(for: .now) ? [job.startDate] : []
        case .daily:
            return stride(from: 0, through: horizonDays, by: 1).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: start).flatMap { d in
                    d <= end ? d : nil
                }
            }
        case .weekly(let weekdays):
            guard !weekdays.isEmpty else { return [] }
            var result: [Date] = []
            var cursor = start
            while cursor <= end {
                let weekday = calendar.component(.weekday, from: cursor)
                if weekdays.contains(weekday) {
                    result.append(cursor)
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }
            return result
        }
    }

    // MARK: - Completion

    func completeOccurrence(_ occurrenceID: UUID, by memberID: UUID? = nil) {
        guard let idx = occurrences.firstIndex(where: { $0.id == occurrenceID }) else { return }
        let who = memberID ?? currentMemberID
        occurrences[idx].completedAt = .now
        occurrences[idx].completedByID = who
        save()
    }

    func uncompleteOccurrence(_ occurrenceID: UUID) {
        guard let idx = occurrences.firstIndex(where: { $0.id == occurrenceID }) else { return }
        occurrences[idx].completedAt = nil
        occurrences[idx].completedByID = nil
        save()
    }

    func skipOccurrence(_ occurrenceID: UUID) {
        guard let idx = occurrences.firstIndex(where: { $0.id == occurrenceID }) else { return }
        occurrences[idx].skipped = true
        save()
    }

    func reassignOccurrence(_ occurrenceID: UUID, to memberID: UUID?) {
        guard let idx = occurrences.firstIndex(where: { $0.id == occurrenceID }) else { return }
        occurrences[idx].assigneeID = memberID
        save()
    }

    // MARK: - Queries

    /// Occurrences visible on the "Today" view: due today + overdue (open).
    func todaysOccurrences(for memberID: UUID? = nil, now: Date = .now) -> [Occurrence] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        return occurrences.filter { occ in
            guard occ.isOpen else { return false }
            let matchesMember: Bool = {
                guard let memberID else { return true }
                return occ.assigneeID == nil || occ.assigneeID == memberID
            }()
            return matchesMember && occ.dueDate < tomorrow
        }
    }

    func futureOccurrences(for memberID: UUID? = nil, now: Date = .now) -> [Occurrence] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        return occurrences
            .filter { occ in
                guard occ.isOpen else { return false }
                let matchesMember: Bool = {
                    guard let memberID else { return true }
                    return occ.assigneeID == nil || occ.assigneeID == memberID
                }()
                return matchesMember && occ.dueDate >= tomorrow
            }
            .sorted { $0.dueDate < $1.dueDate }
    }

    // MARK: - Points ledger

    func points(for memberID: UUID, in window: DateInterval) -> Int {
        occurrences.reduce(0) { sum, occ in
            guard let completedAt = occ.completedAt,
                  occ.completedByID == memberID,
                  window.contains(completedAt) else { return sum }
            return sum + occ.effort.points
        }
    }

    func householdPoints(in window: DateInterval) -> [(member: Member, points: Int)] {
        members.map { m in (m, points(for: m.id, in: window)) }
    }

    // MARK: - Mood

    func mood(for memberID: UUID) -> MoodPreset {
        moodByMember[memberID]?.resolved() ?? .none
    }

    func setMood(_ preset: MoodPreset, for memberID: UUID, expiresAt: Date? = nil) {
        moodByMember[memberID] = MoodState(preset: preset, setAt: .now, expiresAt: expiresAt)
        save()
    }

    // MARK: - Seed data

    static func seedCategories() -> [Category] {
        [
            Category(name: "Cleaning", symbolName: "sparkles", tintHex: "#4ECDC4"),
            Category(name: "Kitchen", symbolName: "fork.knife", tintHex: "#F7B267"),
            Category(name: "Laundry", symbolName: "tshirt", tintHex: "#A06CD5"),
            Category(name: "Errands", symbolName: "bag", tintHex: "#4D96FF"),
            Category(name: "Pets", symbolName: "pawprint", tintHex: "#F58FBA"),
            Category(name: "Admin", symbolName: "tray.full", tintHex: "#7D8597")
        ]
    }
}
