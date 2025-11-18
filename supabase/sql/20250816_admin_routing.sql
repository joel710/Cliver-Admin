-- Admin flag already present in user_profiles; ensure it exists and add index
alter table if exists public.user_profiles
  add column if not exists is_admin boolean not null default false;
create index if not exists idx_user_profiles_is_admin on public.user_profiles(is_admin);

-- Helper: get any admin id
create or replace function public.get_any_admin_id() returns uuid
language sql stable as $$
  select id from public.user_profiles where is_admin = true limit 1
$$;

-- =============================
-- Positions temps réel (livreurs et clients)
-- =============================

-- Table positions_livreurs: stocke la dernière position connue d'un livreur
create table if not exists public.positions_livreurs (
  user_id uuid primary key references auth.users(id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  accuracy double precision,
  is_online boolean not null default true,
  last_seen timestamptz not null default now()
);
create index if not exists idx_positions_livreurs_last_seen on public.positions_livreurs(last_seen desc);
create index if not exists idx_positions_livreurs_online on public.positions_livreurs(is_online);

alter table if exists public.positions_livreurs enable row level security;

drop policy if exists pos_livreurs_admin_all on public.positions_livreurs;
drop policy if exists pos_livreurs_owner_rw on public.positions_livreurs;
drop policy if exists pos_livreurs_read_admin_only on public.positions_livreurs;

-- Admin: accès complet
create policy pos_livreurs_admin_all on public.positions_livreurs
  for all to authenticated
  using (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin))
  with check (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));

-- Propriétaire: peut lire/insérer/mettre à jour sa ligne (clé = user_id)
create policy pos_livreurs_owner_rw on public.positions_livreurs
  for select using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Table positions_clients: optionnel pour analyser activité clients
create table if not exists public.positions_clients (
  user_id uuid primary key references auth.users(id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  accuracy double precision,
  is_online boolean not null default true,
  last_seen timestamptz not null default now()
);
create index if not exists idx_positions_clients_last_seen on public.positions_clients(last_seen desc);
create index if not exists idx_positions_clients_online on public.positions_clients(is_online);

alter table if exists public.positions_clients enable row level security;

drop policy if exists pos_clients_admin_all on public.positions_clients;
drop policy if exists pos_clients_owner_rw on public.positions_clients;

-- Admin: accès complet
create policy pos_clients_admin_all on public.positions_clients
  for all to authenticated
  using (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin))
  with check (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));

-- Propriétaire: peut lire/insérer/mettre à jour sa ligne
create policy pos_clients_owner_rw on public.positions_clients
  for select using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- =============================
-- Row Level Security (RLS)
-- =============================

-- Enable RLS on support tables
alter table if exists public.tickets_support enable row level security;
alter table if exists public.commentaires_tickets enable row level security;

-- Helper predicate reused in policies: current user is admin
-- (We inline the EXISTS expression in each policy for performance and simplicity.)

-- Clean previous policies to avoid duplicates
drop policy if exists tickets_admin_all on public.tickets_support;
drop policy if exists tickets_read_mine on public.tickets_support;
drop policy if exists tickets_insert_mine on public.tickets_support;
drop policy if exists tickets_update_admin_or_assignee on public.tickets_support;
drop policy if exists tickets_delete_admin on public.tickets_support;

drop policy if exists comments_admin_all on public.commentaires_tickets;
drop policy if exists comments_read_related on public.commentaires_tickets;
drop policy if exists comments_insert_related on public.commentaires_tickets;
drop policy if exists comments_update_owner_or_admin on public.commentaires_tickets;
drop policy if exists comments_delete_owner_or_admin on public.commentaires_tickets;

-- tickets_support policies
-- Admin full access split by command
create policy tickets_admin_select on public.tickets_support
  for select to authenticated
  using (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));
create policy tickets_admin_insert on public.tickets_support
  for insert to authenticated
  with check (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));
create policy tickets_admin_update on public.tickets_support
  for update to authenticated
  using (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin))
  with check (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));
create policy tickets_admin_delete on public.tickets_support
  for delete to authenticated
  using (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));

-- Read: livreur or assigned admin can read their tickets
create policy tickets_read_mine on public.tickets_support
  for select to authenticated
  using (livreur_id = auth.uid() or admin_assigne = auth.uid());

