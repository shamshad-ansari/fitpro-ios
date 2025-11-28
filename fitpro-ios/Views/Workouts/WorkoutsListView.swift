import SwiftUI

// At top of WorkoutsListView.swift
private enum WorkoutsSheet: Identifiable {
    case create
    case active(WorkoutRoutine)
    case edit(WorkoutRoutine) // <-- NEW Case

    var id: String {
        switch self {
        case .create: return "create"
        case .active(let r): return "active-\(r.id)"
        case .edit(let r): return "edit-\(r.id)" // <-- NEW ID
        }
    }
}

struct WorkoutsListView: View {
    @Environment(\.appEnvironment) private var env
    @State private var vm: WorkoutsListViewModel? = nil
    @State private var sheet: WorkoutsSheet? = nil

    var body: some View {
        let factory = ServiceFactory(env: env)

        NavigationStack {
            ZStack {
                Theme.Color.bg.ignoresSafeArea()
                
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
                        ProgressView()
                            .tint(Theme.Color.primaryAccent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .create } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.Color.primaryAccent)
                    }
                }
            }
            .onAppear {
                if vm == nil {
                    vm = WorkoutsListViewModel(service: factory.workoutsService())
                }
            }
            .sheet(item: $sheet) { sheetType in
                let factory = ServiceFactory(env: env)
                switch sheetType {
                case .create:
                    // Create Mode
                    CreateRoutineView(service: factory.workoutsService()) { newRoutine in
                        vm?.routines.insert(newRoutine, at: 0)
                    }
                    
                case .edit(let routine):
                    // Edit Mode <-- NEW
                    CreateRoutineView(service: factory.workoutsService(), routineToEdit: routine) { updatedRoutine in
                        // Update the routine locally in the list
                        if let index = vm?.routines.firstIndex(where: { $0.id == updatedRoutine.id }) {
                            vm?.routines[index] = updatedRoutine
                        }
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
            ProgressView("Loading routines...")
                .tint(Theme.Color.primaryAccent)
                .foregroundStyle(Theme.Color.subtle)
        } else if !model.routines.isEmpty {
            ScrollView {
                VStack(spacing: Theme.Spacing.m.rawValue) {
                    ForEach(model.routines) { routine in
                        RoutineCard(
                            routine: routine,
                            onStart: { sheet = .active(routine) },
                            onEdit: { sheet = .edit(routine) }, // <-- Trigger Edit Sheet
                            onDelete: {
                                Task { await model.delete(routine: routine) }
                            }
                        )
                    }
                }
                .padding(Theme.Spacing.l.rawValue)
            }
        } else {
            ContentUnavailableView {
                Label("No Workouts", systemImage: "dumbbell")
                    .foregroundStyle(Theme.Color.primaryAccent)
            } description: {
                Text("Tap + to create your first routine.")
                    .font(Theme.Font.body)
            }
        }
    }
}

// ... RoutineCard struct remains the same as previously updated ...

// MARK: - Routine Card Component (Updated Layout)

private struct RoutineCard: View {
    let routine: WorkoutRoutine
    let onStart: () -> Void
    // New Actions
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            // 1. Main Card Content
            VStack(alignment: .leading, spacing: Theme.Spacing.s.rawValue) {
                
                // Header Row: Date/Subtitle + Menu
                HStack(alignment: .top) {
                    Text(routine.notes?.uppercased() ?? "WORKOUT ROUTINE")
                        .font(Theme.Font.label)
                        .foregroundStyle(Theme.Color.subtle)
                        .padding(.top, 4)
                    
                    Spacer()
                    
                    // Menu Button
                    Menu {
                        Button {
                            onEdit?()
                        } label: {
                            Label("Edit Routine", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            onDelete?()
                        } label: {
                            Label("Delete Routine", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.Color.text)
                            .padding(8)
                            .background(Theme.Color.bg)
                            .clipShape(Circle())
                    }
                }
                
                // ... Title and Exercises list (same as before) ...
                Text(routine.name)
                    .font(Theme.Font.h2)
                    .foregroundStyle(Theme.Color.text)
                    .padding(.bottom, 4)
                
                // Spacer
                Spacer(minLength: 30)
            }
            .padding(Theme.Spacing.l.rawValue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl.rawValue))
            .shadow(
                color: Color.black.opacity(Theme.Elevation.card.o),
                radius: Theme.Elevation.card.r,
                x: Theme.Elevation.card.x,
                y: Theme.Elevation.card.y
            )
            
            // 2. The "Start" Button (Floating Bottom Right)
            Button(action: onStart) {
                Text("START")
                    .font(Theme.Font.button)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Theme.Color.secondaryAccent, Theme.Color.primaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Theme.Color.primaryAccent.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(Theme.Spacing.l.rawValue)
        }
    }
}
