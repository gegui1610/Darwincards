-- Darwin Cards V5.0 — execute no Supabase Dashboard > SQL Editor.
-- Usa Supabase Auth (sem tabela de senhas própria). Nunca exponha a chave service_role no HTML.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null default 'Jogador' check (char_length(username) between 2 and 24),
  avatar_url text,
  banner_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

create or replace function public.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare chosen text;
begin
  chosen := coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), split_part(new.email, '@', 1), 'Jogador');
  insert into public.profiles (id, username) values (new.id, left(chosen, 24))
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile after insert on auth.users
for each row execute function public.create_profile_for_new_user();

alter table public.profiles enable row level security;
drop policy if exists "Profiles are viewable by everyone" on public.profiles;
create policy "Profiles are viewable by everyone" on public.profiles for select using (true);
drop policy if exists "Users insert their own profile" on public.profiles;
create policy "Users insert their own profile" on public.profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "Users update their own profile" on public.profiles;
create policy "Users update their own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

revoke all on table public.profiles from anon, authenticated;
grant select on public.profiles to anon, authenticated;
grant insert, update on public.profiles to authenticated;

create table if not exists public.player_decks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 40),
  cards jsonb not null,
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint deck_cards_shape check (
    jsonb_typeof(cards) = 'object'
    and jsonb_typeof(cards -> 'someone') = 'array'
    and jsonb_typeof(cards -> 'non_someone') = 'array'
    and jsonb_array_length(cards -> 'someone') >= 6
    and jsonb_array_length(cards -> 'non_someone') >= 13
  )
);
create index if not exists player_decks_owner_updated on public.player_decks(owner_id, updated_at desc);
drop trigger if exists player_decks_set_updated_at on public.player_decks;
create trigger player_decks_set_updated_at before update on public.player_decks
for each row execute function public.set_updated_at();

alter table public.player_decks enable row level security;
drop policy if exists "Owners and public decks can be read" on public.player_decks;
create policy "Owners and public decks can be read" on public.player_decks for select to authenticated
using (owner_id = auth.uid() or is_public = true);
drop policy if exists "Users create their own decks" on public.player_decks;
create policy "Users create their own decks" on public.player_decks for insert to authenticated
with check (owner_id = auth.uid());
drop policy if exists "Users update their own decks" on public.player_decks;
create policy "Users update their own decks" on public.player_decks for update to authenticated
using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "Users delete their own decks" on public.player_decks;
create policy "Users delete their own decks" on public.player_decks for delete to authenticated
using (owner_id = auth.uid());
revoke all on table public.player_decks from anon, authenticated;
grant select, insert, update, delete on public.player_decks to authenticated;

-- Buckets públicos para imagens exibidas em perfis. GIF e WebP preservam animação.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-media', 'profile-media', true, 8388608,
  array['image/gif','image/webp','image/png','image/jpeg'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Profile media is publicly readable" on storage.objects;
create policy "Profile media is publicly readable" on storage.objects for select
using (bucket_id = 'profile-media');
drop policy if exists "Users upload media to their own folder" on storage.objects;
create policy "Users upload media to their own folder" on storage.objects for insert to authenticated
with check (bucket_id = 'profile-media' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "Users update media in their own folder" on storage.objects;
create policy "Users update media in their own folder" on storage.objects for update to authenticated
using (bucket_id = 'profile-media' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'profile-media' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "Users delete media in their own folder" on storage.objects;
create policy "Users delete media in their own folder" on storage.objects for delete to authenticated
using (bucket_id = 'profile-media' and (storage.foldername(name))[1] = auth.uid()::text);
