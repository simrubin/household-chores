import SwiftUI

@main
struct ChoresAppApp: App {
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task {
                    // Ask politely on first launch — permission denial is fine,
                    // everything still works without push.
                    _ = await NotificationService.shared.requestPermission()
                    store.regenerateAllOccurrences()
                    await NotificationService.shared.syncReminders(for: store.occurrences)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        store.regenerateAllOccurrences()
                        Task { await NotificationService.shared.syncReminders(for: store.occurrences) }
                    case .background:
                        store.save()
                    default:
                        break
                    }
                }
        }
    }
}
