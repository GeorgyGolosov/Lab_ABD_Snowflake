-- Разведочный анализ
SELECT COUNT(*) AS raw_rows FROM raw_data;

SELECT file_id, COUNT(*) AS rows_per_file
FROM raw_data
GROUP BY file_id
ORDER BY file_id;

SELECT
    COUNT(DISTINCT customer_email) AS unique_customers,
    COUNT(DISTINCT seller_email) AS unique_sellers,
    COUNT(DISTINCT product_name) AS unique_product_names,
    COUNT(DISTINCT (store_name, store_city, store_country)) AS unique_stores,
    COUNT(DISTINCT (supplier_name, supplier_city, supplier_country)) AS unique_suppliers
FROM raw_data;

SELECT
    COUNT(*) FILTER (WHERE NULLIF(BTRIM(customer_email), '') IS NULL) AS null_customer_emails,
    COUNT(*) FILTER (WHERE NULLIF(BTRIM(sale_total_price), '') IS NULL) AS null_sale_prices,
    COUNT(*) FILTER (WHERE NULLIF(BTRIM(sale_date), '') IS NULL) AS null_sale_dates
FROM raw_data;

SELECT COUNT(*) AS unique_countries
FROM (
    SELECT NULLIF(BTRIM(customer_country), '') AS country FROM raw_data
    UNION
    SELECT NULLIF(BTRIM(seller_country), '') FROM raw_data
    UNION
    SELECT NULLIF(BTRIM(store_country), '') FROM raw_data
    UNION
    SELECT NULLIF(BTRIM(supplier_country), '') FROM raw_data
) AS countries
WHERE country IS NOT NULL;

SELECT COUNT(DISTINCT NULLIF(BTRIM(product_category), '')) AS unique_categories
FROM raw_data;
