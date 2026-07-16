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
                    Text(String(localized: "support_us_title"))
                        .font(.title2.weight(.semibold))
                    Text(String(localized: "support_us_description"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
            }

            Section(String(localized: "support_us_links")) {
                Link(destination: URL(string: "https://github.com/mihonapp/mihon")!) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://mihon.app")!) {
                    Label(String(localized: "support_website"), systemImage: "globe")
                }
            }

            Section {
                Text(String(localized: "support_us_thanks"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(String(localized: "label_support_us"))
    }
}
