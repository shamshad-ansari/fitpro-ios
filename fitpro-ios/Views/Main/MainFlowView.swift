import SwiftUI

struct MainFlowView: View {
    @Environment(SessionStore.self) private var session
    @State private var activeTab: AppTab = .home
    @Namespace private var animationNamespace

    enum AppTab: String, CaseIterable {
        case home = "Home"
        case workouts = "Workouts"
        case nutrition = "Nutrition"
        case history = "History"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .workouts: return "dumbbell.fill"
            case .nutrition: return "leaf.fill"
            case .history: return "clock.fill"
            case .profile: return "person.crop.circle.fill"
            }
        }
    }

    var body: some View {
            ZStack(alignment: .bottom) {
                
                // 1. Content Layer
                TabView(selection: $activeTab) {
                    
                    // Pass the binding here!
                    HomeTab(activeTab: $activeTab)
                        .tag(AppTab.home)
                        .safeAreaPadding(.bottom, 100)
                        .toolbar(.hidden, for: .tabBar)
                    
                    // ... rest of the tabs (Workouts, Nutrition, History, Profile) remain the same
                    WorkoutsListView()
                        .tag(AppTab.workouts)
                        .safeAreaPadding(.bottom, 100)
                        .toolbar(.hidden, for: .tabBar)
                    
                    NutritionView()
                        .tag(AppTab.nutrition)
                        .safeAreaPadding(.bottom, 100)
                        .toolbar(.hidden, for: .tabBar)

                    HistoryView()
                        .tag(AppTab.history)
                        .safeAreaPadding(.bottom, 100)
                        .toolbar(.hidden, for: .tabBar)
                    
                    ProfileView()
                        .tag(AppTab.profile)
                        .safeAreaPadding(.bottom, 100)
                        .toolbar(.hidden, for: .tabBar)
                }
                .background(Theme.Color.bg.ignoresSafeArea())
                
                // 2. Custom Bottom Tab Bar
                customTabBar
            }
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(edges: .bottom)
        }
    
    private var customTabBar: some View {
        HStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        activeTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 24))
                        
                        Text(tab.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(activeTab == tab ? Theme.Color.primaryAccent : Color.gray.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    // Add top padding inside the bar
                    .padding(.top, 16)
                    .overlay(
                        ZStack {
                            if activeTab == tab {
                                Circle()
                                    .fill(Theme.Color.primaryAccent)
                                    .frame(width: 5, height: 5)
                                    .offset(y: -28)
                                    .matchedGeometryEffect(id: "TabDot", in: animationNamespace)
                            }
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        // Add bottom padding for the buttons so they don't sit ON the home indicator
        // 34 is the standard height of the home indicator area on iPhones
        .padding(.bottom, 34)
        .background(
            Color.white
                // Round only the top corners
                .clipShape(
                    .rect(
                        topLeadingRadius: 30,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 30
                    )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        )
    }
    
}


