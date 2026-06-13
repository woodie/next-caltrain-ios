# CLAUDE_ADDITIONS.md — layout section replacement

Replace the existing "Layout-jump lesson" and "Lessons from layout
debugging" sections with the following. Other sections (Testing, Light/dark
mode, South County, Privacy policy) are unaffected.

---

## Layout patterns (two distinct cases — don't mix them)

There are two different layout problems in this app, with two different
correct solutions. Mixing them up is the most common source of regressions.

### 1. Pushed views (`NavigationLink` destinations) — safe-area jump fix

Any pushed view that shows the *default* iOS nav bar
(`.navigationBarTitleDisplayMode`, no `.navigationBarHidden`) can render
flush-under-the-status-bar on first frame, then jump down once the safe-area
inset resolves — even if it "looks fine" in a screenshot taken after the
jump.

**Fix**: every pushed view follows the same structure as
HomeView/TripListView's *toolbar* — `.navigationBarHidden(true)`, with a
toolbar `HStack` (back button + title/content) as the literal first child of
the outer `VStack(spacing: 0)`, plain `.padding(.top, 8)`. `TripDetailView`
is fixed this way.

For this specific problem: **no `GeometryReader`, no `.safeAreaInset`, no
extra wrapper views, no `.frame(maxHeight:...)`**. Matching the structure
exactly (not just the padding values) is what fixes it — partial matches can
still misbehave. `.safeAreaInset(edge: .top)`, `UIApplication`-derived status
bar height, and large fixed padding values either don't apply, get clipped,
or cause the whole view to center/bottom-align unexpectedly.

### 2. Root-view content layout (HomeView, TripListView) — floating overlay pattern

This is a *different* problem: making the toolbar/header immune to content
size changes, and centering/positioning the main content independently of
the toolbar. The constraints from case 1 do **not** apply here —
`GeometryReader` is the correct tool for this case.

**Pattern**: in the root `ZStack`, give the toolbar/header its own
top-anchored layer, and let the main content float as a separate sibling
layer sized against the full screen:

```swift
ZStack {
    Color.appBackground.ignoresSafeArea()

    // Toolbar/header — own layer, top-anchored, unaffected by content
    VStack(spacing: 0) {
        toolbar
            .padding(.horizontal, 16)
            .padding(.top, 8)
        Spacer()
    }

    // Main content — floats, sized against the full screen
    mainContent
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // or .top
}
```

- **HomeView**: `mainContent` is the circle, with `alignment: .center` — it
  centers on the whole screen regardless of toolbar height.
- **TripListView**: `mainContent` is the trip list, with `alignment: .top`,
  padded down by the header's measured height (see below) so it sits flush
  below the header without overlapping.

#### Measuring header height (`HeaderHeightKey`)

When floating content needs to start *below* a header of variable height,
measure the header with a `PreferenceKey` and pad the floating content by
that amount:

```swift
private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// In the header's layer:
header
    .background(
        GeometryReader { geo in
            Color.clear.preference(key: HeaderHeightKey.self, value: geo.size.height)
        }
    )
    .onPreferenceChange(HeaderHeightKey.self) { headerHeight = $0 }

// Floating content:
tripList
    .padding(.top, (headerHeight > 0 ? headerHeight : 140) + 14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
```

- The `140` fallback is the estimated header height before the first
  measurement arrives (avoids a visible jump on first frame).
- The `+ 14` is a small buffer so the list doesn't visually crowd the last
  line of the header (e.g. the countdown text in TripListView) — tuned by
  eye against the legacy PWA's row spacing.

#### Row count / overflow (TripListView)

Don't hard-cap the row count to avoid clipping. Instead:

- Use a denser estimate height for the row-count calculation
  (`rowCountEstimateHeight`, e.g. 36pt) than the height used for drag-gesture
  math (`rowHeight`, 44pt) — these serve different purposes and don't need to
  match.
- Let the list `.fixedSize(horizontal: false, vertical: true)` so it renders
  its natural height, even if that means the last row overflows/clips at the
  screen edge. This consistently produces ~17 visible rows (matching the
  legacy PWA), vs. the previous row-count-cap approach which produced only
  13–14.

---

## What NOT to do (superseded approaches)

- **Don't** use `.safeAreaInset(edge: .top)` to pin the toolbar on
  HomeView/TripListView. It was tried in an earlier session and abandoned —
  it fights with the floating-overlay pattern above and produced incorrect
  row counts and centering.
- **Don't** center the circle/content using `VStack { Spacer(); content;
  Spacer() }` nested inside the toolbar's VStack — toolbar height affects the
  Spacer distribution, so centering is off by the toolbar's height. Use the
  floating-overlay `.frame(maxWidth: .infinity, maxHeight: .infinity,
  alignment: .center)` pattern instead.
- **Don't** hard-cap TripListView's row count to "whatever fits without
  clipping." Let it overflow slightly (see above).
