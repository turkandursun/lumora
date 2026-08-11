-- Safe Space Community — free-form anonymous posts, reactions & replies
--
-- Paste this whole file into Supabase's SQL Editor and run it once. Extends
-- the "Safe Space Community" beyond the Daily Question feed with:
--   * community_posts          — free-form anonymous posts
--   * community_post_reactions — gentle "heart" / "hug" reactions
--   * community_post_replies   — short, supportive anonymous replies
--
-- Anonymity model matches daily_question_shares: rows carry user_id (RLS
-- needs it, the client never reads it back) and everything shown in the feed
-- is the generated display_name. Reporting goes through SECURITY DEFINER
-- functions that only ever flip is_flagged to true — never a raw UPDATE
-- policy, which couldn't restrict which columns get rewritten.

-- ─────────────────────────────── Posts ────────────────────────────────
create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  display_name text not null,
  body text not null,
  created_at timestamptz not null default now(),
  is_flagged boolean not null default false
);

create index if not exists community_posts_created_at_idx
  on public.community_posts (created_at desc);

alter table public.community_posts enable row level security;

drop policy if exists "insert own posts" on public.community_posts;
create policy "insert own posts" on public.community_posts
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "read non-flagged or own posts" on public.community_posts;
create policy "read non-flagged or own posts" on public.community_posts
  for select to authenticated using (is_flagged = false or auth.uid() = user_id);

drop policy if exists "delete own posts" on public.community_posts;
create policy "delete own posts" on public.community_posts
  for delete to authenticated using (auth.uid() = user_id);

-- ───────────────────────────── Reactions ──────────────────────────────
create table if not exists public.community_post_reactions (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  kind text not null check (kind in ('heart', 'hug')),
  created_at timestamptz not null default now(),
  unique (post_id, user_id, kind)
);

create index if not exists community_post_reactions_post_idx
  on public.community_post_reactions (post_id);

alter table public.community_post_reactions enable row level security;

drop policy if exists "insert own reactions" on public.community_post_reactions;
create policy "insert own reactions" on public.community_post_reactions
  for insert to authenticated with check (auth.uid() = user_id);

-- Reactions are anonymous counters; any authenticated user may read them so
-- the feed can show totals and whether the viewer already reacted.
drop policy if exists "read all reactions" on public.community_post_reactions;
create policy "read all reactions" on public.community_post_reactions
  for select to authenticated using (true);

drop policy if exists "delete own reactions" on public.community_post_reactions;
create policy "delete own reactions" on public.community_post_reactions
  for delete to authenticated using (auth.uid() = user_id);

-- ────────────────────────────── Replies ───────────────────────────────
create table if not exists public.community_post_replies (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  display_name text not null,
  body text not null,
  created_at timestamptz not null default now(),
  is_flagged boolean not null default false
);

create index if not exists community_post_replies_post_idx
  on public.community_post_replies (post_id, created_at);

alter table public.community_post_replies enable row level security;

drop policy if exists "insert own replies" on public.community_post_replies;
create policy "insert own replies" on public.community_post_replies
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "read non-flagged or own replies" on public.community_post_replies;
create policy "read non-flagged or own replies" on public.community_post_replies
  for select to authenticated using (is_flagged = false or auth.uid() = user_id);

drop policy if exists "delete own replies" on public.community_post_replies;
create policy "delete own replies" on public.community_post_replies
  for delete to authenticated using (auth.uid() = user_id);

-- ───────────────── Feed view (counts + viewer's reactions) ─────────────
-- security_invoker so base-table RLS still applies to the caller.
create or replace view public.community_posts_view
with (security_invoker = true) as
select
  p.id,
  p.display_name,
  p.body,
  p.created_at,
  p.user_id,
  coalesce((select count(*) from public.community_post_reactions r
            where r.post_id = p.id and r.kind = 'heart'), 0) as heart_count,
  coalesce((select count(*) from public.community_post_reactions r
            where r.post_id = p.id and r.kind = 'hug'), 0)   as hug_count,
  exists(select 1 from public.community_post_reactions r
         where r.post_id = p.id and r.kind = 'heart' and r.user_id = auth.uid()) as viewer_hearted,
  exists(select 1 from public.community_post_reactions r
         where r.post_id = p.id and r.kind = 'hug' and r.user_id = auth.uid())   as viewer_hugged,
  coalesce((select count(*) from public.community_post_replies rp
            where rp.post_id = p.id and rp.is_flagged = false), 0) as reply_count
from public.community_posts p
where p.is_flagged = false;

grant select on public.community_posts_view to authenticated;

-- ──────────────────────── Moderation (report) ─────────────────────────
create or replace function public.report_community_post(post_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.community_posts set is_flagged = true where id = post_id;
end;
$$;
revoke all on function public.report_community_post(uuid) from public;
grant execute on function public.report_community_post(uuid) to authenticated;

create or replace function public.report_community_reply(reply_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.community_post_replies set is_flagged = true where id = reply_id;
end;
$$;
revoke all on function public.report_community_reply(uuid) from public;
grant execute on function public.report_community_reply(uuid) to authenticated;
