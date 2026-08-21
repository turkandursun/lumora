-- ASTRA Special Days: account-owned calendar dates.
-- Apply manually in Supabase before releasing the Flutter client.

begin;

create table if not exists public.special_days (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  day_type text not null,
  event_date date not null,
  repeats_annually boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint special_days_title_length
    check (char_length(btrim(title)) between 1 and 80),
  constraint special_days_type_allowed
    check (day_type in ('birthday', 'wedding', 'anniversary', 'custom'))
);

create index if not exists special_days_user_event_date_idx
  on public.special_days (user_id, event_date);

create unique index if not exists special_days_one_birthday_per_user
  on public.special_days (user_id)
  where day_type = 'birthday';

create or replace function public.set_special_days_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists special_days_set_updated_at on public.special_days;
create trigger special_days_set_updated_at
before update on public.special_days
for each row execute function public.set_special_days_updated_at();

alter table public.special_days enable row level security;
alter table public.special_days force row level security;

drop policy if exists "special_days_select_own" on public.special_days;
create policy "special_days_select_own"
on public.special_days
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "special_days_insert_own" on public.special_days;
create policy "special_days_insert_own"
on public.special_days
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "special_days_update_own" on public.special_days;
create policy "special_days_update_own"
on public.special_days
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "special_days_delete_own" on public.special_days;
create policy "special_days_delete_own"
on public.special_days
for delete
to authenticated
using ((select auth.uid()) = user_id);

revoke all on table public.special_days from public, anon, authenticated;
grant select, insert, update, delete on table public.special_days
  to authenticated;

commit;
