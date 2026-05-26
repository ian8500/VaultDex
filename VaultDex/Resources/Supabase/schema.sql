create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists location text;
alter table public.profiles add column if not exists bio text;
alter table public.profiles add column if not exists collector_type text;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists avatar_path text;
alter table public.profiles add column if not exists reputation_score integer not null default 0;
alter table public.profiles add column if not exists trust_badges text[] not null default '{}';
alter table public.profiles add column if not exists completed_trades integer not null default 0;
alter table public.profiles add column if not exists collector_score integer not null default 0;
alter table public.profiles add column if not exists profile_visibility text not null default 'public';
alter table public.profiles add column if not exists collection_visibility text not null default 'friends';
alter table public.profiles add column if not exists wishlist_visibility text not null default 'friends';
alter table public.profiles add column if not exists allow_friend_trade_requests boolean not null default true;
alter table public.profiles add column if not exists is_admin boolean not null default false;
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles add column if not exists updated_at timestamptz not null default now();
alter table public.profiles alter column username drop not null;
alter table public.profiles alter column display_name drop not null;

create table if not exists public.card_sets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  release_year integer not null,
  total_cards integer not null default 0,
  description text,
  symbol_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cards (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references public.card_sets(id) on delete cascade,
  name text not null,
  number text not null,
  rarity text not null,
  card_type text not null,
  type_line text not null default '',
  power integer not null default 0,
  market_value numeric(10, 2) not null default 0,
  accent text not null default 'aurora',
  image_path text,
  artist_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (set_id, number)
);

create table if not exists public.collection_items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  card_id uuid not null references public.cards(id) on delete cascade,
  quantity integer not null default 1 check (quantity > 0),
  condition text not null default 'nearMint',
  variant text not null default 'normal',
  language text not null default 'English',
  graded_company text,
  graded_score text,
  notes text,
  visibility text not null default 'private' check (visibility in ('private', 'friends', 'public')),
  available_for_trade boolean not null default false,
  available_for_credits boolean not null default false,
  asking_credits integer check (asking_credits is null or asking_credits >= 0),
  is_favorite boolean not null default false,
  acquired_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, card_id, condition, variant, language)
);

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'collection_items' and column_name = 'user_id'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'collection_items' and column_name = 'owner_id'
  ) then
    alter table public.collection_items rename column user_id to owner_id;
  end if;
end $$;

alter table public.collection_items add column if not exists language text not null default 'English';
alter table public.collection_items add column if not exists graded_company text;
alter table public.collection_items add column if not exists graded_score text;
alter table public.collection_items add column if not exists notes text;
alter table public.collection_items add column if not exists visibility text not null default 'private';
alter table public.collection_items add column if not exists available_for_trade boolean not null default false;
alter table public.collection_items add column if not exists available_for_credits boolean not null default false;
alter table public.collection_items add column if not exists asking_credits integer;
alter table public.collection_items add column if not exists front_photo_url text;
alter table public.collection_items add column if not exists back_photo_url text;
alter table public.collection_items add column if not exists created_at timestamptz not null default now();
alter table public.collection_items add column if not exists updated_at timestamptz not null default now();

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('card-photos', 'card-photos', true, 10485760, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'collection_items' and column_name = 'is_available_for_trade'
  ) then
    update public.collection_items
    set available_for_trade = is_available_for_trade
    where available_for_trade = false and is_available_for_trade = true;
  end if;
end $$;

create table if not exists public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  card_id uuid not null references public.cards(id) on delete cascade,
  priority text not null default 'medium',
  preferred_condition text not null default 'nearMint',
  max_trade_value numeric(10, 2) not null default 0,
  notes text not null default '',
  added_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, card_id)
);

