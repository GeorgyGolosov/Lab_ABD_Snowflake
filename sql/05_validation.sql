-- Автоматические контрольные точки. Любое нарушение прерывает initdb.
DO $$
DECLARE
    actual_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO actual_count FROM raw_data;
    IF actual_count <> 10000 THEN
        RAISE EXCEPTION 'raw_data: expected 10000 rows, got %', actual_count;
    END IF;

    SELECT COUNT(*) INTO actual_count
    FROM (
        SELECT file_id
        FROM raw_data
        GROUP BY file_id
        HAVING COUNT(*) = 1000
    ) AS complete_files;
    IF actual_count <> 10 THEN
        RAISE EXCEPTION 'raw_data: expected 10 files with 1000 rows each, got %', actual_count;
    END IF;

    SELECT COUNT(*) INTO actual_count FROM fact_sales;
    IF actual_count <> 10000 THEN
        RAISE EXCEPTION 'fact_sales: expected 10000 rows, got %', actual_count;
    END IF;

    SELECT COUNT(*) INTO actual_count
    FROM fact_sales
    WHERE customer_id IS NULL OR seller_id IS NULL OR product_id IS NULL
       OR store_id IS NULL OR supplier_id IS NULL;
    IF actual_count <> 0 THEN
        RAISE EXCEPTION 'fact_sales: found % rows with missing dimension keys', actual_count;
    END IF;
END
$$;

SELECT 'raw_data' AS table_name, COUNT(*) AS row_count FROM raw_data
UNION ALL SELECT 'fact_sales', COUNT(*) FROM fact_sales
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_seller', COUNT(*) FROM dim_seller
UNION ALL SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL SELECT 'dim_store', COUNT(*) FROM dim_store
UNION ALL SELECT 'dim_supplier', COUNT(*) FROM dim_supplier
UNION ALL SELECT 'dim_country', COUNT(*) FROM dim_country
UNION ALL SELECT 'dim_city', COUNT(*) FROM dim_city
UNION ALL SELECT 'dim_category', COUNT(*) FROM dim_category
ORDER BY table_name;

SELECT
    COUNT(DISTINCT sale_date) AS distinct_sale_dates,
    SUM(total_price) AS total_revenue
FROM fact_sales;
