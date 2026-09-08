<div align="center">

# Vista

**A little distance. A clearer day.**

A quiet, native eye-break companion for your Mac.

[Download for macOS](https://github.com/sauren-khosla/vista/releases/download/v0.1.0/Vista-0.1.0-universal.dmg) · [Website](https://sauren-khosla.github.io/vista/) · [Report an issue](https://github.com/sauren-khosla/vista/issues)

![A sunlit landscape of hills, a lake, and an open sky](site/assets/social.jpg)

macOS 14+ · Apple silicon & Intel · Free & open source

</div>

Vista lives in a tiny floating dot on your desktop. Every 20 minutes, it expands into a gentle reminder to look into the distance. Start a 20-second break, listen for a soft chime, and return to what you were doing.

No accounts. No analytics. No subscription. Just a little room for your eyes.

## Install

1. [Download Vista for macOS](https://github.com/sauren-khosla/vista/releases/download/v0.1.0/Vista-0.1.0-universal.dmg).
2. Open the `.dmg` and drag **Vista** onto **Applications**.
3. Eject the disk image, then open **Vista** from Applications.
4. To keep it in your Dock, right-click its icon → **Options → Keep in Dock**.

**Version 0.1.0 is an unnotarized preview.** The application is ad-hoc signed, not signed with an Apple Developer ID. macOS may block the first launch. If you choose to trust this release, attempt to open Vista, then go to **System Settings → Privacy & Security → Open Anyway**. See [Apple's first-launch instructions](https://support.apple.com/guide/mac-help/mh40616/mac). No terminal command or global security change is required.

The same disk image supports Apple silicon and Intel Macs. Release assets include [SHA-256 checksums](https://github.com/sauren-khosla/vista/releases/download/v0.1.0/SHA256SUMS.txt). To verify a downloaded image, place the checksum file beside it and run `shasum -a 256 -c SHA256SUMS.txt`.

## Small by design

- **A gentle rhythm.** A 20-second distance break every 20 minutes, with optional 30- or 45-minute intervals.
- **Your corner of the screen.** Drag the collapsed dot anywhere, including another display. Vista remembers its position and keeps expanded cards on-screen.
- **Quiet controls.** Snooze for five minutes, take a break now, pause for an hour, or turn off the chime.
- **At home on your Mac.** Native SwiftUI and AppKit, automatic light/dark appearance, reduced-motion support, a menu-bar shortcut, and an optional login item.
- **Private by default.** No network requests, camera access, gaze tracking, or telemetry. Preferences stay on your Mac.

Click the dot or Dock icon to open the controls. The reminder waits for you to start; it never assumes a completed timer means you actually looked away. The countdown continues while you read or watch a video, even without keyboard/mouse input. Sleep, display sleep, and inactive login sessions suspend it; waking starts a fresh interval. Sound follows your system volume.

## Build from source

Requires macOS 14+ and Xcode with Swift 6.0 or later. The app has no third-party package dependencies.

```sh
git clone https://github.com/sauren-khosla/vista.git
cd vista
./scripts/build.sh
open dist/Vista.app
```

Build a universal binary with `./scripts/build.sh --universal`. Quit a running copy before opening a new build; Vista only runs one instance at a time.

Run the tests:

```sh
CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache" swift test --disable-sandbox
```

Tests cover timer transitions, sleep/wake, countdowns without input, completed and interrupted breaks, saved positions, display resizing, and on-screen expansion. CI runs them on macOS.

## Website

The landing page is static HTML, CSS, and a small amount of JavaScript in [`site/`](site/). Open Sauce Sans is self-hosted. No build step, analytics, remote fonts, or web framework is required.

```sh
python3 -m http.server 4173 --directory site
# Open http://localhost:4173
```

Pushes to `main` deploy the site to GitHub Pages. The direct download links point to versioned GitHub Release attachments and work without JavaScript. When releasing a new version, update `VERSION`, the site links/copy, and this README together.

## Make a release

```sh
./scripts/package.sh
```

This builds both architectures and creates `dist/Vista-0.1.0-universal.dmg` and `dist/SHA256SUMS.txt`. The script installs pinned packaging dependencies into an isolated `.build/packaging` environment. The disk image contains the app, an Applications shortcut, and a custom installer layout.

For a notarized release, first configure your own **Developer ID Application** certificate and a `notarytool` keychain profile, then run:

```sh
SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
NOTARY_PROFILE='your-notary-profile' ./scripts/package.sh
```

The script signs with the hardened runtime, submits the app and disk image to Apple's notary service, and staples the resulting tickets. Never commit certificates, private keys, or credentials. Only remove the preview/first-launch notice after notarization succeeds and is verified.

The **Build release installer** GitHub Actions workflow can also produce an unnotarized universal DMG as a build artifact. Public releases are published deliberately from verified artifacts; builds are not silently shipped to users.

## Contributing

Small, thoughtful improvements are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow. Please use [issues](https://github.com/sauren-khosla/vista/issues) for reproducible bugs and focused suggestions.

## About the reminder

The default follows the [National Eye Institute's 20–20–20 guidance](https://www.nei.nih.gov/eye-health-information/healthy-vision/how-eyes-work/keep-your-eyes-healthy): every 20 minutes, look roughly 20 feet away for 20 seconds. Vista encourages a comfort habit; it does not diagnose, treat, or promise to improve eyesight. Evidence for the exact timing is limited, and persistent discomfort is a reason to speak with an eye-care professional.

## License & credits

Vista's code is [MIT licensed](LICENSE). Open Sauce Sans is by [Alfredo Marco Pradil](https://github.com/marcologous/Open-Sauce-Fonts), distributed under the [SIL Open Font License](site/assets/fonts/OFL.txt). The landscape artwork was provided by Sauren Khosla for Vista; artwork and branding are excluded from the code license. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
