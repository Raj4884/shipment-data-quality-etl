TRUNCATE dq.error_log;

-- Rule 1: repeated shipment_id (keep the first row, flag later ones)
INSERT INTO dq.error_log (row_id, rule, detail)
SELECT row_id, 'duplicate_shipment_id', shipment_id
FROM (SELECT row_id, shipment_id, row_number() OVER (PARTITION BY shipment_id ORDER BY row_id) AS rn
      FROM staging.shipments_raw) t WHERE rn > 1;

-- Rule 2: missing origin or destination port
INSERT INTO dq.error_log (row_id, rule, detail)
SELECT row_id, 'missing_port', shipment_id FROM staging.shipments_raw
WHERE nullif(trim(origin_port), '') IS NULL OR nullif(trim(dest_port), '') IS NULL;

-- Rule 3: weight is not a positive number
INSERT INTO dq.error_log (row_id, rule, detail)
SELECT row_id, 'bad_weight', weight_kg FROM staging.shipments_raw
WHERE weight_kg !~ '^[0-9]+(\.[0-9]+)?$' OR weight_kg::text ~ '^0+(\.0+)?$';

-- Rule 4: delivery date earlier than dispatch date
INSERT INTO dq.error_log (row_id, rule, detail)
SELECT row_id, 'delivery_before_dispatch', shipment_id FROM staging.shipments_raw
WHERE delivery_date::date < dispatch_date::date;

-- Rule 5: carrier not on the approved list
INSERT INTO dq.error_log (row_id, rule, detail)
SELECT r.row_id, 'unknown_carrier', r.carrier_code FROM staging.shipments_raw r
LEFT JOIN dw.approved_carriers a ON a.carrier_code = r.carrier_code
WHERE a.carrier_code IS NULL;
