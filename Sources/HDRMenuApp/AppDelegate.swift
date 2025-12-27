import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBar: StatusBarController!
    var poller: Poller!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // start as accessory (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        statusBar = StatusBarController()
        poller = Poller()
        poller.delegate = statusBar
        poller.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        poller.stop()
    }
}
