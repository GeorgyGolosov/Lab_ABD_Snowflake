-- Справочники: верхний уровень схемы «снежинка».
CREATE TABLE IF NOT EXISTS dim_country (
    country_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_city (
    city_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country_id INTEGER NOT NULL REFERENCES dim_country(country_id),
    UNIQUE (name, state, country_id)
);

CREATE TABLE IF NOT EXISTS dim_category (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Измерения. У customer/seller/product локальные CSV-ID дополняются file_id
-- при загрузке, потому что диапазон 1..1000 повторяется в каждом файле.
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id INTEGER PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    age INTEGER,
    email VARCHAR(200) NOT NULL,
    country_id INTEGER NOT NULL REFERENCES dim_country(country_id),
    postal_code VARCHAR(20),
    pet_type VARCHAR(50),
    pet_name VARCHAR(100),
    pet_breed VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS dim_seller (
    seller_id INTEGER PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(200) NOT NULL,
    country_id INTEGER NOT NULL REFERENCES dim_country(country_id),
    postal_code VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS dim_product (
    product_id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category_id INTEGER NOT NULL REFERENCES dim_category(category_id),
    price DECIMAL(10,2),
    quantity INTEGER,
    pet_category VARCHAR(100),
    weight DECIMAL(10,2),
    color VARCHAR(50),
    size VARCHAR(50),
    brand VARCHAR(100),
    material VARCHAR(100),
    description TEXT,
    rating DECIMAL(3,2),
    reviews INTEGER,
    release_date DATE,
    expiry_date DATE
);

CREATE TABLE IF NOT EXISTS dim_store (
    store_id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    location VARCHAR(200),
    city_id INTEGER NOT NULL REFERENCES dim_city(city_id),
    phone VARCHAR(50),
    email VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS dim_supplier (
    supplier_id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    contact VARCHAR(200),
    email VARCHAR(200),
    phone VARCHAR(50),
    address VARCHAR(200),
    city_id INTEGER NOT NULL REFERENCES dim_city(city_id)
);

-- Центральная таблица фактов.
CREATE TABLE IF NOT EXISTS fact_sales (
    sale_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES dim_customer(customer_id),
    seller_id INTEGER NOT NULL REFERENCES dim_seller(seller_id),
    product_id INTEGER NOT NULL REFERENCES dim_product(product_id),
    store_id INTEGER NOT NULL REFERENCES dim_store(store_id),
    supplier_id INTEGER NOT NULL REFERENCES dim_supplier(supplier_id),
    sale_date DATE NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0)
);

CREATE INDEX IF NOT EXISTS idx_fact_sales_customer_id ON fact_sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_seller_id ON fact_sales(seller_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_product_id ON fact_sales(product_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_store_id ON fact_sales(store_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_supplier_id ON fact_sales(supplier_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_sale_date ON fact_sales(sale_date);
