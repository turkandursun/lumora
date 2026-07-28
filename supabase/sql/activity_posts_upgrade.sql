-- ============================================================================
-- Upgrade for the "Paylaşımlar" feed: multiple photos per post, a public/
-- private visibility choice, and likes.
-- Run this once in the Supabase SQL editor, AFTER activity_posts.sql.
-- ============================================================================

-- 1) New columns on activity_posts -------------------------------------------
-- image_urls: JSON array of photo URLs (image_url stays as the first photo,
-- for backward compatibility with older rows).
alter table public.activity_posts
  add column if not exists image_urls jsonb not null default '[]'::jsonb;

-- is_public: whether the post shows in everyone's feed. When false, only the
-- author sees it.
alter table public.activity_posts
  add column if not exists is_public boolean not null default true;

-- 2) Visibility policy -------------------------------------------------------
-- Replace the old "everyone can read every post" policy with one that hides
-- private posts from everyone except their author.
drop policy if exists "read posts" on public.activity_posts;
create policy "read posts" on public.activity_posts
  for select to authenticated
  using (is_public = true or auth.uid() = user_id);

-- 3) Likes table -------------------------------------------------------------
create table if not exists public.activity_post_likes (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.activity_posts(id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

create index if not exists activity_post_likes_post_id_idx
  on public.activity_post_likes (post_id);

alter table public.activity_post_likes enable row level security;

-- Any signed-in user can read likes (to show counts).
drop policy if exists "read likes" on public.activity_post_likes;
create policy "read likes" on public.activity_post_likes
  for select to authenticated using (true);

-- Users may like (insert) as themselves.
drop policy if exists "insert own like" on public.activity_post_likes;
create policy "insert own like" on public.activity_post_likes
  for insert to authenticated with check (auth.uid() = user_id);

-- Users may remove their own like.
drop policy if exists "delete own like" on public.activity_post_likes;
create policy "delete own like" on public.activity_post_likes
  for delete to authenticated using (auth.uid() = user_id);
