TRUNCATE fact_sales, dim_customer, dim_seller, dim_product, dim_store, dim_supplier, dim_city, dim_country, dim_category CASCADE;

-- 1. dim_country
INSERT INTO dim_country (name)
SELECT DISTINCT TRIM(customer_country) FROM raw_data WHERE customer_country IS NOT NULL AND TRIM(customer_country) != ''
UNION
SELECT DISTINCT TRIM(seller_country) FROM raw_data WHERE seller_country IS NOT NULL AND TRIM(seller_country) != ''
UNION
SELECT DISTINCT TRIM(store_country) FROM raw_data WHERE store_country IS NOT NULL AND TRIM(store_country) != ''
UNION
SELECT DISTINCT TRIM(supplier_country) FROM raw_data WHERE supplier_country IS NOT NULL AND TRIM(supplier_country) != ''
ON CONFLICT (name) DO NOTHING;

-- 2. dim_city
INSERT INTO dim_city (name, state, country_id)
SELECT DISTINCT COALESCE(NULLIF(TRIM(store_city), ''), '(unknown)'), COALESCE(NULLIF(TRIM(store_state), ''), '(unknown)'), co.country_id
FROM raw_data r JOIN dim_country co ON COALESCE(NULLIF(TRIM(r.store_country), ''), '(unknown)') = co.name
WHERE r.store_city IS NOT NULL AND TRIM(r.store_city) != ''
UNION
SELECT DISTINCT COALESCE(NULLIF(TRIM(supplier_city), ''), '(unknown)'), '(unknown)', co.country_id
FROM raw_data r JOIN dim_country co ON COALESCE(NULLIF(TRIM(r.supplier_country), ''), '(unknown)') = co.name
WHERE r.supplier_city IS NOT NULL AND TRIM(r.supplier_city) != ''
ON CONFLICT (name, state, country_id) DO NOTHING;

-- 3. dim_category
INSERT INTO dim_category (name)
SELECT DISTINCT TRIM(product_category) FROM raw_data WHERE product_category IS NOT NULL AND TRIM(product_category) != '';

-- 4. dim_customer
INSERT INTO dim_customer
SELECT DISTINCT ON (TRIM(r.id)::INTEGER)
    TRIM(r.id)::INTEGER, NULLIF(TRIM(r.customer_first_name), ''), NULLIF(TRIM(r.customer_last_name), ''), NULLIF(TRIM(r.customer_age), '')::INTEGER, NULLIF(TRIM(r.customer_email), ''),
    co.country_id, NULLIF(TRIM(r.customer_postal_code), ''), NULLIF(TRIM(r.customer_pet_type), ''), NULLIF(TRIM(r.customer_pet_name), ''), NULLIF(TRIM(r.customer_pet_breed), '')
FROM raw_data r LEFT JOIN dim_country co ON TRIM(r.customer_country) = co.name
WHERE r.id IS NOT NULL AND TRIM(r.id) != '' ORDER BY TRIM(r.id)::INTEGER;

-- 5. dim_seller
INSERT INTO dim_seller
SELECT DISTINCT ON (TRIM(r.id)::INTEGER)
    TRIM(r.id)::INTEGER, NULLIF(TRIM(r.seller_first_name), ''), NULLIF(TRIM(r.seller_last_name), ''), NULLIF(TRIM(r.seller_email), ''), co.country_id, NULLIF(TRIM(r.seller_postal_code), '')
FROM raw_data r LEFT JOIN dim_country co ON TRIM(r.seller_country) = co.name
WHERE r.id IS NOT NULL AND TRIM(r.id) != '' ORDER BY TRIM(r.id)::INTEGER;

-- 6. dim_product
INSERT INTO dim_product
SELECT DISTINCT ON (TRIM(r.id)::INTEGER)
    TRIM(r.id)::INTEGER, NULLIF(TRIM(r.product_name), ''), cat.category_id, NULLIF(TRIM(r.product_price), '')::DECIMAL(10,2), NULLIF(TRIM(r.product_quantity), '')::INTEGER,
    NULLIF(TRIM(r.pet_category), ''), NULLIF(TRIM(r.product_weight), ''), NULLIF(TRIM(r.product_color), ''), NULLIF(TRIM(r.product_size), ''), NULLIF(TRIM(r.product_material), ''), NULLIF(TRIM(r.product_description), ''),
    NULLIF(TRIM(r.product_brand), ''), NULLIF(TRIM(r.product_reviews), '')::INTEGER, TO_DATE(NULLIF(TRIM(r.product_release_date), ''), 'MM/DD/YYYY'),
    NULLIF(TRIM(r.product_rating), '')::DECIMAL(3,2), TO_DATE(NULLIF(TRIM(r.product_expiry_date), ''), 'MM/DD/YYYY')
