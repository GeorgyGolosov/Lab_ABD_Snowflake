#!/usr/bin/env bash
set -Eeuo pipefail

columns="id,customer_first_name,customer_last_name,customer_age,customer_email,customer_country,customer_postal_code,customer_pet_type,customer_pet_name,customer_pet_breed,seller_first_name,seller_last_name,seller_email,seller_country,seller_postal_code,product_name,product_category,product_price,product_quantity,sale_date,sale_customer_id,sale_seller_id,sale_product_id,sale_quantity,sale_total_price,store_name,store_location,store_city,store_state,store_country,store_phone,store_email,pet_category,product_weight,product_color,product_size,product_brand,product_material,product_description,product_rating,product_reviews,product_release_date,product_expiry_date,supplier_name,supplier_contact,supplier_email,supplier_phone,supplier_address,supplier_city,supplier_country"

csv_files=(
  "/data/MOCK_DATA.csv"
  "/data/MOCK_DATA (1).csv"
  "/data/MOCK_DATA (2).csv"
  "/data/MOCK_DATA (3).csv"
  "/data/MOCK_DATA (4).csv"
  "/data/MOCK_DATA (5).csv"
  "/data/MOCK_DATA (6).csv"
  "/data/MOCK_DATA (7).csv"
  "/data/MOCK_DATA (8).csv"
  "/data/MOCK_DATA (9).csv"
)

for file_id in "${!csv_files[@]}"; do
  csv_file="${csv_files[$file_id]}"

  if [[ ! -r "$csv_file" ]]; then
    echo "CSV file is missing or unreadable: $csv_file" >&2
    exit 1
  fi

  psql --set ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    --command "ALTER TABLE raw_data ALTER COLUMN file_id SET DEFAULT ${file_id};"

  psql --set ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    --command "\\copy raw_data (${columns}) FROM '${csv_file}' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
done

psql --set ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  --command "ALTER TABLE raw_data ALTER COLUMN file_id DROP DEFAULT;"

echo "Imported ${#csv_files[@]} CSV files into raw_data."
