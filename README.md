# E-Commerce Multi-Channel Sales Data Consolidation & Analytics Engine

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-blue?logo=postgresql)](https://www.postgresql.org/)
[![Bash](https://img.shields.io/badge/Pipeline-Bash%20%26%20SQL-green?logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Data Volume](https://img.shields.io/badge/Volume-60k%2B%20Records-orange)](#performance-benchmark)

An end-to-end relational database architecture, high-performance bulk ingestion pipeline, and executive reporting suite built to consolidate un-normalized, multi-channel e-commerce sales data (Shopify, Amazon, Wholesale) into an actionable PostgreSQL database.

---

## The Business Problem

E-commerce brands selling across multiple channels often face significant data operational bottlenecks:
* **Data Discrepancies:** Raw CSV exports repeat customer details, addresses, and shipping costs on every line item, causing duplicate records and inflated sales metrics.
* **Slow Reporting:** Running simple monthly sales or Customer Lifetime Value (CLV) reports against flat CSV dumps or un-indexed tables leads to slow query times and dashboard timeouts.
* **Channel Silos:** Inconsistent product naming and SKU variations across Shopify Online, Shopify POS, and Amazon obscure true product-level profitability.

---

## The Solution & Architecture

This project delivers a **3rd Normal Form (3NF)** relational PostgreSQL architecture with an automated, high-speed bulk ingestion pipeline capable of parsing and indexing tens of thousands of records in under 2 seconds.

```text
[ channels ] ──< [ orders ] ──< [ order_items ] >── [ products ]
                   │
                   ├──> [ customers ]
                   └──> [ addresses ]
