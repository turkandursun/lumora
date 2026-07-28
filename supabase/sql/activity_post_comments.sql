-- ============================================================================
-- Comments for the "Paylaşımlar" (Instagram-style shared feed).
-- Run this once in the Supabase SQL editor, AFTER activity_posts.sql.
-- ============================================================================

-- 1) Comments table ----------------------------------------------------------
create table if not exists public.activity_post_comments (
  id           uuid primary key default gen_random_uuid(),
  post_id      uuid not null references public.activity_posts(id) on delete cascade,
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  display_name text not null,
  text         text not null,
  created_at   timestamptz not null default now()
);

-- Fast lookup of a post's comments in chronological order.
create index if not exists activity_post_comments_post_id_idx
  on public.activity_post_comments (post_id, created_at);

alter table public.activity_post_comments enable row level security;

-- Any signed-in user can read comments.
drop policy if exists "read comments" on public.activity_post_comments;
create policy "read comments" on public.activity_post_comments
  for select to authenticated using (true);

-- Users may add their own comments.
drop policy if exists "insert own comments" on public.activity_post_comments;
create policy "insert own comments" on public.activity_post_comments
  for insert to authenticated with check (auth.uid() = user_id);

-- Users may delete their own comments.
drop policy if exists "delete own comments" on public.activity_post_comments;
create policy "delete own comments" on public.activity_post_comments
  for delete to authenticated using (auth.uid() = user_id);
