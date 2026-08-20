-- Release Day 1: keep the active Safe Space feed without exposing owner UUIDs.
--
-- Data is preserved. The base table remains available to an authenticated
-- owner for insert/select/delete operations on their own rows only. Everyone
-- reads the public feed through an explicit projection that never returns
-- user_id.

alter table public.daily_question_shares enable row level security;

drop policy if exists "Users can read non-flagged or own shares"
  on public.daily_question_shares;
drop policy if exists "Users can read own shares"
  on public.daily_question_shares;

create policy "Users can read own shares"
  on public.daily_question_shares
  for select
  to authenticated
  using (auth.uid() = user_id);

-- Do not let anon read the base table. Authenticated callers may select only
-- the non-sensitive columns below, and RLS still limits those reads to the
-- caller's own rows. In particular, user_id has no SELECT grant.
revoke all privileges on table public.daily_question_shares from public, anon;
revoke select on table public.daily_question_shares from authenticated;
grant insert, delete on table public.daily_question_shares to authenticated;
grant select (id, display_name, question_date, answer_text, created_at, is_flagged)
  on table public.daily_question_shares
  to authenticated;

create or replace function public.get_daily_question_shares_feed(
  p_question_date date
)
returns table (
  id uuid,
  display_name text,
  answer_text text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  return query
  select
    share.id,
    share.display_name,
    share.answer_text,
    share.created_at
  from public.daily_question_shares as share
  where share.question_date = p_question_date
    and share.is_flagged = false
  order by share.created_at desc;
end;
$$;

revoke all on function public.get_daily_question_shares_feed(date)
  from public, anon, authenticated;
grant execute on function public.get_daily_question_shares_feed(date)
  to authenticated;
