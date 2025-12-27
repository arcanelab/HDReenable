import Foundation
import CoreGraphics

class DisplayManager {
    // Attempt to detect HDR state using displayplacer output (if available)
    func isHDREnabled() -> Bool {
        if DisplayPlacer.isInstalled(), let out = DisplayPlacer.listOutput() {
            // crude heuristic: if any listed current mode contains color_depth:30
            let lines = out.split(separator: "\n")
            for ln in lines {
                let s = ln.lowercased()
                if s.contains("color_depth:30") && (s.contains("current") || s.contains("*")) {
                    return true
                }
            }
            // fallback: if any display block contains color_depth:30, assume possible
            for ln in lines {
                if ln.lowercased().contains("color_depth:30") {
                    return false // not currently enabled
                }
            }
        }

        // Fallback: check CGDisplay current mode encoding for wide formats
        var activeCount: UInt32 = 0
        var displays = [CGDirectDisplayID](repeating: 0, count: 8)
        let err = CGGetActiveDisplayList(UInt32(displays.count), &displays, &activeCount)
        if err == .success {
            for i in 0..<Int(activeCount) {
                let did = displays[i]
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
        return false
    }

    func tryEnableHDR() -> Bool {
        guard DisplayPlacer.isInstalled(), let out = DisplayPlacer.listOutput() else {
            log("displayplacer not installed; cannot switch modes automatically")
            return false
        }

        // Parse displayplacer output to find a mode line that contains color_depth:30
        // Each block starts with 'Persistent screen id: <id>' followed by mode lines.
        let lines = out.split(separator: "\n", omittingEmptySubsequences: false)
        var currentId: String? = nil
        var candidateMode: String? = nil

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("persistent screen id:") {
                // pull id
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count > 1 { currentId = parts[1].trimmingCharacters(in: .whitespaces) }
                continue
            }
            if line.contains("color_depth:30") {
                // it's a candidate. Use this entire mode line as argument
                if let id = currentId {
                    // build a single-mode setting string: <mode>
                    candidateMode = "id:\(id) " + line
                    break
                }
            }
        }

        guard let modeSpec = candidateMode else {
            log("no HDR-capable mode found in displayplacer list")
            return false
        }

        // Run displayplacer with the mode specification. It expects a single quoted argument.
        // We'll use shell to pass the argument safely.
        let res = DisplayPlacer.run(args: [modeSpec])
        log("displayplacer run result: \(res.success) output:\n\(res.output)")
        return res.success
    }

    private func log(_ s: String) {
        let p = FileManager.default.currentDirectoryPath + "/hdrenable.log"
        if let dat = (s + "\n").data(using: .utf8) {
            if FileManager.default.fileExists(atPath: p) {
                if let fh = try? FileHandle(forWritingTo: URL(fileURLWithPath: p)) {
                    fh.seekToEndOfFile()
                    fh.write(dat)
                    fh.closeFile()
                }
            } else {
                try? dat.write(to: URL(fileURLWithPath: p))
            }
        }
    }
}
