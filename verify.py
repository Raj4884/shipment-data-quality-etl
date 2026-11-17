"""Compare what the SQL rules found against what generate_data.py injected."""
import json, subprocess, sys
exp = json.load(open("expected_errors.json"))
out = subprocess.run(["psql", "-d", __import__("os").environ.get("DB_NAME", "shipment_dq"), "-At", "-F", "|",
                      "-c", "SELECT rule, count(*) FROM dq.error_log GROUP BY rule"],
                     capture_output=True, text=True, check=True).stdout
found = {l.split("|")[0]: int(l.split("|")[1]) for l in out.strip().splitlines()}
ok = True
for rule, n in exp.items():
    got = found.get(rule, 0)
    print(f"{rule:28s} expected {n:4d}  found {got:4d}  {'OK' if got == n else 'MISMATCH'}")
    ok &= got == n
print("ALL RULES MATCH" if ok else "SOME RULES DO NOT MATCH")
sys.exit(0 if ok else 1)
