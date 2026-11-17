# Shipment Data Quality Checks and Star-Schema Load (PostgreSQL + Python)

Messy shipment records go into a staging table, five SQL rules check them, and only the clean rows are loaded into a star schema for reporting. The data is randomly generated, not real.

## How it works

1. `generate_data.py` writes 10,150 rows and injects a known number of errors, each on its own row.
2. The CSV is loaded into `staging.shipments_raw`, where every column is text so bad values do not stop the load.
3. `02_validate.sql` runs five rules and writes every failure to `dq.error_log`.
4. `03_load.sql` loads the rows that passed into `dw.fact_shipments` plus carrier, port and date dimensions.
5. `04_reports.sql` runs reports: error summary, monthly shipments by carrier with each carrier's share, and ranked transit time by destination port.
6. `verify.py` compares what the rules found against what was injected.

## Rules and results

| Rule | Injected | Found |
|---|---|---|
| Duplicate shipment ID | 150 | 150 |
| Missing origin or destination port | 120 | 120 |
| Weight is zero, negative or not a number | 90 | 90 |
| Delivery date before dispatch date | 70 | 70 |
| Carrier not on the approved list | 60 | 60 |

Result: 490 rows flagged, 9,660 rows loaded into the fact table.

Matching counts show the rules work on this data. Real data has messier cases, so the rules would need extending.

## Run it

```bash
export PGHOST=localhost PGUSER=postgres
./run.sh
```
