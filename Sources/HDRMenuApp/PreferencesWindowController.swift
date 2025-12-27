import AppKit

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    private let intervalField = NSTextField(string: "")
    private let infoLabel = NSTextField(labelWithString: "Polling interval (seconds):")
    private let debugTextView = NSTextView()
    private var debugScrollView: NSScrollView!

    init() {
        let contentRect = NSRect(x: 0, y: 0, width: 480, height: 360)
        let window = NSWindow(contentRect: contentRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "HDR Enabler Settings"
        window.minSize = NSSize(width: 360, height: 220)
        super.init(window: window)
        window.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(handleLogNotification(_:)), name: .HDREnableLogAppended, object: nil)
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
        let revertButton = NSButton(title: "Revert", target: self, action: #selector(revert(_:)))
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        revertButton.translatesAutoresizingMaskIntoConstraints = false

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
        debugTextView.string = "No debug info yet."
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
        content.addSubview(debugScrollView)

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

            // debugScrollView: below intervalField, fill remaining space
            debugScrollView.topAnchor.constraint(equalTo: intervalField.bottomAnchor, constant: 12),
            debugScrollView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            debugScrollView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            debugScrollView.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)
        ])
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

    deinit {
        NotificationCenter.default.removeObserver(self, name: .HDREnableLogAppended, object: nil)
    }

    @objc private func handleLogNotification(_ note: Notification) {
        guard let line = note.object as? String else { return }
        DispatchQueue.main.async {
            let prev = self.debugTextView.string
            let combined = prev + "\n" + line
            self.debugTextView.string = combined
            // ensure layout updated then scroll to end so text is visible
            self.debugTextView.layoutSubtreeIfNeeded()
            let length = (self.debugTextView.string as NSString).length
            if length > 0 {
                self.debugTextView.scrollRangeToVisible(NSRange(location: length - 1, length: 1))
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        // Save polling interval on close
        if let val = Double(intervalField.stringValue), val > 0 {
            UserDefaults.standard.set(val, forKey: "pollingInterval")
            NotificationCenter.default.post(name: .pollingIntervalChanged, object: nil)
        }
        NSApp.setActivationPolicy(.accessory)
    }



    private func loadDebugInfo() {
        var lines = [String]()
        let recent = Logger.shared.recentLines(limit: 200)
        if !recent.isEmpty {
            lines.append("")
            lines.append(contentsOf: recent)
        }

        DispatchQueue.main.async {
            self.debugTextView.string = lines.joined(separator: "\n")
            // ensure layout updated then scroll to end so text is visible
            self.debugTextView.layoutSubtreeIfNeeded()
            let length = (self.debugTextView.string as NSString).length
            if length > 0 {
                self.debugTextView.scrollRangeToVisible(NSRange(location: length - 1, length: 1))
            }
        }
    }
}

extension Notification.Name {
    static let pollingIntervalChanged = Notification.Name("PollingIntervalChanged")
}
