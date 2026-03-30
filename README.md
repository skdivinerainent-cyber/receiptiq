# ReceiptIQ — Setup Guide

## What's in this package

```
receiptiq/
├── index.html                ← Public landing page
├── auth-login.html           ← Sign in page
├── auth-signup.html          ← Sign up page
├── dashboard-overview.html   ← Main dashboard
├── dashboard-upload.html     ← Receipt upload + AI extraction
├── dashboard-transactions.html ← Transaction list
├── dashboard-reports.html    ← Tax exports & reports
├── build-config.js           ← Generates config.js from env vars
├── config.example.js         ← Example client config
├── .env.example              ← Example local environment file
├── netlify/functions/        ← Serverless backend endpoints
└── README.md                 ← You are here
```

---

## Step 1 — Set Up Supabase

1. Go to [supabase.com](https://supabase.com) and create a free account
2. Click **New Project** and fill in the details
3. Go to **SQL Editor** in the left sidebar
4. Open `sql/schema.sql` from this package
5. Paste the entire contents and click **Run**
6. Your database is ready ✅

**Save these for later:**
- Project URL: `https://xxxxx.supabase.co`
- Anon public key: found under Settings → API

---

## Step 2 — Set Up Storage Buckets

In your Supabase dashboard:
1. Go to **Storage** in the left sidebar
2. Click **New Bucket** → name it `receipts` → set to **Private**
3. Click **New Bucket** → name it `exports` → set to **Private**
4. Click **New Bucket** → name it `brand-assets` → set to **Public**

---

## Step 3 — Upload to GitHub

1. Create a free account at [github.com](https://github.com)
2. Click **+** → **New repository** → name it `receiptiq-app`
3. Set to **Private** and click **Create repository**
4. Drag and drop all the files from this zip into the repo
5. Click **Commit changes** ✅

---

## Step 4 — Deploy to Netlify

1. Go to [netlify.com](https://netlify.com) and sign up with GitHub
2. Click **New site from Git** → select your `receiptiq-app` repo
3. Set the build command to `node build-config.js`
4. Set the publish directory to `/`
5. Deploy the site

**Add Environment Variables in Netlify:**
Go to Site settings → Build & deploy → Environment and add:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
CLAUDE_API_KEY=your-claude-api-key
APP_NAME=ReceiptIQ
DEFAULT_CURRENCY=USD
```

Note: `SUPABASE_URL` and `SUPABASE_ANON_KEY` are used to generate `config.js` at build time. Because Netlify secrets scanning can flag environment values written into build output, this project sets `SECRETS_SCAN_OMIT_KEYS` for these keys in `netlify.toml`.

If you use `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` instead, you can add those names to the same omit list.

If you prefer Vercel, use the same environment variables and set `NODE_VERSION=20` if needed.

---

## Step 5 — Get Your Claude API Key

1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Sign up and go to **API Keys**
3. Click **Create Key** and copy it
4. Add it to your environment variables as `CLAUDE_API_KEY`

**The Claude API prompt to use for receipt extraction:**

```
You are a receipt and invoice data extraction AI. 
Analyze the provided image/document and extract:
- merchant: business name
- amount: total amount paid (number only)
- currency: ISO currency code (USD, GBP, EUR, etc.)
- date: transaction date (YYYY-MM-DD format)
- category: one of [Travel, Meals, Software, Office, Client Entertainment, Other]
- tax_status: one of [deductible, non_deductible, partial]
- description: brief description of purchase

Respond ONLY with valid JSON, no other text.
```

---

## Step 6 — Custom Domain (Optional)

1. Buy a domain at [Cloudflare](https://cloudflare.com) (~$10/yr)
2. In Vercel: go to your project → Settings → Domains
3. Add your domain and follow the DNS instructions
4. SSL is automatic ✅

---

## Pricing Plans (as configured)

| Plan | Price | Target |
|---|---|---|
| Starter | $29/mo | Small businesses direct |
| Accountant Pro | $15/seat/mo | Accounting firms |
| White Label | $299/mo + $10/seat | Firms wanting own brand |

---

## Monthly Running Costs

| Service | Launch | Growth |
|---|---|---|
| Vercel | Free | $20/mo |
| Supabase | Free | $25/mo |
| Claude API | ~$5-15/mo | ~$50-150/mo |
| Domain | $10/yr | $10/yr |
| **Total** | **~$15/mo** | **~$100-200/mo** |

---

## Support

Built with ReceiptIQ stack:
- Frontend: HTML/CSS/JS (upgrade to Next.js for production)
- Auth + DB + Storage: Supabase
- AI: Claude API (Anthropic)
- Hosting: Vercel
- Payments: Stripe (add later)
