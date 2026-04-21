# FotoPose — iOS App

AI-powered portrait photography assistant. Phase 1 MVP.

## Requirements

- Xcode 15+
- iOS 17.0+ deployment target (iOS 26+ required later for Foundation Models features in Phase 2)
- macOS 14+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation (or create a project manually)

## Generate the Xcode project

Install XcodeGen once:

```bash
brew install xcodegen
```

Then, from this `Posra/` directory:

```bash
xcodegen generate
open Posra.xcodeproj
```

## First-run setup inside Xcode

1. **Signing**: Select the `Posra` target → Signing & Capabilities → set your Team.
2. **StoreKit Configuration**: Product menu → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → pick `Posra.storekit`. This lets you test purchases and the 1-day trial without App Store Connect.
3. **Run on device**: The camera requires a physical iPhone. Simulator will launch but show the permission empty state.

## Phase 1 deliverables

- Design system (`Design/DesignSystem.swift`, `Extensions/View+Glass.swift`) — colors, gradient, glass modifier, gradient button style
- Onboarding — 3-step photo-backed carousel with Skip + permissions request
- Paywall — hero image, social proof, 3 plan cards, StoreKit 2 wired up
- Camera — live preview, rule-of-thirds grid, AR pose overlay, environment/detection chips, pose card carousel, shutter, timer, flash, camera switch
- Vision — `VNDetectHumanBodyPoseRequest` + `VNDetectHumanRectanglesRequest` at ~6 Hz
- Rule-based pose suggestion engine scoring against detected lighting, scene, person count
- 20-pose starter database (`Resources/poses.json`)

## Phase 2 deliverables (this commit)

- `Extensions/CLLocation+SunPosition.swift` — NOAA-derived solar altitude/azimuth, golden/blue/night window helpers
- `Services/LocationService.swift` — CLLocationManager wrapper publishing user location (low accuracy, 2km filter)
- `Services/LightAnalyzerService.swift` — fuses ISO / white-balance Kelvin / exposure brightness with sun position and scene to pick `Lighting`
- `Services/SceneClassifierService.swift` — `VNClassifyImageRequest` throttled to ~0.8 Hz, mapped to `Scene` enum via keyword buckets
- `Services/FoundationModelsService.swift` — iOS 26+ on-device LLM re-ranker (wrapped in `#if canImport(FoundationModels)` + `@available(iOS 26, *)`) with structured `@Generable` output; returns nil on unsupported devices
- `Services/PoseSuggestionEngine.swift` — now exposes both sync (rule-based) and async (FM re-rank on top of rule-based shortlist) APIs
- `ViewModels/CameraViewModel.swift` — wires location, scene, and light services; `detection.timeOfDay` populated
- `Views/Camera/EnvironmentTagView.swift` — emoji-prefixed light chip, time-of-day detection chip

## Phase 3 deliverables (this commit)

- `Views/PoseDetail/PoseDetailSheet.swift` — editorial hero image, tags, lighting-match card, pro tips, similar poses, "Use This Pose" CTA with paywall gate; presented as a sheet from both Camera (long-press a pose card) and Library (tap any card)
- `Views/Library/LibraryView.swift` — filter pills, trending carousel, golden-hour strip, categories grid with PRO gating
- `Views/Settings/SettingsView.swift` — native grouped list style (Subscription card Free/Pro, Camera prefs, AI detection, Notifications, About); `@AppStorage`-backed prefs
- `Services/NotificationService.swift` — golden-hour alerts (4 ahead), trial-ending (2h before), weekly Friday 18:00 nudge; does not auto-prompt — `requestAuthorizationIfNeeded` is user-initiated from onboarding / settings toggle
- `Resources/Assets.xcassets/AppIcon.appiconset/` — single-size 1024×1024 slot (Xcode 14+ auto-derivation); drop `AppIcon-1024.png` in before archiving
- Camera: "See all" jumps to Library tab; long-press on pose card opens detail sheet
- Onboarding final step now requests notification permission alongside location

## Phase 3 scope (deferred)

- App Store metadata / screenshots
- Real `AppIcon-1024.png` asset (currently a manifest placeholder)

## Architecture

Standard MVVM. Services are plain classes owned by view models. All AI/ML runs on-device — no networking beyond image URLs in `poses.json`.

```
App/            — @main, AppState, navigation root
Models/         — Pose, DetectionResult, SubscriptionStatus
ViewModels/     — CameraViewModel
Views/          — SwiftUI screens (Camera, Library, Settings, Onboarding, Paywall, PoseDetail)
Services/       — CameraService, VisionService, SceneClassifier, LightAnalyzer, LocationService,
                  FoundationModelsService, PoseSuggestionEngine, SubscriptionService,
                  NotificationService, PoseDatabase
Design/         — Design tokens
Extensions/     — Color+Hex, glass modifier, gradient button, CLLocation+SunPosition
Resources/      — poses.json, Assets.xcassets
```
