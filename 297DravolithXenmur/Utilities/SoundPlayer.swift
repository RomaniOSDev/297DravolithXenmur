import AudioToolbox
import Foundation

enum SoundPlayer {
    private static let key = "clarity_soundEnabled"

    static var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: key) == nil { return true }
            return UserDefaults.standard.bool(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    /// App uses system feedback sounds — toggles stay available.
    static var isAvailable: Bool { true }

    static func playSuccess() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }
}
