import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var lastMessage = "Cloud mode is ready. Sign in to load your vault."
    @State private var showProfile = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    dataModeCard
                    authCard
                    sessionCard
                    NavigationLink("Open Collector Profile", destination: SocialProfileView())
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.vdGold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                }
                .padding(20)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(authService.status.title, systemImage: authService.status.systemImage)
                .font(.caption.weight(.black))
                .foregroundStyle(Color.vdNavy)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(statusTint, in: Capsule())

            Text("VaultDex Sign In")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(Color.vdTextPrimary)

            Text("Sign in to sync your profile, cards, collection, wants, friends, trades, and listings from Supabase. Local fallback mode remains available in Settings.")
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

                SecondaryButton(title: "Sign Up", systemImage: "person.badge.plus") {
                    Task { await runAuthAction { try await authService.signUp(email: email, password: password) } }
                }
                .disabled(!canSubmit || authService.isLoading)
            }

            SecondaryButton(title: "Sign Out", systemImage: "rectangle.portrait.and.arrow.right") {
                Task { await runAuthAction { try await authService.signOut() } }
            }
            .disabled(authService.isLoading)

            Text(lastMessage)
                .font(.caption)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.vdGold.opacity(0.26), lineWidth: 1))
    }

    private var dataModeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: Binding(
                get: { authService.isDemoModeEnabled },
                set: { authService.setDemoModeEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Demo Mode")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)
                    Text(authService.isDemoModeEnabled ? "Local fallback mode is active." : "Cloud mode is active. Sign in to sync.")
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                }
            }
            .tint(Color.vdGold)
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.vdGold.opacity(0.22), lineWidth: 1))
    }

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            VaultSectionHeader(title: "Supabase Setup", subtitle: authService.status.message)

            if let session = authService.currentSession() {
                Label(session.email ?? session.userID.uuidString, systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdLeaf)

                Text("User ID: \(session.userID.uuidString)")
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
                    .textSelection(.enabled)
            } else {
                EmptyStateView(
                    systemImage: "person.crop.circle.badge.questionmark",
                    title: "Ready for sign in",
                    message: "Supabase config is present. Sign in or sign up to start cloud sync."
                )
            }

            debugPanel
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 22))
    }

    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Debug")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.vdGold)
            SettingsDebugRow(title: "demoMode", value: authService.debugDemoModeValue)
            SettingsDebugRow(title: "URL configured", value: authService.isSupabaseURLConfigured ? "true" : "false")
            SettingsDebugRow(title: "key configured", value: authService.isSupabaseKeyConfigured ? "true" : "false")
            SettingsDebugRow(title: "isConfigured", value: authService.debugIsConfiguredValue)
        }
        .padding(12)
        .background(Color.vdPanelRaised.opacity(0.74), in: RoundedRectangle(cornerRadius: 12))
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    private var statusTint: Color {
        switch authService.status {
        case .demoMode: .vdSky
        case .cloudReady: .vdGold
        case .cloudSignedIn: .vdLeaf
        case .supabaseConfigMissing: .vdGold
        case .supabaseError: .vdCoral
        }
    }

    private func runAuthAction(_ action: @escaping () async throws -> Void) async {
        do {
            try await action()
            lastMessage = authService.status.message
        } catch {
            lastMessage = error.localizedDescription
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
