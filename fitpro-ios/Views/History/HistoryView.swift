import SwiftUI

struct HistoryView: View {
    @Environment(\.appEnvironment) private var env
    @State private var vm: HistoryViewModel? = nil

    var body: some View {
        let factory = ServiceFactory(env: env)

        NavigationStack {
            Group {
                if let model = vm {
                    content(model)
                        .task {
                            if model.sessions.isEmpty {
                                await model.load()
                            }
                        }
                        .refreshable {
                            await model.refresh()
                        }
                } else {
                    ProgressView("Loading history…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("History")
            .onAppear {
                if vm == nil {
                    vm = HistoryViewModel(workouts: factory.workoutsService())
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ model: HistoryViewModel) -> some View {
        if model.isLoading && model.sessions.isEmpty {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !model.sessions.isEmpty {
            List(model.sessions) { s in
                sessionRow(s)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listStyle(.plain)
        } else {
            ContentUnavailableView(
                "No workout history",
                systemImage: "clock",
                description: Text("Finish a workout to see it here.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Row

    private func sessionRow(_ s: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Routine name + date
            HStack {
                Text(s.routine?.name ?? "Workout")
                    .font(.headline)

                Spacer()

                Text(s.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Duration
            if let duration = s.durationSec {
                let minutes = duration / 60
                let seconds = duration % 60
                Text("Duration: \(minutes)m \(seconds)s")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Exercises + sets
            VStack(alignment: .leading, spacing: 12) {
                ForEach(s.exercises) { ex in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ex.name)
                            .font(.subheadline)
                            .bold()

                        // Header row
                        HStack {
                            Text("SET")
                                .frame(width: 40, alignment: .leading)
                            Text("WEIGHT")
                                .frame(width: 70, alignment: .leading)
                            Text("REPS")
                                .frame(width: 50, alignment: .leading)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                        // Set rows
                        ForEach(ex.sets) { set in
                            HStack {
                                Text("\(set.index)")
                                    .frame(width: 40, alignment: .leading)

                                if let w = set.weightKg {
                                    Text("\(Int(w))")
                                        .frame(width: 70, alignment: .leading)
                                } else {
                                    Text("-")
                                        .frame(width: 70, alignment: .leading)
                                }

                                if let r = set.reps {
                                    Text("\(r)")
                                        .frame(width: 50, alignment: .leading)
                                } else {
                                    Text("-")
                                        .frame(width: 50, alignment: .leading)
                                }
                            }
                            .font(.caption)
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.vertical, 6)
    }
}
 
