# Working with Claude on Next Caltrain (iOS)

This repo (`next-caltrain-ios`) is a SwiftUI port of `next-caltrain-pwa` (a JS/PWA
Caltrain schedule app). The `next-caltrain-pwa` repo also hosts a published
`schedule.json` that this app fetches at runtime.

## Edit cycle

Claude edits files via its file tools, then provides a download link. The
workflow per change is:

1. Download the file(s) to `~/Downloads/`.
2. Run the copy-paste command Claude provides, which typically does:
   ```
   mv ~/Downloads/<Files> Sources/   # or tools/, assets/, etc.
   ./build.sh && ./emulate.sh
   ```

`./build.sh` wraps `xcodegen` (regenerates the Xcode project — needed when
files are added/removed) + `xcodebuild ... | grep "error:"` (build, only
errors printed) + `xcrun simctl uninstall` (clean reinstall).

`./emulate.sh` installs and launches the app in the simulator.

After running, the user shares a simulator screenshot for visual feedback and
iteration.

## Conventions

- **No bold headings/titles** unless explicitly requested. Default to
  `.regular` font weight.
- **Centering ragged content** (rows with variable-width text, e.g. station
  names): use a `PreferenceKey` to measure the max intrinsic width across
  rows, apply `.fixedSize(horizontal: true, vertical: false)` to prevent
  wrapping, fix all rows to that max width (left-aligned within), then center
  the fixed-width column with `.frame(maxWidth: .infinity, alignment: .center)`.
  Use `.offset(x:)` to correct for any asymmetric padding that throws off
  visual centering.
- **Shared styling** lives in `AppStyle.swift`:
  - Font sizes: `fontOriginHero`, `fontStationName`, `fontTripType`, etc.
  - Colors: `Color.calPast`, `.calArrive`, `.calDepart`, `.calSwapped`,
    `.iconCircleBackground`.
  - `AppStyle.iconButtonSize` (44pt) for toolbar icon buttons.
- **Toolbar icons** are circular (`Color.iconCircleBackground` fill,
  `AppStyle.iconButtonSize` frame), used consistently for back/swap/reset
  across Home, TripList, StationSelection, TripDetail, About.

## Schedule data pipeline

- `tools/convert_schedule.py` (in this repo) converts CSVs from
  `../next-caltrain-pwa/data/` into `schedule.json`. Includes a
  `scheduleDate` field (epoch ms = newest source CSV mtime) as a
  freshness/version marker, matching the PWA's convention.
- **Bundled fallback**: `assets/schedule.json` — regenerate with
  `python3 tools/convert_schedule.py` and commit when source data changes.
- **Published copy**: `../next-caltrain-pwa/webapp/schedule.json` — regenerate
  with `python3 tools/convert_schedule.py ../next-caltrain-pwa/data
  ../next-caltrain-pwa/webapp/schedule.json`, commit, then `npm run deploy`
  from `next-caltrain-pwa` (gcloud App Engine). Served at
  `https://next-caltrain-pwa.appspot.com/schedule.json`.
- At launch, `Schedule.refreshFromNetwork()` fetches the published copy and
  caches it to `Documents/schedule.json` for next launch.
  `Schedule.load()` prefers the cache, validates with `Schedule.isValid`
  (stop lists non-empty, schedule table arrays match stop-list lengths), and
  falls back to the bundled copy if the cache is missing/invalid.
- `CaltrainSchedule.swift` currently has temporary `[Schedule]` debug print
  statements from testing the fetch/cache path — harmless, can be removed
  whenever convenient.

## Debugging approach

- When something looks wrong, **compare side-by-side against the legacy PWA**
  using the same origin/destination — `open ~/next-caltrain-pwa/webapp/index.html`
  (or the live site). The PWA is the reference implementation.
- `git bisect` is available, but be careful: some bugs predate all recent
  commits (i.e. they're not regressions), so bisect can converge on a
  meaningless result. Test the oldest candidate commit directly first if
  unsure whether a bug is a regression at all.
- For routing logic specifically, `next-caltrain-pwa/src/CaltrainService.js`
  is the reference — compare its `direction()`/`select()`/`times()`/`merge()`
  against the Swift `CaltrainService.swift` equivalents when something
  doesn't match.
