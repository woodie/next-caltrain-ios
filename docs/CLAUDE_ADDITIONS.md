# Working with Claude on Next Caltrain (iOS) — Additions

> This document is provided to a new Claude session to describe the
> workflow and speed up development. On reading it, respond with: "OK,
> sounds like we're ready to work on this app" and wait for the next
> instruction.

## Testing

- Tests use Quick/Nimble in an RSpec-style `describe`/`context`/`it`
  format, living in `Tests/`. Run with `./test.sh`, which runs `xcodegen
  generate` automatically (so new spec files are picked up) and pipes
  `xcodebuild test` through `xcbeautify` for doc-formatted (`-fd`-style)
  output.
- `Tests/SpecFixtures.swift` is a factory/builder for `Schedule` fixtures —
  a tiny 16-station "railroad" (SF / San Jose Diridon / Morgan Hill / Gilroy
  + filler stops, padded to 16 entries because `TripViewModel.init` defaults
  to `stopAM = 15` and will crash on out-of-bounds with smaller fixtures).
  Use `SpecFixtures.schedule { $0.weekday(electric: .normal, diesel:
  .normal); ... }` to build scenario-specific schedules (e.g. "no service
  tomorrow", "modified holiday schedule").
- `.swiftlint.yml` relaxes `function_body_length`, `identifier_name`
  (allows `gt`), and `static_over_final_class` for spec files — don't fight
  these in Quick specs.
- See `docs/DEVELOPMENT.md` for the full command reference.

## Layout-jump lesson (generalizes the earlier safe-area lesson)

- Any pushed view (`NavigationLink` destination) that shows the *default*
  iOS nav bar (`.navigationBarTitleDisplayMode`, no `.navigationBarHidden`)
  can render flush-under-the-status-bar on first frame, then jump down once
  the safe-area inset resolves — even if it "looks fine" in a screenshot
  taken after the jump.
- Fix: every pushed view should follow the same structure as
  HomeView/TripListView — `.navigationBarHidden(true)`, with a toolbar
  `HStack` (back button + title/content) as the literal first child of the
  outer `VStack(spacing: 0)`, `.padding(.top, 8)`. `TripDetailView` was the
  last holdout and is now fixed this way.

## Light/dark mode

- `AppStyle.swift` colors are now adaptive via a `Color(light:dark:)` init
  using `UIColor { traits in ... }`. This "just works" — no
  `.preferredColorScheme()` override anywhere, system setting is followed
  automatically.
- Current light-mode values: `calPast` = pure blue `#00F`, `calArrive` =
  `#009e0b` (green), `calDepart` = mustard `#CC9E12`. Dark-mode values
  unchanged (neon `#0AF`/`#0F0`/`#FF0`).
- `appBackground`/`appText` are the adaptive black↔white / white↔black
  pair used everywhere `Color.black`/`Color(.white)` used to be hardcoded.
- Two remaining hardcoded (non-adaptive) colors, left as-is intentionally:
  the `Color(white: 0.5)` top gradient (HomeView + TripListView) and
  `Color.gray` divider in StationSelectionView — both looked fine in light
  mode when checked.

## South County "no service tomorrow" behavior (intentional, not a bug)

- South County (Gilroy-area) has weekday-only service in the real schedule.
  When today is the last day with trips and tomorrow has none (e.g.
  Friday→Saturday), `TripViewModel.clampedOffset` selects the **first**
  trip of today (not the last) so the full day's schedule stays visible —
  even if every trip has already departed. The selected trip gets a gray
  ring (`isNext && isInactive` → `.calSwapped`), not green.
- This is deliberate: South County riders are few enough that "NO TRAINS"
  after the last train departs (but before midnight) would hide useful
  info from someone still riding that train and checking later stops.
- Do not try to extend the rollover lookahead to find Monday's trains during
  this gap — explicitly decided against, see session history if revisiting.

## Privacy policy

- Hosted at `https://next-caltrain-pwa.appspot.com/privacy.html` (deployed
  via `npm run deploy` from `next-caltrain-pwa/webapp/`). Contact:
  privacy@netpress.com. Update "Last updated" date if the policy changes.
