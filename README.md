# VaultDex

VaultDex is a native SwiftUI iOS trading-card collection app. The app keeps local demo mode available and only uses Supabase for the first auth/profile connection proof.

## Current Supabase Values

The app is configured with the provided publishable client values:

- `SUPABASE_URL=https://serqknmuacwbdgdrwkrp.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY=sb_publishable_3ZCT0O7LEOOsErhHTHu3wA_4TEA9DRS`

This is a publishable key, not a service-role key. Never add a service-role key to the iOS app.

## Supabase Setup

1. In Supabase, open SQL Editor.
2. Run `VaultDex/Resources/Supabase/schema.sql`.
3. Run `VaultDex/Resources/Supabase/policies.sql`.
4. In Authentication > Providers, enable Email.
5. Build and run VaultDex.
6. Open the Account tab and use Sign Up or Sign In.

Collection, wishlist, trade, binder, and event data intentionally remain in local demo mode for now.

## Xcode Environment Overrides

The app has built-in Supabase publishable values for the first proof step. You can override them in the VaultDex scheme:

- `DEMO_MODE=true` forces local demo mode.
- `DEMO_MODE=false` allows Supabase auth when configured.
- `SUPABASE_URL` overrides the built-in project URL.
- `SUPABASE_PUBLISHABLE_KEY` overrides the built-in publishable key.

If Supabase is unavailable, missing, or errors, the app falls back to local demo data.

## If “No Such Module Supabase” Appears

This project currently compiles without the Supabase Swift package by using a small REST auth fallback. If you add code that imports `Supabase` and Xcode shows `No such module Supabase`, do this manually:

1. Open `VaultDex.xcodeproj` in Xcode.
2. Select File > Add Package Dependencies.
3. Enter `https://github.com/supabase/supabase-swift`.
4. Choose the latest stable version.
5. Add the `Supabase` package product to the `VaultDex` app target.
6. Clean Build Folder with Shift-Command-K.
7. Build again.

Do not add a service-role key. Use only the publishable key in the app.

## App Status Labels

- `Demo Mode`: Local/offline data is active.
- `Cloud Ready`: Supabase URL/key are configured and the app is ready for sign in.
- `Cloud Sync Active`: Email auth succeeded and a session exists.
- `Supabase Setup Needed`: Supabase URL or publishable key is missing.
- `Supabase Error`: A real Supabase client/auth failure occurred.
