"""Sub-category CRUD — the one path no other suite covered.

Sub-categories are nested inside /api/categories on read, but created via
POST /api/categories/:id/sub-categories and edited/deleted/reordered through
/api/sub-categories/:id.
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


def subs_of(cat_id):
    _, cats = call('GET', '/categories')
    cat = next((c for c in cats if c['id'] == cat_id), None)
    return cat['subCategories'] if cat else []


print('=' * 72)
print('SUB-CATEGORY CRUD')
print('=' * 72)

s, cat = call('POST', '/categories', {'name': 'E2E Sub Probe Category'})
ok('parent category created', s == 201, s)
cid = cat['id']
ok('starts with no sub-categories', subs_of(cid) == [], subs_of(cid))

# Insert
s, sub1 = call('POST', f'/categories/{cid}/sub-categories',
               {'name': 'Probe Sub One', 'description': 'first'})
ok('POST sub-category -> 201', s == 201, (s, sub1))
s, sub2 = call('POST', f'/categories/{cid}/sub-categories', {'name': 'Probe Sub Two'})
ok('second sub-category created', s == 201, s)
ok('both appear nested under the category', len(subs_of(cid)) == 2, subs_of(cid))

s, _ = call('POST', f'/categories/{cid}/sub-categories', {'name': '   '})
ok('blank name -> 400', s == 400, s)
s, _ = call('POST', '/categories/999999/sub-categories', {'name': 'Orphan'})
ok('unknown parent -> 404', s == 404, s)

# Update
s, upd = call('PUT', f"/sub-categories/{sub1['id']}",
              {'name': 'Probe Sub Renamed', 'description': 'edited'})
ok('PUT sub-category -> 200', s == 200, s)
ok('name updated', upd['name'] == 'Probe Sub Renamed', upd.get('name'))
ok('rename visible through the parent',
   any(x['name'] == 'Probe Sub Renamed' for x in subs_of(cid)), subs_of(cid))
s, _ = call('PUT', f"/sub-categories/{sub1['id']}", {'name': ''})
ok('blank rename -> 400', s == 400, s)
s, _ = call('PUT', '/sub-categories/999999', {'name': 'Ghost'})
ok('unknown sub-category -> 404', s == 404, s)

# Reorder
before = [x['id'] for x in subs_of(cid)]
s, _ = call('PATCH', '/sub-categories/reorder',
            {'categoryId': cid, 'orderedIds': list(reversed(before))})
ok('PATCH reorder -> 200', s == 200, s)
ok('order actually flipped',
   [x['id'] for x in subs_of(cid)] == list(reversed(before)),
   (before, [x['id'] for x in subs_of(cid)]))

# Stats must count them
_, cstats = call('GET', '/stats/categories')
_, cats = call('GET', '/categories')
ok('stats totalSubCategories matches the real total',
   cstats['totalSubCategories'] == sum(len(c['subCategories']) for c in cats),
   cstats['totalSubCategories'])

# Delete
s, _ = call('DELETE', f"/sub-categories/{sub1['id']}")
ok('DELETE sub-category -> 204', s == 204, s)
ok('one left under the parent', len(subs_of(cid)) == 1, subs_of(cid))
s, _ = call('DELETE', f"/sub-categories/{sub1['id']}")
ok('re-delete -> 404', s == 404, s)

# Deleting the parent cascades
call('DELETE', f'/categories/{cid}')
_, cats = call('GET', '/categories')
ok('parent gone', all(c['id'] != cid for c in cats))
s, _ = call('PUT', f"/sub-categories/{sub2['id']}", {'name': 'Zombie'})
ok('child cascade-deleted with the parent -> 404', s == 404, s)

print()
print('=' * 72)
print(f'{checks[0] - len(fails)}/{checks[0]} checks passed')
if fails:
    print('FAILED:')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('ALL GREEN')
