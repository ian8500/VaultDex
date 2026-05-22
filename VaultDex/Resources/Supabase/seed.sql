insert into public.card_sets (id, name, code, release_year, total_cards)
values
  ('10000000-0000-0000-0000-000000000001', 'Nebula Crown', 'NBC', 2026, 182),
  ('10000000-0000-0000-0000-000000000002', 'Obsidian Keys', 'OSK', 2025, 144),
  ('10000000-0000-0000-0000-000000000003', 'Radiant Archive', 'RDA', 2024, 210)
on conflict (id) do update set
  name = excluded.name,
  code = excluded.code,
  release_year = excluded.release_year,
  total_cards = excluded.total_cards;

insert into public.cards (id, set_id, name, number, rarity, card_type, type_line, power, market_value, accent)
values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Astra Prime', '001', 'mythic', 'psychic', 'Celestial Vanguard', 98, 420.00, 'aurora'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'Gilded Revenant', '017', 'legendary', 'dark', 'Relic Warden', 91, 235.00, 'void'),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'Solaris Wyrm', '024', 'epic', 'dragon', 'Dragon Aspect', 86, 118.00, 'solar'),
  ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', 'Vesper Blade', '042', 'rare', 'dark', 'Shadow Artifact', 74, 62.00, 'void'),
  ('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000003', 'Emerald Oracle', '058', 'legendary', 'grass', 'Verdant Seer', 89, 196.00, 'venom'),
  ('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000002', 'Cinder Paladin', '063', 'epic', 'fire', 'Flame Knight', 82, 94.00, 'ember'),
  ('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000001', 'Glasswing Scout', '077', 'uncommon', 'colorless', 'Aerial Scout', 43, 14.00, 'frost'),
  ('20000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000002', 'Moonlit Vault', '088', 'rare', 'psychic', 'Hidden Location', 68, 49.00, 'aurora'),
  ('20000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000003', 'Ironroot Sentinel', '104', 'uncommon', 'metal', 'Ancient Guardian', 55, 9.00, 'venom'),
  ('20000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000001', 'Prism Courier', '121', 'common', 'electric', 'Arcane Runner', 28, 3.00, 'aurora'),
  ('20000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000002', 'Ashen Contract', '132', 'rare', 'fire', 'Forbidden Pact', 71, 58.00, 'ember'),
  ('20000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000003', 'Frostbound Crown', '166', 'mythic', 'water', 'Royal Relic', 96, 380.00, 'frost')
on conflict (id) do update set
  set_id = excluded.set_id,
  name = excluded.name,
  number = excluded.number,
  rarity = excluded.rarity,
  card_type = excluded.card_type,
  type_line = excluded.type_line,
  power = excluded.power,
  market_value = excluded.market_value,
  accent = excluded.accent;

