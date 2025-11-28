# Supabase Setup for Chitchat

This project requires a `profiles` table and an `avatars` storage bucket with proper Row Level Security (RLS) policies.

Run the following SQL in Supabase (SQL Editor). You can paste and execute in small blocks if your instance does not support `IF EXISTS`/`IF NOT EXISTS` for policies.

---

-- 1) PROFILES TABLE
-- Create table (safe to run if table already exists)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text,
  about text,
  avatar_url text,
  created_at timestamp with time zone default now()
);

-- Ensure columns exist (no-op if already present)
alter table public.profiles
  add column if not exists display_name text,
  add column if not exists about text,
  add column if not exists avatar_url text;

-- Enable RLS
alter table public.profiles enable row level security;

-- Drop existing policies to avoid duplicates (optional)
-- drop policy if exists "profiles_select" on public.profiles;
-- drop policy if exists "profiles_insert_own" on public.profiles;
-- drop policy if exists "profiles_update_own" on public.profiles;

-- Read: allow everyone to view usernames (needed for search)
create policy "profiles_select" on public.profiles
  for select using (true);

-- Insert own row only (used when setting username first time)
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

-- Update own row only (edit display name/about/avatar_url)
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

---

-- 2) STORAGE BUCKET: avatars
-- Create public bucket for avatars (ignore error if it already exists)
-- Note: Re-run only once, ignore the error if bucket exists
select storage.create_bucket('avatars', public => true);

-- Storage RLS policies
-- (These apply to storage.objects underlying the bucket entries)

-- Drop (optional) to avoid duplicates
-- drop policy if exists "avatars_public_read" on storage.objects;
-- drop policy if exists "avatars_insert_own_folder" on storage.objects;
-- drop policy if exists "avatars_update_own_folder" on storage.objects;
-- drop policy if exists "avatars_delete_own_folder" on storage.objects;

-- Public read (serving via public URLs)
create policy "avatars_public_read"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- Allow authenticated users to upload to their own folder: <uid>/...
create policy "avatars_insert_own_folder"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid() is not null
    and name like auth.uid()::text || '/%'
  );

-- Allow updates to files in their own folder
create policy "avatars_update_own_folder"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid() is not null
    and name like auth.uid()::text || '/%'
  );

-- Optional: allow deleting files in own folder
create policy "avatars_delete_own_folder"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.uid() is not null
    and name like auth.uid()::text || '/%'
  );

---

# Verify
- Profiles: Run `select id, username from public.profiles limit 5;` should work.
- Storage: After sign-in, upload an avatar in Settings → Profile. The path will be `<uid>/<timestamp>.<ext>`.
- If upload still fails, check the exact message shown in-app (we surface Storage errors). Common causes:
  - Bucket not created, or different name than `avatars`.
  - Policies missing/duplicated; re-run the policy block (drop then create).
  - Signed-out user attempting upload (ensure you are authenticated).

# Notes
- If you prefer private avatars (no public URLs), set the bucket to private and switch to signed URLs in the app. We can update the code accordingly on request.
