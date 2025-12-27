import Foundation
import CoreGraphics
import DisplayPlaceLib

class DisplayManager {
    private let savedProfilePath: String = FileManager.default.currentDirectoryPath + "/.hdrenable_saved_profile.json"

    // Save the current profile (current modes per display) to disk for rollback
    func saveCurrentProfile() -> [String]? {
        guard DisplayPlacer.isInstalled(), let out = DisplayPlacer.listOutput() else { return nil }
        let displays = DisplayPlaceLib.parseList(out)
        var specs = [String]()
        for dsp in displays {
            if let cur = dsp.modes.first(where: { $0.isCurrent }) {
                let spec = "id:\(dsp.persistentId) " + cur.raw
                specs.append(spec)
            }
        }
        if specs.isEmpty { return nil }
        if let data = try? JSONEncoder().encode(specs) {
            try? data.write(to: URL(fileURLWithPath: savedProfilePath))
        }
        return specs
    }

    // Apply a saved profile (array of mode spec strings)
    func applyProfile(_ specs: [String]) -> Bool {
        guard DisplayPlacer.isInstalled() else { return false }
        let res = DisplayPlacer.run(args: specs)
        Logger.shared.log("applyProfile result: \(res.success) output:\n\(res.output)")
        return res.success
    }

    func revertToSavedProfile() -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: savedProfilePath)), let specs = try? JSONDecoder().decode([String].self, from: data) else {
            Logger.shared.log("no saved profile to revert")
            return false
        }
        return applyProfile(specs)
    }

    // Attempt to detect HDR state using SkyLight when available, else displayplacer/CG heuristics
    func isHDREnabled() -> Bool {
        Logger.shared.log("isHDREnabled: starting check")

        if SkyLightHDR.shared.available {
            Logger.shared.log("isHDREnabled: using SkyLight APIs")
            var onlineCount: UInt32 = 0
            var displays = [CGDirectDisplayID](repeating: 0, count: 16)
            let err = CGGetOnlineDisplayList(UInt32(displays.count), &displays, &onlineCount)
            if err == .success {
                for i in 0..<Int(onlineCount) {
                    let did = displays[i]
                    // skip builtin when multiple displays
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

        if DisplayPlacer.isInstalled(), let out = DisplayPlacer.listOutput() {
            Logger.shared.log("isHDREnabled: displayplacer output length \(out.count)")
            // parse and log summary
            let displays = DisplayPlaceLib.parseList(out)
            for dsp in displays {
                var mdesc = ""
                for m in dsp.modes {
                    mdesc += "[cur:\(m.isCurrent) cd:\(m.colorDepth.map({String($0)}) ?? "-") res:\(m.width.map({String($0)}) ?? "-")x\(m.height.map({String($0)}) ?? "-") hz:\(m.refreshHz.map({String($0)}) ?? "-") scale:\(m.scaling ?? "-")] "
                }
                Logger.shared.log("isHDREnabled: parsed display \(dsp.persistentId) modes: \(mdesc)")
            }

            // crude heuristic: if any listed current mode contains color_depth:30
            let lines = out.split(separator: "\n")
            for ln in lines {
                let s = ln.lowercased()
                if s.contains("color_depth:30") && (s.contains("current") || s.contains("*")) {
                    Logger.shared.log("isHDREnabled: detected color_depth:30 on current mode")
                    return true
                }
            }
            // fallback: if any display block contains color_depth:30, assume possible but not current
            for ln in lines {
                if ln.lowercased().contains("color_depth:30") {
                    Logger.shared.log("isHDREnabled: found HDR-capable mode but not current")
                    return false
                }
            }
        }

        // Fallback: check CGDisplay current mode encoding for wide formats
        var activeCount: UInt32 = 0
        var cgDisplays = [CGDirectDisplayID](repeating: 0, count: 8)
        let err = CGGetActiveDisplayList(UInt32(cgDisplays.count), &cgDisplays, &activeCount)
        if err == .success {
            for i in 0..<Int(activeCount) {
                let did = cgDisplays[i]
                if let mode = CGDisplayCopyDisplayMode(did) {
                    if let encCF = mode.pixelEncoding {
                        let enc = encCF as String
                        if enc.contains("BGRA") || enc.contains("RGBA") {
                            // not a reliable HDR check but a heuristic
                        }
                    }
                }
            }
        }
        Logger.shared.log("isHDREnabled: falling back to CGDisplay heuristics, returning false")
        return false
    }

    // Use SkyLight private API (SLSDisplay*) to enable HDR on external displays.
    // Returns true if at least one display was enabled by this call.
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
            // Skip internal builtin display when multiple displays are present
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
