import Foundation

struct DisplayPlacer {
    static func isInstalled() -> Bool {
        let which = Process()
        which.launchPath = "/usr/bin/which"
        which.arguments = ["displayplacer"]
        let pipe = Pipe()
        which.standardOutput = pipe
        do {
            try which.run()
            which.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return data.count > 0
        } catch {
            return false
        }
    }

    static func run(args: [String]) -> (success: Bool, output: String) {
        let p = Process()
        p.launchPath = "/usr/bin/env"
        p.arguments = ["displayplacer"] + args
        let out = Pipe()
        let err = Pipe()
        p.standardOutput = out
        p.standardError = err
        do {
            try p.run()
            p.waitUntilExit()
            let o = out.fileHandleForReading.readDataToEndOfFile()
            let e = err.fileHandleForReading.readDataToEndOfFile()
            let outStr = String(data: o + e, encoding: .utf8) ?? ""
            return (p.terminationStatus == 0, outStr)
        } catch {
            return (false, "error: \(error)")
        }
    }

    static func listOutput() -> String? {
        let res = run(args: ["list"]) // displayplacer list
        return res.output
    }
}
