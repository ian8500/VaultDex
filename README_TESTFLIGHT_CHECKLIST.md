# VaultDex TestFlight Checklist

Use this checklist before each TestFlight build. VaultDex should feel like a production app: no debug panels, no raw cloud/API errors, no fake data in cloud mode, and no crashes when permissions are denied.

## Build Readiness

- App icon placeholder is configured in `Assets.xcassets/AppIcon.appiconset`.
- Launch screen is configured for the app target.
- Camera permission text is present.
- Photo library permission text is present.
- Photo library add permission text is present.
- Signed-out users see only Login/Register.
- Normal users do not see Supabase, API, config, demo, or diagnostics wording.
- Network failures use friendly messages with retry buttons.
- Loading views use spinners or skeleton states instead of blank screens.
- New accounts show helpful empty states for Vault, Wants, Friends, Trades and Market.
- Cloud mode does not seed demo users, fake trades, fake friends, fake listings, fake wants or fake collection items.

## Manual QA

1. Sign up with a new email address.
2. Complete profile setup.
3. Logout.
4. Login again.
5. Edit profile fields and verify they persist after relaunch.
6. Upload avatar and verify it appears after relaunch.
7. Search card data and confirm real card images load.
8. Add a card to Vault and verify it persists after relaunch.
9. Add a card to Wants and verify it persists after relaunch.
10. View Friends.
11. View Friends' Wants.
12. Create trade with a friend account.
13. Logout and confirm the main app is hidden.
14. Delete account from Profile/Settings and confirm the account flow returns safely to Login/Register.

## Permission QA

- Deny camera permission, open Scan Card, and confirm VaultDex shows a friendly settings/manual-search fallback.
- Deny photo library permission, try avatar upload, and confirm VaultDex shows a friendly error without crashing.
- Confirm the scanner uses manual search fallback if no card is identified.

## Release Notes To Verify

- Values are shown in GBP and marked as estimates.
- No raw technical error text is visible.
- No routine debug logs appear during normal usage.
- Privacy Policy and Terms placeholders are included until final legal copy is ready.
- Safety Centre includes the independent app disclaimer:
  VaultDex is independent and not affiliated with The Pokémon Company, Nintendo, Creatures Inc. or GAME FREAK.
