import gzip
import json
import re

backup_file = 'db_cluster-06-11-2026@05-52-29.backup.gz'

dispatchers = []
routes = {}
drivers = []
units = []

current_table = None
table_headers = {}

with gzip.open(backup_file, 'rt', encoding='utf-8', errors='ignore') as f:
    for line in f:
        copy_match = re.match(r'COPY\s+(?:public\.)?(\w+)\s*\(([^)]+)\)\s+FROM stdin;', line)
        if copy_match:
            current_table = copy_match.group(1)
            raw_cols = [c.strip().strip('"') for c in copy_match.group(2).split(',')]
            table_headers[current_table] = raw_cols
            continue
            
        if current_table:
            if line.strip() == '\\.':
                current_table = None
                continue
            cols = line.rstrip('\n').split('\t')
            headers = table_headers.get(current_table, [])
            row = dict(zip(headers, cols))
            
            def clean(val):
                return None if val == '\\N' else val

            if current_table == 'authorized_dispatchers':
                dispatchers.append({
                    'id': clean(row.get('id')),
                    'uuid': clean(row.get('uuid')),
                    'email': clean(row.get('email')),
                    'name': clean(row.get('name')),
                    'role': clean(row.get('role')),
                    'status': clean(row.get('status')),
                    'is_authorized': clean(row.get('status')) == 'active',
                    'created_at': clean(row.get('created_at')),
                    'updated_at': clean(row.get('updated_at')),
                })
            elif current_table == 'master_routes':
                cfg = clean(row.get('config'))
                try:
                    cfg_json = json.loads(cfg) if cfg else {}
                except Exception:
                    cfg_json = {}
                route_uuid = clean(row.get('uuid'))
                routes[route_uuid] = {
                    'id': clean(row.get('id')),
                    'uuid': route_uuid,
                    'route_code': clean(row.get('route_code')),
                    'route_name': clean(row.get('route_name')),
                    'color': int(row.get('color', 4294940672)),
                    'position': int(row.get('position', 0)),
                    'config': cfg_json,
                    'units': [],
                    'drivers': [],
                    'created_at': clean(row.get('created_at')),
                    'updated_at': clean(row.get('updated_at')),
                }
            elif current_table == 'master_units':
                units.append({
                    'id': clean(row.get('id')),
                    'uuid': clean(row.get('uuid')),
                    'route_uuid': clean(row.get('route_uuid')),
                    'number': clean(row.get('number')),
                    'active': clean(row.get('active')) == 't',
                    'position': int(row.get('position', 0)),
                })
            elif current_table == 'master_drivers':
                s = clean(row.get('default_shift'))
                shift = int(s) if s and s.isdigit() else None
                drivers.append({
                    'id': clean(row.get('id')),
                    'uuid': clean(row.get('uuid')),
                    'route_uuid': clean(row.get('route_uuid')),
                    'full_name': clean(row.get('full_name')),
                    'call_name': clean(row.get('call_name')),
                    'status': clean(row.get('status')),
                    'default_unit_number': clean(row.get('default_unit_number')),
                    'default_shift': shift,
                    'active': clean(row.get('active')) == 't',
                })

for u in units:
    r_uuid = u.get('route_uuid')
    if r_uuid in routes:
        routes[r_uuid]['units'].append(u)

for d in drivers:
    r_uuid = d.get('route_uuid')
    if r_uuid in routes:
        routes[r_uuid]['drivers'].append(d)

for r in routes.values():
    r['units'].sort(key=lambda x: x['position'])

total_units = sum(len(r['units']) for r in routes.values())
total_drivers = sum(len(r['drivers']) for r in routes.values())

print('Parsed successfully:')
print(f' - {len(dispatchers)} dispatchers')
print(f' - {len(routes)} routes')
print(f' - Total {total_units} units mapped')
print(f' - Total {total_drivers} drivers mapped')

output_path = 'seed_data_firestore.json'
with open(output_path, 'w', encoding='utf-8') as out:
    json.dump({
        'dispatchers': dispatchers,
        'routes': list(routes.values())
    }, out, indent=2, ensure_ascii=False)

print(f'Saved to {output_path}')
