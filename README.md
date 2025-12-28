HDReenable
===========

Description
-----------

HDReenable is a small macOS menu-bar utility that automatically enables HDR mode on external displays using the SkyLight private APIs. Polling rate is configurable.

Motivation
----------

Sometimes when my Mac wakes from sleep, my external monitor reverts to SDR mode. Having to manually re-enable HDR mode in System Settings repeatedly became tedious, so I created a tool to automate this process.

How it works
------------
HDReenable is a menu bar app that runs in the background. It checks your external display and turns on HDR mode if it's off. You can set how often it checks by adjusting the polling rate in the settings.

Build
-----

```bash
swift build -c release
```

Run
---

To run the build from the project directory:

```bash
swift run
```

To run the .app bundle:

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
