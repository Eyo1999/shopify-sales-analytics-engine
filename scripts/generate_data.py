import csv
import random
from datetime import datetime, timedelta

# Configuration for high-volume dataset generation
NUM_RECORDS = 50000
OUTPUT_FILE = "data/shopify_bulk_50k.csv"

channels = ["Shopify Online Store", "Shopify POS", "Amazon Marketplace", "Wholesale Direct"]
first_names = ["James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", "David", "Elizabeth", "Abebe", "Tigist", "Kebede", "Sara"]
last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Tadesse", "Bekele", "Alemu"]
cities = [("Austin", "TX", "78701"), ("Seattle", "WA", "98101"), ("Miami", "FL", "33101"), ("Chicago", "IL", "60601"), ("Addis Ababa", "AA", "1000")]

products = [
    ("SKU-TSHIRT-BLK-S", "Classic Cotton T-Shirt", "Black / S", 45.00),
    ("SKU-TSHIRT-BLK-M", "Classic Cotton T-Shirt", "Black / M", 50.00),
    ("SKU-TSHIRT-BLK-L", "Classic Cotton T-Shirt", "Black / L", 50.00),
    ("SKU-HOODIE-GRY-M", "Heavyweight Hoodie", "Grey / M", 80.00),
    ("SKU-HOODIE-GRY-L", "Heavyweight Hoodie", "Grey / L", 85.00),
    ("SKU-MUG-WHT", "Ceramic Coffee Mug", "White / Standard", 20.00),
    ("SKU-HAT-BLK", "Snapback Baseball Cap", "Black / One Size", 35.00),
    ("SKU-JACKET-DRK-XL", "Weatherproof Shell Jacket", "Dark Blue / XL", 180.00),
]

# Generate a pool of 5,000 repeat customers to allow true CLV & Cohort analysis
customers_pool = []
for i in range(5000):
    fn = random.choice(first_names)
    ln = random.choice(last_names)
    email = f"{fn.lower()}.{ln.lower()}{i}@example.com"
    phone = f"+1555{random.randint(1000000, 9999999)}"
    city, prov, zip_code = random.choice(cities)
    customers_pool.append((email, fn, ln, phone, city, prov, zip_code))

print(f"Generating {NUM_RECORDS} realistic transactional records in {OUTPUT_FILE}...")

start_date = datetime(2025, 1, 1)

with open(OUTPUT_FILE, mode="w", newline="", encoding="utf-8") as file:
    writer = csv.writer(file)
    writer.writerow([
        "Name", "Email", "First Name", "Last Name", "Phone", "Address1", "Address2", 
        "City", "Province Code", "Country Code", "Zip", "Created At", "Financial Status", 
        "Fulfillment Status", "Subtotal", "Tax", "Shipping", "Discount", "Total", 
        "Lineitem Quantity", "Lineitem Price", "Lineitem Discount", "Lineitem SKU", 
        "Lineitem Name", "Lineitem Variant", "Sales Channel"
    ])

    order_counter = 1000
    current_time = start_date

    while order_counter < 1000 + (NUM_RECORDS // 2):
        order_name = f"#{order_counter}"
        cust = random.choice(customers_pool)
        channel = random.choice(channels)
        financial_status = random.choices(["paid", "pending", "refunded"], weights=[0.85, 0.10, 0.05])[0]
        fulfillment_status = "fulfilled" if financial_status == "paid" else "unfulfilled"
        
        current_time += timedelta(minutes=random.randint(2, 45))
        
        # Orders contain 1 to 4 line items
        num_items = random.randint(1, 4)
        subtotal = 0.0
        items_data = []

        for _ in range(num_items):
            prod = random.choice(products)
            qty = random.randint(1, 3)
            price = prod[3]
            line_sub = price * qty
            subtotal += line_sub
            items_data.append((qty, price, prod[0], prod[1], prod[2]))

        tax = round(subtotal * 0.08, 2)
        shipping = 0.0 if subtotal > 100 else 10.0
        discount = 5.0 if subtotal > 150 else 0.0
        total = round(subtotal + tax + shipping - discount, 2)

        for item in items_data:
            writer.writerow([
                order_name, cust[0], cust[1], cust[2], cust[3], "100 Commercial Rd", "",
                cust[4], cust[5], "US", cust[6], current_time.strftime("%Y-%m-%d %H:%M:%S"),
                financial_status, fulfillment_status, subtotal, tax, shipping, discount, total,
                item[0], item[1], 0.0, item[2], item[3], item[4], channel
            ])

        order_counter += 1

print("Successfully generated data/shopify_bulk_50k.csv!")