alter table public.profiles enable row level security;

drop policy if exists "profiles are readable by signed in users" on public.profiles;
create policy "profiles are readable by signed in users"
on public.profiles
for select
to authenticated
using (true);

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

