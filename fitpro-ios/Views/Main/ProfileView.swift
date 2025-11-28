import SwiftUI

struct ProfileView: View {
    @Environment(\.appEnvironment) private var env
    @Environment(SessionStore.self) private var session

    @State private var vm: ProfileViewModel? = nil
    @State private var showEdit = false

    var body: some View {
        let factory = ServiceFactory(env: env)

        NavigationStack {
            ZStack {
                Theme.Color.bg.ignoresSafeArea()
                
                if let model = vm {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Theme.Spacing.l.rawValue) {
                            
                            // 1. Profile Header
                            if let user = model.user {
                                ProfileHeader(user: user)
                            }
                            
                            // 2. Stats Grid
                            StatsGrid(model: model)
                            
                            // 3. Settings List
                            SettingsSection(
                                onEditProfile: { showEdit = true }
                            )
                            
                            // 4. Logout Button
                            Button(action: { session.logout() }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Log Out")
                                }
                                .font(Theme.Font.button)
                                .foregroundStyle(Theme.Color.danger)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.Color.danger.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
                            }
                            .padding(.horizontal, Theme.Spacing.l.rawValue)
                            .padding(.bottom, 40)
                        }
                        .padding(.top, Theme.Spacing.xl.rawValue)
                    }
                    .refreshable { await model.load() }
                    .sheet(isPresented: $showEdit) {
                        if let u = model.user {
                            EditProfileView(initial: u) { name, level, age, height, weight, goals in
                                Task {
                                    if await model.save(name: name, fitnessLevel: level, age: age, heightCm: height, weightKg: weight, goals: goals) {
                                        showEdit = false
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ProgressView().tint(Theme.Color.primaryAccent)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if vm == nil {
                    vm = ProfileViewModel(
                        users: factory.usersService(),
                        workouts: factory.workoutsService()
                    )
                }
            }
            .task {
                if let model = vm, model.user == nil {
                    await model.load()
                }
            }
        }
    }
}

// MARK: - Components

private struct ProfileHeader: View {
    let user: User
    
    var initials: String {
        let components = user.name.components(separatedBy: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }
    
    var memberSince: String {
        guard let date = user.createdAt else { return "Member" }
        return "Member since \(date.formatted(.dateTime.month().year()))"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.m.rawValue) {
            // Avatar Circle
            ZStack {
                Circle()
                    .fill(Theme.Color.primaryAccent.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text(initials)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.Color.primaryAccent)
            }
            
            // Text Info
            VStack(spacing: 4) {
                Text(user.name)
                    .font(Theme.Font.h2)
                    .foregroundStyle(Theme.Color.text)
                
                Text(user.email)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.subtle)
            }
            
            // Member Pill
            Text(memberSince)
                .font(.caption)
                .foregroundStyle(Theme.Color.subtle)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Color.surface)
                .clipShape(Capsule())
        }
    }
}

private struct StatsGrid: View {
    let model: ProfileViewModel
    
    // Grid Layout: 2 columns
    let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.m.rawValue),
        GridItem(.flexible(), spacing: Theme.Spacing.m.rawValue)
    ]
    
    var volumeString: String {
        let val = model.totalVolumeKg
        if val >= 1000 {
            return String(format: "%.1fK", val / 1000)
        }
        return String(format: "%.0f", val)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m.rawValue) {
            Text("Your Stats")
                .font(Theme.Font.h3)
                .foregroundStyle(Theme.Color.text)
            
            LazyVGrid(columns: columns, spacing: Theme.Spacing.m.rawValue) {
                StatBox(
                    icon: "dumbbell.fill",
                    value: "\(model.totalWorkouts)",
                    label: "Total Workouts"
                )
                StatBox(
                    icon: "flame.fill",
                    value: "\(model.currentStreak)",
                    label: "Current Streak"
                )
                StatBox(
                    icon: "trophy.fill",
                    value: "\(model.longestStreak)",
                    label: "Longest Streak"
                )
                StatBox(
                    icon: "scalemass.fill",
                    value: volumeString,
                    label: "Total Volume (kg)"
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.l.rawValue)
    }
}

private struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Theme.Color.primaryAccent)
            
            Text(value)
                .font(Theme.Font.h2)
                .foregroundStyle(Theme.Color.text)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Color.subtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 8)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

private struct SettingsSection: View {
    let onEditProfile: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m.rawValue) {
            Text("Settings")
                .font(Theme.Font.h3)
                .foregroundStyle(Theme.Color.text)
                .padding(.horizontal, Theme.Spacing.l.rawValue)
            
            VStack(spacing: 0) {
                SettingsRow(icon: "person", title: "Edit Profile", action: onEditProfile)
                Divider().padding(.leading, 50)
                
                SettingsRow(icon: "bell", title: "Notifications", action: {})
                Divider().padding(.leading, 50)
                
                SettingsRow(icon: "chart.bar", title: "Units & Preferences", action: {})
                Divider().padding(.leading, 50)
                
                SettingsRow(icon: "info.circle", title: "About", action: {})
            }
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .padding(.horizontal, Theme.Spacing.l.rawValue)
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.m.rawValue) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.Color.primaryAccent)
                    .frame(width: 24)
                
                Text(title)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.subtle)
            }
            .padding()
        }
    }
}
