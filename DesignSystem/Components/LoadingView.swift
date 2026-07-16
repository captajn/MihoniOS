import SwiftUI

public struct LoadingView: View {
    public let message: String?

    public init(_ message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct ErrorBanner: View {
    public let message: String
    public let retry: (() -> Void)?

    public init(message: String, retry: (() -> Void)? = nil) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.subheadline)
            Spacer()
            if let retry {
                Button("Retry", action: retry)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
}
