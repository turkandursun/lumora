-- ASTRA exact app-visit calendar days.
-- Run manually in the Supabase SQL editor. No historical dates are inferred
-- from profiles.visit_days_count or profiles.last_visit_date.

create table if not exists public.user_visit_days (
  user_id uuid not null references auth.users(id) on delete cascade,
  visit_date date not null,
  created_at timestamptz not null default now(),
  constraint user_visit_days_pkey primary key (user_id, visit_date)
);

create index if not exists user_visit_days_user_date_desc_idx
  on public.user_visit_days (user_id, visit_date desc);

alter table public.user_visit_days enable row level security;

drop policy if exists "user_visit_days_select_own"
  on public.user_visit_days;
create policy "user_visit_days_select_own"
  on public.user_visit_days
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "user_visit_days_insert_own"
  on public.user_visit_days;
create policy "user_visit_days_insert_own"
  on public.user_visit_days
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "user_visit_days_delete_own"
  on public.user_visit_days;
create policy "user_visit_days_delete_own"
  on public.user_visit_days
  for delete
  to authenticated
  using (auth.uid() = user_id);

revoke all on table public.user_visit_days from public, anon, authenticated;
grant select, insert, delete on table public.user_visit_days to authenticated;
