-- Creating new tables

DROP TABLE IF EXISTS raw_eia_monthly_states;

CREATE TABLE raw_eia_monthly_states (
    year TEXT,
    month TEXT,
    state TEXT,
    data_status TEXT,
    com_revenue_thou_doll TEXT,
    com_sales_mwh TEXT,
    com_customers TEXT,
    com_price_cents_per_kwh TEXT
);

DROP TABLE IF EXISTS raw_census_dp03;

CREATE TABLE raw_census_dp03 (
    state_name TEXT,
    median_household_income TEXT,
    poverty_rate TEXT,
    employment_rate TEXT
);

DROP TABLE IF EXISTS raw_census_dp05;

CREATE TABLE raw_census_dp05 (
    state_name TEXT,
    total_population TEXT,
    total_housing_units TEXT
);

-- Checking if imports worked

SELECT *
FROM raw_eia_monthly_states
LIMIT 10;

SELECT *
FROM raw_census_dp03
LIMIT 10;

SELECT *
FROM raw_census_dp05
LIMIT 10;

SELECT COUNT(*) AS eia_rows
FROM raw_eia_monthly_states;

SELECT COUNT(*) AS dp03_rows
FROM raw_census_dp03;

SELECT COUNT(*) AS dp05_rows
FROM raw_census_dp05;

-- Creating state lookup table

DROP TABLE IF EXISTS state_lookup;

CREATE TABLE state_lookup (
    state_code TEXT,
    state_name TEXT
);

DROP TABLE IF EXISTS state_lookup;

CREATE TABLE state_lookup (
    state_code TEXT,
    state_name TEXT
);

INSERT INTO state_lookup (state_code, state_name) VALUES
('AL', 'Alabama'),
('AK', 'Alaska'),
('AZ', 'Arizona'),
('AR', 'Arkansas'),
('CA', 'California'),
('CO', 'Colorado'),
('CT', 'Connecticut'),
('DE', 'Delaware'),
('DC', 'District of Columbia'),
('FL', 'Florida'),
('GA', 'Georgia'),
('HI', 'Hawaii'),
('ID', 'Idaho'),
('IL', 'Illinois'),
('IN', 'Indiana'),
('IA', 'Iowa'),
('KS', 'Kansas'),
('KY', 'Kentucky'),
('LA', 'Louisiana'),
('ME', 'Maine'),
('MD', 'Maryland'),
('MA', 'Massachusetts'),
('MI', 'Michigan'),
('MN', 'Minnesota'),
('MS', 'Mississippi'),
('MO', 'Missouri'),
('MT', 'Montana'),
('NE', 'Nebraska'),
('NV', 'Nevada'),
('NH', 'New Hampshire'),
('NJ', 'New Jersey'),
('NM', 'New Mexico'),
('NY', 'New York'),
('NC', 'North Carolina'),
('ND', 'North Dakota'),
('OH', 'Ohio'),
('OK', 'Oklahoma'),
('OR', 'Oregon'),
('PA', 'Pennsylvania'),
('RI', 'Rhode Island'),
('SC', 'South Carolina'),
('SD', 'South Dakota'),
('TN', 'Tennessee'),
('TX', 'Texas'),
('UT', 'Utah'),
('VT', 'Vermont'),
('VA', 'Virginia'),
('WA', 'Washington'),
('WV', 'West Virginia'),
('WI', 'Wisconsin'),
('WY', 'Wyoming');

SELECT *
FROM state_lookup
ORDER BY state_name;

-- Cleaning EIA energy table

DROP TABLE IF EXISTS energy_commercial_clean;

CREATE TABLE energy_commercial_clean AS
SELECT
    CAST(year AS INT) AS year,
    CAST(month AS INT) AS month,
    MAKE_DATE(CAST(year AS INT), CAST(month AS INT), 1) AS energy_date,
    state AS state_code,
    data_status,

    CAST(NULLIF(REPLACE(com_revenue_thou_doll, ',', ''), '') AS NUMERIC) AS com_revenue_thousand_dollars,
    CAST(NULLIF(REPLACE(com_sales_mwh, ',', ''), '') AS NUMERIC) AS com_sales_mwh,
    CAST(NULLIF(REPLACE(com_customers, ',', ''), '') AS NUMERIC) AS com_customers,
    CAST(NULLIF(REPLACE(com_price_cents_per_kwh, ',', ''), '') AS NUMERIC) AS com_price_cents_per_kwh

FROM raw_eia_monthly_states
WHERE data_status = 'Final'
  AND state IS NOT NULL
  AND state <> '';

SELECT *
FROM energy_commercial_clean
LIMIT 10;

-- Cleaning DP03 Census table

DROP TABLE IF EXISTS census_dp03_clean_sql;

