CREATE TABLE IF NOT EXISTS raw_data (
    file_id INTEGER,
    id TEXT,
    customer_last_name TEXT,
    customer_first_name TEXT,
    customer_age TEXT,
    customer_email TEXT,
    customer_postal_code TEXT,
    customer_country TEXT,
    customer_pet_type TEXT,
    customer_pet_name TEXT,
    customer_pet_breed TEXT,
    seller_first_name TEXT,
    seller_last_name TEXT,
    seller_email TEXT,
    seller_country TEXT,
    seller_postal_code TEXT,
    product_name TEXT,
    product_category TEXT,
    product_price TEXT,
    product_quantity TEXT,
    pet_category TEXT,
    product_weight TEXT,
    product_color TEXT,
    product_size TEXT,
    product_material TEXT,
    product_description TEXT,
    product_brand TEXT,
    product_reviews TEXT,
    product_release_date TEXT,
    product_rating TEXT,
    product_expiry_date TEXT,
    sale_date TEXT,
    sale_customer_id TEXT,
    sale_seller_id TEXT,
    sale_product_id TEXT,
    sale_quantity TEXT,
    sale_total_price TEXT,
    store_name TEXT,
    store_location TEXT,
    store_city TEXT,
    store_state TEXT,
    store_country TEXT,
    store_phone TEXT,
    store_email TEXT,
    supplier_name TEXT,
    supplier_contact TEXT,
    supplier_email TEXT,
    supplier_phone TEXT,
    supplier_address TEXT,
    supplier_city TEXT,
    supplier_country TEXT
);

-- 1. Справочники
CREATE TABLE dim_country (
    country_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE dim_city (
    city_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    state VARCHAR(100),
    country_id INTEGER REFERENCES dim_country(country_id),
    UNIQUE (name, state, country_id)
);

CREATE TABLE dim_category (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- 2. Измерения
CREATE TABLE dim_customer (
    customer_id INTEGER PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    age INTEGER,
    email VARCHAR(200),
    country_id INTEGER REFERENCES dim_country(country_id),
    postal_code VARCHAR(20),
    pet_type VARCHAR(50),
    pet_name VARCHAR(100),
    pet_breed VARCHAR(100)
);

CREATE TABLE dim_seller (
    seller_id INTEGER PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(200),
    country_id INTEGER REFERENCES dim_country(country_id),
    postal_code VARCHAR(20)
);

CREATE TABLE dim_product (
    product_id INTEGER PRIMARY KEY,
    name TEXT,
    category_id INTEGER REFERENCES dim_category(category_id),
    price DECIMAL(10,2),
    quantity INTEGER,
    pet_category VARCHAR(100),
    weight VARCHAR(50),
    color VARCHAR(50),
    size VARCHAR(50),
    material VARCHAR(100),
    description TEXT,
    brand VARCHAR(100),
    reviews INTEGER,
    release_date DATE,
    rating DECIMAL(3,2),
    expiry_date DATE
);

CREATE TABLE dim_store (
    store_id INTEGER PRIMARY KEY,
    name VARCHAR(200),
    location VARCHAR(200),
    city_id INTEGER REFERENCES dim_city(city_id),
    phone VARCHAR(50),
    email VARCHAR(200)
);

CREATE TABLE dim_supplier (
    supplier_id INTEGER PRIMARY KEY,
    name VARCHAR(200),
    contact VARCHAR(200),
    email VARCHAR(200),
    phone VARCHAR(50),
    address VARCHAR(200),
    city_id INTEGER REFERENCES dim_city(city_id)
);

-- 3. Таблица фактов
CREATE TABLE fact_sales (
    sale_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES dim_customer(customer_id),
    seller_id INTEGER REFERENCES dim_seller(seller_id),
    product_id INTEGER REFERENCES dim_product(product_id),
    store_id INTEGER REFERENCES dim_store(store_id),
    supplier_id INTEGER REFERENCES dim_supplier(supplier_id),
    sale_date DATE,
    quantity INTEGER,
    total_price DECIMAL(10,2)
);
