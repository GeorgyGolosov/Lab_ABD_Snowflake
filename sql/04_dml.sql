TRUNCATE TABLE
    fact_sales,
    dim_customer,
    dim_seller,
    dim_product,
    dim_store,
    dim_supplier,
    dim_city,
    dim_country,
    dim_category
RESTART IDENTITY CASCADE;

-- 1. Страны из всех четырёх групп исходных полей.
INSERT INTO dim_country (name)
SELECT country
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

-- 2. Города магазинов и поставщиков
INSERT INTO dim_city (name, state, country_id)
SELECT source.name, source.state, country.country_id
FROM (
    SELECT DISTINCT
        BTRIM(store_city) AS name,
        COALESCE(NULLIF(BTRIM(store_state), ''), '(unknown)') AS state,
        BTRIM(store_country) AS country_name
    FROM raw_data
    WHERE NULLIF(BTRIM(store_city), '') IS NOT NULL
      AND NULLIF(BTRIM(store_country), '') IS NOT NULL

    UNION

    SELECT DISTINCT
        BTRIM(supplier_city),
        '(unknown)',
        BTRIM(supplier_country)
    FROM raw_data
    WHERE NULLIF(BTRIM(supplier_city), '') IS NOT NULL
      AND NULLIF(BTRIM(supplier_country), '') IS NOT NULL
) AS source
JOIN dim_country AS country ON country.name = source.country_name;

-- 3. Категории товаров.
INSERT INTO dim_category (name)
SELECT DISTINCT BTRIM(product_category)
FROM raw_data
WHERE NULLIF(BTRIM(product_category), '') IS NOT NULL;

-- Локальные ID 1..1000 повторяются в 10 файлах. Формула file_id * 1000 + id
-- создаёт ключи 1..10000 и сохраняет все сущности.
-- 4. Клиенты.
INSERT INTO dim_customer (
    customer_id, first_name, last_name, age, email, country_id,
    postal_code, pet_type, pet_name, pet_breed
)
SELECT
    (r.file_id * 1000) + BTRIM(r.sale_customer_id)::INTEGER,
    NULLIF(BTRIM(r.customer_first_name), ''),
    NULLIF(BTRIM(r.customer_last_name), ''),
    NULLIF(BTRIM(r.customer_age), '')::INTEGER,
    BTRIM(r.customer_email),
    country.country_id,
    NULLIF(BTRIM(r.customer_postal_code), ''),
    NULLIF(BTRIM(r.customer_pet_type), ''),
    NULLIF(BTRIM(r.customer_pet_name), ''),
    NULLIF(BTRIM(r.customer_pet_breed), '')
FROM raw_data AS r
JOIN dim_country AS country ON country.name = BTRIM(r.customer_country);

-- 5. Продавцы.
INSERT INTO dim_seller (
    seller_id, first_name, last_name, email, country_id, postal_code
)
SELECT
    (r.file_id * 1000) + BTRIM(r.sale_seller_id)::INTEGER,
    NULLIF(BTRIM(r.seller_first_name), ''),
    NULLIF(BTRIM(r.seller_last_name), ''),
    BTRIM(r.seller_email),
    country.country_id,
    NULLIF(BTRIM(r.seller_postal_code), '')
FROM raw_data AS r
JOIN dim_country AS country ON country.name = BTRIM(r.seller_country);

-- 6. Товары.
INSERT INTO dim_product (
    product_id, name, category_id, price, quantity, pet_category, weight,
    color, size, brand, material, description, rating, reviews,
    release_date, expiry_date
)
SELECT
    (r.file_id * 1000) + BTRIM(r.sale_product_id)::INTEGER,
    BTRIM(r.product_name),
    category.category_id,
    NULLIF(BTRIM(r.product_price), '')::DECIMAL(10,2),
    NULLIF(BTRIM(r.product_quantity), '')::INTEGER,
    NULLIF(BTRIM(r.pet_category), ''),
    NULLIF(BTRIM(r.product_weight), '')::DECIMAL(10,2),
    NULLIF(BTRIM(r.product_color), ''),
    NULLIF(BTRIM(r.product_size), ''),
    NULLIF(BTRIM(r.product_brand), ''),
    NULLIF(BTRIM(r.product_material), ''),
    NULLIF(BTRIM(r.product_description), ''),
    NULLIF(BTRIM(r.product_rating), '')::DECIMAL(3,2),
    NULLIF(BTRIM(r.product_reviews), '')::INTEGER,
    TO_DATE(NULLIF(BTRIM(r.product_release_date), ''), 'MM/DD/YYYY'),
    TO_DATE(NULLIF(BTRIM(r.product_expiry_date), ''), 'MM/DD/YYYY')
FROM raw_data AS r
JOIN dim_category AS category ON category.name = BTRIM(r.product_category);

