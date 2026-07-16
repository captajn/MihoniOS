# Mihon iOS

Swift port of [Mihon](https://github.com/mihonapp/mihon). Roadmap: [plan-ios.md](../plan-ios.md) · Checklist: [PARITY.md](./PARITY.md)

## Folder layout

Conventional modular iOS layout (same idea as Usagi):

```
ios/
├── App/              # @main, root navigation, DI bootstrap, Info.plist
├── Features/         # Feature screens (Library, Browse, Reader, Settings…)
├── Core/             # Preferences, logging, AppContainer
├── Domain/           # Entities, use cases, repository protocols
├── Data/             # GRDB, repository implementations
├── DesignSystem/     # Theme + shared UI components
├── SourceAPI/        # Source protocols + LocalSource
├── Reader/           # Page loaders + reader models
├── Backup/           # Protobuf backup encode/restore
├── Download/         # Download queue
├── Extensions/       # JS extension runtime + stores
├── Tracking/         # Tracker services
├── Resources/        # Assets.xcassets
├── Tests/            # Unit tests by module
├── Widgets/          # WidgetKit stubs
├── project.yml       # XcodeGen
└── Package.swift     # SPM libraries (optional)
```

**Folder = module name** (import matches disk):

| Folder | `import` |
|--------|----------|
| Core | `import Core` |
| Domain | `import Domain` |
| Data | `import Data` |
| DesignSystem | `import DesignSystem` |
| SourceAPI | `import SourceAPI` |
| Reader | `import Reader` |
| Backup | `import Backup` |
| Download | `import Download` |
| Extensions | `import Extensions` |
| Tracking | `import Tracking` |
| App + Features | app target `Mihon` (no module import) |

## Requirements

- macOS + Xcode 16+
- iOS 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Repo: https://github.com/captajn/MihoniOS

## Open project

```bash
cd ios
xcodegen generate
open Mihon.xcodeproj
```

## App icon

iOS AppIcon is generated from the Android adaptive icon design
(`ic_launcher_background` + glyph from `.github/assets/logo.png`):

```bash
python ios/scripts/generate_app_icon.py
```

Colors match Android: background `#FAFAFA`, ring `#0058A0`, glyph `#031019`.

## Local reading

1. Run app once → creates `Documents/local/`
2. Add series: folders of images or `.cbz`
3. Browse → Local source → open → Read

## Disclaimer

This application hosts zero content and has no affiliation with content providers.
