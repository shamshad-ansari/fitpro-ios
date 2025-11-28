import SwiftUI

struct HistoryView: View {
    @Environment(\.appEnvironment) private var env
    @State private var vm: HistoryViewModel? = nil

    var body: some View {
        let factory = ServiceFactory(env: env)

        NavigationStack {
            ZStack {
                Theme.Color.bg.ignoresSafeArea()
                
                Group {
                    if let model = vm {
                        content(model)
                            .task {
                                if model.sessions.isEmpty { await model.load() }
                            }
                            .refreshable { await model.refresh() }
                    } else {
                        ProgressView()
                            .tint(Theme.Color.primaryAccent)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if vm == nil {
                    vm = HistoryViewModel(workouts: factory.workoutsService())
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ model: HistoryViewModel) -> some View {
        if model.isLoading && model.sessions.isEmpty {
            ProgressView()
                .tint(Theme.Color.primaryAccent)
        } else if !model.sessions.isEmpty {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.m.rawValue) {
                    ForEach(model.sessions) { session in
                                            DetailedSessionCard(session: session) {
                                                Task { await model.delete(session: session) }
                                            }
                                        }
                }
                .padding(Theme.Spacing.l.rawValue)
            }
        } else {
            ContentUnavailableView {
                Label("No History", systemImage: "clock")
                    .foregroundStyle(Theme.Color.primaryAccent)
            } description: {
                Text("Complete a workout to see it here.")
            }
        }
    }
}

// MARK: - Detailed Session Card

private struct DetailedSessionCard: View {
    let session: WorkoutSession
    var onDelete: (() -> Void)? // Callback
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. Header Section
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.routine?.name ?? "Workout")
                        .font(Theme.Font.h3)
                        .foregroundStyle(Theme.Color.text)
                    
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.Font.label)
                        .foregroundStyle(Theme.Color.subtle)
                        .textCase(.uppercase)
                }
                Spacer()
                
                // Duration Badge
                if let duration = session.durationSec {
                    Text(formatDuration(duration))
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Color.bg)
                        .foregroundStyle(Theme.Color.text)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.Color.border, lineWidth: 1)
                        )
                }
                
                // Menu Icon
                Menu {
                    Button(role: .destructive) {
                        onDelete?()
                    } label: {
                        Label("Delete History", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.Color.subtle)
                        .padding(.leading, 8)
                        .padding(8) // Larger touch target
                }
            }
            .padding(Theme.Spacing.m.rawValue)
            .background(Theme.Color.surface)
            
            // ... rest of the card (Divider, Exercises) remains the same ...
            Divider().background(Theme.Color.border)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.l.rawValue) {
                ForEach(session.exercises) { ex in
                    ExerciseDetailRow(exercise: ex)
                }
            }
            .padding(Theme.Spacing.m.rawValue)
            .background(Theme.Color.bg.opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue)
                .stroke(Theme.Color.border, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(Theme.Elevation.card.o),
            radius: Theme.Elevation.card.r,
            x: Theme.Elevation.card.x,
            y: Theme.Elevation.card.y
        )
    }
    
    private func formatDuration(_ sec: Int) -> String {
        let m = sec / 60
        return "\(m) min"
    }
}

// MARK: - Exercise Detail Row

private struct ExerciseDetailRow: View {
    let exercise: WorkoutSession.ExerciseEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s.rawValue) {
            // Exercise Name + Note
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(Theme.Font.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Color.text)
                
                if let note = exercise.notes, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Theme.Color.subtle)
                }
            }
            
            // Sets List - cleaner design matching the reference
            VStack(spacing: 8) {
                ForEach(exercise.sets) { set in
                    HStack(spacing: Theme.Spacing.s.rawValue) {
                        // Set Number Badge - soft rounded square like in reference
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Color.primaryAccent.opacity(0.15))
                            
                            Text("\(set.index)")
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.Color.primaryAccent)
                        }
                        .frame(width: 44, height: 44)
                        
                        // Performance Display - clean and simple
                        HStack(spacing: 4) {
                            if let w = set.weightKg {
                                Text("\(Int(w))")
                                    .font(Theme.Font.body)
                                    .foregroundStyle(Theme.Color.text)
                                Text("kg")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Color.subtle)
                            }
                            
                            if set.weightKg != nil && set.reps != nil {
                                Text("×")
                                    .font(Theme.Font.body)
                                    .foregroundStyle(Theme.Color.subtle)
                            }
                            
                            if let r = set.reps {
                                Text("\(r)")
                                    .font(Theme.Font.body)
                                    .foregroundStyle(Theme.Color.text)
                                Text("reps")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Color.subtle)
                            }
                        }
                        
                        Spacer()
                        
                        // Volume Badge - subtle
                        if let w = set.weightKg, let r = set.reps {
                            Text("\(Int(w * Double(r))) kg")
                                .font(.caption)
                                .foregroundStyle(Theme.Color.subtle)
                        }
                    }
                }
            }
        }
    }
}
