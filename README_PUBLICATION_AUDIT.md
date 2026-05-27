# VaultDex Publication Audit

Last audited: 2026-05-27

## What currently works

- Authentication gating is in place: signed-out users see the Login/Register screen only.
- Supabase email sign up, sign in, sign out and password reset flows are wired through the Supabase Swift SDK.
- Profile setup appears when the signed-in profile has no display name.
- Profile edits save to the `profiles` table and update local state after a successful save.
- My Vault can add, edit and remove collection cards.
- Wants can add, edit and remove wanted cards.
- Search uses lightweight Pokémon TCG API queries and cached local search results.
- Card detail fetches full Pokémon TCG card data, including pricing fields, then caches useful card metadata.
- GBP value formatting is centralised and missing values display as “Value unavailable”.
- Supabase Storage avatar/card-photo services are implemented, with the avatar pipeline using the `avatars` bucket.
- Bottom navigation is custom, floating and limited to core destinations.
- Friendly loading, empty and error states exist across the main flows.

## What is still demo/local

- Demo mode still exists in code for development fallback.
- `DemoVaultRepository` provides local development data only when the app is explicitly in demo mode or cloud setup is unavailable.
- Import preview rows, invite contacts and some feature drafts are local-only helper data.
- Binder pages, events and some safety/admin placeholders are still mostly local or partial cloud implementations.
- Developer/Admin tools remain in code for internal use but are not reachable from the normal Settings UI after this audit pass.

## What uses Supabase

- Auth session handling.
- `profiles`.
- `cards` and `card_sets` as the app card cache/database.
- `collection_items`.
- `wishlist_items`.
- `friend_requests` and `friendships`.
- Trade offers and trade offer items.
- Marketplace listings.
- Events, reputation and verification request repositories exist.
- Supabase Storage for avatar and card photo uploads.

## What uses Pokémon API

- Search fallback when Supabase/local cache has no results.
- Quick-search chips use direct lightweight queries, for example `name:pikachu`.
- Card detail enrichment fetches full card details by external Pokémon TCG card id.
- Scanner matching searches Supabase first, then Pokémon TCG API as fallback.
- Pricing is fetched only from full card detail, not default search lists.

## What data persists

- Supabase auth session is persisted locally.
- Cloud profile fields persist in `profiles`.
- Avatar URL persists in `profiles.avatar_url` when upload/update succeeds.
- Vault items persist in `collection_items`.
- Wants persist in `wishlist_items`.
- Friends, friend requests, trade offers and marketplace listings are loaded through Supabase repositories.
- A local cloud cache is stored under Application Support for offline fallback.
- Local card search results and recently viewed cards are cached.
- Onboarding completion persists in `AppStorage`.

## What data is lost on restart

- Unsaved form drafts are lost when the app is closed.
- Local-only demo mode changes are not production source-of-truth data.
- Feature placeholders without full cloud persistence, such as some binder/event/admin flows, may not reload from Supabase consistently yet.
- If a card row is missing from Supabase while a collection/wishlist row references it, that item cannot render until the card is restored or fetched again.

## Known bugs and risks

- Marketplace, binder and event flows need deeper end-to-end QA before TestFlight.
- Supabase RLS policies must be re-run and validated in the live Supabase project after schema changes.
- Avatar upload reliability depends on the `avatars` bucket and storage policies being configured exactly as documented.
- Account deletion currently removes the profile row and local cache, but full auth-user deletion still requires an admin/server-side flow.
- The Pokémon TCG API can still timeout; cached quick-search results now reduce the impact.
- Card pricing is best-effort and unavailable when external data has no Cardmarket/TCGPlayer price.

## App Store readiness issues

- Move hardcoded development Supabase and Pokémon TCG keys into secure build configuration before release.
- Remove or disable demo mode from any production-distributed build configuration.
- Confirm privacy policy, terms and safety copy are final and reachable.
- Confirm camera/photo permission strings are present in the shipping target.
- Validate all Supabase RLS policies against a non-admin test account.
- Add real account deletion backend support for deleting the Supabase auth user.
- Complete real QA on physical devices for sign up, avatar upload, scanning, search, Vault, Wants, Friends and Trade.

## Fixes made in this audit pass

- Cloud launch now fetches card rows referenced by Vault, Wants, visible friend data, marketplace listings and trade items.
- Vault/Wants are no longer dependent on local cached card metadata after restart.
- Card set loading during launch is non-blocking fallback data, so a set request failure does not block user data.
- Developer/Admin diagnostics are hidden from the normal Settings UI.
- A publication audit document was added for TestFlight/App Store planning.
