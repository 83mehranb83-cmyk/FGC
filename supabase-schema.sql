-- FGC shared database schema for Supabase
-- Run in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'member' check (role in ('member','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  report_date text not null,
  site text not null default '',
  clock_in time,
  clock_out time,
  work_hours numeric(6,2) not null default 0 check (work_hours >= 0),
  deposit numeric(14,0) not null default 0 check (deposit >= 0),
  description text not null default '',
  photo_paths text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, report_date)
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''), 'member')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_fgc_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.reports enable row level security;

drop policy if exists "Read own profile or admin" on public.profiles;
create policy "Read own profile or admin" on public.profiles
for select to authenticated
using (id = (select auth.uid()) or public.is_fgc_admin());

drop policy if exists "Update own profile name" on public.profiles;
create policy "Update own profile name" on public.profiles
for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()) and role = 'member');

drop policy if exists "Read own reports or admin" on public.reports;
create policy "Read own reports or admin" on public.reports
for select to authenticated
using (user_id = (select auth.uid()) or public.is_fgc_admin());

drop policy if exists "Create own reports" on public.reports;
create policy "Create own reports" on public.reports
for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Update own reports or admin" on public.reports;
create policy "Update own reports or admin" on public.reports
for update to authenticated
using (user_id = (select auth.uid()) or public.is_fgc_admin())
with check (user_id = (select auth.uid()) or public.is_fgc_admin());

drop policy if exists "Delete own reports or admin" on public.reports;
create policy "Delete own reports or admin" on public.reports
for delete to authenticated
using (user_id = (select auth.uid()) or public.is_fgc_admin());

-- After you create your account, make yourself an admin using your user UUID:
-- update public.profiles set role = 'admin' where id = 'YOUR-AUTH-USER-UUID';
