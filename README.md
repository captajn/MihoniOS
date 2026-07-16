# Mihon iOS

[Tiếng Việt](#tiếng-việt) | [English](#english)

---

## Tiếng Việt

Port Swift của [Mihon](https://github.com/mihonapp/mihon) — ứng dụng đọc manga, webtoon và truyện tranh miễn phí.

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
└── Package.swift     SPM libraries
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

### Đọc offline

1. Chạy app lần đầu → tạo `Documents/local/`
2. Thêm manga: thư mục ảnh hoặc file `.cbz`
3. Duyệt → Nguồn Local → mở → Đọc

### Tuyên bố từ chối

Ứng dụng này không lưu trữ nội dung nào và không có liên kết với các nhà cung cấp nội dung.

---

## English

Swift port of [Mihon](https://github.com/mihonapp/mihon) — free manga, webtoon, and comic reader.

### Features

- 5-tab navigation: Library, Updates, History, Browse, More
- Reader: LTR, RTL, Vertical, Webtoon, Continuous Vertical
- Local source: read CBZ/ZIP/folders offline
- Download manager with queue
- Backup/Restore (cross-platform with Android)
- Extension system (JavaScript runtime)
- Tracking: MyAnimeList, AniList, Kitsu, + 8 more
- Settings: Appearance, Reader, Downloads, Tracking, Security
- i18n: Vietnamese (default) + English (912 keys from moko-resources)

### Folder layout

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
└── Package.swift     SPM libraries
```

### Requirements

- macOS + Xcode 16+
- iOS 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Python 3.8+ (for i18n scripts)

### Quick start

```bash
cd ios
xcodegen generate
open Mihon.xcodeproj
```

### Local reading

1. Run app → creates `Documents/local/`
2. Add manga: folders of images or `.cbz` files
3. Browse → Local source → open → Read

### Disclaimer

This application hosts zero content and has no affiliation with content providers.
