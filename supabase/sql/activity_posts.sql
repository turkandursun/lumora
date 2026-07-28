-- ============================================================================
-- "Paylaşımlar" (Instagram-style shared feed) backend.
-- Run this once in the Supabase SQL editor for your project.
-- ============================================================================

-- 1) Posts table -------------------------------------------------------------
create table if not exists public.activity_posts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  display_name text not null,
  caption      text,
  image_url    text,
  is_flagged   boolean not null default false,
  created_at   timestamptz not null default now()
);

alter table public.activity_posts enable row level security;

-- Any signed-in user can read the feed.
drop policy if exists "read posts" on public.activity_posts;
create policy "read posts" on public.activity_posts
  for select to authenticated using (true);

-- Users may create their own posts.
drop policy if exists "insert own posts" on public.activity_posts;
create policy "insert own posts" on public.activity_posts
  for insert to authenticated with check (auth.uid() = user_id);

-- Users may delete their own posts.
drop policy if exists "delete own posts" on public.activity_posts;
create policy "delete own posts" on public.activity_posts
  for delete to authenticated using (auth.uid() = user_id);

-- 2) Report/flag RPC (lets anyone flag without editing content) --------------
create or replace function public.report_activity_post(post_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.activity_posts set is_flagged = true where id = post_id;
$$;

-- 3) Storage bucket for post photos (public read) ----------------------------
insert into storage.buckets (id, name, public)
values ('activity-posts', 'activity-posts', true)
on conflict (id) do nothing;

drop policy if exists "upload post photos" on storage.objects;
create policy "upload post photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'activity-posts');

drop policy if exists "read post photos" on storage.objects;
create policy "read post photos" on storage.objects
  for select using (bucket_id = 'activity-posts');
