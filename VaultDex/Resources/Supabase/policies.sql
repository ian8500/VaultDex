alter table public.profiles enable row level security;
alter table public.card_sets enable row level security;
alter table public.cards enable row level security;
alter table public.collection_items enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.friendships enable row level security;
alter table public.binder_pages enable row level security;
alter table public.trade_listings enable row level security;
alter table public.trade_offers enable row level security;
alter table public.marketplace_listings enable row level security;
alter table public.saved_marketplace_listings enable row level security;
alter table public.listing_reports enable row level security;
alter table public.events enable row level security;
alter table public.reputation enable row level security;

create policy "profiles are readable by signed in users"
on public.profiles for select
to authenticated
using (true);

create policy "users insert own profile"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

create policy "users update own profile"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "card sets are readable"
on public.card_sets for select
to authenticated
using (true);

create policy "cards are readable"
on public.cards for select
to authenticated
using (true);

create policy "users manage own collection"
on public.collection_items for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "friends can read visible tradeable collection"
on public.collection_items for select
to authenticated
using (
  is_available_for_trade
  and exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and (
        (f.requester_id = auth.uid() and f.addressee_id = collection_items.user_id)
        or (f.addressee_id = auth.uid() and f.requester_id = collection_items.user_id)
      )
  )
);

create policy "users manage own wishlist"
on public.wishlist_items for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "friends can read wishlists"
on public.wishlist_items for select
to authenticated
using (
  exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and (
        (f.requester_id = auth.uid() and f.addressee_id = wishlist_items.user_id)
        or (f.addressee_id = auth.uid() and f.requester_id = wishlist_items.user_id)
      )
  )
);

create policy "users read their friendships"
on public.friendships for select
to authenticated
using (requester_id = auth.uid() or addressee_id = auth.uid());

create policy "users request friendships"
on public.friendships for insert
to authenticated
with check (requester_id = auth.uid());

create policy "users update their friendships"
on public.friendships for update
to authenticated
using (requester_id = auth.uid() or addressee_id = auth.uid())
with check (requester_id = auth.uid() or addressee_id = auth.uid());

create policy "users manage own binder pages"
on public.binder_pages for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "friends read visible binder pages"
on public.binder_pages for select
to authenticated
using (
  visibility = 'public'
  or (
    visibility = 'friends'
    and exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and (
          (f.requester_id = auth.uid() and f.addressee_id = binder_pages.user_id)
          or (f.addressee_id = auth.uid() and f.requester_id = binder_pages.user_id)
        )
    )
  )
);

create policy "users manage own trade listings"
on public.trade_listings for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "signed in users read public trade listings"
on public.trade_listings for select
to authenticated
using (is_public);

create policy "users read their trade offers"
on public.trade_offers for select
to authenticated
using (sender_id = auth.uid() or receiver_id = auth.uid());

create policy "users create sent trade offers"
on public.trade_offers for insert
to authenticated
with check (sender_id = auth.uid());

create policy "users update their trade offers"
on public.trade_offers for update
to authenticated
using (sender_id = auth.uid() or receiver_id = auth.uid())
with check (sender_id = auth.uid() or receiver_id = auth.uid());

create policy "signed in users read marketplace"
on public.marketplace_listings for select
to authenticated
using (true);

create policy "listing owners maintain marketplace rows"
on public.marketplace_listings for all
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy "users manage saved listings"
on public.saved_marketplace_listings for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "users create listing reports"
on public.listing_reports for insert
to authenticated
with check (reporter_id = auth.uid());

create policy "users read own listing reports"
on public.listing_reports for select
to authenticated
using (reporter_id = auth.uid());

create policy "users manage own events"
on public.events for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "friends read visible events"
on public.events for select
to authenticated
using (
  visibility = 'public'
  or (
    visibility = 'friends'
    and exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and (
          (f.requester_id = auth.uid() and f.addressee_id = events.user_id)
          or (f.addressee_id = auth.uid() and f.requester_id = events.user_id)
        )
    )
  )
);

create policy "users read reputation"
on public.reputation for select
to authenticated
using (true);

create policy "users maintain own reputation row"
on public.reputation for all
to authenticated
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

create policy "users upload own avatars"
on storage.objects for insert
to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "users update own avatars"
on storage.objects for update
to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "users upload own card photos"
on storage.objects for insert
to authenticated
with check (bucket_id = 'card-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "users read card photos"
on storage.objects for select
to authenticated
using (bucket_id in ('avatars', 'card-photos'));

