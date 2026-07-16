# Mihon iOS

[Tiếng Việt](#tiếng-việt) | [English](#english)

---

## Tiếng Việt

Đây là bản **port/đọc lại (rewrite)** sang Swift của [Mihon](https://github.com/mihonapp/mihon) — ứng dụng đọc manga, webtoon và truyện tranh miễn phí, mã nguồn mở.

**Đây KHÔNG PHẢI fork.** Đây là project iOS riêng, viết lại từ đầu bằng Swift/SwiftUI, tham khảo kiến trúc và tính năng từ bản Android gốc.

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
├── Features/         Tất cả màn hình
├── Core/             Preferences, logging, AppContainer
├── Domain/           Entities, use cases, repository protocols
├── Data/             GRDB schema, repository implementations
├── DesignSystem/     Theme, components
├── SourceAPI/        Source protocols + LocalSource
├── Reader/           Page loaders, reader models, navigation modes
├── Backup/           Protobuf encode/decode, backup service
├── Download/         Download manager, page loaders
├── Extensions/       JS extension runtime, extension store manager
├── Tracking/         Tracker protocol + 11 tracker services
├── Resources/        Assets.xcassets, Localizable.xcstrings
└── Package.swift     SPM libraries
```

### Yêu cầu

- macOS + Xcode 16+
- iOS 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

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

### Bản quyền & Giấy phép

- **Giấy phép:** [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) — giấy phép giống project gốc
- **Project gốc:** [Mihon](https://github.com/mihonapp/mihon) bởi [mihonapp](https://github.com/mihonapp)
- **Không affiliated:** Ứng dụng này không có liên kết chính thức với project Mihon gốc hay nhà phát triển của nó
- **Không lưu trữ nội dung:** Ứng dụng không host bất kỳ nội dung nào

### Disclaimer

This is an unofficial port of Mihon to iOS. It is not affiliated with or endorsed by the original Mihon project or its developers. Mihon is an open-source project licensed under Apache 2.0.

---

## English

This is an unofficial **port/rewrite** to Swift of [Mihon](https://github.com/mihonapp/mihon) — a free, open-source manga, webtoon, and comic reader.

**This is NOT a fork.** This is a standalone iOS project, written from scratch in Swift/SwiftUI, referencing the architecture and features of the original Android app.

### Features

- 5-tab navigation: Library, Updates, History, Browse, More
- Reader: LTR, RTL, Vertical, Webtoon, Continuous Vertical
- Local source: read CBZ/ZIP/folders offline
- Download manager with queue
- Backup/Restore (cross-platform with Android)
- Extension system (JavaScript runtime)
- Tracking: MyAnimeList, AniList, Kitsu, + 8 more
- Settings: Appearance, Reader, Downloads, Tracking, Security
- i18n: Vietnamese (default) + English

### Folder layout

```
ios/
├── App/              @main, root view, DI, background tasks
├── Features/         All screens
├── Core/             Preferences, logging, AppContainer
├── Domain/           Entities, use cases, repository protocols
├── Data/             GRDB schema, repository implementations
├── DesignSystem/     Theme, components
├── SourceAPI/        Source protocols + LocalSource
├── Reader/           Page loaders, reader models, navigation modes
├── Backup/           Protobuf encode/decode, backup service
├── Download/         Download manager, page loaders
├── Extensions/       JS extension runtime, extension store manager
├── Tracking/         Tracker protocol + 11 tracker services
├── Resources/        Assets.xcassets, Localizable.xcstrings
└── Package.swift     SPM libraries
```

### Requirements

- macOS + Xcode 16+
- iOS 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

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

### License & Copyright

- **License:** [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) — same as the original project
- **Original project:** [Mihon](https://github.com/mihonapp/mihon) by [mihonapp](https://github.com/mihonapp)
- **Not affiliated:** This app is not officially affiliated with or endorsed by the original Mihon project or its developers
- **No content hosted:** This application does not host any content

### Disclaimer

This is an unofficial port of Mihon to iOS. It is not affiliated with or endorsed by the original Mihon project or its developers. Mihon is an open-source project licensed under Apache 2.0.
