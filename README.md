# 📊 SQL Server Sales Data Analysis

This project showcases advanced SQL analytics on a star-schema Sales Data Warehouse built in SQL Server. The `.bak` database backup file is included for easy restoration and analysis.

## 🧠 Key Business Questions

- How has sales performance changed over time?
- What are the trends in customer and product performance?
- How do different segments contribute to overall sales?
- Which customer groups are most valuable?
- What KPIs can guide strategic decisions?

## 🔍 Analytical Techniques

- 📈 **Change-Over-Time Analysis**: Yearly and monthly trends in sales, units, and customers.
- 📊 **Cumulative Metrics**: Running totals and moving averages using window functions.
- 🚦 **Performance Analysis**: Compare yearly sales vs. averages and previous years.
- 🧩 **Segmentation**: Customers and products grouped by behavior, age, and contribution.
- 🧾 **Customer Report View**: A Power BI-ready view summarizing customer-level KPIs and segments.

## 🛠️ Project Highlights

- Built and queried fact and dimension tables (`gold.fact_sales`, `gold.dim_customers`, `gold.dim_products`)
- Used advanced SQL (CTEs, CASE, DATE functions, window functions)
- Created a reusable **view (`gold.reprot_customers`)** for Power BI integration

## 🗂️ Included

- `DataWarehouse.bak` – Backup file to restore SQL Server database
- Query scripts – Covering all business questions and metrics
- Power BI-ready view for customer analytics

---

🔗 *Feel free to clone this repo, restore the database, and build your own insights!*
