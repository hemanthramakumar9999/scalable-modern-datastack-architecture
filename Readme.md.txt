# Scalable Modern Data Stack Architecture

This repository showcases an end-to-end **modern data stack** built with:

- **Fivetran** for fully managed data ingestion
- **Snowflake** as the cloud data warehouse
- **dbt** for transformation, testing, and modular data modeling

The project is designed as a **portfolio-quality example** of how to build a
scalable, production-style analytics architecture for an e-commerce use case.

---

## Architecture Overview

**Flow:**

1. **Source systems** (e-commerce transactional database, marketing data)
2. **Fivetran** extracts and loads data into Snowflake **raw schemas**
3. **dbt** transforms raw data into:
   - Staging models (`stg_*`)
   - Intermediate models (`int_*`)
   - Analytics-ready marts (`dim_*`, `fct_*`)
4. Final tables are ready for BI / reporting (e.g. revenue, customers, products)

**Key components:**

- **Snowflake**
  - Warehouse: `WH_FIVETRAN_DBT`
  - Database: `ANALYTICS`
  - Schemas: `RAW_FIVETRAN`, `DBT_STAGING`, `DBT_MARTS`
- **Fivetran**
  - Destination: Snowflake (landing into `RAW_FIVETRAN`)
  - Connectors: e-commerce DB, marketing spend (example)
- **dbt**
  - dbt project lives under dbt/scalable_modern_datastack
  - Staging layer over raw Fivetran tables
  - Business logic layer for joins/enrichment
  - Dimensional models and fact tables for analytics

---

## Repository Structure

```text
scalable-modern-datastack-architecture/
├── snowflake/                      # Infra & permissions for Snowflake
├── fivetran/                       # Destination + connector documentation
├── dbt/                            # dbt project (models, configs, tests)
└── ci/                             # Optional CI (GitHub Actions for dbt)
