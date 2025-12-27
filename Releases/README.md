HDReenable
===========

A small macOS menu-bar utility that automatically enables HDR mode on external displays using the SkyLight private APIs. Polling rate is configurable.

Build
-----

```bash
swift build -c release
```

Run
---

To run the bundle:

- GUI: Control‑click `HDReenable.app` → Open → click Open. In System Settings under Privacy & Security find the Security section and allow the app to be run.

- Terminal (one‑time):
	```bash
	xattr -rd com.apple.quarantine /path/to/HDReenable.app
	```
- Admin (add Gatekeeper rule):
	```bash
	sudo spctl --add /path/to/HDReenable.app
	```

Acknowledgements
-------

Thanks to [hoder](https://github.com/kohlschuetter/hoder) for the inspiration.

License
-------
MIT
