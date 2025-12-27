HDR Enabler — menu bar skeleton

This folder contains a minimal Swift AppKit/SwiftUI-bridged skeleton for a macOS menu-bar application that will later poll and enable HDR on an external display.

Files added:
- `Sources/HDRMenuApp/HDRMenuApp.swift` — app entry
- `Sources/HDRMenuApp/AppDelegate.swift` — app delegate bootstrapping status bar and poller
- `Sources/HDRMenuApp/StatusBarController.swift` — status item and menu UI
- `Sources/HDRMenuApp/PreferencesWindowController.swift` — small preferences window to set polling interval
- `Sources/HDRMenuApp/Poller.swift` — polling timer which posts ticks to the delegate

Next steps:
1. Open an Xcode macOS App project and add these source files to it.
2. Run app to verify status item appears and Preferences window works.
3. Implement HDR detection/toggle in the Poller or a separate DisplayManager.
