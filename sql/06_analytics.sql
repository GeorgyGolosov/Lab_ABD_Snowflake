-- 1. Топ-10 стран клиентов по выручке.
SELECT
    country.name AS customer_country,
    COUNT(*) AS sales_count,
    ROUND(SUM(fact.total_price), 2) AS revenue
FROM fact_sales AS fact
JOIN dim_customer AS customer ON customer.customer_id = fact.customer_id
JOIN dim_country AS country ON country.country_id = customer.country_id
GROUP BY country.name
ORDER BY revenue DESC
LIMIT 10;

-- 2. Продажи по категориям товаров.
SELECT
    category.name AS product_category,
    COUNT(*) AS sales_count,
    ROUND(SUM(fact.total_price), 2) AS revenue
FROM fact_sales AS fact
JOIN dim_product AS product ON product.product_id = fact.product_id
JOIN dim_category AS category ON category.category_id = product.category_id
GROUP BY category.name
ORDER BY revenue DESC;

-- 3. Топ-10 городов магазинов по выручке.
SELECT
    city.name AS store_city,
    city.state AS store_state,
    country.name AS store_country,
    COUNT(*) AS sales_count,
    ROUND(SUM(fact.total_price), 2) AS revenue
FROM fact_sales AS fact
JOIN dim_store AS store ON store.store_id = fact.store_id
JOIN dim_city AS city ON city.city_id = store.city_id
JOIN dim_country AS country ON country.country_id = city.country_id
GROUP BY city.name, city.state, country.name
ORDER BY revenue DESC
LIMIT 10;

-- 4. Динамика продаж по месяцам и категориям.
SELECT
    DATE_TRUNC('month', fact.sale_date)::DATE AS month,
    category.name AS product_category,
    COUNT(*) AS sales_count,
    ROUND(SUM(fact.total_price), 2) AS revenue
FROM fact_sales AS fact
JOIN dim_product AS product ON product.product_id = fact.product_id
JOIN dim_category AS category ON category.category_id = product.category_id
GROUP BY month, category.name
ORDER BY month, category.name;

-- 5. Топ-5 продавцов по выручке.
SELECT
    seller.seller_id,
    seller.first_name,
    seller.last_name,
    COUNT(*) AS sales_count,
    ROUND(SUM(fact.total_price), 2) AS revenue
FROM fact_sales AS fact
JOIN dim_seller AS seller ON seller.seller_id = fact.seller_id
GROUP BY seller.seller_id, seller.first_name, seller.last_name
ORDER BY revenue DESC
LIMIT 5;
