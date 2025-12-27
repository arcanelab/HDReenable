import Foundation

protocol PollerDelegate: AnyObject {
    func pollerDidTick(hdrEnabled: Bool)
}

class Poller {
    weak var delegate: PollerDelegate?
    private var timer: Timer?
    private let displayManager = DisplayManager()

    private var interval: TimeInterval {
        let v = UserDefaults.standard.double(forKey: "pollingInterval")
        return v > 0 ? v : 30
    }

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleIntervalChanged), name: .pollingIntervalChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stop()
    }

    func start() {
        stop()
        DispatchQueue.main.async {
            // Create a timer and add it to the main run loop in common modes.
            // Use Timer(timeInterval:) + RunLoop.add to avoid double-scheduling the same timer.
            self.timer = Timer(timeInterval: self.interval, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
            if let t = self.timer {
                RunLoop.main.add(t, forMode: .common)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func tick() {
        // on each tick, check HDR once, try enable if needed, then notify delegate with result
        DispatchQueue.global(qos: .utility).async {
            let enabled = self.displayManager.isHDREnabled()
            if !enabled {
                _ = self.displayManager.tryEnableHDR()
            }
            DispatchQueue.main.async {
                self.delegate?.pollerDidTick(hdrEnabled: enabled)
            }
        }
    }

    @objc private func handleIntervalChanged() {
        start()
    }
}
