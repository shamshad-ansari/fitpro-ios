import SwiftUI

// MARK: - Model
struct OnboardingItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
}

// MARK: - Main Onboarding Flow
struct OnboardingFlowView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    
    // Data Source
    private let pages: [OnboardingItem] = [
        .init(
            title: "Track Your Goal",
            subtitle: "Don't worry if you have trouble determining your goals, we can help you determine your goals and track your goals.",
            imageName: "Onboarding-TrackGoal"
        ),
        .init(
            title: "Get Burn",
            subtitle: "Let's keep burning to achieve your goals. It hurts only temporarily; if you give up now you'll be in pain forever.",
            imageName: "Onboarding-GetBurn"
        ),
        .init(
            title: "Eat Well",
            subtitle: "Improve your nutrition and keep track of your calories so you can get the best results from your training.",
            imageName: "Onboarding-EatWell"
        )
    ]
    
    private var totalPages: Int { pages.count + 1 }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Color.surface.ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                WelcomeSlide()
                    .tag(0)
                    .ignoresSafeArea()
                
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingSlide(item: pages[index])
                        .tag(index + 1)
                        .ignoresSafeArea(edges: .top)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Bottom Controls
            VStack(spacing: Theme.Spacing.m.rawValue) {
                if currentPage > 0 {
                    PageIndicator(count: totalPages - 1, current: currentPage - 1)
                        .padding(.bottom, 10)
                }
                
                HStack {
                    Spacer()
                    
                    if currentPage == 0 {
                        PrimaryButton(title: "Get Started") {
                            withAnimation { currentPage = 1 }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Theme.Spacing.l.rawValue)
                    } else {
                        // MARK: - FIXED LOGIC HERE
                        // We calculate progress based on content pages (Total is 3)
                        // Page 1 = 1/3, Page 2 = 2/3, Page 3 = 3/3
                        let currentStep = Double(currentPage)
                        let totalSteps = Double(pages.count)
                        let progress = currentStep / totalSteps
                        
                        NextCircleButton(
                            progress: progress,
                            isLast: currentPage == totalPages - 1,
                            action: advance
                        )
                        .padding(.trailing, Theme.Spacing.l.rawValue)
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.l.rawValue)
        }
    }
    
    private func advance() {
        if currentPage < totalPages - 1 {
            withAnimation { currentPage += 1 }
        } else {
            onComplete()
        }
    }
}

// MARK: - Slides

/// Refactored for Fullscreen: Gradient fills the whole screen
private struct WelcomeSlide: View {
    var body: some View {
        ZStack {
            // Fullscreen Gradient
            LinearGradient(
                colors: [Theme.Color.primaryAccent, Theme.Color.secondaryAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Content centered
            VStack(spacing: Theme.Spacing.s.rawValue) {
                Spacer()
                
                HStack(spacing: 0) {
                    Text("Fit")
                        .font(Theme.Font.h1)
                        .foregroundStyle(.white)
                    Text("Pro")
                        .font(Theme.Font.h1)
                        .foregroundStyle(Theme.Color.secondary)
                }
                
                Text("Everybody Can Train")
                    .font(Theme.Font.body)
                    .foregroundStyle(.white.opacity(0.85))
                
                Spacer()
            }
            .padding(.bottom, 100) // Leave room for the button at the bottom
        }
    }
}

/// Refactored for Fullscreen: Image takes top half, Text takes bottom half
/// Refactored for Fullscreen: Image fills the entire top area completely
private struct OnboardingSlide: View {
    let item: OnboardingItem
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                
                // Top Half: Image Container
                // We use ZStack to layer the gradient behind the image (just in case PNG has transparency)
                ZStack(alignment: .top) {
                    
                    // 1. Gradient Background (Safety layer)
                    IllustrationMaskShape()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Color.primaryAccent.opacity(0.1), Theme.Color.secondaryAccent.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .ignoresSafeArea()
                    
                    // 2. The Image - NOW FILLING THE SPACE
                    Image(item.imageName)
                        .resizable()
                        // FIX 1: Use scaledToFill so it expands to fill gaps
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        // FIX 2: Match the height of the container exactly
                        .frame(height: geometry.size.height * 0.55)
                        // FIX 3: Clip the image to the wave shape so it doesn't bleed out the bottom rect
                        .clipShape(IllustrationMaskShape())
                        // FIX 4: Ensure it goes behind the dynamic island
                        .ignoresSafeArea(edges: .top)
                }
                // Container height constraint
                .frame(height: geometry.size.height * 0.55)
                
                // Bottom Half: Text Content
                VStack(alignment: .leading, spacing: Theme.Spacing.m.rawValue) {
                    Text(item.title)
                        .font(Theme.Font.h2)
                        .foregroundStyle(Theme.Color.text)
                    
                    Text(item.subtitle)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.subtle)
                        .lineSpacing(4)
                    
                    Spacer()
                }
                .padding(Theme.Spacing.l.rawValue)
            }
        }
    }
}

// MARK: - Components

private struct NextCircleButton: View {
    let progress: Double // New Property
    let isLast: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Theme.Color.secondaryAccent.opacity(0.3), lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                // Progressive Arc
                Circle()
                    .trim(from: 0.0, to: progress) // Uses the calculated progress
                    .stroke(
                        Theme.Color.secondaryAccent,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress) // Animates the fill
                
                // Inner Circle Button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Color.secondaryAccent, Theme.Color.primaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: isLast ? "checkmark" : "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace)) // Nice icon swap animation
            }
        }
        .buttonStyle(.plain)
    }
}

private struct IllustrationMaskShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Simple wave at the bottom of the image container
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - 40))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - 40),
            control: CGPoint(x: rect.width / 2, y: rect.height + 40)
        )
        path.closeSubpath()
        return path
    }
}

private struct PageIndicator: View {
    let count: Int
    let current: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Theme.Color.primaryAccent : Color.gray.opacity(0.3))
                    .frame(width: index == current ? 24 : 8, height: 8)
                    .animation(.spring(), value: current)
            }
        }
    }
}

