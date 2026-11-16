import * as dotenv from 'dotenv';
import * as fs from 'fs';
import * as path from 'path';

function findEnvFile(): string | undefined {
  let dir = __dirname;
  while (dir !== path.dirname(dir)) {
    const candidate = path.join(dir, '.env');
    if (fs.existsSync(candidate)) return candidate;
    dir = path.dirname(dir);
  }
  return undefined;
}

const envPath = findEnvFile();
if (envPath) {
  dotenv.config({ path: envPath });
} else {
  dotenv.config();
}

import { lookupInforegister } from './tools';

async function main() {
  const args = process.argv.slice(2);
  const regkood = args.find((a) => !a.startsWith('--'));
  if (!regkood) {
    console.error('Kasutamine: npm run inforegister-lookup -- <regkood> [--cache-only] [--force-refresh] [--insecure-tls]');
    process.exit(1);
  }

  const cacheOnly = args.includes('--cache-only');
  const forceRefresh = args.includes('--force-refresh');
  const insecureTls = args.includes('--insecure-tls');

  try {
    const res = await lookupInforegister({
      regkood,
      cacheOnly,
      forceRefresh,
      insecureTls,
    });
    console.log(JSON.stringify(res, null, 2));
    if (!res.ok) {
      process.exitCode = 1;
    }
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error('Viga:', msg);
    process.exit(1);
  }
}

main();
