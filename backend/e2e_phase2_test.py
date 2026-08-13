"""End-to-end test for the second wave: transactions, dashboard + notes,
settings, and the reports endpoint."""
import json, sys, urllib.request, urllib.error

BASE = 'http://localhost:4000/api'
fails, checks = [], [0]


def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        BASE + path, data=data, method=method,
        headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read().decode()
            return r.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, raw


def ok(label, cond, extra=''):
    checks[0] += 1
    if cond:
        print(f'  PASS  {label}')
    else:
        print(f'  FAIL  {label}  {extra}')
        fails.append(label)


print('=' * 72)
print('1. TRANSACTIONS  insert / update / status / delete')
print('=' * 72)
s, before = call('GET', '/transactions')
ok('GET /transactions -> 200', s == 200, s)
base_count = len(before)

s, txn = call('POST', '/transactions', {
    'item': 'E2E Probe Item', 'type': 'Outbound', 'party': 'Probe Party',
    'poNumber': '#E2E1', 'date': '2026-08-11T00:00:00.000Z',
    'status': 'Pending', 'notes': 'probe',
})
ok('POST /transactions -> 201', s == 201, (s, txn))
tid = txn['id']
ok('type stored', txn['type'] == 'Outbound', txn.get('type'))
ok('list grew', len(call('GET', '/transactions')[1]) == base_count + 1)

s, upd = call('PUT', f'/transactions/{tid}', {
    'item': 'E2E Probe Renamed', 'type': 'Inbound',
    'date': '2026-08-11T00:00:00.000Z', 'status': 'Received',
})
ok('PUT /transactions -> 200', s == 200, s)
ok('item renamed', upd['item'] == 'E2E Probe Renamed', upd.get('item'))
ok('type flipped', upd['type'] == 'Inbound', upd.get('type'))

s, st = call('PATCH', f'/transactions/{tid}/status', {'status': 'Delivered'})
ok('PATCH status -> 200', s == 200, s)
ok('status changed', st['status'] == 'Delivered', st.get('status'))

s, _ = call('POST', '/transactions', {'item': '', 'date': '2026-08-11'})
ok('blank item -> 400', s == 400, s)
s, _ = call('PATCH', f'/transactions/{tid}/status', {'status': 'Nonsense'})
ok('bad status -> 400', s == 400, s)

s, tstats = call('GET', '/stats/transactions')
ok('/stats/transactions -> 200', s == 200, s)
ok('stats total matches list',
   tstats['totalTransactions'] == len(call('GET', '/transactions')[1]))

s, _ = call('DELETE', f'/transactions/{tid}')
ok('DELETE -> 204', s == 204, s)
ok('list back to baseline',
   len(call('GET', '/transactions')[1]) == base_count)
s, _ = call('DELETE', f'/transactions/{tid}')
ok('re-delete -> 404', s == 404, s)

print()
print('=' * 72)
print('2. DASHBOARD  real aggregates')
print('=' * 72)
s, d = call('GET', '/dashboard')
ok('GET /dashboard -> 200', s == 200, s)
for key in ['summary', 'charts', 'categorySlices', 'recentTransactions',
            'incomingDeliveries', 'lowStockAlerts']:
    ok(f'dashboard has {key}', key in d)

summary = d['summary']
for key in ['totalStockItems', 'outOfStock', 'lowStock', 'duesFromClients',
            'todaysSales', 'monthSales']:
    ok(f'summary has {key}', key in summary)

# The dashboard's stock figures must agree with the inventory endpoint.
_, inv = call('GET', '/stats/inventory')
ok('dashboard totalStockItems matches inventory totalQty',
   summary['totalStockItems'] == inv['totalQty'],
   (summary['totalStockItems'], inv['totalQty']))
ok('dashboard lowStock matches inventory lowStock',
   summary['lowStock'] == inv['lowStock'])
ok('dashboard outOfStock matches inventory outOfStock',
   summary['outOfStock'] == inv['outOfStock'])

for key in ['purchases', 'sales', 'newClients']:
    series = d['charts'][key]['series']
    ok(f'{key} chart has 6 monthly buckets', len(series) == 6, len(series))
    ok(f'{key} buckets are labelled', all(p['label'] for p in series))

ok('category slices sum to ~100%',
   abs(sum(c['percent'] for c in d['categorySlices']) - 100) < 1.5
   or not d['categorySlices'],
   sum(c['percent'] for c in d['categorySlices']))
ok('recentTransactions capped at 6', len(d['recentTransactions']) <= 6)

print()
print('=' * 72)
print('3. DASHBOARD NOTES  insert / update / toggle / delete')
print('=' * 72)
s, notes0 = call('GET', '/dashboard/notes')
ok('GET notes -> 200', s == 200, s)
n0 = len(notes0)

s, note = call('POST', '/dashboard/notes', {'text': 'E2E probe note', 'userId': 1})
ok('POST note -> 201', s == 201, (s, note))
nid = note['id']
ok('note starts not done', note['done'] is False)
ok('notes list grew', len(call('GET', '/dashboard/notes')[1]) == n0 + 1)

