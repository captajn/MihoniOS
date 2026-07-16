import SwiftUI

/// Placeholder cover until Nuke pipeline (Phase 1–2).
public struct MangaCoverView: View {
    public let title: String
    public let url: String?
    public var cornerRadius: CGFloat

    public init(title: String, url: String? = nil, cornerRadius: CGFloat = 8) {
        self.title = title
        self.url = url
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(.tertiarySystemFill))
            if let url, let imageURL = URL(string: url), !url.isEmpty, url.hasPrefix("http") {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .aspectRatio(2 / 3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var placeholder: some View {
        VStack(spacing: 6) {
            Image(systemName: "book.closed")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 4)
        }
    }
}