CREATE TABLE census_dp03_clean_sql AS
SELECT
    TRIM(state_name) AS state_name,
    CAST(NULLIF(REPLACE(median_household_income, ',', ''), '') AS NUMERIC) AS median_household_income,
    CAST(NULLIF(REPLACE(REPLACE(poverty_rate, '%', ''), ',', ''), '') AS NUMERIC) AS poverty_rate,
    CAST(NULLIF(REPLACE(REPLACE(employment_rate, '%', ''), ',', ''), '') AS NUMERIC) AS employment_rate
FROM raw_census_dp03
WHERE state_name IS NOT NULL
  AND TRIM(state_name) <> '';

SELECT *
FROM census_dp03_clean_sql
ORDER BY state_name
LIMIT 10;

-- Cleaning DP05 Census table

DROP TABLE IF EXISTS census_dp05_clean_sql;

CREATE TABLE census_dp05_clean_sql AS
SELECT
    TRIM(state_name) AS state_name,
    CAST(NULLIF(REPLACE(total_population, ',', ''), '') AS NUMERIC) AS total_population,
    CAST(NULLIF(REPLACE(total_housing_units, ',', ''), '') AS NUMERIC) AS total_housing_units
FROM raw_census_dp05
WHERE state_name IS NOT NULL
  AND TRIM(state_name) <> ''
  AND state_name <> 'Puerto Rico';

SELECT *
FROM census_dp05_clean_sql
ORDER BY state_name
LIMIT 10;

-- Creating final modeling dataset

DROP TABLE IF EXISTS modeling_dataset;

CREATE TABLE modeling_dataset AS
SELECT
    e.year,
    e.month,
    e.energy_date,
    e.state_code,
    s.state_name,

    e.com_revenue_thousand_dollars,
    e.com_sales_mwh,
    e.com_customers,
    e.com_price_cents_per_kwh,

    d3.median_household_income,
    d3.poverty_rate,
    d3.employment_rate,

    d5.total_population,
    d5.total_housing_units,

    e.com_price_cents_per_kwh * d3.poverty_rate AS price_poverty_interaction,

    e.com_sales_mwh / NULLIF(e.com_customers, 0) AS sales_mwh_per_customer,

    LAG(e.com_sales_mwh, 1) OVER (
        PARTITION BY e.state_code
        ORDER BY e.energy_date
    ) AS sales_lag_1_month,

    LAG(e.com_sales_mwh, 12) OVER (
        PARTITION BY e.state_code
        ORDER BY e.energy_date
    ) AS sales_lag_12_month

FROM energy_commercial_clean e
LEFT JOIN state_lookup s
    ON e.state_code = s.state_code
LEFT JOIN census_dp03_clean_sql d3
    ON s.state_name = d3.state_name
LEFT JOIN census_dp05_clean_sql d5
    ON s.state_name = d5.state_name;

SELECT *
FROM modeling_dataset
LIMIT 20;

-- Checking if the join worked properly

SELECT
    COUNT(*) AS total_rows,
    COUNT(state_name) AS rows_with_state_name,
    COUNT(median_household_income) AS rows_with_income,
    COUNT(poverty_rate) AS rows_with_poverty,
    COUNT(total_population) AS rows_with_population
FROM modeling_dataset;

SELECT DISTINCT state_code, state_name
FROM modeling_dataset
WHERE median_household_income IS NULL
   OR poverty_rate IS NULL
   OR total_population IS NULL
ORDER BY state_code;

-- Top states by average commercial electricity use

SELECT
    state_name,
    ROUND(AVG(com_sales_mwh), 2) AS avg_monthly_commercial_sales_mwh
FROM modeling_dataset
GROUP BY state_name
ORDER BY avg_monthly_commercial_sales_mwh DESC
LIMIT 10;

-- Average commercial electricity price by state

SELECT
    state_name,
    ROUND(AVG(com_price_cents_per_kwh), 2) AS avg_commercial_price
FROM modeling_dataset
GROUP BY state_name
ORDER BY avg_commercial_price DESC
LIMIT 10;

-- Monthly seasonality

SELECT
    month,
    ROUND(AVG(com_sales_mwh), 2) AS avg_commercial_sales_mwh
FROM modeling_dataset
GROUP BY month
ORDER BY month;

-- Poverty and price interaction by state

SELECT
    state_name,
    ROUND(AVG(com_price_cents_per_kwh), 2) AS avg_price,
    ROUND(AVG(poverty_rate), 2) AS poverty_rate,
    ROUND(AVG(price_poverty_interaction), 2) AS avg_price_poverty_interaction
FROM modeling_dataset
GROUP BY state_name
ORDER BY avg_price_poverty_interaction DESC
LIMIT 10;