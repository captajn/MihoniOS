# Mihon iOS

[English](#english) | [Tiếng Việt](#tiếng-việt)

---

## English

Swift port of [Mihon](https://github.com/mihonapp/mihon) — free manga, webtoon, and comic reader.

**Roadmap:** [plan-ios.md](../plan-ios.md) · **Checklist:** [PARITY.md](./PARITY.md)

### Features / Tính năng

- 5-tab navigation: Library, Updates, History, Browse, More
- Reader: LTR, RTL, Vertical, Webtoon, Continuous Vertical
- Local source: read CBZ/ZIP/folders offline
- Download manager with queue
- Backup/Restore (cross-platform with Android)
- Extension system (JavaScript runtime)
- Tracking: MyAnimeList, AniList, Kitsu, + 8 more
- Settings: Appearance, Reader, Downloads, Tracking, Security
- i18n: Vietnamese (default) + English (912 keys from moko-resources)

### Folder layout / Cấu trúc thư mục

```
ios/
├── App/              @main, root view, DI, background tasks
├── Features/         All screens (Library, Browse, Reader, Settings…)
├── Core/             Preferences, logging, AppContainer
├── Domain/           Entities, use cases, repository protocols
├── Data/             GRDB schema, repository implementations
├── DesignSystem/     Theme, components (EmptyState, MangaCover, Loading)
├── SourceAPI/        Source protocols + LocalSource
├── Reader/           Page loaders, reader models, navigation modes
├── Backup/           Protobuf encode/decode, backup service
├── Download/         Download manager actor, page loaders
├── Extensions/       JS extension runtime, extension store manager
├── Tracking/         Tracker protocol + 11 tracker services
├── Resources/        Assets.xcassets, Localizable.xcstrings
├── Widgets/          WidgetKit stubs
├── Scripts/          i18n conversion scripts
├── Tests/            Unit tests
├── project.yml       XcodeGen config
├── codemagic.yaml    CI/CD pipeline
├── Package.swift     SPM libraries
└── PARITY.md         Feature parity checklist with Android
```

### Requirements / Yêu cầu

- macOS + Xcode 16+
- iOS 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Python 3.8+ (for i18n scripts)

### Quick start / Bắt đầu nhanh

```bash
cd ios
xcodegen generate
open Mihon.xcodeproj
```

### Build (CI/CD)

Build automatically via [Codemagic](https://codemagic.io) on push to `main`:

- **Simulator build** → `.app` for preview
- **Unsigned archive** → `.ipa` for sideload

### Local reading / Đọc offline

1. Run app → creates `Documents/local/`
2. Add manga: folders of images or `.cbz` files
3. Browse → Local source → open → Read

### Tool / Công cụ

```bash
python tool-ios.py          # Interactive menu
python tool-ios.py status   # Git status
python tool-ios.py push     # Git commit + push
python tool-ios.py cm-trigger  # Trigger Codemagic build
python tool-ios.py cm-errors   # Show build errors
python tool-ios.py cm-builds   # List recent builds
```

### Disclaimer

This application hosts zero content and has no affiliation with content providers.

---

## Tiếng Việt

Port Swift của [Mihon](https://github.com/mihonapp/mihon) — ứng dụng đọc manga, webtoon và truyện tranh miễn phí.

**Lộ trình:** [plan-ios.md](../plan-ios.md) · **Kiểm tra:** [PARITY.md](./PARITY.md)

### Tính năng

- 5 tab: Thư viện, Cập nhật, Lịch sử, Duyệt, Thêm
- Trình đọc: Trái→Phải, Phải→Trái, Dọc, Webtoon, Webtoon liên tục
- Nguồn Local: đọc CBZ/ZIP/thư mục offline
- Quản lý tải xuống với hàng chờ
- Sao lưu/Khôi phục (tương thích Android)
- Hệ thống Extension (runtime JavaScript)
- Theo dõi: MyAnimeList, AniList, Kitsu, + 8 dịch vụ khác
- Cài đặt: Giao diện, Trình đọc, Tải xuống, Theo dõi, Bảo mật
- Ngôn ngữ: Tiếng Việt (mặc định) + English (912 key từ moko-resources)

### Cấu trúc thư mục

```
ios/
├── App/              @main, root view, DI, tác vụ nền
├── Features/         Tất cả màn hình (Library, Browse, Reader, Settings…)
├── Core/             Preferences, logging, AppContainer
├── Domain/           Entities, use cases, repository protocols
├── Data/             GRDB schema, repository implementations
├── DesignSystem/     Theme, components (EmptyState, MangaCover, Loading)
├── SourceAPI/        Source protocols + LocalSource
├── Reader/           Page loaders, reader models, navigation modes
├── Backup/           Protobuf encode/decode, backup service
├── Download/         Download manager actor, page loaders
├── Extensions/       JS extension runtime, extension store manager
├── Tracking/         Tracker protocol + 11 tracker services
├── Resources/        Assets.xcassets, Localizable.xcstrings
├── Widgets/          WidgetKit stubs
├── Scripts/          Script chuyển đổi i18n
├── Tests/            Unit tests
├── project.yml       Cấu hình XcodeGen
├── codemagic.yaml    CI/CD pipeline
├── Package.swift     SPM libraries
└── PARITY.md         Kiểm tra tính năng so với Android
```

### Yêu cầu

- macOS + Xcode 16+
- iOS 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Python 3.8+ (cho script i18n)

### Bắt đầu nhanh

```bash
cd ios
xcodegen generate
open Mihon.xcodeproj
```

### Build (CI/CD)

Build tự động qua [Codemagic](https://codemagic.io) khi push lên `main`:

- **Build Simulator** → `.app` để preview
- **Archive unsigned** → `.ipa` để cài sideload

### Đọc offline

1. Chạy app lần đầu → tạo `Documents/local/`
2. Thêm manga: thư mục ảnh hoặc file `.cbz`
3. Duyệt → Nguồn Local → mở → Đọc

### Công cụ

```bash
python tool-ios.py              # Menu tương tác
python tool-ios.py status       # Git status
python tool-ios.py push         # Git commit + push
python tool-ios.py cm-trigger   # Trigger build Codemagic
python tool-ios.py cm-errors    # Hiển thị lỗi build
python tool-ios.py cm-builds    # Liệt kê build gần đây
```

### Tuyên bố từ chối

Ứng dụng này không lưu trữ nội dung nào và không có liên kết với các nhà cung cấp nội dung.
