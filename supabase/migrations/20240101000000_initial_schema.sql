-- ============================================================
-- TasteMatch / Burgundy — initial schema
-- ============================================================

-- identities -------------------------------------------------
create table public.identities (
    id                 uuid primary key default gen_random_uuid(),
    user_id            uuid null references auth.users(id) on delete set null,
    device_install_id  text null unique,
    version            int not null default 1,
    embedding          jsonb not null,          -- float[64]
    anti_embedding     jsonb not null,          -- float[64] — used for notMe / returned style signal
    stability          float not null default 1.0,
    count_me           int not null default 0,
    count_not_me       int not null default 0,
    count_maybe        int not null default 0,
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now()
);

alter table public.identities enable row level security;

-- Service-role bypass (edge functions use service_role key)
create policy "service role full access on identities"
    on public.identities
    using (true)
    with check (true);

-- events (append-only) ---------------------------------------
create table public.events (
    id               uuid primary key default gen_random_uuid(),
    identity_id      uuid not null references public.identities(id) on delete cascade,
    vote             text not null check (vote in ('me', 'notMe', 'maybe', 'returned')),
    return_reason    text null,
    category         text not null,
    object_embedding jsonb not null,    -- float[64]
    context          jsonb null,
    scores           jsonb null,
    pending          boolean not null default false,
    created_at       timestamptz not null default now()
);

alter table public.events enable row level security;

create policy "service role full access on events"
    on public.events
    using (true)
    with check (true);

create index events_identity_id_created_at on public.events (identity_id, created_at desc);

-- pending_reinforcements -------------------------------------
create table public.pending_reinforcements (
    id               uuid primary key default gen_random_uuid(),
    identity_id      uuid not null references public.identities(id) on delete cascade,
    object_embedding jsonb not null,    -- float[64]
    category         text not null,
    vote             text not null check (vote in ('me', 'notMe')),
    unlock_at        timestamptz not null,
    finalized        boolean not null default false,
    created_at       timestamptz not null default now()
);

alter table public.pending_reinforcements enable row level security;

create policy "service role full access on pending_reinforcements"
    on public.pending_reinforcements
    using (true)
    with check (true);

-- updated_at trigger -----------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger identities_updated_at
    before update on public.identities
    for each row execute procedure public.set_updated_at();
