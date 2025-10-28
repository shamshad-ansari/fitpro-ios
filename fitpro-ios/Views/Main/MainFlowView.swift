import SwiftUI

struct MainFlowView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        TabView {
            HomeTab()
                .tabItem { Label("Home", systemImage: "house.fill") }

            Text("Exercise (coming soon)")
                .tabItem { Label("Exercise", systemImage: "dumbbell.fill") }

            Text("Progress (coming soon)")
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
        }
    }
}

private struct HomeTab: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Hello, \(session.userEmail ?? "Athlete") 👋")
                    .font(.title2).bold()
                Text("This is your FitPro dashboard.")
                    .foregroundStyle(.secondary)
                Text("We’ll connect this to real data after authentication.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("FitPro")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout") { session.logout() }
                }
            }
        }
    }
}
