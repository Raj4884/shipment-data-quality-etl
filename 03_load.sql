-- Load only rows that passed every rule into the star schema.
INSERT INTO dw.dim_carrier (carrier_code) SELECT carrier_code FROM dw.approved_carriers ON CONFLICT DO NOTHING;

CREATE TEMP TABLE clean AS
SELECT * FROM staging.shipments_raw r
WHERE NOT EXISTS (SELECT 1 FROM dq.error_log e WHERE e.row_id = r.row_id);

INSERT INTO dw.dim_port (port_code)
SELECT DISTINCT p FROM (SELECT origin_port p FROM clean UNION SELECT dest_port FROM clean) x ON CONFLICT DO NOTHING;

INSERT INTO dw.dim_date (date_key, full_date, year, month, month_name)
SELECT to_char(d,'YYYYMMDD')::int, d, extract(year FROM d), extract(month FROM d), to_char(d,'Mon')
FROM (SELECT dispatch_date::date d FROM clean UNION SELECT delivery_date::date FROM clean) x ON CONFLICT DO NOTHING;

INSERT INTO dw.fact_shipments
SELECT c.shipment_id, dc.carrier_key, po.port_key, pd.port_key,
       to_char(c.dispatch_date::date,'YYYYMMDD')::int, to_char(c.delivery_date::date,'YYYYMMDD')::int,
       c.weight_kg::numeric, c.delivery_date::date - c.dispatch_date::date
FROM clean c
JOIN dw.dim_carrier dc ON dc.carrier_code = c.carrier_code
JOIN dw.dim_port po ON po.port_code = c.origin_port
JOIN dw.dim_port pd ON pd.port_code = c.dest_port;