alter table public.wishlist_items add column if not exists preferred_condition text not null default 'nearMint';
alter table public.wishlist_items add column if not exists max_trade_value numeric(10, 2) not null default 0;
alter table public.wishlist_items add column if not exists notes text not null default '';
alter table public.wishlist_items add column if not exists added_at timestamptz not null default now();
alter table public.wishlist_items add column if not exists created_at timestamptz not null default now();
alter table public.wishlist_items add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'wishlist_items'
      and column_name = 'budget'
  ) then
    update public.wishlist_items
    set max_trade_value = budget
    where max_trade_value = 0 and budget is not null and budget > 0;
  end if;
end $$;

create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  message text,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (requester_id <> addressee_id),
  unique (requester_id, addressee_id)
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid not null references public.profiles(id) on delete cascade,
  user_b_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (user_a_id <> user_b_id),
  unique (user_a_id, user_b_id)
);

create table if not exists public.binder_pages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  theme text not null default 'midnight-gold',
  visibility text not null default 'private',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.binder_slots (
  id uuid primary key default gen_random_uuid(),
  page_id uuid not null references public.binder_pages(id) on delete cascade,
  slot_index integer not null check (slot_index between 1 and 9),
  card_id uuid references public.cards(id) on delete set null,
  collection_item_id uuid references public.collection_items(id) on delete set null,
  note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (page_id, slot_index)
);

create table if not exists public.trade_offers (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  offered_card_ids uuid[] not null default '{}',
  requested_card_ids uuid[] not null default '{}',
  message text not null default '',
  internal_credits integer not null default 0 check (internal_credits >= 0),
  status text not null default 'pending',
  uses_safe_trade boolean not null default false,
  value_delta numeric(10, 2) not null default 0,
  completed_at timestamptz,
  disputed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (sender_id <> receiver_id)
);

alter table public.trade_offers add column if not exists offered_card_ids uuid[] not null default '{}';
alter table public.trade_offers add column if not exists requested_card_ids uuid[] not null default '{}';

create table if not exists public.trade_offer_items (
  id uuid primary key default gen_random_uuid(),
  trade_offer_id uuid not null references public.trade_offers(id) on delete cascade,
  owner_id uuid references public.profiles(id) on delete set null,
  card_id uuid not null references public.cards(id) on delete cascade,
  collection_item_id uuid references public.collection_items(id) on delete set null,
  side text not null check (side in ('offered', 'requested')),
  quantity integer not null default 1 check (quantity > 0),
  estimated_value numeric(10, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.marketplace_listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete set null,
  card_id uuid not null references public.cards(id) on delete cascade,
  collection_item_id uuid references public.collection_items(id) on delete set null,
  title text not null,
  condition text not null default 'nearMint',
  variant text not null default 'normal',
  rarity text not null,
  estimated_value numeric(10, 2) not null default 0,
  asking_for text not null default '',
  seller_display_name text not null default 'VaultDex Collector',
  seller_reputation integer not null default 0,
  location_label text,
  is_public boolean not null default true,
  is_saved boolean not null default false,
  uses_safe_trade boolean not null default false,
  status text not null default 'active',
  listed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.marketplace_listings alter column title set default 'Cloud trade listing';
alter table public.marketplace_listings alter column rarity set default 'rare';
alter table public.marketplace_listings alter column seller_display_name set default 'VaultDex Collector';
alter table public.marketplace_listings add column if not exists listing_kind text not null default 'trade';
alter table public.marketplace_listings add column if not exists asking_credits integer check (asking_credits is null or asking_credits >= 0);
alter table public.marketplace_listings add column if not exists description text;

create table if not exists public.reputation_events (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  trade_offer_id uuid references public.trade_offers(id) on delete set null,
  event_type text not null,
  score_delta integer not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.credit_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  trade_offer_id uuid references public.trade_offers(id) on delete set null,
  amount integer not null,
  reason text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete set null,
  event_date timestamptz not null,
  title text not null,
  emoji_marker text not null default '*',
  location text not null default '',
  notes text not null default '',
  visibility text not null default 'public',
  kind text not null default 'meetup',
  attending_friends integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.safety_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_profile_id uuid references public.profiles(id) on delete set null,
  marketplace_listing_id uuid references public.marketplace_listings(id) on delete set null,
  trade_offer_id uuid references public.trade_offers(id) on delete set null,
  reason text not null,
  details text not null default '',
  status text not null default 'open',
  moderator_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.verification_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'verified', 'rejected')),
  full_name text not null,
  date_of_birth date,
  verification_note text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id) on delete set null,
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.verification_requests add column if not exists status text not null default 'pending';
alter table public.verification_requests add column if not exists full_name text not null default '';
alter table public.verification_requests add column if not exists date_of_birth date;
alter table public.verification_requests add column if not exists verification_note text;
alter table public.verification_requests add column if not exists submitted_at timestamptz not null default now();
alter table public.verification_requests add column if not exists reviewed_at timestamptz;
alter table public.verification_requests add column if not exists reviewed_by uuid references public.profiles(id) on delete set null;
alter table public.verification_requests add column if not exists admin_note text;
alter table public.verification_requests add column if not exists created_at timestamptz not null default now();
alter table public.verification_requests add column if not exists updated_at timestamptz not null default now();

