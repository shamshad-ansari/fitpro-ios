import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.m.rawValue)
            .background(Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue, style: .continuous))
            .shadow(color: .black.opacity(Theme.Elevation.card.o),
                    radius: Theme.Elevation.card.r,
                    x: Theme.Elevation.card.x,
                    y: Theme.Elevation.card.y)
    }
}

struct SectionHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Font.label)
            .foregroundStyle(Theme.Color.subtle)
            .textCase(.uppercase)
            .padding(.horizontal, Theme.Spacing.m.rawValue)
            .padding(.top, Theme.Spacing.l.rawValue)
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
    func sectionHeader() -> some View { modifier(SectionHeader()) }
}
