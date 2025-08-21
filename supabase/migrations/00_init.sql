-- ================================
-- 00_init.sql - Initial schema for Supabase
-- ================================

-- Extensions
create extension if not exists pgcrypto;

-- ================================
-- Tables
-- ================================

-- Profiles table
create table if not exists public.profiles (
    id uuid primary key, -- mirrors auth.users.id
    email text unique not null,
    full_name text,
    avatar_url text,
    created_at timestamptz default now()
);

-- Workspaces (org/team)

create table if not exists public.workspaces (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    owner_id uuid not null references public.profiles(id) on delete cascade,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Memberships (user ↔ workspace, many-to-many)

create table if not exists public.memberships (
    workspace_id uuid not null references public.workspaces(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    role text not null default 'member', -- member | owner | admin (extend as needed)
    created_at timestamptz default now(),
    primary key (workspace_id, user_id)
);

-- Projects

create table if not exists public.projects (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references public.workspaces(id) on delete cascade,
    name text not null,
    description text,
    status text not null default 'active', -- active | paused | archived
    start_date date,
    due_date date,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Tasks

create table if not exists public.tasks (
    id uuid primary key default gen_random_uuid(),
    project_id uuid not null references public.projects(id) on delete cascade,
    parent_id uuid references public.tasks(id) on delete set null,
    title text not null,
    description text,
    status text not null default 'todo', -- todo | in_progress | done | blocked | cancelled
    priority text not null default 'med', -- low | med | high | urgent
    order_index numeric not null default 1000, -- for Kanban ordering
    assignee_id uuid references public.profiles(id) on delete set null,
    due_date date,
    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    status_changed_at timestamptz
);

-- Comments

create table if not exists public.comments (
    id uuid primary key default gen_random_uuid(),
    task_id uuid not null references public.tasks(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    content text not null,
    created_at timestamptz default now()
);

-- Attachments
create table if not exists public.attachments (
    id uuid primary key default gen_random_uuid(),
    task_id uuid not null references public.tasks(id) on delete cascade,
    file_url text not null,
    created_at timestamptz default now()
);


-- ================================
-- Indexes
-- ================================
create index if not exists idx_projects_workspace on public.projects (workspace_id);
create index if not exists idx_tasks_project on public.tasks (project_id);
create index if not exists idx_tasks_parent on public.tasks (parent_id);
create index if not exists idx_memberships_user on public.memberships (user_id);
create index if not exists idx_tasks_status on public.tasks (project_id, status, order_index);


-- Row Level Security
alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.memberships enable row level security;
alter table public.projects enable row level security;
alter table public.tasks enable row level security;
alter table public.comments enable row level security;
alter table public.attachments enable row level security;

-- Policies (workspace-scoped access)
-- profiles: a user can read/update their own profile
drop policy if exists profiles_self_select on public.profiles;
create policy profiles_self_select on public.profiles for select using ( auth.uid() = id );
drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update on public.profiles for update using ( auth.uid() = id );


-- workspaces: members can read/update; only creator can insert; owners can delete
drop policy if exists workspaces_member_select on public.workspaces;
create policy workspaces_members_select on public.workspaces for select using (
    exists (
        select 1 from public.memberships m
        where m.workspace_id = id and m.user_id = auth.uid()
    )
);

drop policy if exists workspaces_insert_owner on public.workspaces;
create policy workspaces_insert_owner on public.workspaces for insert with check ( auth.uid() = owner_id );
drop policy if exists workspaces_members_update on public.workspaces;
create policy workspaces_members_update on public.workspaces for update using (
    exists (
        select 1 from public.memberships m
        where m.workspace_id = id and m.user_id = auth.uid()
    )
);

drop policy if exists workspaces_delete_owner on public.workspaces;
create policy workspaces_delete_owner on public.workspaces for delete using (
    exists (
        select 1 from public.memberships m
        where m.workspace_id = id and m.user_id = auth.uid()
        and m.role = 'owner' -- ! only owners can delete
    )
);

-- memberships: user can see memberships they're a part of
drop policy if exists memberships_self_select on public.memberships;
create policy memberships_self_select on public.memberships for select using ( user_id = auth.uid() );

-- projects: accessible if user is a member of the workspace
drop policy if exists projects_members_all on public.projects;
create policy projects_members_all on public.projects for all using (
    exists (
        select 1 from public.memberships m
        where m.workspace_id = projects.workspace_id and m.user_id = auth.uid()
    )
) with check (
    exists (
        select 1 from public.memberships m
        where m.workspace_id = projects.workspace_id and m.user_id = auth.uid()
    )
);

-- tasks: same membership rule
drop policy if exists tasks_members_all on public.tasks;
create policy tasks_members_all on public.tasks for all using (
    exists (
        select 1 from public.projects p
        join public.memberships m on m.workspace_id = p.workspace_id
        where p.id = tasks.project_id and m.user_id = auth.uid()
    )
) with check (
    exists (
        select 1 from public.projects p
        join public.memberships m on m.workspace_id = p.workspace_id
        where p.id = tasks.project_id and m.user_id = auth.uid()
    )
);

-- comments: same membership rule via task -> project -> workspace
drop policy if exists comments_members_all on public.comments;
create policy comments_members_all on public.comments for all using (
    exists (
        select 1 from public.tasks t
        join public.projects p on p.id = t.project_id
        join public.memberships m on m.workspace_id = p.workspace_id
        where t.id = comments.tasks_id and m.user_id = auth.uid()
    )
) with check (
    exists (
        select 1 from public.tasks t
        join public.projects p on p.id = t.project_id
        join public.memberships m on m.workspace_id = p.workspace_id
        where t.id = comments.tasks_id and m.user_id = auth.uid()
    )
);

-- attachments: same membership rule via task -> project -> workspace
drop policy if exists attachments_members_all on public.attachments;
create policy attachments_members_all on public.attachments for all using (
    exists (
        select 1 from public.tasks t
        join public.projects p on p.id = t.project_id
        join public.memberships m on m.workspace_id = p.workspace_id
        where t.id = attachments.task_id and m.user_id = auth.uid()
    )
) with check (
    exists (
        select 1 from public.tasks t
        join public.projects p on p.id = t.project_id
        join public.memberships m on m.workspace_id = p.workspace_id
        where t.id = attachments.task_id and m.user_id = auth.uid()
    )
);

-- ================================
-- Triggers
-- ================================

-- Miirror auth.users -> profiles on signup
-- (ensures each user has a profiles row automatically)

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, email)
    values (new.id, new.email);
    on conflict (id) do nothing;
    return new;
end;
$$;

-- Create the auth.users trigger (Supabase-managed schema)
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();



-- Generic updated_at trigger
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

-- Projects: bump updated_at on any update
drop trigger if exists trg_projects_updated_at on public.projects;
create trigger trg_projects_updated_at before update on public.projects for each row execute function public.tg_set_updated_at();

-- Tasks: bump updated_at on any update
drop trigger if exists trg_tasks_updated_at on public.tasks;
create trigger trg_tasks_updated_at before update on public.tasks for each row execute function public.tg_set_updated_at();

-- Comments: bump updated_at on any update
-- !Ask GPT 5 about comments updated_at and attachments updated_at triggers
drop trigger if exists trg_comments_updated_at on public.comments;
create trigger trg_comments_updated_at before update on public.comments for each row execute function public.tg_set_updated_at();

-- Attachments: bump updated_at on any update
drop trigger if exists trg_attachments_updated_at on public.attachments;
create trigger trg_attachments_updated_at before update on public.attachments for each row execute function public.tg_set_updated_at();

-- Track status_changed_at when task status changes
create or replace function public.tg_bump_status_changed_at()
returns trigger
language plpgsql
as $$
begin
    if new.status is distinct from old.status then
        new.status_changed_at := now();
    end if;
    return new;
end;
$$;

-- Tasks: bump status_changed_at on status change
drop trigger if exists trg_tasks_status_changed_at on public.tasks;
create trigger trg_tasks_status_changed_at before update on public.tasks for each row execute function public.tg_bump_status_changed_at();
