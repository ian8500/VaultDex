create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null,
  location text,
  bio text,
  collector_type text,
  avatar_path text,
  reputation_score integer not null default 0,
  trust_badges text[] not null default '{}',
  completed_trades integer not null default 0,
  collector_score integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.card_sets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  release_year integer not null,
  total_cards integer not null
);

create table if not exists public.cards (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references public.card_sets(id) on delete cascade,
  name text not null,
  number text not null,
  rarity text not null,
  card_type text not null,
  type_line text not null,
  power integer not null default 0,
  market_value numeric(12,2) not null default 0,
  accent text not null default 'aurora',
  image_path text,
  created_at timestamptz not null default now(),
  unique(set_id, number)
);

create table if not exists public.collection_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  card_id uuid not null references public.cards(id) on delete cascade,
  quantity integer not null default 1 check (quantity > 0),
  condition text not null default 'nearMint',
  variant text not null default 'normal',
  is_available_for_trade boolean not null default false,
  is_favorite boolean not null default false,
  acquired_at timestamptz not null default now(),
  notes text,
  unique(user_id, card_id, condition, variant)
);

create table if not exists public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  card_id uuid not null references public.cards(id) on delete cascade,
  priority text not null default 'medium',
  budget numeric(12,2) not null default 0,
  notes text not null default '',
  added_at timestamptz not null default now(),
  unique(user_id, card_id)
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (requester_id <> addressee_id),
  unique(requester_id, addressee_id)
);

create table if not exists public.binder_pages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  theme text not null default 'Custom vault layout',
  visibility text not null default 'private',
  slots jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.trade_listings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  card_id uuid not null references public.cards(id) on delete cascade,
  condition text not null default 'nearMint',
  variant text not null default 'normal',
  asking_for text not null default 'Open to fair offers',
  location_label text,
  seller_reputation integer not null default 0,
  is_public boolean not null default true,
  uses_safe_trade boolean not null default false,
  listed_at timestamptz not null default now()
);

create table if not exists public.trade_offers (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  offered_card_ids uuid[] not null default '{}',
  requested_card_ids uuid[] not null default '{}',
  internal_credits integer not null default 0 check (internal_credits >= 0),
  message text not null default '',
  status text not null default 'pending',
  uses_safe_trade boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.marketplace_listings (
  id uuid primary key default gen_random_uuid(),
  trade_listing_id uuid not null references public.trade_listings(id) on delete cascade,
  card_id uuid not null references public.cards(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  card_name text not null,
  rarity text not null,
  condition text not null,
  estimated_value numeric(12,2) not null default 0,
  seller_reputation integer not null default 0,
  created_at timestamptz not null default now(),
  unique(trade_listing_id)
);

create table if not exists public.saved_marketplace_listings (
  user_id uuid not null references public.profiles(id) on delete cascade,
  trade_listing_id uuid not null references public.trade_listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, trade_listing_id)
);

create table if not exists public.listing_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  trade_listing_id uuid not null references public.trade_listings(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  event_date timestamptz not null,
  emoji_marker text not null default '*',
  location text not null default '',
  notes text not null default '',
  visibility text not null default 'private',
  created_at timestamptz not null default now()
);

create table if not exists public.reputation (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  score integer not null default 0,
  completed_trades integer not null default 0,
  disputes_opened integer not null default 0,
  reports_received integer not null default 0,
  updated_at timestamptz not null default now()
);

create index if not exists cards_name_idx on public.cards using gin (to_tsvector('english', name));
create index if not exists collection_user_idx on public.collection_items(user_id);
create index if not exists wishlist_user_idx on public.wishlist_items(user_id);
create index if not exists trade_listings_public_idx on public.trade_listings(is_public, listed_at desc);
create index if not exists events_user_date_idx on public.events(user_id, event_date);

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('card-photos', 'card-photos', true)
on conflict (id) do nothing;

