-- ReceiptIQ — Supabase Database Schema
-- Paste this into Supabase SQL Editor and click Run

-- ─────────────────────────────────────────
-- 1. ENABLE UUID EXTENSION
-- ─────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────
-- 2. WORKSPACES (one per accountant firm or business)
-- ─────────────────────────────────────────
create table workspaces (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  plan text not null default 'starter', -- starter | accountant_pro | white_label
  brand_name text,                       -- for white-label: custom brand name
  brand_color text,                      -- for white-label: hex color
  brand_logo_url text,                   -- for white-label: logo URL
  custom_domain text,                    -- for white-label: custom domain
  seats_limit integer default 5,
  created_at timestamptz default now()
);

-- ─────────────────────────────────────────
-- 3. PROFILES (linked to Supabase Auth users)
-- ─────────────────────────────────────────
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  workspace_id uuid references workspaces(id),
  role text not null default 'member',   -- owner | accountant | client | member
  full_name text,
  email text,
  avatar_url text,
  created_at timestamptz default now()
);

-- ─────────────────────────────────────────
-- 4. CLIENTS (businesses managed by accountants)
-- ─────────────────────────────────────────
create table clients (
  id uuid primary key default uuid_generate_v4(),
  workspace_id uuid references workspaces(id) on delete cascade,
  user_id uuid references profiles(id),   -- linked profile if they have login
  name text not null,
  email text,
  company text,
  notes text,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ─────────────────────────────────────────
-- 5. RECEIPTS (uploaded files)
-- ─────────────────────────────────────────
create table receipts (
  id uuid primary key default uuid_generate_v4(),
  workspace_id uuid references workspaces(id) on delete cascade,
  client_id uuid references clients(id),
  uploaded_by uuid references profiles(id),
  file_name text not null,
  file_url text not null,               -- Supabase Storage URL
  file_type text,                       -- image/jpeg | application/pdf
  file_size_bytes bigint,
  status text default 'pending',        -- pending | processing | done | review | error
  ai_raw_response jsonb,                -- raw Claude API response
  created_at timestamptz default now()
);

-- ─────────────────────────────────────────
-- 6. TRANSACTIONS (extracted receipt data)
-- ─────────────────────────────────────────
create table transactions (
  id uuid primary key default uuid_generate_v4(),
  receipt_id uuid references receipts(id) on delete cascade,
  workspace_id uuid references workspaces(id) on delete cascade,
  client_id uuid references clients(id),

  -- Extracted fields
  merchant text,
  description text,
  amount decimal(12,2),
  currency_original text,               -- e.g. GBP, EUR, JPY
  amount_original decimal(12,2),        -- original amount before conversion
  currency_converted text default 'USD',
  fx_rate decimal(12,6),                -- rate used for conversion
  fx_date date,                         -- date FX rate was fetched

  -- Classification
  category text,                        -- Travel | Meals | Software | Office | etc.
  tax_status text,                      -- deductible | non_deductible | partial
  deductible_percent integer default 100,

  -- Metadata
  transaction_date date,
  status text default 'done',           -- done | review | rejected
  confidence_score decimal(3,2),        -- AI confidence 0.00–1.00
  notes text,
  tags text[],

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ─────────────────────────────────────────
-- 7. EXPORTS (tax report history)
-- ─────────────────────────────────────────
create table exports (
  id uuid primary key default uuid_generate_v4(),
  workspace_id uuid references workspaces(id) on delete cascade,
  client_id uuid references clients(id),
  exported_by uuid references profiles(id),
  format text not null,                 -- csv | pdf
  date_from date,
  date_to date,
  filters jsonb,                        -- category, status filters used
  file_url text,                        -- Supabase Storage URL of generated file
  row_count integer,
  total_amount decimal(12,2),
  created_at timestamptz default now()
);

-- ─────────────────────────────────────────
-- 8. ROW LEVEL SECURITY (RLS)
-- Each user only sees data in their workspace
-- ─────────────────────────────────────────
alter table workspaces enable row level security;
alter table profiles enable row level security;
alter table clients enable row level security;
alter table receipts enable row level security;
alter table transactions enable row level security;
alter table exports enable row level security;

-- Workspace: users see their own workspace
create policy "workspace_access" on workspaces
  for all using (
    id in (select workspace_id from profiles where id = auth.uid())
  );

-- Profiles: users see profiles in same workspace
create policy "profile_access" on profiles
  for all using (
    workspace_id in (select workspace_id from profiles where id = auth.uid())
  );

-- Clients: workspace-scoped access
create policy "client_access" on clients
  for all using (
    workspace_id in (select workspace_id from profiles where id = auth.uid())
  );

-- Receipts: workspace-scoped access
create policy "receipt_access" on receipts
  for all using (
    workspace_id in (select workspace_id from profiles where id = auth.uid())
  );

-- Transactions: workspace-scoped access
create policy "transaction_access" on transactions
  for all using (
    workspace_id in (select workspace_id from profiles where id = auth.uid())
  );

-- Exports: workspace-scoped access
create policy "export_access" on exports
  for all using (
    workspace_id in (select workspace_id from profiles where id = auth.uid())
  );

-- ─────────────────────────────────────────
-- 9. INDEXES (for query performance)
-- ─────────────────────────────────────────
create index idx_receipts_workspace on receipts(workspace_id);
create index idx_receipts_client on receipts(client_id);
create index idx_receipts_status on receipts(status);
create index idx_transactions_workspace on transactions(workspace_id);
create index idx_transactions_client on transactions(client_id);
create index idx_transactions_date on transactions(transaction_date);
create index idx_transactions_category on transactions(category);
create index idx_transactions_status on transactions(status);

-- ─────────────────────────────────────────
-- 10. SUPABASE STORAGE BUCKETS
-- Run these in the Storage section of your Supabase dashboard
-- OR uncomment and run here:
-- ─────────────────────────────────────────
-- insert into storage.buckets (id, name, public) values ('receipts', 'receipts', false);
-- insert into storage.buckets (id, name, public) values ('exports', 'exports', false);
-- insert into storage.buckets (id, name, public) values ('brand-assets', 'brand-assets', true);

-- ─────────────────────────────────────────
-- DONE! Your ReceiptIQ database is ready.
-- Next steps:
-- 1. Create your first workspace in the workspaces table
-- 2. Connect your Supabase URL + anon key to your app
-- 3. Deploy to Railway and Vercel
-- ─────────────────────────────────────────
