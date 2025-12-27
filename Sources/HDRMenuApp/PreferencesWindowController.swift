import AppKit

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    private let intervalField = NSTextField(string: "")
    private let infoLabel = NSTextField(labelWithString: "Polling interval (seconds):")
    private let debugTextView = NSTextView()
    private var debugScrollView: NSScrollView!
    private let buildLabel = NSTextField(labelWithString: "")

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
        buildLabel.translatesAutoresizingMaskIntoConstraints = false
        debugScrollView = NSScrollView()
        debugScrollView.translatesAutoresizingMaskIntoConstraints = false
        

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
        content.addSubview(buildLabel)

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

            // debugScrollView: below intervalField, fill remaining space above buildLabel
            debugScrollView.topAnchor.constraint(equalTo: intervalField.bottomAnchor, constant: 12),
            debugScrollView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            debugScrollView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            // buildLabel: below debugScrollView
            buildLabel.topAnchor.constraint(equalTo: debugScrollView.bottomAnchor, constant: 8),
            buildLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            buildLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            buildLabel.heightAnchor.constraint(equalToConstant: 18),
            buildLabel.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),

            // set debugScrollView bottom relative to buildLabel top
            debugScrollView.bottomAnchor.constraint(equalTo: buildLabel.topAnchor, constant: -8)
        ])
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        // update build label and debug info when showing
        buildLabel.stringValue = "Build: \(self.buildNumberString())"
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

    private func buildNumberString() -> String {
        // Try to read the executable modification time as the build time
        var exeURL: URL? = nil
        if let url = Bundle.main.executableURL {
            exeURL = url
        } else {
            exeURL = URL(fileURLWithPath: CommandLine.arguments.first ?? "")
        }

        if let exe = exeURL {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: exe.path), let mod = attrs[.modificationDate] as? Date {
                let df = DateFormatter()
                df.timeZone = TimeZone.current
                df.dateFormat = "yyyy.MM.dd-HH:mm:ss"
                return df.string(from: mod)
            }
        }
        // fallback to now
        let df = DateFormatter()
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy.MM.dd-HH:mm:ss"
        return df.string(from: Date())
    }
}

extension Notification.Name {
    static let pollingIntervalChanged = Notification.Name("PollingIntervalChanged")
}
