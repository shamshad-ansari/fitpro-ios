import SwiftUI

struct FormTextField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .never

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs.rawValue) {
            Text(label).font(Theme.Font.label).foregroundStyle(Theme.Color.subtle)
            TextField(label, text: $text)
                .textInputAutocapitalization(autocap)
                .keyboardType(keyboard)
                .padding(.vertical, Theme.Spacing.xs.rawValue)
                .padding(.horizontal, Theme.Spacing.s.rawValue)
                .background(Theme.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s.rawValue, style: .continuous))
        }
    }
}

struct FormSecureField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs.rawValue) {
            Text(label).font(Theme.Font.label).foregroundStyle(Theme.Color.subtle)
            SecureField(label, text: $text)
                .padding(.vertical, Theme.Spacing.xs.rawValue)
                .padding(.horizontal, Theme.Spacing.s.rawValue)
                .background(Theme.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s.rawValue, style: .continuous))
        }
    }
}
