import Foundation
import CoreGraphics

class DisplayManager {
    // Detect HDR using SkyLight private APIs when available
    func isHDREnabled() -> Bool {
        if SkyLightHDR.shared.available {
            var onlineCount: UInt32 = 0
            var displays = [CGDirectDisplayID](repeating: 0, count: 16)
            let err = CGGetOnlineDisplayList(UInt32(displays.count), &displays, &onlineCount)
            if err == .success {
                for i in 0..<Int(onlineCount) {
                    let did = displays[i]
                    let isBuiltin = (CGDisplayIsBuiltin(did) != 0)
                    if isBuiltin && onlineCount > 1 { continue }
                    if SkyLightHDR.shared.supportsHDR(display: did) && SkyLightHDR.shared.isHDREnabled(display: did) {
                        Logger.shared.log("HDR enabled on display \(did)")
                        return true
                    }
                }
            }
            Logger.shared.log("HDR not enabled on any display")
            return false
        }
        Logger.shared.log("SkyLight not available; HDR unknown")
        return false
    }

    // Enable HDR using SkyLight only. Returns true if any display was changed.
    func tryEnableHDR() -> Bool {
        guard SkyLightHDR.shared.available else {
            Logger.shared.log("tryEnableHDR: SkyLight APIs not available; cannot enable HDR")
            return false
        }

        Logger.shared.log("enabling HDR (SkyLight)")
        var onlineCount: UInt32 = 0
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        let cgErr = CGGetOnlineDisplayList(UInt32(displays.count), &displays, &onlineCount)
        if cgErr != .success {
            Logger.shared.log("tryEnableHDR: CGGetOnlineDisplayList returned \(cgErr)")
            return false
        }

        Logger.shared.log("online displays=\(onlineCount)")
        var didEnable = false
        for i in 0..<Int(onlineCount) {
            let did = displays[i]
            let isBuiltin = (CGDisplayIsBuiltin(did) != 0)
            Logger.shared.log("display index=\(i) id=\(did) isBuiltin=\(isBuiltin)")

            if isBuiltin && onlineCount > 1 {
                Logger.shared.log("skipping builtin display \(did)")
                continue
            }
            if !SkyLightHDR.shared.supportsHDR(display: did) {
                Logger.shared.log("display \(did) does not support HDR")
                continue
            }
            if SkyLightHDR.shared.isHDREnabled(display: did) {
                Logger.shared.log("display \(did) already HDR enabled")
                continue
            }
            Logger.shared.log("enabling HDR on display \(did)")
            let ok = SkyLightHDR.shared.setHDREnabled(true, display: did)
            Logger.shared.log("setHDR result=\(ok) for \(did)")
            if ok { didEnable = true }
        }

        if !didEnable {
            Logger.shared.log("no displays changed")
        }
        return didEnable
    }
}
