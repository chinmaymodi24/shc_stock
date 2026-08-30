"""End-to-end API test for all six modules + the purchase/sale stock flow."""
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


def stock_of(pid):
    _, inv = call('GET', '/inventory')
    for row in inv:
        if row['productId'] == pid:
            return row['stockInHand']
    return None


print('=' * 72)
print('1. CATEGORIES  insert / update / delete')
print('=' * 72)
s, cat = call('POST', '/categories', {'name': 'E2E Test Category', 'description': 'tmp'})
ok('POST /categories -> 201', s == 201, s)
cat_id = cat['id']
s, upd = call('PUT', f'/categories/{cat_id}', {'name': 'E2E Renamed', 'description': 'x'})
ok('PUT /categories -> 200 + renamed', s == 200 and upd['name'] == 'E2E Renamed', (s, upd))
s, _ = call('POST', '/categories', {'name': '   '})
ok('POST /categories blank name -> 400', s == 400, s)

print()
print('=' * 72)
print('2. PRODUCTS  insert / update / delete')
print('=' * 72)
s, prod = call('POST', '/products', {
    'name': 'E2E Widget', 'sku': 'E2E-SKU-001', 'categoryId': cat_id,
    'unit': 'Piece', 'sellingPrice': 500, 'costPrice': 300,
    'currentStock': 100, 'minimumStock': 10,
})
ok('POST /products -> 201', s == 201, (s, prod))
pid = prod['id']
ok('product starts at stock 100', prod['currentStock'] == 100, prod.get('currentStock'))
s, upd = call('PUT', f'/products/{pid}', {
    'name': 'E2E Widget v2', 'sku': 'E2E-SKU-001', 'categoryId': cat_id,
    'unit': 'Piece', 'sellingPrice': 550, 'costPrice': 300,
    'currentStock': 100, 'minimumStock': 10,
})
ok('PUT /products -> 200 + renamed', s == 200 and upd['name'] == 'E2E Widget v2', (s, upd))
ok('product visible in /inventory', stock_of(pid) == 100, stock_of(pid))

print()
print('=' * 72)
print('3. CLIENTS  insert / update / delete')
print('=' * 72)
s, cl = call('POST', '/clients', {
    'name': 'E2E Client', 'regCity': 'Morbi', 'regState': 'Gujarat',
    'regAddr1': 'Plot 1', 'regPin': '363642', 'gstin': '24AAAAA0000A1Z5',
})
ok('POST /clients -> 201', s == 201, s)
cl_id = cl['id']
ok('address composed from reg fields', 'Morbi - 363642' in cl['address'], cl['address'])
s, upd = call('PUT', f'/clients/{cl_id}', {'name': 'E2E Client v2', 'regState': 'Gujarat'})
ok('PUT /clients -> 200 + renamed', s == 200 and upd['name'] == 'E2E Client v2', s)

print()
print('=' * 72)
print('4. PURCHASE  ->  stock moves only once the order is RECEIVED')
print('=' * 72)
before = stock_of(pid)
s, po = call('POST', '/purchase-orders', {
    'poNumber': 'E2E-PO-001', 'supplier': 'E2E Supplier',
    'date': '2026-08-10T00:00:00.000Z', 'amount': 7500, 'status': 'Pending',
    'paymentType': 'Half Payment', 'paidAmount': 3750,
    'items': [{'productId': pid, 'product': 'E2E Widget v2', 'qty': 25, 'unit': 'Piece', 'rate': 300}],
})
ok('POST /purchase-orders -> 201', s == 201, (s, po))
po_id = po['id']
ok('pending purchase left stock alone', stock_of(pid) == before, stock_of(pid))
ok('payment fields stored', po['paymentType'] == 'Half Payment' and po['paidAmount'] == 3750, po)
ok('purchase item stored productId', po['items'][0]['productId'] == pid, po['items'][0])

s, recv = call('PATCH', f'/purchase-orders/{po_id}/status', {'status': 'Received'})
ok('PATCH status Received -> 200', s == 200, (s, recv))
after = stock_of(pid)
ok(f'receiving 25 raised stock {before} -> {after}', after == before + 25, after)

# ...and moving it back off Received takes the stock out again.
call('PATCH', f'/purchase-orders/{po_id}/status', {'status': 'Pending'})
ok('un-receiving reversed the stock', stock_of(pid) == before, stock_of(pid))
call('PATCH', f'/purchase-orders/{po_id}/status', {'status': 'Received'})

_, movs = call('GET', f'/inventory/movements?productId={pid}')
ok('IN movement logged', any(m['type'] == 'IN' and m['refType'] == 'purchase' for m in movs), movs)

# Edit the PO: 25 -> 40 should net +15 more
s, po2 = call('PUT', f'/purchase-orders/{po_id}', {
    'poNumber': 'E2E-PO-001', 'supplier': 'E2E Supplier',
    'date': '2026-08-10T00:00:00.000Z', 'amount': 12000, 'status': 'Received',
    'items': [{'productId': pid, 'product': 'E2E Widget v2', 'qty': 40, 'unit': 'Piece', 'rate': 300}],
})
ok('PUT /purchase-orders -> 200', s == 200, (s, po2))
after_edit = stock_of(pid)
ok(f'edit 25->40 re-applied stock: {before}+40 = {after_edit}', after_edit == before + 40, after_edit)

