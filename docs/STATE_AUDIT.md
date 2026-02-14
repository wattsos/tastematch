# TasteMatch — State Audit

_Last updated: 2026-02-14_

## App Flow Map

```
Onboarding → Upload (photo) → Context (room type) → Calibration (swipe deck)
  → Results → Shop / Board / Discovery
```

### Screen Inventory

| Screen | File | Purpose |
|--------|------|---------|
| OnboardingScreen | `OnboardingScreen.swift` | First-run welcome |
| UploadScreen | `UploadScreen.swift` | Photo capture / import |
| ContextScreen | `ContextScreen.swift` | Room type + design goal selection |
| TasteCalibrationScreen | `TasteCalibrationScreen.swift` | Swipe-to-refine deck |
| AnalyzingView | `AnalyzingView.swift` | Loading state during analysis |
| ResultScreen | `ResultScreen.swift` | Profile + recommendations + discovery |
| ShopScreen | `ShopScreen.swift` | Full commerce grid ranked to profile |
| BoardScreen | `BoardScreen.swift` | Saved/favorited items grid |
| RecommendationDetailScreen | `RecommendationDetailScreen.swift` | Single product detail |
| MaterialShopSheet | `MaterialShopSheet.swift` | Commerce filtered by material |
| HistoryScreen | `HistoryScreen.swift` | Saved profiles list |
| CompareScreen | `CompareScreen.swift` | Side-by-side profile comparison |
| EvolutionScreen | `EvolutionScreen.swift` | Profile evolution timeline |
| FavoritesScreen | `FavoritesScreen.swift` | Global favorites list |
| SettingsScreen | `SettingsScreen.swift` | App settings |
| AboutScreen | `AboutScreen.swift` | About / credits |

## Inventory Sources

| Source | File | Count | Format |
|--------|------|-------|--------|
| Commerce catalog | `commerce_seed.json` | 150 items | JSON array, loaded by `LocalSeedCommerceProvider` |
| Discovery feed | `discovery.ndjson` | 300 items | Newline-delimited JSON, loaded by `DiscoveryLoader` |
| Legacy catalog | `MockCatalog.legacyItems` | 30 items | Hardcoded Swift array (fallback) |

## Engine Pipeline

1. **SignalExtractor** — extracts `VisualSignals` from photo data
2. **TasteEngine** — produces `TasteProfile` + `TasteVector` from signals, context, goal
3. **RecommendationEngine** — ranks `CatalogItem[]` against vector → `RecommendationItem[]`
4. **TasteVector.generateVariants()** — creates "Just Outside" alternative taste lanes
5. **DiscoveryEngine** — ranks discovery feed against axis scores + signal history
6. **ProfileNamingEngine** — generates profile name from vector + swipe count
7. **AxisPresentation** — produces influence/avoid phrases from axis scores
8. **DesignTipsEngine** — produces contextual design tips for profile

## Persistence (All Local)

| Store | File | Mechanism |
|-------|------|-----------|
| ProfileStore | `ProfileStore.swift` | UserDefaults (JSON-encoded `SavedProfile`) |
| CalibrationStore | `CalibrationStore.swift` | UserDefaults (per profile ID) |
| FavoritesStore | `FavoritesStore.swift` | UserDefaults |
| EventLogger | `EventLogger.swift` | Disk queue (JSON lines) |
| DiscoverySignalStore | `DiscoverySignalStore.swift` | UserDefaults (viewed/saved/dismissed) |
| DiscoveryCacheStore | `DiscoveryCacheStore.swift` | UserDefaults (ranked cache) |

## Local-Only vs Backend-Needed

### Currently Local (working)
- Photo analysis pipeline (SignalExtractor → TasteEngine → RecommendationEngine)
- Calibration swipe loop
- Profile naming
- Discovery ranking
- Favorites / board
- Event logging (queued to disk, no flush endpoint)
- Commerce ranking and shop

### Backend-Needed (not yet implemented)
- **User accounts / auth** — no user identity system
- **Profile sync** — profiles stored in UserDefaults only
- **Event flush** — EventLogger queues to disk but `APIClient.sendEvent` is a no-op stub
- **Image hosting** — all 180 image URLs pointed to non-existent `cdn.burgundy.app`
- **Share profile** — `showShareSheet` state exists but no UI button triggers it
- **Analytics pipeline** — events captured locally, no backend ingestion
- **Remote catalog updates** — commerce_seed.json bundled, no remote refresh

## Known Gaps

1. **Broken images** — All URLs use `cdn.burgundy.app` which does not resolve. Fixed by switching to `picsum.photos/seed/` deterministic placeholders.
2. **Dead share flow** — `showShareSheet` exists in ResultScreen but nothing sets it to `true`. Needs a toolbar button.
3. **No backend abstraction** — `APIClient` has hardcoded stubs; no protocol for swapping local/remote.
4. **No feature flags** — no mechanism to toggle local vs remote mode.
5. **No image caching** — `AsyncImage` used everywhere with no NSCache layer.

## File Count

- **45 source files** in `TasteMatch/`
- **15 test files** in `TasteMatchTests/` (126 tests across 15 suites)
- **1 JSON data file** (`commerce_seed.json`)
- **1 NDJSON data file** (`discovery.ndjson`)
