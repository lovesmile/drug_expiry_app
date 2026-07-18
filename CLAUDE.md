# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Flutter mobile app (物品有效期管理工具 / Expiry Tracker) for tracking expiration dates of household items including drugs, food, cosmetics, and daily necessities. Supports barcode scanning, family sync via LAN, local notifications, and biometric app lock.

**Framework**: Flutter 3.x + Dart 3.x
**State Management**: Provider
**Database**: SQLite (sqflite)
**Target Platforms**: Android (primary), iOS

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run development version
flutter run

# Build Android APK (release)
flutter build apk --release

# Build Android APK (debug)
flutter build apk --debug

# Build iOS (release)
flutter build ios --release

# Static analysis
flutter analyze

# Run tests
flutter test
```

## Architecture

### State Management (Provider Pattern)

Four main providers, all injected at app root via `MultiProvider`:
- `SettingsProvider` — theme color, dark mode, app lock settings (persisted via SharedPreferences)
- `ItemProvider` — items CRUD, search, sort, filter
- `FamilyProvider` — family members for LAN sync
- `UserProvider` — user profile, premium status

### Service Layer

Services handle data access and external integrations:
- `DatabaseService` — SQLite CRUD, backup/restore (single singleton)
- `BarcodeService` — barcode lookup API calls + local cache in SQLite
- `NearbyService` — Google Nearby Connections for LAN device discovery and data sync
- `NotificationService` — `flutter_local_notifications` + `zonedSchedule` real scheduling (4 buckets: 30d/7d/3d/expired), `rescheduleFromDb()` called on item/settings changes and cold start
- `AdService` — Google Mobile Ads banner (bottom of item list)

### Startup Flow

```
main() → ExpiryTrackerApp() → MultiProvider → _PrivacyGate → _LockGate → ItemListScreen
```

- `_PrivacyGate` — shows privacy agreement on first launch
- `_LockGate` — checks `SettingsProvider.appLockEnabled` and requires biometric auth if enabled
- `ItemListScreen` `initState` — calls `NotificationService.rescheduleFromDb()`; if warning/expired items exist, shows a one-time SnackBar fallback (`_hasShownFallbackReminder` flag prevents repeat within session)

### Localization

Custom `AppLocalizations` with delegate. Two locales: `zh` and `en`. Resolution callback matches `zh` first, defaults to `en`. Keys are Chinese-readable strings used via `context.tr()`.

### Theming

`design/app_theme.dart` contains `AppTheme.build()` — single factory for all `ThemeData` fields. Uses `ColorScheme.fromSeed()` with user-selectable seed colors (green/blue/cyan). Material 3 enabled. Both light and dark themes built and switched via `themeMode`.

### Database Schema (version 6)

Tables: `drugs`, `family_members`, `reminders`, `users`, `barcode_cache`. Migrations handled via `onUpgrade` callback with version checks. Version 5 added electronics warranty fields; version 6 added `deadline_type` (expiry / warranty / none).

## Key Patterns

### Item Model
`lib/models/item.dart` — contains enums `ItemStatus`, `WarrantyStatus`, `UsageStatus`, `ItemCategory`. Status computed from `expiryDate` vs `DateTime.now()`. Warranty dates calculated from `purchaseDate` + `warrantyMonths`.

### Barcode Caching
`BarcodeService` first checks SQLite `barcode_cache` table before making HTTP requests to external APIs (AliCloud/Open Food Facts). Cache never expires by default.

### Family Sync
`NearbyService` uses Google Nearby Connections API. Devices discover each other on same WiFi and exchange items + members data as JSON. No cloud server required.

## File Organization

```
lib/
├── main.dart                    # Entry point, MultiProvider, privacy/lock gates
├── constants.dart              # Colors, sizes, strings, theme seeds
├── l10n/app_localizations.dart # Chinese/English translations
├── models/                     # Data models with enums
├── providers/                   # ChangeNotifier providers
├── services/                   # Database, API, notifications, sync
├── screens/                    # Full-page widgets
├── widgets/                    # Reusable UI components
└── design/                     # Theme, colors, semantic tokens
```