-- Insert: admin can insert any; livreur can create their own ticket
create policy tickets_insert_mine on public.tickets_support
  for insert to authenticated
  with check (
    exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin)
    or livreur_id = auth.uid()
  );

-- Update: only admin or assigned admin
create policy tickets_update_admin_or_assignee on public.tickets_support
  for update to authenticated
  using (
    exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin)
    or admin_assigne = auth.uid()
  )
  with check (
    exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin)
    or admin_assigne = auth.uid()
  );

-- Delete: admin only
create policy tickets_delete_admin on public.tickets_support
  for delete to authenticated
  using (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));

-- commentaires_tickets policies
-- Admin full access split by command
create policy comments_admin_select on public.commentaires_tickets
  for select to authenticated
  using (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));
create policy comments_admin_insert on public.commentaires_tickets
  for insert to authenticated
  with check (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));
create policy comments_admin_update on public.commentaires_tickets
  for update to authenticated
  using (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin))
  with check (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));
create policy comments_admin_delete on public.commentaires_tickets
  for delete to authenticated
  using (exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin));

-- Read: admin or users related to the ticket (livreur or assigned admin)
create policy comments_read_related on public.commentaires_tickets
  for select to authenticated
  using (
    exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin)
    or exists(
      select 1 from public.tickets_support t
      where t.id = commentaires_tickets.ticket_id
        and (t.livreur_id = auth.uid() or t.admin_assigne = auth.uid())
    )
  );

-- Insert: admin or users related to the ticket can add comments
create policy comments_insert_related on public.commentaires_tickets
  for insert to authenticated
  with check (
    exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin)
    or exists(
      select 1 from public.tickets_support t
      where t.id = commentaires_tickets.ticket_id
        and (t.livreur_id = auth.uid() or t.admin_assigne = auth.uid())
    )
  );

-- Update: admin or comment owner (admin_id)
create policy comments_update_owner_or_admin on public.commentaires_tickets
  for update to authenticated
  using (
    exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin)
    or admin_id = auth.uid()
  )
  with check (
    exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin)
    or admin_id = auth.uid()
  );

-- Delete: admin or comment owner
create policy comments_delete_owner_or_admin on public.commentaires_tickets
  for delete to authenticated
  using (
    exists(select 1 from public.user_profiles up where up.id = auth.uid() and up.is_admin)
    or admin_id = auth.uid()
  );

-- Support tickets table (used by app SupportService)
create table if not exists public.tickets_support (
  id uuid primary key default gen_random_uuid(),
  livreur_id uuid references auth.users(id),
  livreur_nom text,
  probleme text not null,
  priorite text not null default 'medium' check (priorite in ('low','medium','high','urgent')),
  statut text not null default 'open' check (statut in ('open','in_progress','resolved')),
  date_creation timestamptz not null default now(),
  date_resolution timestamptz,
  admin_assigne uuid references auth.users(id)
);
create index if not exists idx_tickets_support_statut on public.tickets_support(statut);
create index if not exists idx_tickets_support_priorite on public.tickets_support(priorite);

-- Ticket comments table (used by SupportService)
create table if not exists public.commentaires_tickets (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets_support(id) on delete cascade,
  admin_id uuid references auth.users(id),
  admin_nom text,
  commentaire text not null,
  date_creation timestamptz not null default now()
);
create index if not exists idx_commentaires_ticket_id on public.commentaires_tickets(ticket_id);

-- Assign admin automatically on new support tickets
create or replace function public.assign_admin_on_ticket_insert() returns trigger
language plpgsql as $$
declare admin_id uuid;
begin
  if new.admin_assigne is null then
    select public.get_any_admin_id() into admin_id;
    if admin_id is not null then
      new.admin_assigne := admin_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_assign_admin_tickets_support on public.tickets_support;
create trigger trg_assign_admin_tickets_support
before insert on public.tickets_support
for each row execute function public.assign_admin_on_ticket_insert();

-- Auto-assign admin for user reports (reviewer)
create or replace function public.assign_admin_on_user_report_insert() returns trigger
language plpgsql as $$
declare admin_id uuid;
begin
  if new.reviewer_id is null then
    select public.get_any_admin_id() into admin_id;
    if admin_id is not null then
      new.reviewer_id := admin_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_assign_admin_user_reports on public.user_reports;
