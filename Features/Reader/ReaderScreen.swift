import SwiftUI
import Core
import Reader
import UIKit

struct ReaderScreen: View {
    @StateObject private var model: ReaderViewModel
    @Environment(\.dismiss) private var dismiss

    init(request: ReaderOpenRequest) {
        _model = StateObject(wrappedValue: ReaderViewModel(request: request))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if model.isLoading {
                ProgressView()
                    .tint(.white)
            } else if let error = model.errorMessage {
                VStack(spacing: 12) {
                    Text(error)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button(String(localized: "action_close")) { dismiss() }
                        .buttonStyle(.borderedProminent)
                }
            } else if model.pages.isEmpty {
                Text(String(localized: "reader_no_pages"))
                    .foregroundStyle(.white)
            } else {
                readerContent
                    .ignoresSafeArea()
            }

            // Pager only: navigation tap zones using NavigationMode
            if model.isPagerMode, !model.isLoading, model.errorMessage == nil, !model.pages.isEmpty, !model.menuVisible {
                NavigationTapZones(model: model)
            }

            if model.menuVisible {
                menuOverlay
            } else if model.showPageNumber, !model.isLoading, model.pageCount > 0 {
                VStack {
                    Spacer()
                    Text(model.pageLabel)
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.45), in: Capsule())
                        .padding(.bottom, 20)
                }
                .allowsHitTesting(false)
            }
        }
        .statusBarHidden(!model.menuVisible)
        .persistentSystemOverlays(model.menuVisible ? .automatic : .hidden)
        .task {
            UIApplication.shared.isIdleTimerDisabled =
                AppContainer.shared.readerPreferences.keepScreenOn.get()
            await model.load()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            model.onDisappear()
        }
    }

    @ViewBuilder
    private var readerContent: some View {
        switch model.readingMode {
        case .webtoon, .continuousVertical:
            WebtoonReaderView(model: model)
        case .vertical:
            PagerReaderView(model: model, rtl: false, vertical: true)
        case .leftToRight:
            PagerReaderView(model: model, rtl: false, vertical: false)
        case .rightToLeft, .default:
            PagerReaderView(model: model, rtl: true, vertical: false)
        }
    }

    private var menuOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.mangaTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(model.chapterName)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .top, endPoint: .bottom)
            )

            // Dismiss menu by tapping middle
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { model.menuVisible = false }

            VStack(spacing: 12) {
                Text(model.pageLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white)

                if model.pageCount > 1 {
                    Slider(
                        value: Binding(
                            get: { Double(model.currentIndex) },
                            set: { model.goToPage(Int($0.rounded())) }
                        ),
                        in: 0...Double(max(0, model.pageCount - 1)),
                        step: 1
                    )
                    .tint(.white)
                    .padding(.horizontal)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(
                            [ReadingMode.rightToLeft, .leftToRight, .vertical, .webtoon, .continuousVertical],
                            id: \.flagValue
                        ) { mode in
                            Button {
                                model.readingMode = mode
                            } label: {
                                Text(shortName(mode))
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        model.readingMode == mode
                                            ? Color.accentColor
                                            : Color.white.opacity(0.15),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 28)
            .padding(.top, 12)
            .background(
                LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom)
            )
        }
    }

    private func shortName(_ mode: ReadingMode) -> String {
        switch mode {
        case .rightToLeft: String(localized: "right_to_left_viewer")
        case .leftToRight: String(localized: "left_to_right_viewer")
        case .vertical: String(localized: "vertical_viewer")
        case .webtoon: String(localized: "webtoon_viewer")
        case .continuousVertical: String(localized: "continuous_vertical_viewer")
        case .default: String(localized: "label_default")
        }
    }
}

// MARK: - Pager

private struct PagerReaderView: View {
    @ObservedObject var model: ReaderViewModel
    var rtl: Bool
    var vertical: Bool

