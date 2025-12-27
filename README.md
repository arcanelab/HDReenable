HDReenable
===========

A small macOS menu-bar utility that detects and (optionally) enables HDR on external displays using the SkyLight private APIs.

Important
---------
- This project uses private macOS APIs (SkyLight). Using or distributing binaries that call private APIs may break with OS updates and can cause App Store/App Notarization issues. Use at your own risk.
- The project no longer includes displayplacer-based logic — it's a SkyLight-only implementation.

Build
-----

From the repository root:

```bash
swift build -c debug
# or for an optimized build
swift build -c release
```

Run
---

Start the app (background) and log to `hdrenable.log`:

```bash
./.build/debug/HDReenable &> hdrenable.log & echo $! > hdrenable.pid
```

- Logs are written to `hdrenable.log` in the working directory.
- The background process PID is saved to `hdrenable.pid`.

Behavior
--------
- The menu-bar app polls displays and uses SkyLight to detect and enable HDR where supported.
- Preferences include a debug view that shows runtime logs.

Credits & Origin
----------------
- Inspired by the `hoder` SkyLight-based CLI approach — thanks to its author for the working proof-of-concept that informed this project.

Repository Notes
----------------
- The previous `DisplayPlaceLib` parsing utilities were removed (no longer used). If you relied on displayplacer parsing, restore the earlier commit or reintroduce the parsing target.

License
-------
Check the repository for any license files or add one as appropriate before redistribution.
