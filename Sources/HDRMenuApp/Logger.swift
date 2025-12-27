import Foundation

final class Logger {
    static let shared = Logger()
    private let queue = DispatchQueue(label: "com.hdrenable.logger")
    private var buffer: [String] = []
    private let maxLines = 2000

    private init() {
    }

    func log(_ message: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "[\(ts)] \(message)"

        queue.async { [weak self] in
            guard let self = self else { return }
            // append to in-memory buffer
            self.buffer.append(line)
            if self.buffer.count > self.maxLines {
                self.buffer.removeFirst(self.buffer.count - self.maxLines)
            }

            // post notification on main
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .HDREnableLogAppended, object: line)
            }
        }
    }

    // Return a snapshot of recent lines
    func recentLines(limit: Int = 200) -> [String] {
        var copy: [String] = []
        queue.sync {
            copy = Array(self.buffer.suffix(limit))
        }
        return copy
    }
}

extension Notification.Name {
    static let HDREnableLogAppended = Notification.Name("HDREnableLogAppended")
}