s, toggled = call('PUT', f'/dashboard/notes/{nid}', {'done': True})
ok('toggle done -> 200', s == 200, s)
ok('done flipped', toggled['done'] is True)

s, renamed = call('PUT', f'/dashboard/notes/{nid}', {'text': 'E2E renamed note'})
ok('rename note -> 200', s == 200, s)
ok('text updated', renamed['text'] == 'E2E renamed note')

s, _ = call('POST', '/dashboard/notes', {'text': '   '})
ok('blank note -> 400', s == 400, s)
s, _ = call('PUT', f'/dashboard/notes/{nid}', {'text': '  '})
ok('blanking an existing note -> 400', s == 400, s)
s, _ = call('PUT', '/dashboard/notes/999999', {'done': True})
ok('unknown note -> 404', s == 404, s)

s, _ = call('DELETE', f'/dashboard/notes/{nid}')
ok('DELETE note -> 204', s == 204, s)
ok('notes back to baseline', len(call('GET', '/dashboard/notes')[1]) == n0)

print()
print('=' * 72)
print('4. SETTINGS  load / save / password')
print('=' * 72)
s, cfg = call('GET', '/settings?userId=1')
ok('GET /settings -> 200', s == 200, s)
ok('never returns the hash', 'passwordHash' not in cfg, list(cfg)[:20])
for key in ['name', 'email', 'notifyLowStock', 'twoFactor', 'rowsPerPage']:
    ok(f'settings has {key}', key in cfg)

s, _ = call('GET', '/settings')
ok('missing userId -> 400', s == 400, s)

original_rows = cfg['rowsPerPage']
original_2fa = cfg['twoFactor']
s, saved = call('PUT', '/settings', {
    'userId': 1, 'rowsPerPage': 50, 'twoFactor': not original_2fa,
    'notifyPayment': True,
})
ok('PUT /settings -> 200', s == 200, s)
ok('rowsPerPage saved', saved['rowsPerPage'] == 50, saved.get('rowsPerPage'))
ok('twoFactor saved', saved['twoFactor'] == (not original_2fa))
ok('preference persists on reload',
   call('GET', '/settings?userId=1')[1]['rowsPerPage'] == 50)

s, _ = call('PUT', '/settings', {'userId': 1, 'rowsPerPage': 7})
ok('invalid rowsPerPage -> 400', s == 400, s)
s, _ = call('PUT', '/settings', {'userId': 1, 'email': 'not-an-email'})
ok('invalid email -> 400', s == 400, s)
s, _ = call('PUT', '/settings', {'userId': 1, 'name': '  '})
ok('blank name -> 400', s == 400, s)

# Restore
call('PUT', '/settings', {
    'userId': 1, 'rowsPerPage': original_rows, 'twoFactor': original_2fa,
})
ok('settings restored',
   call('GET', '/settings?userId=1')[1]['rowsPerPage'] == original_rows)

# Password change must verify the current one
s, _ = call('POST', '/settings/password', {
    'userId': 1, 'currentPassword': 'wrong-password', 'newPassword': 'newpass123',
})
ok('wrong current password -> 401', s == 401, s)
s, _ = call('POST', '/settings/password', {
    'userId': 1, 'currentPassword': '123456', 'newPassword': 'abc',
})
ok('too-short new password -> 400', s == 400, s)

s, _ = call('POST', '/settings/password', {
    'userId': 1, 'currentPassword': '123456', 'newPassword': 'temp-pass-123',
})
ok('valid password change -> 200', s == 200, s)
ok('can log in with the new password',
   call('POST', '/auth/login',
        {'email': 'shc@gmail.com', 'password': 'temp-pass-123'})[0] == 200)
# Put it back so the dev login keeps working.
call('POST', '/settings/password', {
    'userId': 1, 'currentPassword': 'temp-pass-123', 'newPassword': '123456',
})
ok('original password restored',
   call('POST', '/auth/login',
        {'email': 'shc@gmail.com', 'password': '123456'})[0] == 200)

print()
print('=' * 72)
print('5. REPORTS')
print('=' * 72)
s, rep = call('GET', '/stats/reports')
ok('GET /stats/reports -> 200', s == 200, s)
for key in ['sales', 'purchase', 'stock', 'netMovement', 'topProducts', 'topClients']:
    ok(f'report has {key}', key in rep)
ok('netMovement = sales - purchases',
   abs(rep['netMovement'] - (rep['sales']['total'] - rep['purchase']['total'])) < 0.01,
   (rep['netMovement'], rep['sales']['total'], rep['purchase']['total']))
ok('report stock matches inventory stats',
   rep['stock']['lowStock'] == inv['lowStock'])

s, ranged = call('GET', '/stats/reports?from=2020-01-01&to=2020-12-31')
ok('date range accepted -> 200', s == 200, s)
ok('empty range yields zero sales', ranged['sales']['total'] == 0,
   ranged['sales'])

print()
print('=' * 72)
print(f'{checks[0] - len(fails)}/{checks[0]} checks passed')
if fails:
    print('FAILED:')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('ALL GREEN')
