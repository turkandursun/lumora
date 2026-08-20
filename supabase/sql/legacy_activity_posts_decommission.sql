-- Release Day 1: decommission the unreachable Activity Posts feed.
-- Existing rows are intentionally preserved. Client roles lose all CRUD and
-- reporting access; service-role/admin access is unchanged.

alter table public.activity_posts enable row level security;
alter table public.activity_post_comments enable row level security;
alter table public.activity_post_likes enable row level security;

drop policy if exists "read posts" on public.activity_posts;
drop policy if exists "insert own posts" on public.activity_posts;
drop policy if exists "delete own posts" on public.activity_posts;
drop policy if exists "update own posts" on public.activity_posts;

drop policy if exists "read comments" on public.activity_post_comments;
drop policy if exists "insert own comments" on public.activity_post_comments;
drop policy if exists "delete own comments" on public.activity_post_comments;

drop policy if exists "read likes" on public.activity_post_likes;
drop policy if exists "insert own like" on public.activity_post_likes;
drop policy if exists "delete own like" on public.activity_post_likes;

revoke all privileges on table public.activity_posts
  from public, anon, authenticated;
revoke all privileges on table public.activity_post_comments
  from public, anon, authenticated;
revoke all privileges on table public.activity_post_likes
  from public, anon, authenticated;

revoke execute on function public.report_activity_post(uuid)
  from public, anon, authenticated;
