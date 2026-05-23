alter table public.profiles enable row level security;
alter table public.card_sets enable row level security;
alter table public.cards enable row level security;
alter table public.collection_items enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.binder_pages enable row level security;
alter table public.binder_slots enable row level security;
alter table public.trade_offers enable row level security;
alter table public.trade_offer_items enable row level security;
alter table public.marketplace_listings enable row level security;
alter table public.reputation_events enable row level security;
alter table public.credit_ledger enable row level security;
alter table public.app_events enable row level security;
alter table public.safety_reports enable row level security;

drop policy if exists "profiles are readable by signed in users" on public.profiles;
drop policy if exists "profiles are publicly readable when visible" on public.profiles;
create policy "profiles are publicly readable when visible"
on public.profiles
for select
using (auth.uid() is not null and (profile_visibility = 'public' or id = auth.uid()));

drop policy if exists "users insert own profile" on public.profiles;
create policy "users insert own profile"
on public.profiles
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "users delete own profile" on public.profiles;
create policy "users delete own profile"
on public.profiles
for delete
to authenticated
using (id = auth.uid());

drop policy if exists "card sets are readable" on public.card_sets;
create policy "card sets are readable"
on public.card_sets
for select
using (true);

drop policy if exists "authenticated users can cache card sets" on public.card_sets;
create policy "authenticated users can cache card sets"
on public.card_sets
for insert
to authenticated
with check (true);

drop policy if exists "authenticated users can refresh card sets" on public.card_sets;
create policy "authenticated users can refresh card sets"
on public.card_sets
for update
to authenticated
using (true)
with check (true);

drop policy if exists "cards are readable" on public.cards;
create policy "cards are readable"
on public.cards
for select
using (is_active = true);

drop policy if exists "authenticated users can cache cards" on public.cards;
create policy "authenticated users can cache cards"
on public.cards
for insert
to authenticated
with check (is_active = true);

drop policy if exists "authenticated users can refresh cards" on public.cards;
create policy "authenticated users can refresh cards"
on public.cards
for update
to authenticated
using (is_active = true)
with check (is_active = true);

drop policy if exists "users read own collection and tradeable public items" on public.collection_items;
create policy "users read own collection and tradeable public items"
on public.collection_items
for select
to authenticated
using (
  owner_id = auth.uid()
  or visibility = 'public'
  or available_for_trade = true
  or (
    visibility = 'friends'
    and exists (
      select 1
      from public.friendships f
      where f.status = 'active'
        and (
          (f.user_a_id = auth.uid() and f.user_b_id = collection_items.owner_id)
          or (f.user_b_id = auth.uid() and f.user_a_id = collection_items.owner_id)
        )
    )
  )
);

drop policy if exists "users insert own collection" on public.collection_items;
create policy "users insert own collection"
on public.collection_items
for insert
to authenticated
with check (owner_id = auth.uid());

drop policy if exists "users update own collection" on public.collection_items;
create policy "users update own collection"
on public.collection_items
for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "users delete own collection" on public.collection_items;
create policy "users delete own collection"
on public.collection_items
for delete
to authenticated
using (owner_id = auth.uid());

drop policy if exists "users read own wishlist" on public.wishlist_items;
create policy "users read own wishlist"
on public.wishlist_items
for select
to authenticated
using (
  user_id = auth.uid()
  or exists (
    select 1
    from public.profiles p
    where p.id = wishlist_items.user_id
      and p.wishlist_visibility = 'public'
  )
  or exists (
    select 1
    from public.profiles p
    where p.id = wishlist_items.user_id
      and p.wishlist_visibility = 'friends'
      and exists (
        select 1
        from public.friendships f
        where f.status = 'active'
          and (
            (f.user_a_id = auth.uid() and f.user_b_id = wishlist_items.user_id)
            or (f.user_b_id = auth.uid() and f.user_a_id = wishlist_items.user_id)
          )
      )
  )
);

drop policy if exists "users insert own wishlist" on public.wishlist_items;
create policy "users insert own wishlist"
on public.wishlist_items
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "users update own wishlist" on public.wishlist_items;
create policy "users update own wishlist"
on public.wishlist_items
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "users delete own wishlist" on public.wishlist_items;
create policy "users delete own wishlist"
on public.wishlist_items
for delete
to authenticated
using (user_id = auth.uid());

