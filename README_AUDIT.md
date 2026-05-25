# VaultDex End-to-End Audit

Date: 2026-05-25

## Executive Summary

VaultDex is gated behind authentication in the active app entry path. When no Supabase session exists, `ContentView` renders only `AuthView`; the tab bar and main feature screens are hidden. After sign-in, the app loads the cloud snapshot, shows profile setup if required, and only then presents the main tabs.

This pass confirmed the highest-impact production risks are controlled:

- No demo collection, wants, friends, trades or listings are loaded in cloud mode.
- Search uses live Pokémon TCG API data only.
- Normal user screens do not expose cloud/debug/demo status panels.
- Empty states are present across the main empty collection, wants, friend, trade and marketplace flows.
- Marketplace listing creation now writes to Supabase.

## Fixes Applied In This Pass

- Added Supabase persistence for cards listed for trade by wiring `LocalVaultStore.listCardForTrade` to `RemoteTradeListing` and `marketplace_listings`.
- Corrected `RemoteTradeListing` field mapping to match the current `marketplace_listings` schema (`owner_id`, `collection_item_id`, `title`, `rarity`, `estimated_value`, `status`, and related listing fields).
- Refreshed this audit report to match the current codebase state.

## Authentication And Pre-Login Content

Active file: `VaultDex/ContentView.swift`

Observed flow:

- Signed out: only `AuthView` is shown.
- Signed in and loading: `AuthenticatedLoadingView` is shown.
- Profile load failure: friendly retry screen is shown.
- Missing username/display name: `ProfileSetupView` is shown before main tabs.
- Ready: bottom tabs are shown for Home, Search, Vault, Friends and Trade.

Finding: no main app content is visible before login in the active app path.

## Demo And Mock Data

Active file: `VaultDex/Data/LocalVaultStore.swift`

Cloud mode now initialises with empty arrays for:

- cards
- sets
- collection items
- wishlist items
- friends
- friend requests
- friend wants
- trade listings
- trade offers
- binder pages
- events

`DemoVaultRepository` still exists, but it is only used when explicit demo mode is enabled or by legacy view models.

Remaining demo/mock references:

- `DemoVaultRepository` exists as a development fallback.
- `ProfileViewModel` still initialises from `DemoVaultRepository`; this appears legacy and not part of the active profile editing flow.
- `InviteFriendsViewModel` uses generated invite/contact data rather than a backend invite/contact model.

Finding: cloud mode no longer loads fake trades, listings, friends, collection items or wants.

## Card Data

Active files:

- `VaultDex/ViewModels/SearchViewModel.swift`
- `VaultDex/Services/API/CardAPIService.swift`

Search uses `https://api.pokemontcg.io/v2` and supports:

- name search
- set search
- number search through local filtering on live results
- rarity filter
- type filter
- set filter
- sort
- pagination/load more

Live API results are cached into Supabase `card_sets` and `cards`. Search no longer falls back to `store.cards` when API results are empty or failed.

Finding: Search is live API-backed. Existing Vault/Wants/Trades display the signed-in user cloud snapshot plus user-specific offline cache.

## Profile Persistence

Active files:

- `VaultDex/Views/Screens/SocialProfileView.swift`
- `VaultDex/Data/LocalVaultStore.swift`
- `VaultDex/Repositories/RemoteSupabaseRepositories.swift`

Profile edits call Supabase profile upsert and update local app state after the save succeeds. On launch, signed-in users load profile data from Supabase. If no profile exists, the app creates a cloud profile and requires setup before showing the main app.

Finding: no active launch path overwrites a signed-in cloud profile with demo profile values.

## Supabase Write Coverage

Confirmed app write paths:

- `profiles`: upsert/delete
- `card_sets`: upsert/cache
- `cards`: upsert/cache
- `collection_items`: upsert/delete
- `wishlist_items`: upsert/delete
- `friend_requests`: upsert/update
- `friendships`: upsert/delete
- `binder_pages`: upsert/delete
- `trade_offers`: upsert/status update
- `trade_offer_items`: upsert
- `marketplace_listings`: upsert for new listings; save/report support exists
- `app_events`: upsert/delete
- `reputation_events`: upsert
- `safety_reports`: insert from listing report path

Known gaps:

- `binder_slots` exists in the schema, but the current app stores binder slots through the `binder_pages` payload rather than writing the `binder_slots` table directly.
- `credit_ledger` exists in the schema but does not have an active user-flow write path.
- Some report/block/dispute placeholders show friendly feedback but do not yet create `safety_reports` from every screen.

## Broken Buttons And Dead Ends

Fixed or acceptable current behavior:

- Invite screen uses Share/Copy actions; the old empty Send Invites button is gone.
- Safety Centre report/block actions show friendly placeholder feedback.
- Trade empty state routes users to Search and Invite.
- Marketplace offer action opens the trade offer composer for live listings.

Remaining placeholder/dead-end areas:

- Friend and marketplace matching badges in card detail still use placeholder wording.
- Some moderation flows are still placeholders until the full safety workflow is implemented.
- Dispute and intermediary-safe-trade flows remain prototype placeholders.

## Fake Trades, Listings And Friends

Finding: cloud-mode startup does not seed fake trades, listings or friends. The only trades/listings/friends shown in cloud mode come from Supabase or user-specific offline cache.

## Debug UI And Logging

Normal user-facing screens no longer show:

- cloud status panels
- Supabase config panels
- demo mode labels
- developer diagnostics
- raw network or stack trace text

`VaultDexLogger` remains available for production-safe logging. The visible app UI uses friendly errors and retry affordances where needed.

## Empty States

Polished empty states were found for the major empty flows:

- Home empty vault summary
- Vault empty collection
- Wants empty wishlist
- Friends empty list
- Friend visible collection/wants
- Trade active/completed empty lists
- Marketplace no listings
- Search no results/error

## Recommended Next Pass

- Remove or fully isolate legacy `ProfileViewModel`.
- Replace invite contact demo data with a real invite/contact backend model or share-only UX.
- Wire every report/block/dispute placeholder into `safety_reports`.
- Decide whether `binder_slots` should be first-class remote rows or folded into `binder_pages`.
- Add a real `credit_ledger` write path before internal credits are treated as auditable balances.
