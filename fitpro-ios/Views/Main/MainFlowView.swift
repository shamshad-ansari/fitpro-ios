import SwiftUI

struct MainFlowView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        TabView {
            HomeTab()
                .tabItem { Label("Home", systemImage: "house.fill") }
            
            WorkoutsListView()
                            .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }


            HistoryView()
                            .tabItem { Label("History", systemImage: "clock.fill") }

            
//            ProgressViewScreen()
//                            .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            
            ProfileView()
                            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}
