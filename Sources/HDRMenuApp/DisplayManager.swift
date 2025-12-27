import Foundation
import CoreGraphics

class DisplayManager {
    // Save/apply/revert profile helpers are intentionally stubbed
    // because we removed displayplacer-based mode management.

    func saveCurrentProfile() -> [String]? {
        Logger.shared.log("saveCurrentProfile: unsupported (DisplayPlaceLib removed)")
        return nil
    }

    func applyProfile(_ specs: [String]) -> Bool {
        Logger.shared.log("applyProfile: unsupported (DisplayPlaceLib removed)")
        return false
    }

    func revertToSavedProfile() -> Bool {
        Logger.shared.log("revertToSavedProfile: unsupported (DisplayPlaceLib removed)")
        return false
    }

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
                        Logger.shared.log("isHDREnabled: SkyLight reports HDR enabled on display \(did)")
                        return true
                    }
                }
            }
            Logger.shared.log("isHDREnabled: SkyLight reports no HDR enabled")
            return false
        }

        Logger.shared.log("isHDREnabled: SkyLight not available, falling back to false")
        return false
    }

    // Enable HDR using SkyLight only. Returns true if any display was changed.
    func tryEnableHDR() -> Bool {
        guard SkyLightHDR.shared.available else {
            Logger.shared.log("tryEnableHDR: SkyLight APIs not available; cannot enable HDR")
            return false
        }

        Logger.shared.log("tryEnableHDR: attempting SkyLight path")
        var onlineCount: UInt32 = 0
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        let cgErr = CGGetOnlineDisplayList(UInt32(displays.count), &displays, &onlineCount)
        if cgErr != .success {
            Logger.shared.log("tryEnableHDR: CGGetOnlineDisplayList returned \(cgErr)")
            return false
        }

        Logger.shared.log("tryEnableHDR: online displays=\(onlineCount)")
        var didEnable = false
        for i in 0..<Int(onlineCount) {
            let did = displays[i]
            let isBuiltin = (CGDisplayIsBuiltin(did) != 0)
            Logger.shared.log("tryEnableHDR: display index=\(i) id=\(did) isBuiltin=\(isBuiltin)")

            if isBuiltin && onlineCount > 1 {
                Logger.shared.log("tryEnableHDR: skipping builtin display id=\(did)")
                continue
            }

            if !SkyLightHDR.shared.supportsHDR(display: did) {
                Logger.shared.log("tryEnableHDR: display id=\(did) does not support HDR")
                continue
            }

            if SkyLightHDR.shared.isHDREnabled(display: did) {
                Logger.shared.log("tryEnableHDR: display id=\(did) already HDR enabled")
                continue
            }

            Logger.shared.log("tryEnableHDR: enabling HDR on display id=\(did)")
            let ok = SkyLightHDR.shared.setHDREnabled(true, display: did)
            Logger.shared.log("tryEnableHDR: setHDREnabled result=\(ok) for id=\(did)")
            if ok { didEnable = true }
        }

        if !didEnable {
            Logger.shared.log("tryEnableHDR: no displays were changed by SkyLight path")
        }
        return didEnable
    }
}
