-- Release Day 1: decommission the unreachable free-form community feed.
-- Existing rows are intentionally preserved. Client roles lose every table,
-- view and reporting-function capability; service-role/admin access is not
-- changed by this migration.

alter table public.community_posts enable row level security;
alter table public.community_post_reactions enable row level security;
alter table public.community_post_replies enable row level security;

drop policy if exists "insert own posts" on public.community_posts;
drop policy if exists "read non-flagged or own posts" on public.community_posts;
drop policy if exists "delete own posts" on public.community_posts;

drop policy if exists "insert own reactions" on public.community_post_reactions;
drop policy if exists "read all reactions" on public.community_post_reactions;
drop policy if exists "delete own reactions" on public.community_post_reactions;

drop policy if exists "insert own replies" on public.community_post_replies;
drop policy if exists "read non-flagged or own replies" on public.community_post_replies;
drop policy if exists "delete own replies" on public.community_post_replies;

revoke all privileges on table public.community_posts
  from public, anon, authenticated;
revoke all privileges on table public.community_post_reactions
  from public, anon, authenticated;
revoke all privileges on table public.community_post_replies
  from public, anon, authenticated;
revoke all privileges on table public.community_posts_view
  from public, anon, authenticated;

revoke execute on function public.report_community_post(uuid)
  from public, anon, authenticated;
revoke execute on function public.report_community_reply(uuid)
  from public, anon, authenticated;
