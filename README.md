# VaultDex

VaultDex is a native SwiftUI iOS trading-card collection app. Cloud mode is the default, with local fallback mode still available for development and offline testing.

## Current Supabase Values

The app is configured directly in `VaultDex/Services/Supabase/SupabaseConfig.swift` with the provided publishable client values:

- URL: `https://serqknmuacwbdgdrwkrp.supabase.co`
- Publishable key: `sb_publishable_3ZCT0O7LEOOsErhHTHu3wA_4TEA9DRS`

This is a publishable key, not a service-role key. Never add a service-role key to the iOS app.

## Supabase Setup

1. In Supabase, open SQL Editor.
2. Run `VaultDex/Resources/Supabase/schema.sql`.
3. Run `VaultDex/Resources/Supabase/policies.sql`.
4. Optionally run `VaultDex/Resources/Supabase/seed.sql`; it intentionally inserts no demo user data.
5. In Authentication > Providers, enable Email.
6. Build and run VaultDex.
7. Open the Account tab and use Sign Up or Sign In.

## Local Development Config

Local development uses the hardcoded publishable Supabase config in `VaultDex/Services/Supabase/SupabaseConfig.swift`. It does not require Xcode environment variables, `.env` files, `Secrets.plist`, or custom `Info.plist` keys.

Move the publishable key and URL into secure build configuration before production.

If Supabase is unavailable, missing, or errors, the app falls back to an empty local state with polished onboarding empty states.

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

## App Status Labels

- `Demo Mode`: Local/offline fallback mode is active.
- `Cloud Ready`: Supabase URL/key are configured and the app is ready for sign in.
- `Cloud Sync Active`: Email auth succeeded and a session exists.
- `Supabase Setup Needed`: Supabase URL or publishable key is missing.
- `Supabase Error`: A real Supabase client/auth failure occurred.
