import SwiftUI

@MainActor
@Observable
final class AuthViewModel {
    enum Mode { case signIn, signUp }

    var mode: Mode = .signIn
    var fullName = ""
    var email = ""
    var password = ""
    var role: Role = .employee
    var organizationName = ""
    var inviteCode = ""

    var isLoading = false
    var errorMessage: String?

    var canSubmit: Bool {
        guard email.contains("@"), password.count >= 4 else { return false }
        switch mode {
        case .signIn:
            return true
        case .signUp:
            guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
            if role.isManager { return !organizationName.trimmingCharacters(in: .whitespaces).isEmpty }
            return !inviteCode.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    func toggleMode() {
        withAnimation(Theme.Motion.spring) {
            mode = (mode == .signIn) ? .signUp : .signIn
            errorMessage = nil
        }
    }

    func prefillDemo(manager: Bool) {
        email = manager ? SampleData.employerEmail : SampleData.employeeEmail
        password = SampleData.demoPassword
        mode = .signIn
        Haptics.selection()
    }

    func submit(using session: SessionStore) async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            switch mode {
            case .signIn:
                try await session.signIn(email: email, password: password)
            case .signUp:
                let payload = SignUpPayload(
                    fullName: fullName, email: email, password: password, role: role,
                    organizationName: role.isManager ? organizationName : nil,
                    inviteCode: role.isManager ? nil : inviteCode
                )
                try await session.signUp(payload)
            }
        } catch {
            errorMessage = AppError.from(error).errorDescription
            Haptics.error()
        }
    }
}
