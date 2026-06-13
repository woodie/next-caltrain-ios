# Git Workflow & Release Process

## Branching strategy

This project uses a simplified Git Flow model:

- **`main`** — production-ready code, always deployable to App Store. Every
  commit should pass `./test.sh` and be ready for release.
- **Feature branches** (`feature/*`) — new features, UI changes, bug fixes.
  Branch from `main`, merge back to `main` via pull request after review.
- **Hotfix branches** (`hotfix/*`) — urgent fixes for production bugs. Branch
  from `main`, merge back to `main` immediately after testing.

## Feature development workflow

1. **Create a branch** from `main`:
   ```bash
   git checkout main && git pull
   git checkout -b feature/my-feature-name
   ```

2. **Make changes** — edit files in vim, run `./build.sh && ./simulate.sh` to
   test interactively, take screenshots for feedback.

3. **Run tests** before committing:
   ```bash
   ./test.sh
   ```
   All 59 tests must pass. If you add new tests (recommended for new features),
   add them to `Tests/` and they'll be picked up automatically by `./test.sh`.

4. **Lint** to catch style issues:
   ```bash
   swiftlint
   ```
   (Relaxed rules for test files are already configured in `.swiftlint.yml`.)

5. **Commit** with a clear message:
   ```bash
   git add -A
   git commit -m "feature: add countdown timer to trip detail view"
   ```

6. **Push** and create a pull request on GitHub:
   ```bash
   git push origin feature/my-feature-name
   ```

7. **Review & merge**:
   - Run `./test.sh` one more time locally (or via CI if set up).
   - Merge via GitHub ("Squash and merge" to keep history clean, or regular
     merge if the feature has meaningful intermediate commits).
   - Delete the branch after merging.

## Hotfix workflow (for production bugs)

Same as feature workflow, but branch from `main` and name it `hotfix/*`:

```bash
git checkout main && git pull
git checkout -b hotfix/fix-countdown-display-bug
# ... make changes, test, commit ...
git push origin hotfix/fix-countdown-display-bug
# ... merge to main immediately (don't wait for review if urgent) ...
```

