# VaultDex

VaultDex is a native SwiftUI iOS trading-card collection app for collectors, families and safe friend-to-friend trading.

The app uses Supabase for authentication and cloud data, Pokémon TCG API data for card search, GBP value formatting, and polished empty states when a collector has not added content yet.

## Supabase Setup

1. In Supabase, open SQL Editor.
2. Run `VaultDex/Resources/Supabase/schema.sql`.
3. Run `VaultDex/Resources/Supabase/policies.sql`.
4. Optionally run `VaultDex/Resources/Supabase/seed.sql`; it intentionally inserts no demo user data.
5. In Authentication > Providers, enable Email.
6. Build and run VaultDex.
7. Open the Account tab and use Sign Up or Sign In.

## Local Development Config

Local development currently uses the publishable Supabase config in `VaultDex/Services/Supabase/SupabaseConfig.swift`. This is a publishable client key, not a service-role key. Never add a service-role key to the iOS app.

Before production, move the URL and publishable key into build configuration or another release-managed configuration path.

If cloud loading fails after sign-in, the app should use user-specific local cache where available and show friendly retry messaging when user action is needed.

## If “No Such Module Supabase” Appears

If Xcode shows `No such module Supabase`, do this manually:

1. Open `VaultDex.xcodeproj` in Xcode.
2. Select File > Add Package Dependencies.
3. Enter `https://github.com/supabase/supabase-swift`.
4. Choose the latest stable version.
5. Add the `Supabase` package product to the `VaultDex` app target.
6. Clean Build Folder with Shift-Command-K.
7. Build again.

Do not add a service-role key. Use only the publishable key in the app.

## TestFlight Checklist

- Confirm the app launches to the VaultDex auth screen when signed out.
- Confirm no debug, demo, Supabase, config or raw network text is visible in normal screens.
- Confirm the generated launch screen and app icon placeholder appear on device/simulator.
- Confirm sign-up creates or loads a profile row.
- Confirm sign-in restores the user profile.
- Confirm profile edits persist after force quit and relaunch.
- Confirm card search loads real Pokémon TCG API results and images.
- Confirm card values are displayed in GBP with estimate wording.
- Confirm adding a card saves to My Vault.
- Confirm adding a card saves to Wants.
- Confirm friend search/request flows use Supabase users only.
- Confirm trade creation, sent/received trades and status updates reload after restart.
- Confirm marketplace listings show only live active listings.
- Confirm logout returns to the auth screen and hides all tabs.
- Confirm friendly loading, empty, error and retry states appear when network requests fail.

## Manual QA Checklist

1. Sign up with a new email.
2. Complete profile setup.
3. Log out.
4. Sign in again.
5. Edit profile and restart the app.
6. Search cards by name, set, number, rarity and type.
7. Open a card detail screen and verify the image/value metadata.
8. Add a card to My Vault.
9. Edit quantity, condition, variant, notes and visibility.
10. Add a card to Wants and edit priority/max value/notes.
11. Search for a user and send a friend request.
12. Accept or reject a friend request from the receiving account.
13. Create a trade offer with collection items and optional internal credits.
14. Accept, reject, cancel and complete trade offers.
15. List a marketplace card and view it from another account.
16. Report a listing/user placeholder and confirm no open chat is exposed.
17. Upload an avatar and owned card photos.
18. Confirm all user-facing errors are friendly.

## Privacy Policy Placeholder

A production privacy policy should be published before external testing. A draft placeholder is tracked in `PRIVACY_POLICY.md`.

## Independent App Disclaimer

VaultDex is independent and not affiliated with The Pokémon Company, Nintendo, Creatures Inc. or GAME FREAK.
