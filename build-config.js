const fs = require('fs');
const path = require('path');

function loadDotEnv() {
  const envPath = path.join(__dirname, '.env');
  if (!fs.existsSync(envPath)) return;
  const raw = fs.readFileSync(envPath, 'utf8');
  raw.split(/\r?\n/).forEach(line => {
    const match = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!match) return;
    let [, key, value] = match;
    if (/^['"].*['"]$/.test(value)) {
      value = value.slice(1, -1);
    }
    if (!process.env[key]) {
      process.env[key] = value;
    }
  });
}

loadDotEnv();

const env = process.env;
const config = {
  SUPABASE_URL: env.SUPABASE_URL || env.NEXT_PUBLIC_SUPABASE_URL || '',
  SUPABASE_ANON_KEY: env.SUPABASE_ANON_KEY || env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
  APP_NAME: env.APP_NAME || 'ReceiptIQ',
  DEFAULT_CURRENCY: env.DEFAULT_CURRENCY || 'USD',
};

const output = `// Auto-generated config.js
// Do not commit real keys to source control.
// Generated from environment variables at build time.

const RECEIPTIQ_CONFIG = {
  SUPABASE_URL: ${JSON.stringify(config.SUPABASE_URL || 'https://YOUR_PROJECT.supabase.co')},
  SUPABASE_ANON_KEY: ${JSON.stringify(config.SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY')},
  APP_NAME: ${JSON.stringify(config.APP_NAME)},
  DEFAULT_CURRENCY: ${JSON.stringify(config.DEFAULT_CURRENCY)},
};
`;

const targetPath = path.join(__dirname, 'config.js');
fs.writeFileSync(targetPath, output, 'utf8');
console.log(`Wrote ${targetPath}`);

if (!config.SUPABASE_URL || !config.SUPABASE_ANON_KEY) {
  console.warn('Warning: SUPABASE_URL and SUPABASE_ANON_KEY should be set before build.');
}
