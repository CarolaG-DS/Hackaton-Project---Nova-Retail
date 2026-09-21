# 🛒 Nova Retail - End-to-End Modern Data Pipeline

![Architecture](https://img.shields.io/badge/Architecture-Medallion%20(Bronze%20%7C%20Silver%20%7C%20Gold)-blue)
![Stack](https://img.shields.io/badge/Tech%20Stack-KNIME%20%7C%20Snowflake%20%7C%20dbt%20Cloud%20%7C%20Tableau-brightgreen)
![Orchestration](https://img.shields.io/badge/Orchestration-Windows%20Task%20Scheduler%20%2B%20dbt%20Cloud-orange)

## 📌 Project Overview
**Nova Retail** is a global tech and electronics retailer whose operational data was previously fragmented across departments (Sales CSVs, Finance Excel targets, Marketing JSON web reviews). 

This project implements a fully automated, scalable, end-to-end data pipeline using a **Medallion Architecture**. It ingests raw multi-format datasets, cleans and standardizes them, models them into a Star Schema, and serves business-ready data to an interactive executive Tableau dashboard.

---

## 🏗️ Architecture & Tech Stack

The architecture follows the **Medallion Data Model** implemented inside **Snowflake** (`NOVA_RETAIL` database):


```

┌─────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────┐
│  Source Data    │      │   BRONZE (Raw Landing)  │      │ Silver (Clean/Staged)   │      │   GOLD (Star Schema)    │
│                 │      │                         │      │                         │      │                         │
│ • Sales (CSV)   │ ───► │ RAW_SALES_TRANSACTIONS  │ ───► │ stg_sales_transactions  │ ───► │ fct_sales               │
│ • Finance (CSV) │ ───► │ RAW_FINANCE_TARGETS     │ ───► │ stg_finance_targets     │ ───► │ fct_finance_targets     │ ───► Tableau (Live)
│ • Reviews(JSON) │ ───► │ RAW_WEB_REVIEWS         │ ───► │ stg_web_reviews         │ ───► │ dim_customers           │
└─────────────────┘      └─────────────────────────┘      └─────────────────────────┘      │ dim_products            │
▲                                                                                   │ dim_region_mapping      │
│                                                                                   └─────────────────────────┘
KNIME (Batch)                                                     dbt Cloud (Scheduled)

```

* **Ingestion (Bronze):** `KNIME Analytics Platform` running in batch mode to parse flat CSVs and unpack nested JSON web reviews.
* **Storage & Compute:** `Snowflake` (`BRONZE`, `SILVER`, and `GOLD` schemas).
* **Transformation & Testing (Silver → Gold):** `dbt Cloud` managing data lineage, business logic, currency conversion, and automated data quality tests.
* **Visualization:** `Tableau Desktop` connected directly via **Live Connection** to the Gold layer.

---

## 🔄 Automated Pipeline Orchestration

The pipeline is completely decoupled into two automated layers to avoid reliance on local CLI execution:

1. **Local Ingestion (KNIME & Task Scheduler):**
   * Executed via `01_knime_ingestion/run_knime.bat` using non-interactive flags (`-nosplash -reset -overwrite`).
   * Scheduled daily via **Windows Task Scheduler** to push fresh raw data to Snowflake `BRONZE`.
2. **Cloud Transformations (dbt Cloud):**
   * Scheduled via a dbt Cloud Deployment Job (`Run_Silver_Gold_Daily`) triggered after the local ingestion window.
   * Runs `dbt run` and `dbt test` in sequence to populate `SILVER` and `GOLD` schemas and validate data quality contracts.
3. **Executive Reporting (Tableau):**
   * Tableau Desktop accesses the updated Gold layer instantly via **Live Connection**.

---

## 🛡️ Data Quality & Schema Drift Strategy

* **Schema Placement Stability:** Custom macro `generate_schema_name.sql` guarantees explicit `BRONZE`, `SILVER`, and `GOLD` schema materialization independent of user targets.
* **Automated dbt Testing:**
  * Generic tests: `unique`, `not_null`, `accepted_values` on primary keys and categorical domain values.
  * Singular custom SQL tests: Enforcing non-overlapping finance targets grain (`assert_finance_targets_grain.sql`), discount ranges, revenue sign rules, and chronological order dates.
* **Data Cleaning Highlights:**
  * Multi-format date parsing (`COALESCE(TRY_TO_DATE(...))`).
  * Currency symbol extraction & multi-currency normalization to EUR using a reference table.
  * Array/Object unnesting of web review JSON exports.
  * Finance targets wide-to-long `UNPIVOT` transformation.

---

## 📁 Repository Structure

```text
.
├── 01_knime_ingestion/
│   ├── 01.Bronze_Ingestion_Hackaton.knwf   # KNIME Ingestion Workflow
│   └── run_knime.bat                      # Windows Batch script for automation
├── macros/
│   └── generate_schema_name.sql           # Custom dbt schema resolution macro
├── models/
│   ├── staging/                           # Silver layer staging models & sources (src_bronze.yml)
│   └── core/                              # Gold layer dimensional star schema & YAML contracts
├── tests/                                 # Singular SQL data quality tests
├── snowflake_setup/                       # DDL scripts and Exchange Rate reference seeds
└── README.md

```

---

*Created as part of The Information Lab Data Academy Hackathon.*

