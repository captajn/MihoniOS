import SwiftUI

/// Support us screen with donation links
struct SupportScreen: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.tint)
                    Text(String(localized: "label_support_us"))
                        .font(.title2.weight(.semibold))
                    Text(String(localized: "label_support_us"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
            }

            Section(String(localized: "label_support_us")) {
                Link(destination: URL(string: "https://github.com/mihonapp/mihon")!) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://mihon.app")!) {
                    Label(String(localized: "label_support_us"), systemImage: "globe")
                }
            }

            Section {
                Text(String(localized: "label_support_us"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(String(localized: "label_support_us"))
    }
}
