import SwiftUI
import Combine

struct ActiveWorkoutView: View {
    let routine: WorkoutRoutine

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appEnvironment) private var env

    @State private var vm: ActiveWorkoutViewModel? = nil
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Alert state for finishing
    @State private var showFinishAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.bg.ignoresSafeArea()
                
                if let model = vm {
                    VStack(spacing: 0) {
                        // 1. Sticky Header (Timer & Controls)
                        ActiveWorkoutHeader(
                            routineName: model.routineName,
                            elapsedTime: model.elapsedLabel,
                            onFinish: { showFinishAlert = true }
                        )
                        
                        // 2. Scrollable Content
                        ScrollView {
                            VStack(spacing: Theme.Spacing.l.rawValue) {
                                // Routine Note if present
                                if let note = model.routineNote, !note.isEmpty {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundStyle(Theme.Color.primaryAccent)
                                        Text(note)
                                            .font(Theme.Font.body)
                                            .foregroundStyle(Theme.Color.subtle)
                                        Spacer()
                                    }
                                    .padding(Theme.Spacing.m.rawValue)
                                    .background(Theme.Color.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
                                }
                                
                                // Exercise Cards
                                ForEach(model.exercises) { ex in
                                    ActiveExerciseCard(
                                        exercise: ex,
                                        onAddSet: { model.addSet(to: ex.id) },
                                        weightBinding: { set in
                                            binding(for: set, in: ex, keyPath: \.weightText)
                                        },
                                        repsBinding: { set in
                                            binding(for: set, in: ex, keyPath: \.repsText)
                                        }
                                    )
                                }
                                
                                // Bottom Padding for scrolling
                                Spacer().frame(height: 100)
                            }
                            .padding(Theme.Spacing.l.rawValue)
                        }
                    }
                } else {
                    ProgressView()
                        .tint(Theme.Color.primaryAccent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true) // We use a custom header
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
            // Finish Confirmation
            .alert("Finish Workout?", isPresented: $showFinishAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Finish", role: .none) {
                    Task {
                        if let ok = await vm?.finish(), ok {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("Are you sure you're done? Empty sets will be discarded.")
            }
            // Error Alert
            .overlay {
                if let err = vm?.errorMessage {
                    VStack {
                        Spacer()
                        Text(err)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Theme.Color.danger)
                            .clipShape(Capsule())
                            .padding(.bottom, 50)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .onAppear {
                        // Auto-dismiss error after 3s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            vm?.errorMessage = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Binding Helper
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

// MARK: - Components

private struct ActiveWorkoutHeader: View {
    let routineName: String
    let elapsedTime: String
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            // Close / Minimize
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Color.subtle)
                    .padding(8)
                    .background(Theme.Color.surface)
                    .clipShape(Circle())
            }

            Spacer()

            // Timer (Central Focus)
            VStack(spacing: 2) {
                Text(elapsedTime)
                    .font(Theme.Font.h2)
                    .monospacedDigit() // Prevents jitter
                    .foregroundStyle(Theme.Color.text)
                Text(routineName)
                    .font(Theme.Font.label)
                    .foregroundStyle(Theme.Color.subtle)
            }

            Spacer()

            // Finish Button
            Button(action: onFinish) {
                Text("Finish")
                    .font(Theme.Font.button)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Color.primaryAccent)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Theme.Color.bg)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Theme.Color.border),
            alignment: .bottom
        )
    }
}

private struct ActiveExerciseCard: View {
    let exercise: ActiveWorkoutViewModel.ActiveExercise
    let onAddSet: () -> Void
    let weightBinding: (ActiveWorkoutViewModel.ActiveSet) -> Binding<String>
    let repsBinding: (ActiveWorkoutViewModel.ActiveSet) -> Binding<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m.rawValue) {
            
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(Theme.Font.h3)
                        .foregroundStyle(Theme.Color.text)
                    
                    if let note = exercise.note, !note.isEmpty {
                        Text(note)
                            .font(Theme.Font.label)
                            .foregroundStyle(Theme.Color.subtle)
                    }
                }
                Spacer()
                // Could add an "Exercise Options" dots menu here
            }
            
            // Sets Table Header
            HStack {
                Text("SET").frame(width: 40, alignment: .center)
                Spacer()
                Text("KG").frame(width: 80, alignment: .center)
                Spacer()
                Text("REPS").frame(width: 80, alignment: .center)
            }
            .font(Theme.Font.label)
            .foregroundStyle(Theme.Color.subtle)
            
            // Sets Rows
            VStack(spacing: Theme.Spacing.s.rawValue) {
                ForEach(exercise.sets) { set in
                    ActiveSetRow(
                        index: set.index,
                        weight: weightBinding(set),
                        reps: repsBinding(set)
                    )
                }
            }
            
            // Add Set Button
            Button(action: onAddSet) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Set")
                }
                .font(Theme.Font.label)
                .foregroundStyle(Theme.Color.primaryAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.Color.primaryAccent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s.rawValue))
            }
        }
        .padding(Theme.Spacing.m.rawValue)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
        .shadow(
            color: Color.black.opacity(Theme.Elevation.card.o),
            radius: Theme.Elevation.card.r,
            x: Theme.Elevation.card.x,
            y: Theme.Elevation.card.y
        )
    }
}

private struct ActiveSetRow: View {
    let index: Int
    @Binding var weight: String
    @Binding var reps: String
    
    var body: some View {
        HStack {
            // Set Number Badge
            Text("\(index)")
                .font(Theme.Font.label)
                .foregroundStyle(Theme.Color.subtle)
                .frame(width: 40, height: 40)
                .background(Theme.Color.bg) // Subtle visual separation
                .clipShape(Circle())
            
            Spacer()
            
            // Weight Input
            CompactInput(text: $weight, placeholder: "-")
                .frame(width: 80)

            Spacer()
            
            // Reps Input
            CompactInput(text: $reps, placeholder: "-")
                .frame(width: 80)
        }
    }
}

// Custom Input for the table cells
private struct CompactInput: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .font(Theme.Font.body)
            .padding(.vertical, 8)
            .background(Theme.Color.bg)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s.rawValue))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.s.rawValue)
                    .stroke(text.isEmpty ? Color.clear : Theme.Color.primaryAccent, lineWidth: 1)
            )
    }
}
