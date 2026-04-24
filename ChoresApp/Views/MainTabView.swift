import SwiftUI

struct MainTabView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedTab: AppTab = .today

    enum AppTab: Hashable { case today, future, jobs, household }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "sun.max.fill", value: AppTab.today) {
                TodayView()
            }

            Tab("Upcoming", systemImage: "calendar", value: AppTab.future) {
                FutureView()
            }

            Tab("Jobs", systemImage: "checklist", value: AppTab.jobs) {
                JobsView()
            }

            Tab("Household", systemImage: "house.fill", value: AppTab.household) {
                HouseholdView()
            }
        }
        .tint(.accentColor)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}
