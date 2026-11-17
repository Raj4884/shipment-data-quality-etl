"""Create a messy shipment CSV with a known number of injected errors.
Synthetic data: random values, not from any real company."""
import csv, json, random
from datetime import date, timedelta

random.seed(7)
CARRIERS = ["MAEU", "MSCU", "CMDU", "HLCU", "ONEY", "EGLV", "ZIMU", "YMLU"]
ORIGINS = ["INNSA", "INMUN", "INMAA", "INCOK", "INVTZ", "INTUT", "INKOL", "INPAV"]
DESTS = ["AEJEA", "SGSIN", "NLRTM", "DEHAM", "USNYC", "CNSHA", "LKCMB", "GBFXT"]
N = 10_000
COUNTS = {"duplicate_shipment_id": 150, "missing_port": 120, "bad_weight": 90,
          "delivery_before_dispatch": 70, "unknown_carrier": 60}

rows = []
for i in range(1, N + 1):
    dispatch = date(2026, 1, 1) + timedelta(days=random.randint(0, 270))
    delivery = dispatch + timedelta(days=random.randint(5, 35))
    rows.append({"shipment_id": f"SHP{i:06d}", "carrier_code": random.choice(CARRIERS),
                 "origin_port": random.choice(ORIGINS), "dest_port": random.choice(DESTS),
                 "weight_kg": str(round(random.uniform(200, 24000), 1)),
                 "dispatch_date": dispatch.isoformat(), "delivery_date": delivery.isoformat()})

# each injected error goes on its own row, so detected counts must match exactly
idx = random.sample(range(N), sum(v for k, v in COUNTS.items() if k != "duplicate_shipment_id"))
pos = 0
def take(n):
    global pos
    out = idx[pos:pos + n]; pos += n; return out

for r in take(COUNTS["missing_port"]):
    rows[r][random.choice(["origin_port", "dest_port"])] = random.choice(["", "  "])
for r in take(COUNTS["bad_weight"]):
    rows[r]["weight_kg"] = random.choice(["0", "-150.5", "abc"])
for r in take(COUNTS["delivery_before_dispatch"]):
    d = date.fromisoformat(rows[r]["dispatch_date"])
    rows[r]["delivery_date"] = (d - timedelta(days=random.randint(1, 10))).isoformat()
for r in take(COUNTS["unknown_carrier"]):
    rows[r]["carrier_code"] = random.choice(["XXXX", "ABCD", "ZZZZ"])

clean_pool = [i for i in range(N) if i not in set(idx)]
for r in random.sample(clean_pool, COUNTS["duplicate_shipment_id"]):
    rows.append(dict(rows[r]))          # exact repeat of a good row, appended at the end

with open("shipments_raw.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
json.dump(COUNTS, open("expected_errors.json", "w"), indent=2)
print(f"wrote {len(rows)} rows with injected errors: {COUNTS}")
