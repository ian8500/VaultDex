import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var lastMessage = ""

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    authCard
                }
                .padding(20)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultDexLogo(size: 72)

            Text("Welcome to VaultDex")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(Color.vdTextPrimary)

            Text("Sign in to keep your collection, wants and trades together.")
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
        }
    }

    private var authCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .vaultTextFieldStyle()

            SecureField("Password", text: $password)
                .textContentType(.password)
                .vaultTextFieldStyle()

            HStack(spacing: 12) {
                PrimaryButton(title: "Sign In", systemImage: "person.fill.checkmark") {
                    Task { await runAuthAction { try await authService.signIn(email: email, password: password) } }
                }
                .disabled(!canSubmit || authService.isLoading)

                SecondaryButton(title: "Create Account", systemImage: "person.badge.plus") {
                    Task { await runAuthAction { try await authService.signUp(email: email, password: password) } }
                }
                .disabled(!canSubmit || authService.isLoading)
            }

            if authService.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Color.vdGold)

                    Text("Working on it...")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vdTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !lastMessage.isEmpty {
                Text(lastMessage)
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.vdGold.opacity(0.26), lineWidth: 1))
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    private func runAuthAction(_ action: @escaping () async throws -> Void) async {
        do {
            try await action()
            lastMessage = authService.currentSession() == nil ? "" : "Signed in."
        } catch {
            lastMessage = authService.status.message
        }
    }
}

private extension View {
    func vaultTextFieldStyle() -> some View {
        self
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.vdTextPrimary)
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color.vdPanelRaised.opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vdGold.opacity(0.25), lineWidth: 1))
    }
}