FROM raw_data r LEFT JOIN dim_category cat ON TRIM(r.product_category) = cat.name
WHERE r.id IS NOT NULL AND TRIM(r.id) != '' ORDER BY TRIM(r.id)::INTEGER;

-- 7. dim_store
INSERT INTO dim_store (store_id, name, location, city_id, phone, email)
SELECT DISTINCT
    (abs(hashtext(COALESCE(TRIM(store_name), '') || '|' || COALESCE(TRIM(store_location), '') || '|' || COALESCE(TRIM(store_city), '') || '|' || COALESCE(TRIM(store_state), '') || '|' || COALESCE(TRIM(store_country), '') || '|' || COALESCE(TRIM(store_phone), '') || '|' || COALESCE(TRIM(store_email), ''))) % 2147483647) AS store_id,
    NULLIF(TRIM(store_name), ''), NULLIF(TRIM(store_location), ''), dc.city_id, NULLIF(TRIM(store_phone), ''), NULLIF(TRIM(store_email), '')
FROM raw_data r LEFT JOIN dim_city dc ON COALESCE(NULLIF(TRIM(r.store_city), ''), '(unknown)') = dc.name AND COALESCE(NULLIF(TRIM(r.store_state), ''), '(unknown)') = dc.state
WHERE r.store_name IS NOT NULL AND TRIM(r.store_name) != '';

-- 8. dim_supplier
INSERT INTO dim_supplier (supplier_id, name, contact, email, phone, address, city_id)
SELECT DISTINCT
    (abs(hashtext(COALESCE(TRIM(supplier_name), '') || '|' || COALESCE(TRIM(supplier_contact), '') || '|' || COALESCE(TRIM(supplier_email), '') || '|' || COALESCE(TRIM(supplier_phone), '') || '|' || COALESCE(TRIM(supplier_address), '') || '|' || COALESCE(TRIM(supplier_city), '') || '|' || COALESCE(TRIM(supplier_country), ''))) % 2147483647) AS supplier_id,
    NULLIF(TRIM(supplier_name), ''), NULLIF(TRIM(supplier_contact), ''), NULLIF(TRIM(supplier_email), ''), NULLIF(TRIM(supplier_phone), ''), NULLIF(TRIM(supplier_address), ''), dc.city_id
FROM raw_data r LEFT JOIN dim_city dc ON COALESCE(NULLIF(TRIM(r.supplier_city), ''), '(unknown)') = dc.name
WHERE r.supplier_name IS NOT NULL AND TRIM(r.supplier_name) != '';

-- 9. fact_sales
INSERT INTO fact_sales
SELECT
    (r.file_id * 1000) + TRIM(r.id)::INTEGER AS sale_id,
    TRIM(r.sale_customer_id)::INTEGER, TRIM(r.sale_seller_id)::INTEGER, TRIM(r.sale_product_id)::INTEGER,
    (abs(hashtext(COALESCE(TRIM(store_name), '') || '|' || COALESCE(TRIM(store_location), '') || '|' || COALESCE(TRIM(store_city), '') || '|' || COALESCE(TRIM(store_state), '') || '|' || COALESCE(TRIM(store_country), '') || '|' || COALESCE(TRIM(store_phone), '') || '|' || COALESCE(TRIM(store_email), ''))) % 2147483647),
    (abs(hashtext(COALESCE(TRIM(supplier_name), '') || '|' || COALESCE(TRIM(supplier_contact), '') || '|' || COALESCE(TRIM(supplier_email), '') || '|' || COALESCE(TRIM(supplier_phone), '') || '|' || COALESCE(TRIM(supplier_address), '') || '|' || COALESCE(TRIM(supplier_city), '') || '|' || COALESCE(TRIM(supplier_country), ''))) % 2147483647),
    TO_DATE(NULLIF(TRIM(r.sale_date), ''), 'MM/DD/YYYY'), NULLIF(TRIM(r.sale_quantity), '')::INTEGER, NULLIF(TRIM(r.sale_total_price), '')::DECIMAL(10,2)
FROM raw_data r WHERE r.id IS NOT NULL AND TRIM(r.id) != '';