alter table public.card_sets add column if not exists created_at timestamptz not null default now();
alter table public.card_sets add column if not exists updated_at timestamptz not null default now();
alter table public.cards add column if not exists created_at timestamptz not null default now();
alter table public.cards add column if not exists updated_at timestamptz not null default now();
alter table public.friend_requests add column if not exists created_at timestamptz not null default now();
alter table public.friend_requests add column if not exists updated_at timestamptz not null default now();
alter table public.friendships add column if not exists created_at timestamptz not null default now();
alter table public.friendships add column if not exists updated_at timestamptz not null default now();
alter table public.binder_pages add column if not exists created_at timestamptz not null default now();
alter table public.binder_pages add column if not exists updated_at timestamptz not null default now();
alter table public.binder_slots add column if not exists created_at timestamptz not null default now();
alter table public.binder_slots add column if not exists updated_at timestamptz not null default now();
alter table public.trade_offers add column if not exists created_at timestamptz not null default now();
alter table public.trade_offers add column if not exists updated_at timestamptz not null default now();
alter table public.trade_offer_items add column if not exists created_at timestamptz not null default now();
alter table public.trade_offer_items add column if not exists updated_at timestamptz not null default now();
alter table public.marketplace_listings add column if not exists created_at timestamptz not null default now();
alter table public.marketplace_listings add column if not exists updated_at timestamptz not null default now();
alter table public.reputation_events add column if not exists created_at timestamptz not null default now();
alter table public.reputation_events add column if not exists updated_at timestamptz not null default now();
alter table public.credit_ledger add column if not exists created_at timestamptz not null default now();
alter table public.credit_ledger add column if not exists updated_at timestamptz not null default now();
alter table public.app_events add column if not exists created_at timestamptz not null default now();
alter table public.app_events add column if not exists updated_at timestamptz not null default now();
alter table public.safety_reports add column if not exists created_at timestamptz not null default now();
alter table public.safety_reports add column if not exists updated_at timestamptz not null default now();
alter table public.verification_requests add column if not exists created_at timestamptz not null default now();
alter table public.verification_requests add column if not exists updated_at timestamptz not null default now();

