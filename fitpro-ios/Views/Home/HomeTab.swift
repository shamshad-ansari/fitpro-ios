import SwiftUI

struct HomeTab: View {
    @Environment(\.appEnvironment) private var env
    @State private var vm: HomeViewModel? = nil
    
    // Navigation Control passed from MainFlowView
    @Binding var activeTab: MainFlowView.AppTab
    
    // Navigation for Quick Start Sheet
    @State private var activeRoutineSheet: WorkoutRoutine?
    @State private var showCreateRoutine = false

    var body: some View {
        let factory = ServiceFactory(env: env)

        NavigationStack {
            ZStack {
                Theme.Color.bg.ignoresSafeArea()
                
                if let model = vm {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.l.rawValue) {
                            
                            // 1. Header
                            headerSection(name: model.userName)
                            
                            // 2. Workout Stats Grid
                            workoutStatsGrid(model)
                            
                            // 3. Nutrition Overview (NEW)
                            nutritionOverviewSection(model)
                            
                            // 4. Quick Start Section
                            quickStartSection(routines: model.routines)
                            
                            // 5. Recent Activity
                            recentActivitySection(sessions: model.recentActivity)
                            
                            Spacer().frame(height: 50)
                        }
                        .padding(.vertical, Theme.Spacing.l.rawValue)
                    }
                    .refreshable { await model.load() }
                } else {
                    ProgressView().tint(Theme.Color.primaryAccent)
                }
            }
            .navigationBarHidden(true)
            
            // Sheets
            .sheet(item: $activeRoutineSheet) { routine in
                ActiveWorkoutView(routine: routine)
            }
            .sheet(isPresented: $showCreateRoutine) {
                CreateRoutineView(service: factory.workoutsService()) { _ in
                    Task { await vm?.load() }
                }
            }
            
            .onAppear {
                if vm == nil {
                    vm = HomeViewModel(
                        workouts: factory.workoutsService(),
                        users: factory.usersService(),
                        nutrition: factory.nutritionService()
                    )
                }
            }
            .task {
                if let model = vm, model.userName == "User" {
                    await model.load()
                }
            }
        }
    }

    // MARK: - Sections
    
    private func headerSection(name: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome Back,")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.subtle)
            Text(name)
                .font(Theme.Font.h1)
                .foregroundStyle(Theme.Color.text)
        }
        .padding(.horizontal, Theme.Spacing.l.rawValue)
        .padding(.top, Theme.Spacing.s.rawValue)
    }

    private func workoutStatsGrid(_ model: HomeViewModel) -> some View {
        HStack(spacing: Theme.Spacing.m.rawValue) {
            StatCard(icon: "flame.fill", iconColor: Theme.Color.primaryAccent, value: "\(model.currentStreak)", label: "Day Streak")
            StatCard(icon: "dumbbell.fill", iconColor: Theme.Color.secondary, value: "\(model.weeklyWorkouts)", label: "This Week")
            StatCard(icon: "checkmark.circle.fill", iconColor: Theme.Color.primaryAccent, value: "\(model.totalWorkouts)", label: "Total")
        }
        .padding(.horizontal, Theme.Spacing.l.rawValue)
    }
    
    // MARK: - NEW: Nutrition Overview
    private func nutritionOverviewSection(_ model: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m.rawValue) {
            Text("Today's Overview")
                .font(Theme.Font.h3)
                .foregroundStyle(Theme.Color.text)
                .padding(.horizontal, Theme.Spacing.l.rawValue)
            
            // Cards Row
            HStack(spacing: Theme.Spacing.m.rawValue) {
                // Calories
                let eaten = model.nutritionSummary?.calories.eaten ?? 0
                let goal = model.nutritionSummary?.calories.goal ?? 2000
                
                NutritionMiniCard(
                    title: "Calories",
                    icon: "apple.logo", // Placeholder for Apple
                    iconColor: .red,
                    current: eaten,
                    target: goal,
                    unit: "kcal",
                    progressColor: Theme.Color.primaryAccent
                )
                
                // Protein
                let proteinCurrent = model.nutritionSummary?.macros.protein.grams ?? 0
                let proteinTarget = model.nutritionSummary?.macros.protein.target ?? 150
                
                NutritionMiniCard(
                    title: "Protein",
                    icon: "fork.knife", // Placeholder for Chicken Leg
                    iconColor: Color(hex: "A0522D"), // Brownish
                    current: proteinCurrent,
                    target: proteinTarget,
                    unit: "g",
                    progressColor: Theme.Color.secondary
                )
            }
            .padding(.horizontal, Theme.Spacing.l.rawValue)
            
            // View Details Button
            Button {
                // SWITCH TO NUTRITION TAB
                withAnimation { activeTab = .nutrition }
            } label: {
                Text("View Nutrition Details")
                    .font(Theme.Font.button)
                    .foregroundStyle(Theme.Color.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.Color.primaryAccent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
            }
            .padding(.horizontal, Theme.Spacing.l.rawValue)
        }
    }
    
    private func quickStartSection(routines: [WorkoutRoutine]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m.rawValue) {
            Text("Quick Start")
                .font(Theme.Font.h3)
                .foregroundStyle(Theme.Color.text)
                .padding(.horizontal, Theme.Spacing.l.rawValue)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.m.rawValue) {
                    ForEach(routines) { routine in
                        QuickStartCard(routine: routine) {
                            activeRoutineSheet = routine
                        }
                    }
                    Button { showCreateRoutine = true } label: { CreateRoutineLink() }
                }
                .padding(.horizontal, Theme.Spacing.l.rawValue)
            }
        }
    }
    
    private func recentActivitySection(sessions: [WorkoutSession]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m.rawValue) {
            HStack {
                Text("Recent Activity")
                    .font(Theme.Font.h3)
                    .foregroundStyle(Theme.Color.text)
                Spacer()
                Button("See All") {
                    withAnimation { activeTab = .history } // Switch to History Tab
                }
                .font(.caption)
                .foregroundStyle(Theme.Color.primaryAccent)
            }
            .padding(.horizontal, Theme.Spacing.l.rawValue)
            
            VStack(spacing: Theme.Spacing.m.rawValue) {
                if sessions.isEmpty {
                    Text("No recent activity.")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.subtle)
                        .padding()
                } else {
                    ForEach(sessions) { session in
                        // Make the whole row clickable to go to history
                        Button {
                            withAnimation { activeTab = .history }
                        } label: {
                            ActivityRow(session: session)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l.rawValue)
        }
    }
}

