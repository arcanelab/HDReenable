import AppKit

class StatusBarController: NSObject, PollerDelegate, NSMenuDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var preferencesWindow: PreferencesWindowController?
    private var hdrState: Bool? = nil

    override init() {
        super.init()
        constructMenu()
        // initial status
        DispatchQueue.global(qos: .background).async {
            let dm = DisplayManager()
            let s = dm.isHDREnabled()
            DispatchQueue.main.async {
                self.hdrState = s
                self.updateHDRMenu()
            }
        }
    }

    private func constructMenu() {
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "sun.max", accessibilityDescription: "HDR")
                button.image?.isTemplate = true
            } else {
                button.title = "HDR"
            }
        }

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        let hdrItem = NSMenuItem(title: "HDR: Unknown", action: nil, keyEquivalent: "")
        hdrItem.tag = 100
        hdrItem.isEnabled = false
        menu.addItem(hdrItem)
        menu.addItem(NSMenuItem.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openPreferences(_:)), keyEquivalent: ",")
        settings.target = self
        settings.isEnabled = true
        menu.addItem(settings)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit HDR Enabler", action: #selector(quit(_:)), keyEquivalent: "q")
        quitItem.target = self
        quitItem.isEnabled = true
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func openPreferences(_ sender: Any?) {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController()
        }
        // Ensure the app can receive focus and the window is focusable by temporarily switching
        // to regular activation policy (adds a Dock icon) while preferences are open.
        NSApp.setActivationPolicy(.regular)
        preferencesWindow?.window?.delegate = preferencesWindow
        preferencesWindow?.showWindow(nil)
        preferencesWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func updateHDRMenu() {
        guard let menu = statusItem.menu, let hdrItem = menu.item(withTag: 100) else { return }
        let title: String
        if let s = hdrState {
            title = "HDR: " + (s ? "On" : "Off")
        } else {
            title = "HDR: Unknown"
        }
        hdrItem.title = title
    }

    // MARK: - NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        guard let hdrItem = menu.item(withTag: 100) else { return }
        hdrItem.title = "HDR: Checking..."
        DispatchQueue.global(qos: .background).async {
            let dm = DisplayManager()
            let s = dm.isHDREnabled()
            DispatchQueue.main.async {
                self.hdrState = s
                self.updateHDRMenu()
            }
        }
    }

    // MARK: - PollerDelegate
    func pollerDidTick(hdrEnabled: Bool) {
        // Poller provided the HDR state to avoid duplicate checks
        self.hdrState = hdrEnabled
        self.updateHDRMenu()
    }
}
