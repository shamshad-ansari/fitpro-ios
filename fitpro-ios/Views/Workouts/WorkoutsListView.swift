import SwiftUI

// At top of WorkoutsListView.swift (outside the struct)
private enum WorkoutsSheet: Identifiable {
    case create
    case active(WorkoutRoutine)

    var id: String {
        switch self {
        case .create: return "create"
        case .active(let r): return "active-\(r.id)"
        }
    }
}


struct WorkoutsListView: View {
    @Environment(\.appEnvironment) private var env

    @State private var vm: WorkoutsListViewModel? = nil
    @State private var sheet: WorkoutsSheet? = nil   // 👈 drives both sheets

    var body: some View {
        let factory = ServiceFactory(env: env)

        NavigationStack {
            Group {
                if let model = vm {
                    content(model)
                        .task {
                            if model.routines.isEmpty && !model.isLoading {
                                await model.load()
                            }
                        }
                        .refreshable { await model.load() }
                } else {
                    ProgressView("Loading workouts…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sheet = .create                  // 👈 tap + to create
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                if vm == nil {
                    vm = WorkoutsListViewModel(service: factory.workoutsService())
                }
            }
            .sheet(item: $sheet) { sheet in
                // Rebuild factory inside sheet so it sees env
                let factory = ServiceFactory(env: env)

                switch sheet {
                case .create:
                    CreateRoutineView(
                        service: factory.workoutsService()
                    ) { newRoutine in
                        // Insert newly created routine at top
                        vm?.routines.insert(newRoutine, at: 0)
                    }

                case .active(let routine):
                    ActiveWorkoutView(routine: routine)
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ model: WorkoutsListViewModel) -> some View {
        if model.isLoading && model.routines.isEmpty {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !model.routines.isEmpty {
            List {
                ForEach(model.routines) { routine in
                    routineRow(routine)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            sheet = .active(routine)      // 👈 open ActiveWorkout
                        }
                }

                if let err = model.errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }
            }
        } else {
            VStack(spacing: 12) {
                ContentUnavailableView(
                    "No workouts yet",
                    systemImage: "dumbbell",
                    description: Text("Tap + to create your first routine.")
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func routineRow(_ r: WorkoutRoutine) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(r.name)
                .font(.headline)

            if !r.exercises.isEmpty {
                Text(r.exercises.map { $0.name }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text("No exercises yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button {
                    sheet = .active(r)                  // 👈 same behavior as tap
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 8)
    }
}