print()
print('=' * 72)
print('5. SALES  ->  stock moves only once the order is DELIVERED')
print('=' * 72)
before_sale = stock_of(pid)
s, so = call('POST', '/sales-orders', {
    'soNumber': 'E2E-SO-001', 'client': 'E2E Client v2',
    'date': '2026-08-10T00:00:00.000Z', 'amount': 5500, 'status': 'Confirmed',
    'items': [{'productId': pid, 'product': 'E2E Widget v2', 'qty': 10, 'unit': 'Piece', 'rate': 550}],
})
ok('POST /sales-orders -> 201', s == 201, (s, so))
so_id = so['id']
ok('confirmed sale left stock alone', stock_of(pid) == before_sale, stock_of(pid))

s, dlv = call('PATCH', f'/sales-orders/{so_id}/status', {'status': 'Delivered'})
ok('PATCH status Delivered -> 200', s == 200, (s, dlv))
after_sale = stock_of(pid)
ok(f'delivering 10 lowered stock {before_sale} -> {after_sale}', after_sale == before_sale - 10, after_sale)

# Overselling must be refused and must not change stock. Only a delivered order
# books stock, so the order that oversells has to be created as Delivered.
s, err = call('POST', '/sales-orders', {
    'soNumber': 'E2E-SO-OVER', 'client': 'E2E Client v2',
    'date': '2026-08-10T00:00:00.000Z', 'status': 'Delivered',
    'items': [{'productId': pid, 'product': 'E2E Widget v2', 'qty': 999999, 'unit': 'Piece', 'rate': 1}],
})
ok('overselling -> 409', s == 409, (s, err))
ok('overselling left stock untouched', stock_of(pid) == after_sale, stock_of(pid))

print()
print('=' * 72)
print('6. INVENTORY  adjust / update / delete-movement')
print('=' * 72)
base_inv = stock_of(pid)
s, adj = call('POST', '/inventory/adjust', {'productId': pid, 'type': 'IN', 'qty': 7, 'note': 'found in bay 3'})
ok('POST /inventory/adjust IN -> 201', s == 201, (s, adj))
mov_id = adj['movementId']
ok(f'adjust IN 7 raised stock {base_inv} -> {stock_of(pid)}', stock_of(pid) == base_inv + 7, stock_of(pid))

s, adj2 = call('POST', '/inventory/adjust', {'productId': pid, 'type': 'OUT', 'qty': 2, 'note': 'damaged'})
ok('POST /inventory/adjust OUT -> 201', s == 201, s)
ok('adjust OUT 2 lowered stock', stock_of(pid) == base_inv + 5, stock_of(pid))

s, _ = call('POST', '/inventory/adjust', {'productId': pid, 'type': 'IN', 'qty': 0})
ok('adjust qty 0 -> 400', s == 400, s)

s, put = call('PUT', f'/inventory/{pid}', {'minimumStock': 500, 'stockLocation': 'Bay 3'})
ok('PUT /inventory -> 200', s == 200, s)
ok('minimumStock updated', put['minimumStock'] == 500, put)
ok('status recomputed to lowStock', put['status'] == 'lowStock', put['status'])

s, back = call('DELETE', f'/inventory/movements/{mov_id}')
ok('DELETE manual movement -> 200', s == 200, s)
ok('deleting the +7 adjustment reversed it', stock_of(pid) == base_inv - 2, stock_of(pid))

_, movs = call('GET', f'/inventory/movements?productId={pid}')
purchase_mov = next((m for m in movs if m['refType'] == 'purchase'), None)
s, err = call('DELETE', f"/inventory/movements/{purchase_mov['id']}")
ok('cannot delete a purchase movement here -> 400', s == 400, (s, err))

print()
print('=' * 72)
print('7. DELETING ORDERS REVERSES STOCK')
print('=' * 72)
pre_del = stock_of(pid)
s, _ = call('DELETE', f'/sales-orders/{so_id}')
ok('DELETE /sales-orders -> 204', s == 204, s)
ok(f'deleting the sale put 10 back: {pre_del} -> {stock_of(pid)}', stock_of(pid) == pre_del + 10, stock_of(pid))

pre_del = stock_of(pid)
s, _ = call('DELETE', f'/purchase-orders/{po_id}')
ok('DELETE /purchase-orders -> 204', s == 204, s)
ok(f'deleting the purchase removed 40: {pre_del} -> {stock_of(pid)}', stock_of(pid) == pre_del - 40, stock_of(pid))

s, _ = call('DELETE', f'/purchase-orders/{po_id}')
ok('re-delete purchase -> 404', s == 404, s)

print()
print('=' * 72)
print('8. CLEANUP (delete path for products / clients / categories)')
print('=' * 72)
s, _ = call('DELETE', f'/clients/{cl_id}')
ok('DELETE /clients -> 204', s == 204, s)
s, _ = call('DELETE', f'/products/{pid}')
ok('DELETE /products -> 204', s == 204, s)
s, _ = call('DELETE', f'/categories/{cat_id}')
ok('DELETE /categories -> 204', s == 204, s)
_, inv = call('GET', '/inventory')
ok('deleted product gone from /inventory', all(r['productId'] != pid for r in inv))

print()
print('=' * 72)
print(f'{checks[0] - len(fails)}/{checks[0]} checks passed')
if fails:
    print('FAILED:')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('ALL GREEN')
