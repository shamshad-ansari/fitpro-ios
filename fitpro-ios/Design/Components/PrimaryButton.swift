import SwiftUI

struct PrimaryButton: View {
    var title: String
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading { ProgressView().tint(.white) }
                Text(title)
                    .font(Theme.Font.button)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, Theme.Spacing.m.rawValue)
            .padding(.horizontal, Theme.Spacing.l.rawValue)
            .background(Theme.Color.primaryAccent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl.rawValue, style: .continuous))
        }
        .disabled(isLoading)
    }
}
