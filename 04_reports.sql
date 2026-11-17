-- 1. Error summary
SELECT rule, count(*) AS rows_flagged FROM dq.error_log GROUP BY rule ORDER BY rows_flagged DESC;

-- 2. Monthly shipments and tonnes by carrier, with each carrier's share of the month (window function)
SELECT d.year, d.month, c.carrier_code, count(*) AS shipments, round(sum(f.weight_kg)/1000, 1) AS tonnes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY d.year, d.month), 1) AS share_pct
FROM dw.fact_shipments f
JOIN dw.dim_date d ON d.date_key = f.dispatch_key
JOIN dw.dim_carrier c ON c.carrier_key = f.carrier_key
GROUP BY d.year, d.month, c.carrier_code ORDER BY d.year, d.month, shipments DESC LIMIT 12;

-- 3. Average transit days per destination port, ranked (CTE + RANK)
WITH transit AS (
    SELECT p.port_code AS dest, avg(f.transit_days) AS avg_days, count(*) AS shipments
    FROM dw.fact_shipments f JOIN dw.dim_port p ON p.port_key = f.dest_key GROUP BY p.port_code
)
SELECT dest, shipments, round(avg_days, 1) AS avg_transit_days, RANK() OVER (ORDER BY avg_days DESC) AS slowest_rank
FROM transit ORDER BY slowest_rank;
