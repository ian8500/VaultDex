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
                VStack(alignment: .leading, spacing: 22) {
                    header
                    onboardingCard
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
        VStack(alignment: .leading, spacing: 14) {
            VaultDexLogo(size: 82)

            Text("Welcome to VaultDex")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text("Your calm place to collect, track wants and trade safely.")
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 18)
    }

    private var onboardingCard: some View {
        VStack(spacing: 12) {
            OnboardingFeatureRow(title: "Build your vault", subtitle: "Save cards, photos and values.", systemImage: "lock.shield.fill", tint: .vdGold)
            OnboardingFeatureRow(title: "Find your next grail", subtitle: "Search live card data.", systemImage: "sparkles", tint: .vdSky)
            OnboardingFeatureRow(title: "Trade with care", subtitle: "Friends, wants and fair offers.", systemImage: "arrow.left.arrow.right.circle.fill", tint: .vdLeaf)
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.76), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.vdGold.opacity(0.18), lineWidth: 1))
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

            VStack(spacing: 12) {
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

            Button {
                Task { await resetPassword() }
            } label: {
                Text("Forgot password?")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdGold)
            }
            .buttonStyle(.plain)
            .disabled(!canResetPassword || authService.isLoading)

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

    private var canResetPassword: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func runAuthAction(_ action: @escaping () async throws -> Void) async {
        do {
            try await action()
            lastMessage = ""
        } catch SupabaseAuthFlowError.emailConfirmationRequired {
            lastMessage = "Account created. Check your email, then sign in."
        } catch {
            lastMessage = "Unable to connect right now. Please try again."
        }
    }

    private func resetPassword() async {
        do {
            try await authService.resetPassword(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            lastMessage = "Password reset email sent. Check your inbox."
        } catch {
            lastMessage = "Unable to send reset email. Please try again."
        }
    }
}

private struct OnboardingFeatureRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.black))
                .foregroundStyle(Color.vdNavy)
                .frame(width: 40, height: 40)
                .background(tint, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
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