drop policy if exists "friend request participants read" on public.friend_requests;
create policy "friend request participants read"
on public.friend_requests
for select
to authenticated
using (requester_id = auth.uid() or addressee_id = auth.uid());

drop policy if exists "users create outgoing friend requests" on public.friend_requests;
create policy "users create outgoing friend requests"
on public.friend_requests
for insert
to authenticated
with check (requester_id = auth.uid());

drop policy if exists "friend request participants update" on public.friend_requests;
create policy "friend request participants update"
on public.friend_requests
for update
to authenticated
using (addressee_id = auth.uid())
with check (addressee_id = auth.uid());

drop policy if exists "friend request participants delete" on public.friend_requests;
create policy "friend request participants delete"
on public.friend_requests
for delete
to authenticated
using (requester_id = auth.uid() or addressee_id = auth.uid());

drop policy if exists "friendship participants read" on public.friendships;
create policy "friendship participants read"
on public.friendships
for select
to authenticated
using (user_a_id = auth.uid() or user_b_id = auth.uid());

drop policy if exists "users create own friendships" on public.friendships;
create policy "users create own friendships"
on public.friendships
for insert
to authenticated
with check (
  (user_a_id = auth.uid() or user_b_id = auth.uid())
  and exists (
    select 1
    from public.friend_requests r
    where r.status = 'accepted'
      and r.requester_id = friendships.user_a_id
      and r.addressee_id = friendships.user_b_id
  )
);

drop policy if exists "friendship participants update" on public.friendships;
create policy "friendship participants update"
on public.friendships
for update
to authenticated
using (user_a_id = auth.uid() or user_b_id = auth.uid())
with check (user_a_id = auth.uid() or user_b_id = auth.uid());

drop policy if exists "friendship participants delete" on public.friendships;
create policy "friendship participants delete"
on public.friendships
for delete
to authenticated
using (user_a_id = auth.uid() or user_b_id = auth.uid());

drop policy if exists "read own or public binder pages" on public.binder_pages;
create policy "read own or public binder pages"
on public.binder_pages
for select
to authenticated
using (user_id = auth.uid() or visibility = 'public');

drop policy if exists "users insert own binder pages" on public.binder_pages;
create policy "users insert own binder pages"
on public.binder_pages
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "users update own binder pages" on public.binder_pages;
create policy "users update own binder pages"
on public.binder_pages
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "users delete own binder pages" on public.binder_pages;
create policy "users delete own binder pages"
on public.binder_pages
for delete
to authenticated
using (user_id = auth.uid());

drop policy if exists "read slots for visible binder pages" on public.binder_slots;
create policy "read slots for visible binder pages"
on public.binder_slots
for select
to authenticated
using (
  exists (
    select 1 from public.binder_pages
    where binder_pages.id = binder_slots.page_id
      and (binder_pages.user_id = auth.uid() or binder_pages.visibility = 'public')
  )
);

drop policy if exists "users insert slots on own binder pages" on public.binder_slots;
create policy "users insert slots on own binder pages"
on public.binder_slots
for insert
to authenticated
with check (
  exists (
    select 1 from public.binder_pages
    where binder_pages.id = binder_slots.page_id
      and binder_pages.user_id = auth.uid()
  )
);

drop policy if exists "users update slots on own binder pages" on public.binder_slots;
create policy "users update slots on own binder pages"
on public.binder_slots
for update
to authenticated
using (
  exists (
    select 1 from public.binder_pages
    where binder_pages.id = binder_slots.page_id
      and binder_pages.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.binder_pages
    where binder_pages.id = binder_slots.page_id
      and binder_pages.user_id = auth.uid()
  )
);

drop policy if exists "users delete slots on own binder pages" on public.binder_slots;
create policy "users delete slots on own binder pages"
on public.binder_slots
for delete
to authenticated
using (
  exists (
    select 1 from public.binder_pages
    where binder_pages.id = binder_slots.page_id
      and binder_pages.user_id = auth.uid()
  )
);

drop policy if exists "trade participants read offers" on public.trade_offers;
create policy "trade participants read offers"
on public.trade_offers
for select
to authenticated
using (sender_id = auth.uid() or receiver_id = auth.uid());

drop policy if exists "users create sent trade offers" on public.trade_offers;
create policy "users create sent trade offers"
on public.trade_offers
for insert
to authenticated
with check (sender_id = auth.uid());

