-- Dilemma votes — real, app-users-only crowd stats for the Dilemma Swipe
--
-- Paste this whole file into Supabase's SQL Editor and run it once. Records
-- one vote per user per dilemma and exposes ONLY aggregate counts (never other
-- users' individual votes) through a SECURITY DEFINER function.

create table if not exists public.dilemma_votes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  dilemma_id int not null,
  choice text not null check (choice in ('left', 'right')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, dilemma_id)
);

create index if not exists dilemma_votes_dilemma_idx
  on public.dilemma_votes (dilemma_id);

alter table public.dilemma_votes enable row level security;

-- A user may insert / update / read only their OWN vote. Aggregate counts for
-- everyone come from get_dilemma_stats() below, so no one can read another
-- user's individual choice.
drop policy if exists "insert own vote" on public.dilemma_votes;
create policy "insert own vote" on public.dilemma_votes
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "update own vote" on public.dilemma_votes;
create policy "update own vote" on public.dilemma_votes
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "read own vote" on public.dilemma_votes;
create policy "read own vote" on public.dilemma_votes
  for select to authenticated using (auth.uid() = user_id);

-- Aggregate counts for one dilemma across ALL app users. SECURITY DEFINER so
-- it can count every row while the table's RLS keeps individual votes private.
create or replace function public.get_dilemma_stats(p_dilemma_id int)
returns table (left_count bigint, right_count bigint)
language sql
security definer
set search_path = public
as $$
  select
    count(*) filter (where choice = 'left')  as left_count,
    count(*) filter (where choice = 'right') as right_count
  from public.dilemma_votes
  where dilemma_id = p_dilemma_id;
$$;

revoke all on function public.get_dilemma_stats(int) from public;
grant execute on function public.get_dilemma_stats(int) to authenticated;
