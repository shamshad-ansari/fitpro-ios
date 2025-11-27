import SwiftUI

struct HomeTab: View {
    @Environment(\.appEnvironment) private var env

    @State private var vm: HomeViewModel? = nil

    var body: some View {
        let factory = ServiceFactory(env: env)

        NavigationStack {
            Group {
                if let model = vm {
                    content(model)
                        .task {
                            if !model.isLoading && model.totalWorkouts == 0 && model.todayWorkouts == 0 {
                                await model.load()
                            }
                        }
                        .refreshable {
                            await model.load()
                        }
                } else {
                    SwiftUI.ProgressView("Preparing…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("FitPro")
            .onAppear {
                if vm == nil {
                    vm = HomeViewModel(exercises: factory.exercisesService())
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ model: HomeViewModel) -> some View {
        if model.isLoading && model.totalWorkouts == 0 && model.todayWorkouts == 0 {
            SwiftUI.ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Today snapshot
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today")
                            .sectionHeader()
                        HStack(spacing: 12) {
                            smallStat(title: "Workouts", value: "\(model.todayWorkouts)")
                            smallStat(title: "Minutes", value: "\(Int(model.todayMinutes))")
                            smallStat(title: "Calories", value: "\(Int(model.todayCalories))")
                        }
                    }

                    // Last 7 days
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last 7 days")
                            .sectionHeader()
                        HStack(spacing: 12) {
                            bigStat(title: "Total Workouts", value: "\(model.totalWorkouts)")
                            bigStat(title: "Minutes", value: "\(Int(model.totalMinutes))")
                            bigStat(title: "Calories", value: "\(Int(model.totalCalories))")
                        }
                    }

                    // Last exercise (if any)
                    if let ex = model.lastExercise {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last exercise")
                                .sectionHeader()
                            VStack(alignment: .leading, spacing: 6) {
                                Text(ex.name)
                                    .font(.headline)
                                HStack(spacing: 12) {
                                    if let cat = ex.category {
                                        Label(cat.capitalized, systemImage: "tag")
                                    }
                                    if let dur = ex.durationMin {
                                        Label("\(Int(dur)) min", systemImage: "clock")
                                    }
                                    if let cals = ex.calories {
                                        Label("\(Int(cals)) kcal", systemImage: "flame")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                Text(ex.performedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .card()
                        }
                    }

                    // Quick note / CTA
                    if model.totalWorkouts == 0 {
                        Text("Start your journey by logging your first workout in the Exercise tab.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l.rawValue)
                .padding(.vertical, Theme.Spacing.l.rawValue)
            }
        }
    }

    private func smallStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.Font.label)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .card()
    }

    private func bigStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.Font.label)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .card()
    }
}
