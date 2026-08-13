"""End-to-end test for the Employee (users) module.

Covers CRUD, the stats endpoint, and the two things that could go badly wrong
when a login table doubles as an employee directory: passwords leaking out,
and the last Admin being deletable.
"""
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


def stats():
    s, d = call('GET', '/stats/users')
    assert s == 200, (s, d)
    return d


print('=' * 72)
print('1. LIST + SECRECY')
print('=' * 72)
s, users = call('GET', '/users')
ok('GET /users -> 200', s == 200, s)
ok('seeded employees present', len(users) >= 15, len(users))
ok('passwordHash never returned',
   not any('passwordHash' in u for u in users))
ok('every row has a USR- code',
   all(str(u['code']).startswith('USR-') for u in users),
   [u['code'] for u in users if not str(u['code']).startswith('USR-')])

print()
print('=' * 72)
print('2. LOGIN STILL WORKS AFTER THE SCHEMA CHANGE')
print('=' * 72)
s, me = call('POST', '/auth/login', {'email': 'shc@gmail.com', 'password': '123456'})
ok('login -> 200', s == 200, (s, me))
ok('login returns the admin', s == 200 and me.get('role') == 'Admin', me)
ok('login response carries no hash', isinstance(me, dict) and 'passwordHash' not in me)
s, _ = call('POST', '/auth/login', {'email': 'shc@gmail.com', 'password': 'wrong'})
ok('wrong password rejected', s in (400, 401), s)

print()
print('=' * 72)
print('3. INSERT')
print('=' * 72)
before = stats()
s, made = call('POST', '/users', {
    'name': 'E2E Probe Employee', 'email': 'e2e.probe@shc.com',
    'phone': '+91 90000 00000', 'role': 'Stock Manager',
    'department': 'Warehouse', 'isActive': True,
})
ok('POST /users -> 201', s == 201, (s, made))
uid = made['id']
ok('server assigned a USR- code', str(made['code']).startswith('USR-'), made.get('code'))
ok('created row hides the hash', 'passwordHash' not in made)
ok('role stored', made['role'] == 'Stock Manager', made.get('role'))
ok('stats totalUsers rose',
   stats()['totalUsers'] == before['totalUsers'] + 1, stats()['totalUsers'])

s, _ = call('POST', '/users', {'name': 'Dup', 'email': 'e2e.probe@shc.com'})
ok('duplicate email -> 409', s == 409, s)
s, _ = call('POST', '/users', {'name': '', 'email': 'x@y.com'})
ok('blank name -> 400', s == 400, s)
s, _ = call('POST', '/users', {'name': 'Bad Email', 'email': 'not-an-email'})
ok('invalid email -> 400', s == 400, s)

# The starter password must actually work.
s, _ = call('POST', '/auth/login',
            {'email': 'e2e.probe@shc.com', 'password': 'shc@12345'})
ok('new employee can log in with the starter password', s == 200, s)

print()
print('=' * 72)
print('4. UPDATE')
print('=' * 72)
s, upd = call('PUT', f'/users/{uid}', {
    'name': 'E2E Probe Renamed', 'email': 'e2e.probe@shc.com',
    'role': 'Manager', 'department': 'Ops', 'phone': '+91 91111 11111',
})
ok('PUT /users -> 200', s == 200, s)
ok('name updated', upd['name'] == 'E2E Probe Renamed', upd.get('name'))
ok('role updated', upd['role'] == 'Manager', upd.get('role'))

active_before = stats()['activeUsers']
s, off = call('PATCH', f'/users/{uid}/status', {'isActive': False})
ok('PATCH status -> 200', s == 200, s)
ok('isActive flipped to false', off['isActive'] is False, off.get('isActive'))
ok('stats activeUsers dropped', stats()['activeUsers'] == active_before - 1)
call('PATCH', f'/users/{uid}/status', {'isActive': True})
ok('stats activeUsers restored', stats()['activeUsers'] == active_before)

s, _ = call('PUT', '/users/99999', {'name': 'Ghost', 'email': 'g@h.com'})
ok('PUT unknown id -> 404', s == 404, s)

print()
print('=' * 72)
print('5. DELETE + LAST-ADMIN GUARD')
print('=' * 72)
admins = [u for u in call('GET', '/users')[1] if u['role'] == 'Admin']
ok('exactly one Admin seeded', len(admins) == 1, len(admins))
s, err = call('DELETE', f"/users/{admins[0]['id']}")
ok('cannot delete the last Admin -> 409', s == 409, (s, err))
ok('that Admin still exists',
   any(u['id'] == admins[0]['id'] for u in call('GET', '/users')[1]))

s, _ = call('DELETE', f'/users/{uid}')
ok('DELETE /users -> 204', s == 204, s)
ok('stats back to baseline', stats()['totalUsers'] == before['totalUsers'])
s, _ = call('DELETE', f'/users/{uid}')
ok('re-delete -> 404', s == 404, s)

print()
print('=' * 72)
print('6. STATS SHAPE')
print('=' * 72)
d = stats()
for k in ['totalUsers', 'activeUsers', 'inactiveUsers', 'adminCount']:
    ok(f'stats has {k}', k in d)
ok('inactive = total - active',
   d['inactiveUsers'] == d['totalUsers'] - d['activeUsers'])
ok('roleBreakdown present and sorted desc',
   len(d['roleBreakdown']) > 0 and
   all(d['roleBreakdown'][i]['count'] >= d['roleBreakdown'][i + 1]['count']
       for i in range(len(d['roleBreakdown']) - 1)),
   d.get('roleBreakdown'))
ok('roleBreakdown sums to the total',
   sum(r['count'] for r in d['roleBreakdown']) == d['totalUsers'])
ok('stats matches /users length', d['totalUsers'] == len(call('GET', '/users')[1]))

print()
print('=' * 72)
print(f'{checks[0] - len(fails)}/{checks[0]} checks passed')
if fails:
    print('FAILED:')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('ALL GREEN')
