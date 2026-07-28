-- Daily Question Shares — "Safe Space Community" feature
--
-- Paste this whole file into Supabase's SQL Editor and run it once. Backs
-- the optional, anonymous community-sharing layer on top of the Daily
-- Question feature (features/daily_question, features/community).
--
-- Security note: reporting is NOT implemented as a raw `UPDATE` RLS policy
-- ("any authenticated user can set is_flagged = true on any row"), even
-- though that's the plain-English shape of the requirement. Postgres RLS
-- can't restrict which *columns* an UPDATE touches — only which *rows* are
-- visible — so a policy like `USING (true) WITH CHECK (true)` would let any
-- authenticated user rewrite any column on any row, including another
-- user's answer_text or display_name, not just flag it. Instead, flagging
-- goes through report_daily_question_share(uuid), a SECURITY DEFINER
-- function that only ever flips is_flagged to true and touches nothing
-- else — functionally identical to what was asked for, without the
-- column-tampering side door.

create table if not exists public.daily_question_shares (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  display_name text not null,
  question_date date not null,
  answer_text text not null,
  created_at timestamptz not null default now(),
  is_flagged boolean not null default false
);

create index if not exists daily_question_shares_question_date_idx
  on public.daily_question_shares (question_date);

alter table public.daily_question_shares enable row level security;

-- Any authenticated user can insert a row for themselves. user_id defaults
-- to auth.uid(), so the client never needs to (and can't usefully try to)
-- pass it explicitly.
drop policy if exists "Users can insert their own shares" on public.daily_question_shares;
create policy "Users can insert their own shares"
  on public.daily_question_shares
  for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Any authenticated user can read non-flagged rows, or their own rows even
-- if flagged (so they can still see what they posted).
drop policy if exists "Users can read non-flagged or own shares" on public.daily_question_shares;
create policy "Users can read non-flagged or own shares"
  on public.daily_question_shares
  for select
  to authenticated
  using (is_flagged = false or auth.uid() = user_id);

-- Only the row's own user_id can update it (e.g. this app never lets users
-- edit answer_text after sharing, but the client does delete+reinsert on
-- edit, and this covers any future direct-update need).
drop policy if exists "Users can update their own shares" on public.daily_question_shares;
create policy "Users can update their own shares"
  on public.daily_question_shares
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Only the row's own user_id can delete it (used when a user turns the
-- share toggle back off while editing an already-shared answer).
drop policy if exists "Users can delete their own shares" on public.daily_question_shares;
create policy "Users can delete their own shares"
  on public.daily_question_shares
  for delete
  to authenticated
  using (auth.uid() = user_id);

-- Simple community-moderation mechanism: any authenticated user can flag
-- any share as reported, but this function is the ONLY way to do it — it
-- only ever sets is_flagged to true, on the row identified by share_id, and
-- changes nothing else. SECURITY DEFINER lets it bypass the UPDATE policy
-- above (which is scoped to the row's own owner) for this one, narrow
-- purpose.
create or replace function public.report_daily_question_share(share_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.daily_question_shares
  set is_flagged = true
  where id = share_id;
end;
$$;

revoke all on function public.report_daily_question_share(uuid) from public;
grant execute on function public.report_daily_question_share(uuid) to authenticated;
