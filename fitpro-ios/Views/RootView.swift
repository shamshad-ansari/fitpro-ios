import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            if session.isLoggedIn {
                MainFlowView()
            } else {
                AuthFlowView()
            }
        }
    }
}
