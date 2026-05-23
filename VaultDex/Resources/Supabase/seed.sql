-- VaultDex production-style testing seed.
--
-- This file intentionally inserts no seeded users, friend relationships,
-- collection items, wishlist items, trade offers, marketplace listings,
-- notifications, conversations, messages, or events.
--
-- Use authenticated app flows and real card API search results to populate
-- cloud data during testing. This keeps the database safe to re-run without
-- dropping or overwriting existing user data.

select 'VaultDex seed: no demo data inserted' as status;