After merging, **you must re-release to the App Store** (see "App Store
release" below).

## Testing a feature branch

Before merging, always verify:

1. **Unit tests pass**:
   ```bash
   ./test.sh
   ```

2. **Simulator behavior** — build and test manually:
   ```bash
   ./build.sh && ./simulate.sh
   ```

3. **Edge cases** — if your change touches schedule logic, routing, or time
   calculations, test with debug overrides:
   - Set `GoodTimes.debugOverrideMinutes` / `debugOverrideDotw` to simulate
     different times/days (see `docs/TODAY_TOMORROW_ROLLOVER.md`).
   - Test South County no-service behavior (Friday evening, tomorrow is
     Saturday with no service).
   - Test schedule type cycling (weekday ↔ weekend ↔ modified).

4. **Logs** — stream debug logs while testing:
   ```bash
   ./simulate.sh -l
   ```

## Schedule updates (publish new `schedule.json`)

The app fetches `schedule.json` from the network at startup, so updating the
published schedule does **not** require an App Store release.

### Workflow

1. **Update the source CSVs** in `../next-caltrain-pwa/data/` (weekday,
   weekend, modified schedules from Caltrain's website).

2. **Convert to JSON**:
   ```bash
   cd next-caltrain-ios
   python3 tools/convert_schedule.py ../next-caltrain-pwa/data ../next-caltrain-pwa/webapp/schedule.json
   ```

3. **Validate** — the converter will print errors if anything is malformed
   (e.g. CSV rows don't match stop counts). Fix and retry.

4. **Spot-check** with `jq` to verify structure:
   ```bash
   jq '.northStops | length' ../next-caltrain-pwa/webapp/schedule.json
   jq '.northWeekday | to_entries | map(.value | length) | unique' ../next-caltrain-pwa/webapp/schedule.json
   ```
   Both should be 30 (or whatever the canonical stop count is); all schedule
   tables should have rows matching that count.

5. **Commit and push** to `next-caltrain-pwa`:
   ```bash
   cd ../next-caltrain-pwa
   git add webapp/schedule.json
   git commit -m "Update schedule: new modified schedule for Thanksgiving 2026"
   git push
   ```

6. **Deploy** to App Engine (accessible to the iOS app):
   ```bash
   npm run deploy
   ```
   This pushes the webapp (including the new `schedule.json`) to
   `https://next-caltrain-pwa.appspot.com/`.

7. **Verify** — the iOS app will fetch and cache the new schedule on next
   launch. To test:
   - Delete the local cache (see `docs/SCHEDULE_ENDPOINT.md`).
   - Restart the app.
   - Confirm the new schedule loads and displays correctly.

No app update is needed for users; they'll get the new schedule automatically
next time they open the app.

### Common mistakes to avoid

- **Forgetting to run `convert_schedule.py`** — editing the CSV by hand and
  pushing it without converting will silently break the JSON (the app's
  startup load will fail because the JSON is malformed).
- **Invalid times in the CSV** — see `docs/SCHEDULE_PARSING.md` for the
  AM/PM → minutes-since-midnight conversion rules. A single bad "12:XX"
  (noon vs. midnight) will break `Schedule.isValid()` and block the load.
- **Forgetting the all-empty Broadway row** — if a modified schedule PDF
  omits Broadway (a real station), you must insert an all-empty row in the
  CSV, or validation will fail (see `docs/SCHEDULE_PARSING.md`).
- **Forgetting to deploy** — if you commit the new JSON to `next-caltrain-pwa`
  but don't run `npm run deploy`, the app still fetches the old version from
  App Engine.

## App Store release workflow

Releasing a new version of the app to the App Store involves:

1. **Merge all feature branches** to `main` and ensure `./test.sh` passes.

2. **Update version numbers** in `NextCaltrain/Info.plist`:
   ```
   CFBundleShortVersionString = 1.1  (for a minor release)
   CFBundleVersion = 2               (build number, always increment)
   ```

3. **Update release notes** (recommended: maintain a `CHANGELOG.md`):
   - Summarize user-facing changes (new features, bug fixes, performance
     improvements).
   - Note any schedule changes or known limitations.

4. **Commit and tag**:
   ```bash
   git add -A
   git commit -m "Release 1.1"
   git tag -a v1.1 -m "Version 1.1 release"
   git push origin main --tags
   ```

5. **Build for distribution** in Xcode:
   - Open the project in Xcode.
   - Select Product > Archive (destination = generic iOS device).
   - Xcode Organizer will open; select your archive and click "Distribute
     App".
   - Choose App Store Connect as the destination.
   - Follow Apple's signing/upload flow.

6. **Submit for review** in App Store Connect:
   - Complete the "App Review Information" form if this is a version update.
   - Set the release date (Phased Release, immediate, or scheduled).
   - Click "Submit for Review".

7. **Monitor review status** — check App Store Connect daily for approval or
   rejection. Apple typically reviews within 24–48 hours.

8. **Release** — once approved, click "Release This Version" to make it live
   to users (or set a scheduled release time).

### Testing before release (TestFlight)

Recommended but optional: before submitting to App Store review, upload to
TestFlight and have testers (friends, colleagues, or internal team) verify
the app on real devices for a few days. This catches issues that don't appear
in the simulator.

To upload a build to TestFlight:
- In Xcode Organizer, after archiving, click "Distribute App" and choose
  "TestFlight" instead of App Store Connect.
- Wait for Apple to process (usually 10–30 min).
- Invite testers via App Store Connect (they install via TestFlight app).
- Collect feedback before submitting to review.

## Regression testing checklist

Before releasing (either a schedule update or an app update), verify:

- [ ] `./test.sh` passes (all 59 tests).
- [ ] `swiftlint` has no errors (warnings are OK).
- [ ] Simulator build works: `./build.sh && ./simulate.sh`.
- [ ] **Manual testing on a real device** (not just simulator), if possible.
- [ ] Schedule loads correctly (check "Schedule data: <date>" in About view).
- [ ] Time/date logic is correct (e.g. countdown updates every second,
      weekday/weekend detection works around midnight).
- [ ] South County edge case: test Friday evening (no Saturday service),
      confirm first trip of Friday is selected, not last.
- [ ] Dark mode and light mode both render correctly.
- [ ] App works offline (if cache exists, app should launch even with no
      network; verify this before release by temporarily disconnecting
      network or using Xcode's Network Link Conditioner).
