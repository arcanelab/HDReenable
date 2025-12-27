HDReenable
===========

A small macOS menu-bar utility that automatically enables HDR mode on external displays using the SkyLight private APIs.

Build
-----

From the repository root:

```bash
swift build -c debug
# or for an optimized build
swift build -c release
```

Behavior
--------
- The menu-bar app polls displays and uses SkyLight to detect and enable HDR where supported.
- Preferences include a debug view that shows runtime logs.

Credits & Origin
----------------
- Inspired by the `hoder` SkyLight-based CLI approach — thanks to its author for the working proof-of-concept that informed this project.

License
-------
MIT
