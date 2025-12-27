import AppKit

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    private let intervalField = NSTextField(string: "")
    private let infoLabel = NSTextField(labelWithString: "Polling interval (seconds):")
    private let debugTextView = NSTextView()
    private var debugScrollView: NSScrollView!
    private let refreshButton = NSButton(title: "Refresh Debug Info", target: nil, action: #selector(refreshDebug(_:)))

    init() {
        let contentRect = NSRect(x: 0, y: 0, width: 480, height: 360)
        let window = NSWindow(contentRect: contentRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "HDR Enabler Settings"
        window.minSize = NSSize(width: 360, height: 220)
        super.init(window: window)
        window.delegate = self
        setupUI()
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    private func setupUI() {
        guard let content = window?.contentView else { return }

        // Prepare views for Auto Layout
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        intervalField.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        debugScrollView = NSScrollView()
        debugScrollView.translatesAutoresizingMaskIntoConstraints = false
        let saveButton = NSButton(title: "Save", target: self, action: #selector(save(_:)))
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        // Configure fields
        intervalField.isEditable = true
        intervalField.isBezeled = true
        intervalField.isSelectable = true
        intervalField.focusRingType = .default
        intervalField.isEnabled = true
        let saved = UserDefaults.standard.double(forKey: "pollingInterval")
        intervalField.stringValue = String(saved > 0 ? saved : 30)

        // Configure debug text view and scroll view
        debugTextView.isEditable = false
        debugTextView.isSelectable = true
        debugTextView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        debugTextView.string = "No debug info yet. Click Refresh."
        // Make the text view resizable inside the scroll view so content is visible
        debugTextView.isVerticallyResizable = true
        debugTextView.isHorizontallyResizable = false
        debugTextView.autoresizingMask = [.width]
        debugTextView.minSize = NSSize(width: 0, height: 0)
        debugTextView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        debugTextView.textContainer?.widthTracksTextView = true
        debugScrollView.hasVerticalScroller = true
        debugScrollView.borderType = .bezelBorder
        debugScrollView.documentView = debugTextView

        // Add to content view
        content.addSubview(infoLabel)
        content.addSubview(intervalField)
        content.addSubview(refreshButton)
        content.addSubview(saveButton)
        content.addSubview(debugScrollView)

        refreshButton.target = self

        // Layout constraints
        NSLayoutConstraint.activate([
            // infoLabel: top, leading, trailing
            infoLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            infoLabel.heightAnchor.constraint(equalToConstant: 20),

            // intervalField: below infoLabel
            intervalField.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 8),
            intervalField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            intervalField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            intervalField.heightAnchor.constraint(equalToConstant: 24),

            // refreshButton: below intervalField, leading
            refreshButton.topAnchor.constraint(equalTo: intervalField.bottomAnchor, constant: 12),
            refreshButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            refreshButton.heightAnchor.constraint(equalToConstant: 28),

            // saveButton: aligned to refreshButton top, trailing
            saveButton.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor),
            saveButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 80),
            saveButton.heightAnchor.constraint(equalToConstant: 30),

            // debugScrollView: below buttons, fill remaining space
            debugScrollView.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 12),
            debugScrollView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            debugScrollView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            debugScrollView.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)
        ])
    }

    @objc private func save(_ sender: Any?) {
        if let val = Double(intervalField.stringValue), val > 0 {
            UserDefaults.standard.set(val, forKey: "pollingInterval")
            NotificationCenter.default.post(name: .pollingIntervalChanged, object: nil)
        }
        window?.close()
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        loadDebugInfo()
        if let win = self.window {
            win.center()
            win.makeKeyAndOrderFront(nil)
            win.makeFirstResponder(intervalField)
            intervalField.selectText(nil)
        }
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    @objc private func refreshDebug(_ sender: Any?) {
        loadDebugInfo()
    }

    private func loadDebugInfo() {
        var lines = [String]()
        let dm = DisplayManager()
        let hdrOn = dm.isHDREnabled()
        lines.append("HDR enabled: \(hdrOn)")
        lines.append("")
        if DisplayPlacer.isInstalled() {
            if let out = DisplayPlacer.listOutput() {
                lines.append("displayplacer output:")
                lines.append(out)
            } else {
                lines.append("displayplacer installed but returned no output")
            }
        } else {
            lines.append("displayplacer not installed (install via Homebrew: brew install jakehilborn/tap/displayplacer)")
        }

        DispatchQueue.main.async {
            self.debugTextView.string = lines.joined(separator: "\n")
        }
    }
}

extension Notification.Name {
    static let pollingIntervalChanged = Notification.Name("PollingIntervalChanged")
}