// MARK: - Nutrition Mini Card

struct NutritionMiniCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let current: Int
    let target: Int
    let unit: String
    let progressColor: Color
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(Theme.Color.bg) // Light grey bg for icon
                    .clipShape(Circle())
                
                Text(title)
                    .font(Theme.Font.label)
                    .foregroundStyle(Theme.Color.text)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(current)")
                    .font(Theme.Font.h2)
                    .foregroundStyle(Theme.Color.text)
                
                Text("of \(target) \(unit)")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.subtle)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Color.bg)
                    Capsule().fill(progressColor).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
        }
        .padding(Theme.Spacing.m.rawValue)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// ... (Other components like StatCard, QuickStartCard, ActivityRow remain the same)



// MARK: - Components (Unchanged)

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .padding(12)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            Text(value)
                .font(Theme.Font.h2)
                .foregroundStyle(Theme.Color.text)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Color.subtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.m.rawValue)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct QuickStartCard: View {
    let routine: WorkoutRoutine
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 24))
                .foregroundStyle(Theme.Color.primaryAccent)
                .padding(10)
                .background(Theme.Color.primaryAccent.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(Theme.Font.h4)
                    .foregroundStyle(Theme.Color.text)
                    .lineLimit(1)
                
                Text("\(routine.exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.subtle)
            }
            
            Button(action: onStart) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
                .font(Theme.Font.label)
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Color.primaryAccent)
                .clipShape(Capsule())
            }
        }
        .padding(Theme.Spacing.l.rawValue)
        .frame(width: 160)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct CreateRoutineLink: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.largeTitle)
                .foregroundStyle(Theme.Color.subtle)
            Text("Create New")
                .font(.caption)
                .foregroundStyle(Theme.Color.subtle)
        }
        .frame(width: 160, height: 180)
        .background(Theme.Color.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(Theme.Color.border)
        )
    }
}

struct ActivityRow: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack(spacing: Theme.Spacing.m.rawValue) {
            ZStack {
                Theme.Color.primaryAccent.opacity(0.1)
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(Theme.Color.primaryAccent)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.routine?.name ?? "Workout")
                    .font(Theme.Font.h4)
                    .foregroundStyle(Theme.Color.text)
                
                Text(detailsString)
                    .font(.caption)
                    .foregroundStyle(Theme.Color.subtle)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Color.subtle)
        }
        .padding(Theme.Spacing.m.rawValue)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private var detailsString: String {
        let date = session.startedAt.formatted(date: .abbreviated, time: .omitted)
        var parts = [date]
        if let dur = session.durationSec {
            parts.append("\(dur / 60) min")
        }
        parts.append("\(session.exercises.count) exercises")
        return parts.joined(separator: " • ")
    }
}