drop policy if exists "trade participants update offers" on public.trade_offers;
create policy "trade participants update offers"
on public.trade_offers
for update
to authenticated
using (sender_id = auth.uid() or receiver_id = auth.uid())
with check (sender_id = auth.uid() or receiver_id = auth.uid());

drop policy if exists "trade participants delete offers" on public.trade_offers;
create policy "trade participants delete offers"
on public.trade_offers
for delete
to authenticated
using (sender_id = auth.uid());

drop policy if exists "trade participants read offer items" on public.trade_offer_items;
create policy "trade participants read offer items"
on public.trade_offer_items
for select
to authenticated
using (
  exists (
    select 1 from public.trade_offers
    where trade_offers.id = trade_offer_items.trade_offer_id
      and (trade_offers.sender_id = auth.uid() or trade_offers.receiver_id = auth.uid())
  )
);

drop policy if exists "sender creates trade offer items" on public.trade_offer_items;
create policy "sender creates trade offer items"
on public.trade_offer_items
for insert
to authenticated
with check (
  exists (
    select 1 from public.trade_offers
    where trade_offers.id = trade_offer_items.trade_offer_id
      and trade_offers.sender_id = auth.uid()
  )
);

drop policy if exists "trade participants update offer items" on public.trade_offer_items;
create policy "trade participants update offer items"
on public.trade_offer_items
for update
to authenticated
using (
  exists (
    select 1 from public.trade_offers
    where trade_offers.id = trade_offer_items.trade_offer_id
      and (trade_offers.sender_id = auth.uid() or trade_offers.receiver_id = auth.uid())
  )
)
with check (
  exists (
    select 1 from public.trade_offers
    where trade_offers.id = trade_offer_items.trade_offer_id
      and (trade_offers.sender_id = auth.uid() or trade_offers.receiver_id = auth.uid())
  )
);

drop policy if exists "sender deletes trade offer items" on public.trade_offer_items;
create policy "sender deletes trade offer items"
on public.trade_offer_items
for delete
to authenticated
using (
  exists (
    select 1 from public.trade_offers
    where trade_offers.id = trade_offer_items.trade_offer_id
      and trade_offers.sender_id = auth.uid()
  )
);

drop policy if exists "public marketplace listings are readable" on public.marketplace_listings;
create policy "public marketplace listings are readable"
on public.marketplace_listings
for select
using (is_public = true or owner_id = auth.uid());

drop policy if exists "users insert own marketplace listings" on public.marketplace_listings;
create policy "users insert own marketplace listings"
on public.marketplace_listings
for insert
to authenticated
with check (owner_id = auth.uid());

drop policy if exists "users update own marketplace listings" on public.marketplace_listings;
create policy "users update own marketplace listings"
on public.marketplace_listings
for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "users delete own marketplace listings" on public.marketplace_listings;
create policy "users delete own marketplace listings"
on public.marketplace_listings
for delete
to authenticated
using (owner_id = auth.uid());

drop policy if exists "reputation events are readable" on public.reputation_events;
create policy "reputation events are readable"
on public.reputation_events
for select
using (true);

drop policy if exists "users insert reputation events they authored" on public.reputation_events;
create policy "users insert reputation events they authored"
on public.reputation_events
for insert
to authenticated
with check (actor_id = auth.uid());

drop policy if exists "users read own credit ledger" on public.credit_ledger;
create policy "users read own credit ledger"
on public.credit_ledger
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "users insert own credit ledger entries" on public.credit_ledger;
create policy "users insert own credit ledger entries"
on public.credit_ledger
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "public or owned events are readable" on public.app_events;
create policy "public or owned events are readable"
on public.app_events
for select
using (visibility = 'public' or owner_id = auth.uid());

drop policy if exists "users insert own events" on public.app_events;
create policy "users insert own events"
on public.app_events
for insert
to authenticated
with check (owner_id = auth.uid());

drop policy if exists "users update own events" on public.app_events;
create policy "users update own events"
on public.app_events
for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "users delete own events" on public.app_events;
create policy "users delete own events"
on public.app_events
for delete
to authenticated
using (owner_id = auth.uid());

drop policy if exists "users read own safety reports" on public.safety_reports;
create policy "users read own safety reports"
on public.safety_reports
for select
to authenticated
using (reporter_id = auth.uid());

drop policy if exists "users create safety reports" on public.safety_reports;
create policy "users create safety reports"
on public.safety_reports
for insert
to authenticated
with check (reporter_id = auth.uid());
