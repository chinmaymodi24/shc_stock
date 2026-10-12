// Dumps the whole database to a timestamped file and prunes old dumps.
//
//   npm run backup:db
//
// Runs daily from Windows Task Scheduler (task "SHC Stock DB Backup"). Added
// after every product, purchase, sale, stock movement and transaction was
// deleted from the dev database with no backup to restore them from.
//
// Restore one dump (replaces the current data):
//   pg_restore --clean --if-exists -h localhost -U postgres -d shc_stock <file>
//
// Env (all optional except DATABASE_URL, which .env already has):
//   BACKUP_DIR   where dumps go — default: <repo>/../db_backups, outside git
//   BACKUP_KEEP  how many dumps to keep — default 30
//   BACKUP_COPY_DIRS  other places to copy every dump to, comma separated — a
//                synced cloud folder, an external drive, a network share. A
//                backup that only sits next to the database is lost with the
//                machine. Each copy is size-checked; one failing place is
//                reported (and fails the run) but never stops the others.
//   PG_DUMP      pg_dump executable — default: the PostgreSQL 17 install,
//                falling back to `pg_dump` on PATH
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const PREFIX = 'shc_stock_';

function pgDumpPath() {
  if (process.env.PG_DUMP) return process.env.PG_DUMP;
  const installed = 'C:\\Program Files\\PostgreSQL\\17\\bin\\pg_dump.exe';
  return fs.existsSync(installed) ? installed : 'pg_dump';
}

function pgRestorePath() {
  const pgDump = pgDumpPath();
  if (pgDump === 'pg_dump') return 'pg_restore';
  return path.join(path.dirname(pgDump), process.platform === 'win32' ? 'pg_restore.exe' : 'pg_restore');
}

/// A dump that cannot be read back is not a backup. `pg_restore -l` lists its
/// contents without touching any database.
function verifyDump(file) {
  const r = spawnSync(pgRestorePath(), ['-l', file], { encoding: 'utf8' });
  if (r.error) return `could not run pg_restore (${r.error.message})`;
  if (r.status !== 0) return `pg_restore could not read it: ${(r.stderr || '').trim()}`;
  if (!/TABLE DATA/.test(r.stdout)) return 'the dump lists no table data';
  return null;
}

function pruneDir(dir, keep) {
  // Names sort by date, so the oldest come first.
  const dumps = fs
    .readdirSync(dir)
    .filter((f) => f.startsWith(PREFIX) && f.endsWith('.dump'))
    .sort();
  for (const old of dumps.slice(0, Math.max(0, dumps.length - keep))) {
    fs.rmSync(path.join(dir, old));
    console.log(`pruned ${old} from ${dir}`);
  }
}

/// Copies [file] into every directory in BACKUP_COPY_DIRS and checks the size.
/// Returns the places that failed.
function copyOffsite(file, keep) {
  const dirs = (process.env.BACKUP_COPY_DIRS || '')
    .split(',')
    .map((d) => d.trim())
    .filter(Boolean);
  const failed = [];
  for (const raw of dirs) {
    const dir = path.resolve(raw);
    try {
      fs.mkdirSync(dir, { recursive: true });
      const target = path.join(dir, path.basename(file));
      fs.copyFileSync(file, target);
      if (fs.statSync(target).size !== fs.statSync(file).size) {
        throw new Error('the copy is not the same size as the dump');
      }
      console.log(`copied to ${target}`);
      pruneDir(dir, keep);
    } catch (err) {
      failed.push(`${dir}: ${err.message}`);
    }
  }
  return failed;
}

function stamp(d = new Date()) {
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}_${p(d.getHours())}${p(d.getMinutes())}`;
}

function main() {
  const raw = process.env.DATABASE_URL;
  if (!raw) throw new Error('DATABASE_URL is not set');

  // Prisma's URL carries ?schema=public, which pg_dump rejects — so pass the
  // parts instead, and the password through the environment rather than the
  // command line, where it would show up in the process list.
  const url = new URL(raw);
  const db = decodeURIComponent(url.pathname.replace(/^\//, ''));
  const dir = path.resolve(
    process.env.BACKUP_DIR || path.join(__dirname, '..', '..', '..', 'db_backups'),
  );
  const keep = Math.max(1, Number(process.env.BACKUP_KEEP) || 30);
  fs.mkdirSync(dir, { recursive: true });

  const file = path.join(dir, `${PREFIX}${stamp()}.dump`);
  const result = spawnSync(
    pgDumpPath(),
    [
      '-h', url.hostname,
      '-p', url.port || '5432',
      '-U', decodeURIComponent(url.username),
      '-d', db,
      '-F', 'c', // custom format: compressed, restorable table by table
      '-f', file,
    ],
    {
      env: { ...process.env, PGPASSWORD: decodeURIComponent(url.password) },
      encoding: 'utf8',
    },
  );
  if (result.error) throw result.error;
  if (result.status !== 0) {
    // Don't leave a half-written dump that looks like a good one.
    fs.rmSync(file, { force: true });
    throw new Error(`pg_dump exited ${result.status}: ${result.stderr.trim()}`);
  }

  const problem = verifyDump(file);
  if (problem) {
    fs.rmSync(file, { force: true });
    throw new Error(`the dump was written but is not usable: ${problem}`);
  }

  const size = fs.statSync(file).size;
  console.log(`[${new Date().toISOString()}] backup ok: ${file} (${(size / 1024).toFixed(1)} KB)`);
  pruneDir(dir, keep);

  const failed = copyOffsite(file, keep);
  if (failed.length) {
    throw new Error(`the local backup is fine, but copying to other places failed — ${failed.join('; ')}`);
  }
  if (!process.env.BACKUP_COPY_DIRS) {
    console.warn(
      'note: BACKUP_COPY_DIRS is not set — this backup exists only on this machine. ' +
        'Add a synced cloud folder or an external drive (see .env.example).',
    );
  }
}

try {
  main();
} catch (err) {
  console.error(`[${new Date().toISOString()}] backup FAILED: ${err.message}`);
  process.exit(1);
}
