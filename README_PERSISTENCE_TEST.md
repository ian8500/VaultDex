# VaultDex Persistence Test

Use this checklist before TestFlight builds that touch auth, profile, Vault, Wants, friends, trades, marketplace, or onboarding.

## Profile

1. Sign in with a real VaultDex account.
2. Open Collector Profile.
3. Edit username, display name, bio, location, and collector type.
4. Save changes and wait for `Saved`.
5. Force close the app.
6. Reopen the app.
7. Verify the saved profile values remain.
8. Add or change the avatar photo.
9. Force close and reopen again.
10. Verify the avatar still loads from `avatar_url`.

## My Vault

1. Search for a live card.
2. Add it to My Vault.
3. Wait for `Saved`.
4. Edit quantity, condition, variant, notes, visibility, and trade availability.
5. Wait for `Saved`.
6. Force close the app.
7. Reopen the app.
8. Verify the card and edited details remain in My Vault.
9. Remove the card.
10. Force close and reopen.
11. Verify the card stays removed.

## Wants

1. Search for a live card.
2. Add it to Wants.
3. Wait for `Saved`.
4. Edit priority, preferred condition, max value, and notes.
5. Wait for `Saved`.
6. Force close the app.
7. Reopen the app.
8. Verify the Want and edited details remain.
9. Remove the Want.
10. Force close and reopen.
11. Verify the Want stays removed.

## Friends And Trades

1. Search for another user by username.
2. Send a friend request.
3. Force close and reopen.
4. Verify the pending request remains.
5. Create a trade offer with a friend.
6. Wait for `Saved`.
7. Force close and reopen.
8. Verify sent/received trade state remains.
9. Accept, reject, cancel, or complete a trade.
10. Force close and reopen.
11. Verify the trade status remains.

## Marketplace

1. List one of your Vault cards.
2. Wait for `Saved`.
3. Force close and reopen.
4. Verify the listing remains visible.
5. Remove the listing.
6. Force close and reopen.
7. Verify the listing stays removed.

## Onboarding

1. Complete onboarding.
2. Force close and reopen.
3. Verify onboarding does not appear again for the same install.

## Expected Failure Behaviour

- If a save fails, VaultDex should show `Couldn’t save. Please try again.`
- The app should not replace cloud data with demo data after restart.
- The app should not show fake friends, trades, listings, Vault cards, or Wants in cloud mode.
