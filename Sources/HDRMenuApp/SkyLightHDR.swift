import Foundation
import CoreGraphics

// Dynamic loader for private SkyLight functions. Uses dlsym to avoid linking private frameworks.
final class SkyLightHDR {
    static let shared = SkyLightHDR()

    private typealias SLSSetHDR = @convention(c) (CGDirectDisplayID, Bool, Int32, Int32) -> CGError
    private typealias SLSIsHDR = @convention(c) (CGDirectDisplayID) -> Bool
    private typealias SLSSupportsHDR = @convention(c) (CGDirectDisplayID) -> Bool

    private var handle: UnsafeMutableRawPointer?
    private var setPtr: SLSSetHDR?
    private var isPtr: SLSIsHDR?
    private var supportsPtr: SLSSupportsHDR?

    private init() {
        // Try to open SkyLight private framework
        let paths = [
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
            "/System/Library/Frameworks/SkyLight.framework/SkyLight"
        ]
        for p in paths {
            if let h = dlopen(p, RTLD_NOW) {
                self.handle = h
                break
            }
        }

        if let h = handle {
            if let sym = dlsym(h, "SLSDisplaySetHDRModeEnabled") {
                setPtr = unsafeBitCast(sym, to: SLSSetHDR.self)
            }
            if let sym = dlsym(h, "SLSDisplayIsHDRModeEnabled") {
                isPtr = unsafeBitCast(sym, to: SLSIsHDR.self)
            }
            if let sym = dlsym(h, "SLSDisplaySupportsHDRMode") {
                supportsPtr = unsafeBitCast(sym, to: SLSSupportsHDR.self)
            }
        }
    }

    var available: Bool {
        return setPtr != nil || isPtr != nil || supportsPtr != nil
    }

    func supportsHDR(display: CGDirectDisplayID) -> Bool {
        guard let f = supportsPtr else { return false }
        return f(display)
    }

    func isHDREnabled(display: CGDirectDisplayID) -> Bool {
        guard let f = isPtr else { return false }
        return f(display)
    }

    @discardableResult
    func setHDREnabled(_ enable: Bool, display: CGDirectDisplayID) -> Bool {
        guard let f = setPtr else { return false }
        let err = f(display, enable, 0, 0)
        return err == CGError.success
    }
}

// dlsym import
import Darwin
