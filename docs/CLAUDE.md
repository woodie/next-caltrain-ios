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
   ./build.sh && ./simulate.sh
   ```

`./build.sh` wraps `xcodegen` (regenerates the Xcode project — needed when
files are added/removed) + `xcodebuild ... | grep "error:"` (build, only
errors printed) + `xcrun simctl uninstall` (clean reinstall).

`./simulate.sh` installs and launches the app in the simulator.

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
- **No bundled fallback**: the app does not ship `schedule.json` in the
  bundle. On first launch with no cache and a failed/slow fetch, the app
  shows a loading state (see "Startup / loading flow" below) until the
  network fetch succeeds.
- **Published copy**: `../next-caltrain-pwa/webapp/schedule.json` — regenerate
  with `python3 tools/convert_schedule.py ../next-caltrain-pwa/data
  ../next-caltrain-pwa/webapp/schedule.json`, commit, then `npm run deploy`
  from `next-caltrain-pwa` (gcloud App Engine). Served at
  `https://next-caltrain-pwa.appspot.com/schedule.json`.
- At launch, `Schedule.refreshFromNetwork()` fetches the published copy and
  caches it to `Documents/schedule.json` for next launch.
  `Schedule.load()` prefers the cache, validates with `Schedule.isValid`
  (stop lists non-empty, schedule table arrays match stop-list lengths).
- `CaltrainSchedule.swift` currently has temporary `[Schedule]` debug print
  statements from testing the fetch/cache path — harmless, can be removed
  whenever convenient.

## Startup / loading flow

- On launch, show a modified `AboutView` as a loading screen: the "Schedule
  data: <date>" section is replaced with "Loading schedule data", and the
  back button is hidden.
- While this is shown, the app loads schedule data — prefer the cache
  (`Documents/schedule.json`) if valid, then attempt
  `Schedule.refreshFromNetwork()` to update it.
- Once schedule data is available (from cache or network), automatically
  transition to `HomeView`.
- If there is no valid cache and the network fetch fails/times out, this is
  currently an open question for how to handle (e.g. retry vs. error state)
  — don't assume a bundled fallback exists.

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

## Workflow reminders

- After every file edit, always provide the copy-paste command:
  ```
  mv ~/Downloads/<Files> Sources/   # or tools/, assets/, etc.
  ./build.sh && ./simulate.sh
  ```
  Don't omit this even if it was given recently — always include it with each
  set of changed files.

- When Claude needs the contents of a file it doesn't have, ask for it via:
  ```
  cat Sources/<filename> | pbcopy
  ```
  (one file per command, or one command listing multiple filenames if the
  user is sending several files at once).

## Lessons from layout debugging

- **`.navigationBarHidden(true)` on a pushed view (via `NavigationLink`) does
  not preserve the safe-area top inset**, even though the same modifier on a
  root view (like Home) does. A pushed view's content can render flush under
  the status bar/notch despite normal `.padding(.top, ...)`.
  - Symptom: toolbar icons render under the clock and become untappable.
  - Fix that worked: structure the pushed view's body **identically** to the
    working root view — toolbar `HStack` as the literal first child of the
    outermost `VStack(spacing: 0)`, with plain `.padding(.top, 8)`, no extra
    wrapper views, no `GeometryReader`, no `.safeAreaInset`, no
    `.frame(maxHeight:...)`. Matching the structure exactly (not just the
    padding values) is what fixes it — partial matches can still misbehave.
  - Avoid going down the rabbit hole of `.safeAreaInset(edge: .top)`,
    `UIApplication`-derived status bar height, or large fixed padding values
    — these either don't apply, get clipped, or cause the whole view to
    center/bottom-align unexpectedly.

- **Toolbar-vs-content layout pattern**: pin the toolbar as a fixed-height,
  non-flexible `HStack` (no `Spacer()` that could absorb extra space) at the
  top of the outer `VStack`. Put everything else (back button, headers,
  scrollable/list content) in a separate block below it. This avoids fights
  over who "owns" vertical space.

- **Constrain content instead of fighting for header space**: rather than
  squeezing every pixel for a header/toolbar against a content area that
  wants to grow (e.g. a long trip list), cap the content's row count so
  there's natural slack at the bottom. For TripListView, 17 rows fits the
  screen with a little breathing room below.