create index if not exists profiles_username_idx on public.profiles(username);
create index if not exists profiles_is_admin_idx on public.profiles(is_admin);
create index if not exists profiles_created_at_idx on public.profiles(created_at);
create index if not exists card_sets_created_at_idx on public.card_sets(created_at);
create index if not exists cards_set_id_idx on public.cards(set_id);
create index if not exists cards_name_idx on public.cards using gin (to_tsvector('english', name));
create index if not exists cards_card_type_idx on public.cards(card_type);
create index if not exists cards_rarity_idx on public.cards(rarity);
create index if not exists cards_created_at_idx on public.cards(created_at);
create index if not exists collection_items_owner_id_idx on public.collection_items(owner_id);
create index if not exists collection_items_card_id_idx on public.collection_items(card_id);
create index if not exists collection_items_owner_card_idx on public.collection_items(owner_id, card_id);
create index if not exists collection_items_created_at_idx on public.collection_items(created_at);
create index if not exists collection_items_updated_at_idx on public.collection_items(updated_at);
create index if not exists wishlist_items_user_id_idx on public.wishlist_items(user_id);
create index if not exists wishlist_items_card_id_idx on public.wishlist_items(card_id);
create index if not exists wishlist_items_user_card_idx on public.wishlist_items(user_id, card_id);
create index if not exists wishlist_items_created_at_idx on public.wishlist_items(created_at);
create index if not exists friend_requests_requester_idx on public.friend_requests(requester_id);
create index if not exists friend_requests_addressee_idx on public.friend_requests(addressee_id);
create index if not exists friend_requests_status_idx on public.friend_requests(status);
create index if not exists friend_requests_created_at_idx on public.friend_requests(created_at);
create index if not exists friendships_user_a_idx on public.friendships(user_a_id);
create index if not exists friendships_user_b_idx on public.friendships(user_b_id);
create index if not exists friendships_status_idx on public.friendships(status);
create index if not exists friendships_created_at_idx on public.friendships(created_at);
create index if not exists binder_pages_user_id_idx on public.binder_pages(user_id);
create index if not exists binder_pages_visibility_idx on public.binder_pages(visibility);
create index if not exists binder_pages_created_at_idx on public.binder_pages(created_at);
create index if not exists binder_slots_page_id_idx on public.binder_slots(page_id);
create index if not exists binder_slots_card_id_idx on public.binder_slots(card_id);
create index if not exists binder_slots_collection_item_id_idx on public.binder_slots(collection_item_id);
create index if not exists binder_slots_created_at_idx on public.binder_slots(created_at);
create index if not exists trade_offers_sender_idx on public.trade_offers(sender_id);
create index if not exists trade_offers_receiver_idx on public.trade_offers(receiver_id);
create index if not exists trade_offers_status_idx on public.trade_offers(status);
create index if not exists trade_offers_created_at_idx on public.trade_offers(created_at);
create index if not exists trade_offer_items_offer_idx on public.trade_offer_items(trade_offer_id);
create index if not exists trade_offer_items_owner_idx on public.trade_offer_items(owner_id);
create index if not exists trade_offer_items_card_idx on public.trade_offer_items(card_id);
create index if not exists trade_offer_items_side_idx on public.trade_offer_items(side);
create index if not exists trade_offer_items_created_at_idx on public.trade_offer_items(created_at);
create index if not exists marketplace_listings_card_idx on public.marketplace_listings(card_id);
create index if not exists marketplace_listings_owner_idx on public.marketplace_listings(owner_id);
create index if not exists marketplace_listings_collection_item_idx on public.marketplace_listings(collection_item_id);
create index if not exists marketplace_listings_status_idx on public.marketplace_listings(status);
create index if not exists marketplace_listings_listing_kind_idx on public.marketplace_listings(listing_kind);
create index if not exists marketplace_listings_created_at_idx on public.marketplace_listings(created_at);
create index if not exists reputation_events_profile_idx on public.reputation_events(profile_id);
create index if not exists reputation_events_actor_idx on public.reputation_events(actor_id);
create index if not exists reputation_events_trade_offer_idx on public.reputation_events(trade_offer_id);
create index if not exists reputation_events_created_at_idx on public.reputation_events(created_at);
create index if not exists credit_ledger_user_idx on public.credit_ledger(user_id);
create index if not exists credit_ledger_trade_offer_idx on public.credit_ledger(trade_offer_id);
create index if not exists credit_ledger_created_at_idx on public.credit_ledger(created_at);
create index if not exists app_events_date_idx on public.app_events(event_date);
create index if not exists app_events_owner_idx on public.app_events(owner_id);
create index if not exists app_events_visibility_idx on public.app_events(visibility);
create index if not exists app_events_created_at_idx on public.app_events(created_at);
create index if not exists safety_reports_reporter_idx on public.safety_reports(reporter_id);
create index if not exists safety_reports_reported_profile_idx on public.safety_reports(reported_profile_id);
create index if not exists safety_reports_marketplace_listing_idx on public.safety_reports(marketplace_listing_id);
create index if not exists safety_reports_trade_offer_idx on public.safety_reports(trade_offer_id);
create index if not exists safety_reports_status_idx on public.safety_reports(status);
create index if not exists safety_reports_created_at_idx on public.safety_reports(created_at);
create index if not exists verification_requests_user_id_idx on public.verification_requests(user_id);
create index if not exists verification_requests_status_idx on public.verification_requests(status);
create index if not exists verification_requests_submitted_at_idx on public.verification_requests(submitted_at);
create index if not exists verification_requests_reviewed_by_idx on public.verification_requests(reviewed_by);

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
alter table public.verification_requests enable row level security;

