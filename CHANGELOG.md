# Changelog

All notable changes to this project will be documented in this file.

## [0.2.1] - 2026-04-07

### Added
- New modular app architecture with controllers, services, repositories, and feature widgets.
- PIX QR scanner flow with payload parsing and form auto-fill.
- History editing workflow states (`clean`, `editing`, `consolidated`) with visual indicators.
- Smart save behavior for history entries: update existing entry or create a new one depending on key/amount/txid changes.
- `updatedAt` field in history entries with backward-compatible JSON parsing.
- App version label rendered discreetly on the main screen.
- Native Android splash screen using Tech7 artwork for light/dark themes.
- Unit and widget tests for payload generation/parsing and controller behavior.

### Changed
- Project identity updated to `qrpix` and Android package updated to `com.tech7.qrpix`.
- Main app moved from single-file implementation to structured screens/components.
- App launcher icons and Android startup resources regenerated.
- App version bumped to `0.2.1+3`.

### Removed
- Legacy monolithic files (`lib/pix_logic.dart`, `lib/pix_parser.dart`, `lib/qr_scanner_screen.dart`).