create trigger trg_assign_admin_user_reports
before insert on public.user_reports
for each row execute function public.assign_admin_on_user_report_insert();

-- Simple notifier for new user_reports (compat with external triggers)
create or replace function public.notify_admin_new_report()
returns trigger as $$
begin
  -- Placeholder: emit a notice; downstream can hook into notifications table if desired
  raise notice 'Nouveau signalement (user_reports): reported_user=%, reporter=%', new.reported_user_id, new.reporter_id;
  return new;
end;
$$ language plpgsql;

-- Auto-route messages to admin for support/incident/bug categories via metadata
-- Expect metadata JSON like {"category": "support"}
create or replace function public.assign_admin_on_support_message() returns trigger
language plpgsql as $$
declare admin_id uuid;
        category text;
begin
  if new.metadata is not null then
    category := coalesce((new.metadata->>'category'), '');
    if category in ('support','incident','bug','report') then
      if new.receiver_id is null then
        select public.get_any_admin_id() into admin_id;
        if admin_id is not null then
          new.receiver_id := admin_id;
        end if;
      end if;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_assign_admin_support_messages on public.messages;
create trigger trg_assign_admin_support_messages
before insert on public.messages
for each row execute function public.assign_admin_on_support_message();

-- Notify admin upon new routed item (tickets, reports, messages)
create or replace function public.notify_admin_on_new_item() returns trigger
language plpgsql as $$
declare admin_id uuid;
        notif_type text;
        content text;
begin
  select public.get_any_admin_id() into admin_id;
  if admin_id is null then
    return new;
  end if;

  if TG_TABLE_NAME = 'tickets_support' then
    notif_type := 'support_ticket';
    content := 'Nouveau ticket de support: ' || coalesce(new.probleme,'');
  elsif TG_TABLE_NAME = 'user_reports' then
    notif_type := 'user_report';
    content := 'Nouveau signalement utilisateur';
  elsif TG_TABLE_NAME = 'messages' then
    notif_type := 'support_message';
    content := 'Nouveau message de support';
  else
    return new;
  end if;

  insert into public.notifications(user_id, type, content)
  values (admin_id, notif_type, content);
  return new;
end;
$$;

drop trigger if exists trg_notify_admin_tickets_support on public.tickets_support;
create trigger trg_notify_admin_tickets_support
after insert on public.tickets_support
for each row execute function public.notify_admin_on_new_item();

drop trigger if exists trg_notify_admin_user_reports on public.user_reports;
create trigger trg_notify_admin_user_reports
after insert on public.user_reports
for each row execute function public.notify_admin_on_new_item();

drop trigger if exists trg_notify_admin_messages on public.messages;
create trigger trg_notify_admin_messages
after insert on public.messages
for each row execute function public.notify_admin_on_new_item();

-- Optional: add blocked flag for users to track blocked persons (if desired)
alter table if exists public.user_profiles
  add column if not exists is_blocked boolean not null default false;
create index if not exists idx_user_profiles_is_blocked on public.user_profiles(is_blocked);

-- Dashboard stats RPC combining livreurs + clients quickly
create or replace function public.admin_dashboard_counts()
returns jsonb
language plpgsql stable as $$
declare r jsonb;
begin
  r := jsonb_build_object(
    'total_livreurs', (select count(1) from public.user_profiles where role = 'livreur'),
    'total_clients', (select count(1) from public.user_profiles where role = 'client'),
    'clients_blocked', (select count(1) from public.user_profiles where role = 'client' and is_blocked = true),
    'kyc_pending', (select count(1) from public.livreur_kyc_submissions where status = 'pending'),
    'kyc_approved', (select count(1) from public.livreur_kyc_submissions where status = 'approved'),
    'missions_actives', (select count(1) from public.missions where status in ('en_livraison','attribuée')),
    'missions_today', (select count(1) from public.missions where created_at >= now() - interval '1 day'),
    'missions_month', (select count(1) from public.missions where created_at >= now() - interval '30 days'),
    'revenue_today', coalesce((select sum(prix) from public.missions where created_at >= now() - interval '1 day'), 0),
    'revenue_month', coalesce((select sum(prix) from public.missions where created_at >= now() - interval '30 days'), 0)
  );
  return r;
end;
$$;
