import Foundation

protocol PollerDelegate: AnyObject {
    func pollerDidTick()
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
            self.timer = Timer.scheduledTimer(timeInterval: self.interval, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
            RunLoop.main.add(self.timer!, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func tick() {
        delegate?.pollerDidTick()
        // on each tick, check HDR and enable if needed
        DispatchQueue.global(qos: .utility).async {
            let enabled = self.displayManager.isHDREnabled()
            if !enabled {
                _ = self.displayManager.tryEnableHDR()
            }
        }
    }

    @objc private func handleIntervalChanged() {
        start()
    }
}
