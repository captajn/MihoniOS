import SwiftUI
import LocalAuthentication
import Core

struct AppLockView: View {
    var onUnlocked: () -> Void
    @State private var error: String?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text(String(localized: "lock_with_biometrics"))
                .font(.title2.weight(.semibold))
            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Button(String(localized: "lock_unlock")) {
                Task { await unlock() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task { await unlock() }
    }

    private func unlock() async {
        let context = LAContext()
        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
            onUnlocked()
            return
        }
        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "lock_unlock")
            )
            if ok { onUnlocked() }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
