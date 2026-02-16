import SwiftUI

struct IdentityHomeView: View {
    @Binding var path: NavigationPath

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("PROFILE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.2)

            Text("Your identity")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.ink)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }
}
