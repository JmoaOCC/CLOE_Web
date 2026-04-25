-- C.L.O.E. COACH
-- Pega este archivo completo en Supabase SQL Editor y ejecútalo.

create table if not exists profiles (
  id           uuid references auth.users on delete cascade primary key,
  full_name    text,
  email        text,
  role         text default 'user',
  status       text default 'pending',
  week         integer default 1,
  age          integer,
  sex          text,
  weight_kg    numeric,
  height_cm    integer,
  goal         text,
  notes        text,
  week1_plan   text,
  current_plan text,
  created_at   timestamptz default now()
);

alter table profiles enable row level security;

create or replace function is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

drop policy if exists "own profile" on profiles;
create policy "own profile"
  on profiles for all
  using (auth.uid() = id);

drop policy if exists "admin all" on profiles;
create policy "admin all"
  on profiles for all
  using (is_admin())
  with check (is_admin());

create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.email)
  )
  on conflict (id) do update
  set email = excluded.email,
      full_name = excluded.full_name;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
