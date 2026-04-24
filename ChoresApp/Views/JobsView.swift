import SwiftUI

/// Reached from `Me → Chore library`. Lists all active templates in the household.
/// Edits and creation both go through `AddChoreWizardView`.
struct JobsView: View {
    @Environment(AppStore.self) private var store
    @State private var showEditor = false
    @State private var editingJob: Job?

    private var activeJobs: [Job] {
        store.jobs
            .filter { !$0.archived }
            .sorted { $0.title.lowercased() < $1.title.lowercased() }
    }

    var body: some View {
        Group {
            if activeJobs.isEmpty {
                EmptyStateView(
                    title: "Nothing on rotation",
                    message: "Nothing's on rotation yet. Add a chore and it'll live here.",
                    systemImage: "tray",
                    tint: CardPalette.coral.primary,
                    actionTitle: Copy.Hub.addChoreTitle,
                    action: { showEditor = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(activeJobs) { job in
                            Button {
                                editingJob = job
                            } label: {
                                jobCard(job)
                            }
                            .buttonStyle(.plain)
                            .pressable()
                            .contextMenu {
                                Button(Copy.Common.edit, systemImage: "pencil") { editingJob = job }
                                Button(Copy.Common.retire, systemImage: "archivebox", role: .destructive) {
                                    withAnimation(Motion.standard) {
                                        store.archiveJob(job.id)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
                .scrollContentBackground(.hidden)
                .background(backdrop.ignoresSafeArea())
            }
        }
        .navigationTitle(Copy.Me.choreLibrary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.glass)
                .accessibilityLabel(Copy.Hub.addChoreTitle)
            }
        }
        .sheet(isPresented: $showEditor) {
            AddChoreWizardView()
        }
        .sheet(item: $editingJob) { job in
            AddChoreWizardView(existing: job)
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: DayScene.current().backgroundStops(),
            startPoint: .top, endPoint: .bottom
        )
    }

    private func jobCard(_ job: Job) -> some View {
        HStack(spacing: Spacing.md) {
            if let cat = store.category(job.categoryID) {
                Image(systemName: cat.symbolName)
                    .font(.title2)
                    .foregroundStyle(cat.tint)
                    .frame(width: 44, height: 44)
                    .background(cat.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.headline)
                    .foregroundStyle(Color.ink)
                HStack(spacing: Spacing.sm) {
                    Text(job.recurrence.label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.inkSoft)
                    Text("·").foregroundStyle(.tertiary)
                    EffortBadge(effort: job.effort, compact: true)
                }
            }

            Spacer(minLength: 0)

            if let member = store.member(job.defaultAssigneeID) {
                AvatarView(emoji: member.emoji, tint: member.tint, size: 32)
            } else {
                Image(systemName: "person.2")
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.ink.opacity(0.06), in: Circle())
                    .accessibilityLabel(Copy.Wizard.whoOpen)
            }
        }
        .padding(Spacing.lg)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.06), lineWidth: 0.5)
        )
    }
}
