import SwiftUI

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
        NavigationStack {
            Group {
                if activeJobs.isEmpty {
                    EmptyStateView(
                        title: "No jobs yet",
                        message: "Create your first recurring chore — vacuum, dishes, bins…",
                        systemImage: "checklist",
                        tint: .accentColor,
                        actionTitle: "Add a job",
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
                                    Button("Edit", systemImage: "pencil") { editingJob = job }
                                    Button("Archive", systemImage: "archivebox", role: .destructive) {
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
                }
            }
            .navigationTitle("Jobs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.glass)
                }
            }
            .sheet(isPresented: $showEditor) {
                JobEditorView()
            }
            .sheet(item: $editingJob) { job in
                JobEditorView(existing: job)
            }
        }
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
                Text(job.title).font(.headline)
                HStack(spacing: Spacing.sm) {
                    Text(job.recurrence.label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
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
                    .background(.white.opacity(0.08), in: Circle())
            }
        }
        .padding(Spacing.lg)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}