    var body: some View {
        TabView(selection: Binding(
            get: { model.currentIndex },
            set: { model.goToPage($0) }
        )) {
            ForEach(0..<model.pageCount, id: \.self) { index in
                GeometryReader { geo in
                    ZoomablePageView(image: model.image(for: index), size: geo.size)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
        // Note: pure vertical page-flip TabView still swipes horizontally on iOS;
        // continuous vertical is covered by Webtoon mode.
        .opacity(vertical ? 1 : 1)
    }
}

// MARK: - Webtoon

private struct WebtoonReaderView: View {
    @ObservedObject var model: ReaderViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: model.readingMode == .continuousVertical ? 12 : 0) {
                    ForEach(0..<model.pageCount, id: \.self) { index in
                        WebtoonPageRow(model: model, index: index)
                            .id(index)
                            .onAppear {
                                model.currentIndex = index
                            }
                    }
                }
            }
            .onTapGesture {
                if !model.menuVisible {
                    model.toggleMenu()
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(model.currentIndex, anchor: .top)
                }
            }
        }
    }
}

private struct WebtoonPageRow: View {
    let model: ReaderViewModel
    let index: Int

    var body: some View {
        Group {
            if let image = model.image(for: index) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 400)
                    .overlay { ProgressView().tint(.white) }
                    .task {
                        _ = model.image(for: index)
                    }
            }
        }
    }
}

// MARK: - Zoomable page (UIKit)

private struct ZoomablePageView: UIViewRepresentable {
    let image: UIImage?
    let size: CGSize

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.delegate = context.coordinator
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 4
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.backgroundColor = .black
        scroll.bouncesZoom = true
        // Don't steal paging swipes when not zoomed
        scroll.panGestureRecognizer.minimumNumberOfTouches = 2

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.tag = 100
        scroll.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.onDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)

        context.coordinator.scrollView = scroll
        context.coordinator.imageView = imageView
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        guard let imageView = scroll.viewWithTag(100) as? UIImageView else { return }
        imageView.image = image
        imageView.frame = CGRect(origin: .zero, size: size)
        scroll.contentSize = size
        context.coordinator.imageView = imageView
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var scrollView: UIScrollView?
        weak var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        @objc func onDoubleTap(_ gr: UITapGestureRecognizer) {
            guard let scroll = scrollView else { return }
            if scroll.zoomScale > 1 {
                scroll.setZoomScale(1, animated: true)
            } else {
                let point = gr.location(in: imageView)
                let rect = zoomRect(for: scroll, scale: 2.5, center: point)
                scroll.zoom(to: rect, animated: true)
            }
        }

        private func zoomRect(for scroll: UIScrollView, scale: CGFloat, center: CGPoint) -> CGRect {
            var rect = CGRect.zero
            rect.size.height = scroll.frame.height / scale
            rect.size.width = scroll.frame.width / scale
            rect.origin.x = center.x - rect.size.width / 2
            rect.origin.y = center.y - rect.size.height / 2
            return rect
        }
    }
}

// MARK: - Navigation Tap Zones

private struct NavigationTapZones: View {
    @ObservedObject var model: ReaderViewModel

    var body: some View {
        GeometryReader { geo in
            let mode = NavigationMode(rawValue: model.navigationMode) ?? .lShaped
            let regions = mode.regions(for: geo.size)

            ForEach(Array(regions.enumerated()), id: \.offset) { _, region in
                Color.clear
                    .contentShape(Rectangle())
                    .frame(
                        width: region.rect.width * geo.size.width,
                        height: region.rect.height * geo.size.height
                    )
                    .position(
                        x: region.rect.midX * geo.size.width,
                        y: region.rect.midY * geo.size.height
                    )
                    .onTapGesture {
                        switch region.type {
                        case .menu:
                            model.toggleMenu()
                        case .prev, .left:
                            model.previousPage()
                        case .next, .right:
                            model.nextPage()
                        }
                    }
            }
        }
    }
}