-- 7. Магазины. Хеш строится по полной комбинации исходных атрибутов.
WITH store_source AS (
    SELECT DISTINCT
        BTRIM(store_name) AS name,
        COALESCE(NULLIF(BTRIM(store_location), ''), '') AS location_key,
        BTRIM(store_city) AS city_name,
        COALESCE(NULLIF(BTRIM(store_state), ''), '(unknown)') AS state_name,
        BTRIM(store_country) AS country_name,
        COALESCE(NULLIF(BTRIM(store_phone), ''), '') AS phone_key,
        COALESCE(NULLIF(BTRIM(store_email), ''), '') AS email_key
    FROM raw_data
)
INSERT INTO dim_store (store_id, name, location, city_id, phone, email)
SELECT
    MOD(ABS(HASHTEXT(CONCAT_WS('|',
        source.name, source.location_key, source.city_name, source.state_name,
        source.country_name, source.phone_key, source.email_key
    ))::BIGINT), 2147483647)::INTEGER,
    source.name,
    NULLIF(source.location_key, ''),
    city.city_id,
    NULLIF(source.phone_key, ''),
    NULLIF(source.email_key, '')
FROM store_source AS source
JOIN dim_country AS country ON country.name = source.country_name
JOIN dim_city AS city
  ON city.name = source.city_name
 AND city.state = source.state_name
 AND city.country_id = country.country_id;

-- 8. Поставщики.
WITH supplier_source AS (
    SELECT DISTINCT
        BTRIM(supplier_name) AS name,
        COALESCE(NULLIF(BTRIM(supplier_contact), ''), '') AS contact_key,
        COALESCE(NULLIF(BTRIM(supplier_email), ''), '') AS email_key,
        COALESCE(NULLIF(BTRIM(supplier_phone), ''), '') AS phone_key,
        COALESCE(NULLIF(BTRIM(supplier_address), ''), '') AS address_key,
        BTRIM(supplier_city) AS city_name,
        BTRIM(supplier_country) AS country_name
    FROM raw_data
)
INSERT INTO dim_supplier (
    supplier_id, name, contact, email, phone, address, city_id
)
SELECT
    MOD(ABS(HASHTEXT(CONCAT_WS('|',
        source.name, source.contact_key, source.email_key, source.phone_key,
        source.address_key, source.city_name, source.country_name
    ))::BIGINT), 2147483647)::INTEGER,
    source.name,
    NULLIF(source.contact_key, ''),
    NULLIF(source.email_key, ''),
    NULLIF(source.phone_key, ''),
    NULLIF(source.address_key, ''),
    city.city_id
FROM supplier_source AS source
JOIN dim_country AS country ON country.name = source.country_name
JOIN dim_city AS city
  ON city.name = source.city_name
 AND city.state = '(unknown)'
 AND city.country_id = country.country_id;

-- 9. Факты. JOIN со всеми измерениями одновременно проверяет соответствия.
WITH sales_source AS (
    SELECT
        (r.file_id * 1000) + BTRIM(r.id)::INTEGER AS sale_id,
        (r.file_id * 1000) + BTRIM(r.sale_customer_id)::INTEGER AS customer_id,
        (r.file_id * 1000) + BTRIM(r.sale_seller_id)::INTEGER AS seller_id,
        (r.file_id * 1000) + BTRIM(r.sale_product_id)::INTEGER AS product_id,
        MOD(ABS(HASHTEXT(CONCAT_WS('|',
            BTRIM(r.store_name),
            COALESCE(NULLIF(BTRIM(r.store_location), ''), ''),
            BTRIM(r.store_city),
            COALESCE(NULLIF(BTRIM(r.store_state), ''), '(unknown)'),
            BTRIM(r.store_country),
            COALESCE(NULLIF(BTRIM(r.store_phone), ''), ''),
            COALESCE(NULLIF(BTRIM(r.store_email), ''), '')
        ))::BIGINT), 2147483647)::INTEGER AS store_id,
        MOD(ABS(HASHTEXT(CONCAT_WS('|',
            BTRIM(r.supplier_name),
            COALESCE(NULLIF(BTRIM(r.supplier_contact), ''), ''),
            COALESCE(NULLIF(BTRIM(r.supplier_email), ''), ''),
            COALESCE(NULLIF(BTRIM(r.supplier_phone), ''), ''),
            COALESCE(NULLIF(BTRIM(r.supplier_address), ''), ''),
            BTRIM(r.supplier_city),
            BTRIM(r.supplier_country)
        ))::BIGINT), 2147483647)::INTEGER AS supplier_id,
        TO_DATE(NULLIF(BTRIM(r.sale_date), ''), 'MM/DD/YYYY') AS sale_date,
        NULLIF(BTRIM(r.sale_quantity), '')::INTEGER AS quantity,
        NULLIF(BTRIM(r.sale_total_price), '')::DECIMAL(10,2) AS total_price
    FROM raw_data AS r
)
INSERT INTO fact_sales (
    sale_id, customer_id, seller_id, product_id, store_id, supplier_id,
    sale_date, quantity, total_price
)
SELECT
    source.sale_id,
    customer.customer_id,
    seller.seller_id,
    product.product_id,
    store.store_id,
    supplier.supplier_id,
    source.sale_date,
    source.quantity,
    source.total_price
FROM sales_source AS source
JOIN dim_customer AS customer ON customer.customer_id = source.customer_id
JOIN dim_seller AS seller ON seller.seller_id = source.seller_id
JOIN dim_product AS product ON product.product_id = source.product_id
JOIN dim_store AS store ON store.store_id = source.store_id
JOIN dim_supplier AS supplier ON supplier.supplier_id = source.supplier_id;
