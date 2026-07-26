import pandas as pd
import re

SRC = r"C:\Users\Admin\Downloads\Transactions.xlsx"
OUT = r"D:\Work\SHC\SHC STOCK\shc_stock\lib\app\modules\clients\data\clients_seed_data.dart"

df = pd.read_excel(SRC, sheet_name="Day Book", header=None)

def dart_str(v):
    if v is None:
        return "''"
    s = str(v).strip()
    if s.lower() == 'nan':
        s = ''
    # collapse whitespace/newlines
    s = re.sub(r'\s+', ' ', s).strip()
    s = s.replace('\\', '\\\\').replace("'", "\\'").replace('\$', '\\\$')
    return "'" + s + "'"

rows = []
for i in range(8, len(df)):
    sl = df.iat[i, 0]
    if pd.isna(sl):
        continue
    name = df.iat[i, 1]
    if pd.isna(name) or str(name).strip() == '':
        continue
    address = df.iat[i, 2]
    state = df.iat[i, 3]
    country = df.iat[i, 4]
    regtype = df.iat[i, 5]
    gstin = df.iat[i, 6]
    pan = df.iat[i, 7]
    rows.append((name, address, state, country, regtype, gstin, pan))

print(f'Total client rows: {len(rows)}')

lines = []
lines.append("// GENERATED FILE — universal client list sourced from the company's")
lines.append("// accounting export (Day Book: All Parties under Sundry Creditors).")
lines.append("// Regenerate with scripts/gen_clients_data.py if the source sheet changes.")
lines.append("import '../models/client_model.dart';")
lines.append("")
lines.append("final List<ClientModel> kClientsSeedData = [")
for idx, (name, address, state, country, regtype, gstin, pan) in enumerate(rows, start=1):
    code = f"CLT-{idx:04d}"
    reg = regtype
    if pd.isna(reg) or str(reg).strip() == '' or str(reg).strip().startswith('_x'):
        reg = 'Unknown'
    lines.append(
        "  ClientModel("
        f"id: '{idx}', code: {dart_str(code)}, name: {dart_str(name)}, "
        f"address: {dart_str(address)}, state: {dart_str(state)}, "
        f"country: {dart_str(country)}, registrationType: {dart_str(reg)}, "
        f"gstin: {dart_str(gstin)}, pan: {dart_str(pan)}),"
    )
lines.append("];")

with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')

print('Wrote', OUT)
