import Foundation

public struct DPMode {
    public let raw: String
    public let isCurrent: Bool
    public let colorDepth: Int?
    public let width: Int?
    public let height: Int?
    public let refreshHz: Double?
    public let scaling: String?
}

public struct DPDisplay {
    public let persistentId: String
    public var modes: [DPMode]
}

public enum DisplayPlaceLib {
    // Parse `displayplacer list` output into DPDisplay blocks
    public static func parseList(_ out: String) -> [DPDisplay] {
        var displays = [DPDisplay]()
        var currentId: String? = nil
        var currentModes = [DPMode]()

        let lines = out.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("persistent screen id:") {
                // flush previous
                if let id = currentId {
                    displays.append(DPDisplay(persistentId: id, modes: currentModes))
                }
                currentModes = []
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count > 1 {
                    currentId = parts[1].trimmingCharacters(in: .whitespaces)
                } else {
                    currentId = nil
                }
                continue
            }

            // Mode lines typically contain 'current' or 'color_depth:' tokens
            if line.isEmpty { continue }
            // treat lines starting with 'mode' or with 'color_depth' as mode candidates
            if line.contains("color_depth:") || line.contains("res:") {
                let isCur = line.lowercased().contains("current") || line.contains("*")
                let cd = extractIntToken(from: line, token: "color_depth:")
                let res = extractRes(from: line)
                let hz = extractDoubleToken(from: line, token: "hz:")
                let scaling = extractToken(from: line, token: "scaling:")
                let mode = DPMode(raw: line, isCurrent: isCur, colorDepth: cd, width: res?.0, height: res?.1, refreshHz: hz, scaling: scaling)
                currentModes.append(mode)
            }
        }

        if let id = currentId {
            displays.append(DPDisplay(persistentId: id, modes: currentModes))
        }
        return displays
    }

    // Choose a HDR-capable mode (color_depth:30) for the first display that has one.
    // Strategy: prefer a mode already current with color_depth:30; otherwise pick the mode
    // with matching resolution to current mode when possible, or the first color_depth:30.
    public static func chooseHDRMode(from displays: [DPDisplay]) -> (displayId: String, modeSpec: String)? {
        for dsp in displays {
            // if any current is HDR, nothing to do
            for m in dsp.modes where m.isCurrent && (m.colorDepth == 30) {
                return nil // already HDR
            }
        }

        for dsp in displays {
            // prefer modes with color_depth:30 and same resolution as current
            let current = dsp.modes.first(where: { $0.isCurrent })
            if let cur = current {
                // prefer same resolution + hz + scaling
                if let exact = dsp.modes.first(where: { $0.colorDepth == 30 && $0.width == cur.width && $0.height == cur.height && (cur.refreshHz == nil || $0.refreshHz == cur.refreshHz) && (cur.scaling == nil || $0.scaling == cur.scaling) }) {
                    return (dsp.persistentId, exact.raw)
                }
                // fallback: match resolution only
                if let same = dsp.modes.first(where: { $0.colorDepth == 30 && $0.width == cur.width && $0.height == cur.height }) {
                    return (dsp.persistentId, same.raw)
                }
            }
            // otherwise pick first color_depth:30 mode
            if let firstHDR = dsp.modes.first(where: { $0.colorDepth == 30 }) {
                return (dsp.persistentId, firstHDR.raw)
            }
        }
        return nil
    }

    // Helpers
    private static func extractIntToken(from s: String, token: String) -> Int? {
        guard let r = extractToken(from: s, token: token) else { return nil }
        return Int(r)
    }

    private static func extractDoubleToken(from s: String, token: String) -> Double? {
        guard let r = extractToken(from: s, token: token) else { return nil }
        return Double(r.replacingOccurrences(of: "f", with: ""))
    }

    private static func extractToken(from s: String, token: String) -> String? {
        if let rng = s.range(of: token) {
            let after = s[rng.upperBound...]
            let comps = after.split(whereSeparator: { $0 == " " || $0 == "," })
            if let first = comps.first {
                return String(first).trimmingCharacters(in: .punctuationCharacters)
            }
        }
        return nil
    }

    private static func extractRes(from s: String) -> (Int, Int)? {
        // look for res:WxH or res:W x H
        if let rng = s.range(of: "res:") {
            let after = s[rng.upperBound...]
            let token = String(after).trimmingCharacters(in: .whitespaces)
            // token may start like 3840x2160 or 3840x2160x2 or 3840x2160@2
            let digits = token.split(whereSeparator: { !$0.isNumber && $0 != "x" })
            if let first = digits.first {
                let parts = first.split(separator: "x")
                if parts.count >= 2, let w = Int(parts[0]), let h = Int(parts[1]) {
                    return (w, h)
                }
            }
        }
        return nil
    }
}
