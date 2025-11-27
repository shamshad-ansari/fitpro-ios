import SwiftUI
import Combine

struct ActiveWorkoutView: View {
    let routine: WorkoutRoutine

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appEnvironment) private var env

    @State private var vm: ActiveWorkoutViewModel? = nil
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if let model = vm {
                    content(model)
                } else {
                    ProgressView("Preparing workout…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(routine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let model = vm {
                        Button {
                            Task {
                                let ok = await model.finish()
                                if ok { dismiss() }
                            }
                        } label: {
                            if model.isSaving {
                                ProgressView()
                            } else {
                                Text("Finish")
                            }
                        }
                    }
                }
            }
            .onAppear {
                if vm == nil {
                    let factory = ServiceFactory(env: env)
                    let model = ActiveWorkoutViewModel(
                        routine: routine,
                        workouts: factory.workoutsService()
                    )
                    vm = model
                    model.startWorkout()
                }
            }
            .onReceive(timer) { _ in
                vm?.tick()
            }
        }
    }

    @ViewBuilder
    private func content(_ model: ActiveWorkoutViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(model.routineName)
                        .font(.headline)
                    Spacer()
                    Text(model.elapsedLabel)
                        .monospacedDigit()
                        .font(.title3)
                }
                .padding(.horizontal)

                if let note = model.routineNote, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                ForEach(model.exercises) { ex in
                    exerciseCard(ex, model: model)
                }

                if let err = model.errorMessage {
                    Text(err)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
        }
    }

    private func exerciseCard(
        _ ex: ActiveWorkoutViewModel.ActiveExercise,
        model: ActiveWorkoutViewModel
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ex.name)
                .font(.headline)

            if let note = ex.note, !note.isEmpty {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Header row: SET | WEIGHT | REPS
            HStack {
                Text("SET").frame(width: 40, alignment: .leading)
                Text("WEIGHT").frame(width: 70, alignment: .trailing)
                Text("REPS").frame(width: 60, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Each set row
            ForEach(ex.sets) { set in
                HStack(spacing: 8) {
                    Text("\(set.index)")
                        .frame(width: 40, alignment: .leading)

                    TextField("", text: binding(for: set, in: ex, keyPath: \.weightText))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)

                    TextField("", text: binding(for: set, in: ex, keyPath: \.repsText))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
                .font(.caption)
                .padding(.vertical, 4)
            }

            Button {
                model.addSet(to: ex.id)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add Set")
                }
                .font(.subheadline)
            }
            .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    private func binding(
        for set: ActiveWorkoutViewModel.ActiveSet,
        in exercise: ActiveWorkoutViewModel.ActiveExercise,
        keyPath: WritableKeyPath<ActiveWorkoutViewModel.ActiveSet, String>
    ) -> Binding<String> {
        Binding(
            get: {
                guard
                    let vm,
                    let exIndex = vm.exercises.firstIndex(where: { $0.id == exercise.id }),
                    let setIndex = vm.exercises[exIndex].sets.firstIndex(where: { $0.id == set.id })
                else { return "" }
                return vm.exercises[exIndex].sets[setIndex][keyPath: keyPath]
            },
            set: { newValue in
                guard
                    let vmCurrent = vm,
                    let exIndex = vmCurrent.exercises.firstIndex(where: { $0.id == exercise.id }),
                    let setIndex = vmCurrent.exercises[exIndex].sets.firstIndex(where: { $0.id == set.id })
                else { return }
                vm?.exercises[exIndex].sets[setIndex][keyPath: keyPath] = newValue
            }
        )
    }
}
