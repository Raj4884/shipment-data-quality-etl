#!/usr/bin/env bash
# Generates messy data, loads it, runs the validation rules, loads the star schema, and checks the counts.
set -euo pipefail
DB=${DB:-shipment_dq}
python3 generate_data.py
dropdb --if-exists "$DB" && createdb "$DB"
psql -d "$DB" -q -v ON_ERROR_STOP=1 -f 01_schema.sql 2>&1 | grep -v NOTICE || true
psql -d "$DB" -q -v ON_ERROR_STOP=1 -c "\copy staging.shipments_raw (shipment_id,carrier_code,origin_port,dest_port,weight_kg,dispatch_date,delivery_date) FROM 'shipments_raw.csv' CSV HEADER"
psql -d "$DB" -q -v ON_ERROR_STOP=1 -f 02_validate.sql
DB_NAME="$DB" python3 verify.py
psql -d "$DB" -q -v ON_ERROR_STOP=1 -f 03_load.sql
psql -d "$DB" -f 04_reports.sql