create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.handle_updated_at();
drop trigger if exists card_sets_updated_at on public.card_sets;
create trigger card_sets_updated_at before update on public.card_sets for each row execute function public.handle_updated_at();
drop trigger if exists cards_updated_at on public.cards;
create trigger cards_updated_at before update on public.cards for each row execute function public.handle_updated_at();
drop trigger if exists collection_items_updated_at on public.collection_items;
create trigger collection_items_updated_at before update on public.collection_items for each row execute function public.handle_updated_at();
drop trigger if exists wishlist_items_updated_at on public.wishlist_items;
create trigger wishlist_items_updated_at before update on public.wishlist_items for each row execute function public.handle_updated_at();
drop trigger if exists friend_requests_updated_at on public.friend_requests;
create trigger friend_requests_updated_at before update on public.friend_requests for each row execute function public.handle_updated_at();
drop trigger if exists friendships_updated_at on public.friendships;
create trigger friendships_updated_at before update on public.friendships for each row execute function public.handle_updated_at();
drop trigger if exists binder_pages_updated_at on public.binder_pages;
create trigger binder_pages_updated_at before update on public.binder_pages for each row execute function public.handle_updated_at();
drop trigger if exists binder_slots_updated_at on public.binder_slots;
create trigger binder_slots_updated_at before update on public.binder_slots for each row execute function public.handle_updated_at();
drop trigger if exists trade_offers_updated_at on public.trade_offers;
create trigger trade_offers_updated_at before update on public.trade_offers for each row execute function public.handle_updated_at();
drop trigger if exists trade_offer_items_updated_at on public.trade_offer_items;
create trigger trade_offer_items_updated_at before update on public.trade_offer_items for each row execute function public.handle_updated_at();
drop trigger if exists marketplace_listings_updated_at on public.marketplace_listings;
create trigger marketplace_listings_updated_at before update on public.marketplace_listings for each row execute function public.handle_updated_at();
drop trigger if exists reputation_events_updated_at on public.reputation_events;
create trigger reputation_events_updated_at before update on public.reputation_events for each row execute function public.handle_updated_at();
drop trigger if exists credit_ledger_updated_at on public.credit_ledger;
create trigger credit_ledger_updated_at before update on public.credit_ledger for each row execute function public.handle_updated_at();
drop trigger if exists app_events_updated_at on public.app_events;
create trigger app_events_updated_at before update on public.app_events for each row execute function public.handle_updated_at();
drop trigger if exists safety_reports_updated_at on public.safety_reports;
create trigger safety_reports_updated_at before update on public.safety_reports for each row execute function public.handle_updated_at();
drop trigger if exists verification_requests_updated_at on public.verification_requests;
create trigger verification_requests_updated_at before update on public.verification_requests for each row execute function public.handle_updated_at();
