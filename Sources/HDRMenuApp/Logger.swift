import Foundation

final class Logger {
    static let shared = Logger()

    private let logURL: URL
    private let queue = DispatchQueue(label: "com.hdrenable.logger")

    private init() {
        let fm = FileManager.default
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        logURL = cwd.appendingPathComponent("hdrenable.log")
    }

    func log(_ message: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let lineForFile = "[\(ts)] \(message)\n"
        let lineForNotification = "[\(ts)] \(message)"

        // write to file asynchronously
        queue.async { [weak self] in
            guard let self = self else { return }
            if let data = lineForFile.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.logURL.path) {
                    if let fh = try? FileHandle(forWritingTo: self.logURL) {
                        defer { try? fh.close() }
                        try? fh.seekToEnd()
                        try? fh.write(contentsOf: data)
                    }
                } else {
                    try? data.write(to: self.logURL)
                }
            }

            // post notification on main without trailing newline to avoid double-spacing
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .HDREnableLogAppended, object: lineForNotification)
            }
        }
    }
}

extension Notification.Name {
    static let HDREnableLogAppended = Notification.Name("HDREnableLogAppended")
}
