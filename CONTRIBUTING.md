# Contributing to Vista

Vista is intentionally small: a quiet reminder that feels at home on macOS. Changes should preserve that focus.

1. Open an issue before a substantial feature or visual redesign.
2. Fork the repository and create a branch for your change.
3. Build with `./scripts/build.sh` and run `CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache" swift test --disable-sandbox`.
4. For app changes, check the affected flow in both appearances, with Reduced Motion where relevant. Verify that timers keep running, the app doesn't steal keyboard focus, and dragging/expansion remain usable at screen edges.
5. For site changes, serve `site/` locally and check desktop and narrow mobile layouts, keyboard navigation, installation help, and download links.
6. Open a pull request describing the user-visible change and how you checked it.

Keep app preferences local. Don't add telemetry or network access without discussing the need first. Avoid changing reminder defaults without explaining the rationale. Add regression tests for timer and positioning bugs; visual tweaks usually need visual verification instead.

Use GitHub issues for bugs with your macOS version, chip type, steps to reproduce, and expected/actual behavior. Please omit private information from screenshots and logs.
