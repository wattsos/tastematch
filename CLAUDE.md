# TasteMatch — Project Rules

## Build & Test
- `xcodebuild test -project ios/TasteMatch.xcodeproj -scheme TasteMatch -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' -quiet`

## Design System Rules (enforce everywhere, every file, every PR)

1. **No shadows.** Zero. `.shadow(color: .clear, radius: 0)` if you must override an inherited one. Never add `shadow()` to any view.

2. **Corner radius max 8.** Use `Theme.radius` (currently 8). Never hardcode a radius above 8. No `cornerRadius: 12`, no `cornerRadius: 14`, no `cornerRadius: 20`.

3. **No beige-on-beige.** Never place a warm-tinted card (`Theme.surface`) on a same-tone background. If the surface and background are close, use a hairline border or skip the background entirely. Content sits on `Theme.bg`; cards use `Theme.surface` with `Theme.hairline` border.

4. **Typography carries hierarchy.** Size and weight do the work — not color, not decoration, not cards. Section labels: uppercase, `.caption.weight(.semibold)`, `Theme.muted`, `tracking(1.2)`. Body: `Theme.ink`. Don't rely on colored badges or backgrounds to create emphasis.

5. **One accent color max — prefer none.** `Theme.accent` is aliased to `Theme.ink` (near-black). Do not introduce additional accent colors. Match-strength colors (sage/amber/rose) are the only exception and must stay desaturated. No terracotta, no blush, no bright tints.

6. **Remove or heavily demote percentage metrics.** Never show "85% match" or similar confidence percentages prominently. Use qualitative words instead: "High", "Moderate", "Low". If a percentage must appear, use `.caption2`, `Theme.muted` — smallest possible presence.

7. **No retail language.** Banned phrases: "Results", "Picks for You", "Strong match", "Good match", "Your Story", "Shop Now". Use instead: "READING", "SELECTION", "ALIGNMENT", "PROFILE 01". Tone is lab/editorial, not e-commerce.
