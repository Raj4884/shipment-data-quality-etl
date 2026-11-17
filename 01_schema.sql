DROP SCHEMA IF EXISTS staging, dq, dw CASCADE;
CREATE SCHEMA staging; CREATE SCHEMA dq; CREATE SCHEMA dw;

-- staging: everything is text so the load never fails on bad values
CREATE TABLE staging.shipments_raw (
    row_id        serial PRIMARY KEY,
    shipment_id   text, carrier_code text, origin_port text, dest_port text,
    weight_kg     text, dispatch_date text, delivery_date text
);

-- error log: one row per failed rule per record
CREATE TABLE dq.error_log (
    error_id serial PRIMARY KEY,
    row_id   int  NOT NULL,
    rule     text NOT NULL,
    detail   text
);

-- star schema
CREATE TABLE dw.dim_carrier (carrier_key serial PRIMARY KEY, carrier_code text UNIQUE NOT NULL);
CREATE TABLE dw.dim_port    (port_key    serial PRIMARY KEY, port_code    text UNIQUE NOT NULL);
CREATE TABLE dw.dim_date    (date_key int PRIMARY KEY, full_date date UNIQUE NOT NULL, year int, month int, month_name text);
CREATE TABLE dw.fact_shipments (
    shipment_id   text PRIMARY KEY,
    carrier_key   int  NOT NULL REFERENCES dw.dim_carrier,
    origin_key    int  NOT NULL REFERENCES dw.dim_port,
    dest_key      int  NOT NULL REFERENCES dw.dim_port,
    dispatch_key  int  NOT NULL REFERENCES dw.dim_date,
    delivery_key  int  NOT NULL REFERENCES dw.dim_date,
    weight_kg     numeric(10,1) NOT NULL CHECK (weight_kg > 0),
    transit_days  int  NOT NULL CHECK (transit_days >= 0)
);

-- the approved carrier list used by the validation rule
CREATE TABLE dw.approved_carriers (carrier_code text PRIMARY KEY);
INSERT INTO dw.approved_carriers VALUES ('MAEU'),('MSCU'),('CMDU'),('HLCU'),('ONEY'),('EGLV'),('ZIMU'),('YMLU');
