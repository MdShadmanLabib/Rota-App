import Foundation
import LocalAuthentication

/// Face ID / Touch ID gate used to unlock a remembered session.
enum BiometricAuth {
    enum Kind { case faceID, touchID, none }

    static var available: Kind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }

    static var label: String {
        switch available {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "Biometrics"
        }
    }

    static func authenticate(reason: String = "Unlock Rota") async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
