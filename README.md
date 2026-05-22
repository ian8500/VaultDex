# VaultDex

VaultDex is a native SwiftUI iOS trading-card collection app. It runs in local demo mode by default, and can switch to Supabase-backed data when configured.

## Supabase Setup

1. Create a Supabase project.
   - In the Supabase dashboard, create a new project.
   - Copy the Project URL and anon public API key from Project Settings > API.
   - Do not use or ship the service-role key in the iOS app.

2. Run `schema.sql`.
   - Open the Supabase SQL editor.
   - Run `VaultDex/Resources/Supabase/schema.sql`.
   - This creates tables for profiles, cards, collection, wishlist, friends, binder pages, trade listings, trade offers, marketplace listings, events, reputation, and storage buckets for avatars/card photos.

3. Run `policies.sql`.
   - Run `VaultDex/Resources/Supabase/policies.sql`.
   - This enables row level security and adds owner/friend/public access policies.

4. Run `seed.sql`.
   - Run `VaultDex/Resources/Supabase/seed.sql`.
   - This seeds the demo card sets and card catalogue.

5. Enable Email Auth.
   - In Authentication > Providers, enable Email.
   - Configure confirmation settings for your environment.

6. Add app configuration.
   - In Xcode, edit the VaultDex scheme and add environment variables:
     - `DEMO_MODE=false`
     - `SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co`
     - `SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY`
   - To force local mode, set `DEMO_MODE=true` or omit the Supabase URL/key.

## Runtime Modes

- `DEMO_MODE=true`: Uses local demo/offline data.
- `DEMO_MODE=false`: Uses Supabase repositories when both `SUPABASE_URL` and `SUPABASE_ANON_KEY` are present.
- Missing Supabase values automatically keep the app in local/demo fallback so the app still compiles and launches safely.

## Security Notes

- Never hardcode secrets in source.
- Use only the Supabase anon key in the iOS app.
- Keep row level security enabled.
- User-uploaded avatars and card photos go through Supabase Storage buckets: `avatars` and `card-photos`.

