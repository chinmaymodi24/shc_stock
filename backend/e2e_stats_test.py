"""End-to-end test for the /api/stats summary endpoints.

Proves every summary card is served by the API with real numbers, and that
those numbers actually move when the underlying data changes.
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


def stats(mod):
    s, d = call('GET', f'/stats/{mod}')
    assert s == 200, (mod, s, d)
    return d


print('=' * 72)
print('1. EVERY MODULE HAS A STATS ENDPOINT WITH REAL NUMBERS')
print('=' * 72)
shape = {
    'clients':    ['totalClients', 'gstRegistered', 'unregistered', 'statesCovered'],
    'products':   ['totalProducts', 'lowStock', 'outOfStock', 'totalValue'],
    'inventory':  ['totalItems', 'inStock', 'lowStock', 'outOfStock', 'totalQty', 'totalValue'],
    'purchase':   ['totalOrders', 'purchaseMTD', 'amountPaid', 'amountDue'],
    'sales':      ['salesMTD', 'totalOrders', 'amountDue', 'receivedMTD'],
    'categories': ['totalCategories', 'totalSubCategories'],
}
for mod, keys in shape.items():
    d = stats(mod)
    ok(f'/stats/{mod} returns all card keys',
       all(k in d for k in keys), [k for k in keys if k not in d])
    ok(f'/stats/{mod} has a trends block', isinstance(d.get('trends'), dict), d.get('trends'))

print()
print('=' * 72)
print('2. STATS MATCH THE ACTUAL LIST ENDPOINTS')
print('=' * 72)
_, clients = call('GET', '/clients')
cs = stats('clients')
ok('client total matches /clients', cs['totalClients'] == len(clients),
   (cs['totalClients'], len(clients)))
ok('gstRegistered matches Regular rows',
   cs['gstRegistered'] == sum(1 for c in clients if c['registrationType'] == 'Regular'))
ok('unregistered = total - registered',
   cs['unregistered'] == cs['totalClients'] - cs['gstRegistered'])
ok('statesCovered matches distinct regState',
   cs['statesCovered'] == len({c['regState'] for c in clients if c['regState']}))

_, inv = call('GET', '/inventory')
ivs = stats('inventory')
ok('inventory total matches /inventory', ivs['totalItems'] == len(inv))
ok('inventory totalQty matches sum of rows',
   ivs['totalQty'] == sum(r['stockInHand'] for r in inv),
   (ivs['totalQty'], sum(r['stockInHand'] for r in inv)))
ok('inventory lowStock matches row statuses',
   ivs['lowStock'] == sum(1 for r in inv if r['status'] == 'lowStock'))

print()
print('=' * 72)
print('3. CLIENTS RIGHT PANEL IS API-DRIVEN')
print('=' * 72)
ok('topStates present and sorted desc',
   len(cs['topStates']) > 0 and
   all(cs['topStates'][i]['count'] >= cs['topStates'][i + 1]['count']
       for i in range(len(cs['topStates']) - 1)),
   cs['topStates'])
ok('topStates counts match the client list',
   cs['topStates'][0]['count'] ==
   sum(1 for c in clients if c['regState'] == cs['topStates'][0]['state']))
ok('quickStats block exists', 'quickStats' in cs, cs.get('quickStats'))
ok('quickStats has avgOrderValue + repeatClientsPct',
   'avgOrderValue' in cs['quickStats'] and 'repeatClientsPct' in cs['quickStats'])
ok('newThisMonth block exists', isinstance(cs.get('newThisMonth'), list))

print()
print('=' * 72)
print('4. NUMBERS MOVE WHEN DATA CHANGES')
print('=' * 72)
before = stats('clients')['totalClients']
s, cl = call('POST', '/clients', {'name': 'Stats Probe Client', 'regState': 'Goa'})
ok('probe client created', s == 201, s)
after = stats('clients')['totalClients']
ok(f'client total moved {before} -> {after}', after == before + 1, after)

goa = next((t for t in stats('clients')['topStates'] if t['state'] == 'Goa'), None)
newnames = [n['name'] for n in stats('clients')['newThisMonth']]
ok('newThisMonth picked up the new client', 'Stats Probe Client' in newnames, newnames)

call('DELETE', f"/clients/{cl['id']}")
ok('client total restored after delete', stats('clients')['totalClients'] == before)

# Sales stats must react to a real order
_, cat = call('POST', '/categories', {'name': 'Stats Probe Cat'})
_, prod = call('POST', '/products', {
    'name': 'Stats Probe Product', 'sku': 'STATS-PROBE-1', 'categoryId': cat['id'],
    'unit': 'Piece', 'sellingPrice': 100, 'costPrice': 60,
    'currentStock': 50, 'minimumStock': 5,
})
pid = prod['id']

sales_before = stats('sales')
s, so = call('POST', '/sales-orders', {
    'soNumber': 'STATS-SO-1', 'client': 'Probe', 'date': '2026-08-10T00:00:00.000Z',
    'amount': 5000, 'paymentStatus': 'Pending',
    'items': [{'productId': pid, 'product': 'Stats Probe Product', 'qty': 5,
               'unit': 'Piece', 'rate': 1000}],
})
ok('probe sales order created', s == 201, (s, so))
sales_after = stats('sales')
ok(f"salesMTD rose {sales_before['salesMTD']} -> {sales_after['salesMTD']}",
   sales_after['salesMTD'] == sales_before['salesMTD'] + 5000, sales_after['salesMTD'])
ok(f"amountDue rose to {sales_after['amountDue']}",
   sales_after['amountDue'] == sales_before['amountDue'] + 5000)
ok('sales totalOrders rose',
   sales_after['totalOrders'] == sales_before['totalOrders'] + 1)

# The sale moved stock, so inventory stats must follow
inv_after = stats('inventory')
ok(f"inventory totalQty dropped by the 5 sold: {ivs['totalQty']} -> {inv_after['totalQty']}",
   inv_after['totalQty'] == ivs['totalQty'] + 50 - 5,
   (ivs['totalQty'], inv_after['totalQty']))

# avgOrderValue is now computable
cs2 = stats('clients')
ok(f"avgOrderValue now non-zero ({cs2['quickStats']['avgOrderValue']})",
   cs2['quickStats']['avgOrderValue'] > 0, cs2['quickStats'])

purchase_before = stats('purchase')
s, po = call('POST', '/purchase-orders', {
    'poNumber': 'STATS-PO-1', 'supplier': 'Probe Supplier',
    'date': '2026-08-10T00:00:00.000Z', 'amount': 3000, 'status': 'Received',
    'items': [{'productId': pid, 'product': 'Stats Probe Product', 'qty': 10,
               'unit': 'Piece', 'rate': 300}],
})
ok('probe purchase order created', s == 201, s)
purchase_after = stats('purchase')
ok(f"purchaseMTD rose {purchase_before['purchaseMTD']} -> {purchase_after['purchaseMTD']}",
   purchase_after['purchaseMTD'] == purchase_before['purchaseMTD'] + 3000)
ok(f"amountPaid rose (status Received) to {purchase_after['amountPaid']}",
   purchase_after['amountPaid'] == purchase_before['amountPaid'] + 3000)

print()
print('=' * 72)
print('5. CLEANUP + STATS RETURN TO BASELINE')
print('=' * 72)
call('DELETE', f"/sales-orders/{so['id']}")
call('DELETE', f"/purchase-orders/{po['id']}")
ok('salesMTD back to baseline', stats('sales')['salesMTD'] == sales_before['salesMTD'])
ok('purchaseMTD back to baseline',
   stats('purchase')['purchaseMTD'] == purchase_before['purchaseMTD'])
call('DELETE', f'/products/{pid}')
call('DELETE', f"/categories/{cat['id']}")
ok('inventory total back to baseline', stats('inventory')['totalItems'] == ivs['totalItems'])

print()
print('=' * 72)
print(f'{checks[0] - len(fails)}/{checks[0]} checks passed')
if fails:
    print('FAILED:')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('ALL GREEN')
