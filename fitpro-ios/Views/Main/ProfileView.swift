import SwiftUI

struct ProfileView: View {
    @Environment(\.appEnvironment) private var env
    @Environment(SessionStore.self) private var session

    @State private var vm: ProfileViewModel? = nil
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            Group {
                if let model = vm {
                    content(model)
                        .task {
                            if model.user == nil && !model.isLoading {
                                await model.load()
                            }
                        }
                        .refreshable { await model.load() }
                } else {
                    ProgressView("Preparing profile…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                if vm != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Logout") { session.logout() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") { showEdit = true }
                            .disabled(vm?.user == nil)
                    }
                }
            }
            .onAppear {
                if vm == nil {
                    let factory = ServiceFactory(env: env)
                    vm = ProfileViewModel(users: factory.usersService())
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ model: ProfileViewModel) -> some View {
        if model.isLoading && model.user == nil {
            ProgressView("Loading profile…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let u = model.user {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l.rawValue) {

                    sectionCard(title: "Account") {
                        LabeledContent("Email", value: u.email)
                        LabeledContent("Name", value: u.name)
                    }

                    sectionCard(title: "Fitness") {
                        LabeledContent("Level", value: u.fitnessLevel ?? "—")
                        LabeledContent("Age", value: u.age.map(String.init) ?? "—")
                        LabeledContent("Height (cm)", value: u.heightCm?.formatted() ?? "—")
                        LabeledContent("Weight (kg)", value: u.weightKg?.formatted() ?? "—")
                    }

                    sectionCard(title: "Goals") {
                        LabeledContent("Type", value: u.goals?.goalType ?? "—")
                        LabeledContent("Target (kg)", value: u.goals?.targetWeightKg?.formatted() ?? "—")
                        LabeledContent("Weekly Workouts", value: u.goals?.weeklyWorkouts.map(String.init) ?? "—")
                    }

                    if let err = model.errorMessage, !err.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(err)
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.Color.danger)
                        }
                        .card()
                    }
                }
                .padding(.horizontal, Theme.Spacing.l.rawValue)
                .padding(.vertical, Theme.Spacing.l.rawValue)
                .background(Theme.Color.bg.ignoresSafeArea())
            }
            .sheet(isPresented: $showEdit) {
                EditProfileView(
                    initial: u,
                    onSave: { name, level, age, height, weight, goals in
                        Task {
                            let ok = await model.save(
                                name: name,
                                fitnessLevel: level,
                                age: age,
                                heightCm: height,
                                weightKg: weight,
                                goals: goals
                            )
                            if ok { showEdit = false }
                        }
                    }
                )
            }
        } else {
            VStack(spacing: Theme.Spacing.m.rawValue) {
                ContentUnavailableView(
                    "Couldn’t load your profile",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text(model.errorMessage ?? "Please try again.")
                )
                Button {
                    Task { await model.load() }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, Theme.Spacing.l.rawValue)
        }
    }

    // MARK: - Local layout helper using design tokens
    @ViewBuilder
    private func sectionCard(title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s.rawValue) {
            Text(title).sectionHeader()
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .card()
        }
    }
}
