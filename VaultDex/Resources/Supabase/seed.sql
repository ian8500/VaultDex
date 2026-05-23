insert into public.card_sets (id, name, code, release_year, total_cards, description)
values
  ('10000000-0000-0000-0000-000000000001', 'Radiant Archive', 'RAD', 2026, 120, 'A gold-lit showcase set for premium binders.'),
  ('10000000-0000-0000-0000-000000000002', 'Midnight Circuit', 'MID', 2026, 96, 'Electric night-market cards with glossy foil variants.'),
  ('10000000-0000-0000-0000-000000000003', 'Verdant Skies', 'VRD', 2025, 84, 'Leaf, sky, and dragon-themed cards for friendly collectors.')
on conflict (id) do update
set
  name = excluded.name,
  code = excluded.code,
  release_year = excluded.release_year,
  total_cards = excluded.total_cards,
  description = excluded.description,
  updated_at = now();

insert into public.cards (id, set_id, name, number, rarity, card_type, type_line, power, market_value, accent, image_path)
values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Solaris Wyrm', '001', 'mythic', 'dragon', 'Dragon / Radiant', 980, 142.50, 'solar', null),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'Amber Sprite', '014', 'rare', 'fire', 'Fire / Companion', 410, 18.75, 'ember', null),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'Moonlit Vault', '077', 'legendary', 'psychic', 'Psychic / Relic', 760, 96.00, 'void', null),
  ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000002', 'Circuit Lynx', '009', 'epic', 'electric', 'Electric / Scout', 640, 44.25, 'aurora', null),
  ('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', 'Harbor Sentinel', '033', 'uncommon', 'water', 'Water / Guardian', 280, 6.50, 'frost', null),
  ('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000002', 'Ashen Contract', '091', 'rare', 'dark', 'Dark / Trick', 510, 22.00, 'void', null),
  ('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000003', 'Canopy Cub', '004', 'common', 'grass', 'Grass / Companion', 120, 2.25, 'solar', null),
  ('20000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000003', 'Skyforge Golem', '040', 'epic', 'metal', 'Metal / Construct', 690, 38.40, 'aurora', null),
  ('20000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000003', 'Cloudstep Runner', '052', 'uncommon', 'colorless', 'Colorless / Swift', 260, 5.75, 'frost', null),
  ('20000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000003', 'Leaf Crown Elder', '083', 'legendary', 'grass', 'Grass / Ancient', 810, 88.90, 'solar', null)
on conflict (id) do update
set
  set_id = excluded.set_id,
  name = excluded.name,
  number = excluded.number,
  rarity = excluded.rarity,
  card_type = excluded.card_type,
  type_line = excluded.type_line,
  power = excluded.power,
  market_value = excluded.market_value,
  accent = excluded.accent,
  image_path = excluded.image_path,
  updated_at = now();

insert into public.marketplace_listings (
  id,
  owner_id,
  card_id,
  title,
  condition,
  variant,
  rarity,
  estimated_value,
  asking_for,
  seller_display_name,
  seller_reputation,
  location_label,
  is_public,
  uses_safe_trade,
  status
)
values
  (
    '30000000-0000-0000-0000-000000000001',
    null,
    '20000000-0000-0000-0000-000000000001',
    'Solaris Wyrm Holo Trade',
    'nearMint',
    'holo',
    'mythic',
    148.00,
    'Looking for legendary grass or psychic grails.',
    'Mara Demo',
    98,
    'London, UK',
    true,
    true,
    'active'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    null,
    '20000000-0000-0000-0000-000000000004',
    'Circuit Lynx Full Art',
    'mint',
    'fullArt',
    'epic',
    52.00,
    'Open to fair value bundles.',
    'Theo Demo',
    94,
    'Manchester, UK',
    true,
    false,
    'active'
  ),
  (
    '30000000-0000-0000-0000-000000000003',
    null,
    '20000000-0000-0000-0000-000000000010',
    'Leaf Crown Elder Binder Copy',
    'excellent',
    'reverseHolo',
    'legendary',
    74.50,
    'Seeking Midnight Circuit rares.',
    'Lena Demo',
    99,
    'Bristol, UK',
    true,
    true,
    'active'
  )
on conflict (id) do update
set
  card_id = excluded.card_id,
  title = excluded.title,
  condition = excluded.condition,
  variant = excluded.variant,
  rarity = excluded.rarity,
  estimated_value = excluded.estimated_value,
  asking_for = excluded.asking_for,
  seller_display_name = excluded.seller_display_name,
  seller_reputation = excluded.seller_reputation,
  location_label = excluded.location_label,
  is_public = excluded.is_public,
  uses_safe_trade = excluded.uses_safe_trade,
  status = excluded.status,
  updated_at = now();

insert into public.app_events (
  id,
  owner_id,
  event_date,
  title,
  emoji_marker,
  location,
  notes,
  visibility,
  kind,
  attending_friends
)
values
  (
    '40000000-0000-0000-0000-000000000001',
    null,
    now() + interval '7 days',
    'VaultDex Saturday Trade Night',
    '*',
    'London Card Hall',
    'Friendly swap tables, parent-friendly safety desk, and binder showcases.',
    'public',
    'tradeNight',
    12
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    null,
    now() + interval '21 days',
    'Radiant Archive Completion Meetup',
    '#',
    'Bristol Collectors Cafe',
    'Bring want lists and duplicate rare cards for fair local trades.',
    'public',
    'meetup',
    8
  ),
  (
    '40000000-0000-0000-0000-000000000003',
    null,
    now() + interval '35 days',
    'Binder Design Showcase',
    '+',
    'Online',
    'Share your best 3x3 page layouts and vote on premium binder themes.',
    'public',
    'showcase',
    24
  )
on conflict (id) do update
set
  event_date = excluded.event_date,
  title = excluded.title,
  emoji_marker = excluded.emoji_marker,
  location = excluded.location,
  notes = excluded.notes,
  visibility = excluded.visibility,
  kind = excluded.kind,
  attending_friends = excluded.attending_friends,
  updated_at = now();
