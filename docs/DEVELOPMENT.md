# Development

This project assumes macOS with Xcode installed.

## One-time setup

```
brew install xcodegen xcbeautify swiftlint
```

(`brew install` can take a while the first time — these only need to be
installed once.)

## Running tests

Tests are written with [Quick](https://github.com/Quick/Quick) and
[Nimble](https://github.com/Quick/Nimble) in an RSpec-style
`describe`/`context`/`it` format, living in `Tests/`.

```
./test.sh
```

This runs `xcodegen generate` (so newly added spec files are picked up
automatically) and wraps `xcodebuild test`, piped through `xcbeautify`
(falling back to `xcpretty` or a quiet grep if `xcbeautify` isn't
installed) for RSpec `-fd`-style, doc-formatted output: each
`describe`/`context`/`it` shown as a nested line with a pass/fail mark.

First run will resolve and download Quick/Nimble (and their transitive
dependencies) via Swift Package Manager — this requires network access and
may take a minute. Subsequent runs use the cached packages.

The result is at the very end:

```
** TEST SUCCEEDED **
```

or

```
** TEST FAILED **
```

## Linting

```
swiftlint
```

`.swiftlint.yml` relaxes a few rules (`function_body_length`,
`identifier_name`, `static_over_final_class`) that don't fit the Quick spec
DSL — `override class func spec()` and short names like `gt` are
conventional in this style and not worth fighting.

## Regenerating the Xcode project

After adding/removing files or targets, or editing `project.yml`:

```
xcodegen generate
```

`./test.sh` runs this automatically, so new spec files in `Tests/` don't
need a separate step. For the app target (`Sources/`), run it manually
before `./build.sh` if you've added or removed files.

## Simulator build (debug, app target only)

```
./build.sh && ./simulate.sh
```

`build.sh` wraps `xcodegen` + `xcodebuild ... | grep "error:"` + a clean
simulator reinstall. `simulate.sh` installs and launches the app.

## Viewing logs

To stream debug logs from the running simulator app:

```
./simulate.sh -l
```

This captures `os_log` output from Swift code tagged with `[GoodTimes]`,
`[TripViewModel]`, or `[Schedule]`. To add your own debug logs, use:

```swift
import os.log
os_log("Your message here", log: OSLog.default, type: .debug)
```

The log predicate is configured in `simulate.sh` — edit it to capture
different tags or add new ones.

## Quick reference

| Task | Command |
| --- | --- |
| One-time setup | `brew install xcodegen xcbeautify swiftlint` |
| Regenerate Xcode project | `xcodegen generate` |
| Run unit tests | `./test.sh` |
| Lint | `swiftlint` |
| Build + run in simulator | `./build.sh && ./simulate.sh` |
| View debug logs | `./simulate.sh -l` |
