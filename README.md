# 📊 Online Retail RFM Customer Segmentation & Analysis

## 📌 Project Overview

This project analyzes customer purchasing behavior using **RFM (Recency, Frequency, Monetary) analysis** on an Online Retail dataset.

The objective is to identify valuable customer segments, understand revenue contribution, measure customer retention, and identify customers who may require targeted re-engagement.

The analysis was performed using **PostgreSQL** for data analysis and **Power BI** for interactive dashboard visualization.

---

## 🎯 Business Questions

The analysis answers the following business questions:

1. Who are the most valuable customers?
2. How should customers be segmented using RFM analysis?
3. Which RFM segment generates the most revenue?
4. What is the average order value by customer segment?
5. Do Champions spend more per order or simply purchase more frequently?
6. Which segment has the largest gap between customer share and revenue contribution?
7. How many new customers are acquired each month?
8. What percentage of customers make repeat purchases?
9. Which country generates the highest revenue?
10. What are the top products by revenue?
11. How much historical revenue is associated with At-Risk customers?
12. Which customers should the business contact first?

---

## 🛠️ Tools & Technologies

- **Pandas** — Data cleaning, transformation 
- **PostgreSQL** — Customer segmentation and business analysis,RFM Analysis
- **Power BI** — Interactive dashboard and visualization
- **GitHub** — Project documentation and portfolio

---

## 📐 RFM Methodology

RFM analysis evaluates customers using three dimensions:

### Recency

Measures how recently a customer made a purchase.

Customers with more recent purchases receive better Recency scores.

### Frequency

Measures how frequently a customer purchases.

Customers with more purchases receive better Frequency scores.

### Monetary

Measures how much revenue a customer generates.

Customers generating higher revenue receive better Monetary scores.

Each metric is divided into **4 quartile groups using NTILE(4)**.

The resulting RFM scores are then used to classify customers into four business segments.

---

## 👥 Customer Segments

The final analysis contains four customer segments:

| Segment | Description |
|---|---|
| 🏆 Champions | Recent, frequent and high-value customers |
| ⚠️ At Risk | Previously valuable customers showing weaker recent activity |
| 🔴 Lost | Low engagement and low historical value |
| 🆕 New Customers | Recently acquired or developing customers |

---

## 📊 Dashboard

The Power BI dashboard provides a one-page overview of customer behavior and revenue performance.

### Key KPIs

- Total Revenue
- Total Customers
- Repeat Purchase Rate
- Revenue at Risk

### Dashboard Visualizations

- Customer Share vs Revenue Share by RFM Segment
- Revenue by RFM Segment
- Customer Count by RFM Segment
- Average Order Value by Segment
- Monthly New Customer Acquisition
- Top Countries by Revenue
- Priority At-Risk Customers

---
<img width="1187" height="742" alt="RFM Screenshot" src="https://github.com/user-attachments/assets/70e19ad8-7cd5-48f3-aa7a-e734b06f0d2e" />

## 💡 Key Insights

The analysis highlights several important business findings:

- **Champions represent 11.1% of customers but generate 53.8% of total revenue**, showing that a relatively small group of highly valuable customers contributes disproportionately to revenue.

- **New Customers represent 59.1% of the customer base and contribute 32.3% of revenue**, indicating a large opportunity to convert new customers into repeat and higher-value buyers.

- **Lost customers represent 18.6% of customers but contribute only 1.9% of revenue**, suggesting that broad retention efforts on this segment may have lower financial impact than focusing on higher-value At-Risk customers.

- **At-Risk customers represent approximately 2.11M in historical revenue**, making targeted re-engagement an important potential revenue opportunity.

- The overall **repeat purchase rate is 72.39%**, indicating strong evidence of repeat purchasing behavior within the customer base.

---

## 📈 Business Recommendations

### 1. Protect Champions

Champions contribute a disproportionate share of revenue.

Recommended actions:

- Loyalty programs
- Exclusive offers
- Early access to products
- Personalized recommendations

### 2. Re-engage At-Risk Customers

At-Risk customers represent a meaningful amount of historical revenue.

Recommended actions:

- Personalized email campaigns
- Targeted discounts
- Product recommendations
- Win-back campaigns

### 3. Convert New Customers

New Customers make up the largest portion of the customer base.

The business should focus on moving these customers toward repeat purchases.

Recommended actions:

- Second-purchase incentives
- Welcome campaigns
- Cross-selling
- Personalized follow-ups

### 4. Prioritize High-Value Customers

The Priority At-Risk Customers table identifies customers with high historical revenue who should receive attention first.

---

## 🗂️ Project Structure

```text
Online-Retail-RFM-Analysis/
│
├── README.md
│
├── sql/
│   ├── rfm_analysis.sql
│   ├── business_questions.sql
│   └── views.sql
│
├── powerbi/
│   └── online_retail_rfm_dashboard.pbix
│
└── images/
    └── dashboard.png

🔍 RFM Segmentation Logic
The customer-level RFM scores are calculated using:

NTILE(4) OVER (ORDER BY ...)

The three scores are then combined using a CASE statement to create the final customer segment.

Example:

CASE
    WHEN r_rank = 1
         AND f_rank = 1
         AND m_rank = 1
        THEN 'Champions'

    WHEN r_rank >= 3
         AND f_rank <= 2
         AND m_rank <= 2
        THEN 'At Risk'

    WHEN r_rank = 4
         AND f_rank >= 3
         AND m_rank >= 3
        THEN 'Lost'

    ELSE 'New Customers'
END AS rfm_segment

📊 Key Metrics
Metric	Result
Total Revenue	17.37M
Total Customers	~6K
Repeat Purchase Rate	72.39%
Revenue at Risk	2.11M
Champions Customer Share	11.1%
Champions Revenue Share	53.8%
New Customer Share	59.1%
New Customer Revenue Share	32.3%
Lost Customer Share	18.6%
Lost Revenue Share	1.9%

🚀 Conclusion
The RFM analysis demonstrates that customer value is highly concentrated within a relatively small group of customers.

Champions are the most valuable segment and should be protected, while At-Risk customers represent the strongest re-engagement opportunity.

The analysis can help businesses prioritize retention efforts, allocate marketing resources more effectively, and focus on customers with the greatest potential financial impact.

👤 Author
Princy Chaubey
Data Analytics Project
Pandas | PostgreSQL | Power BI | RFM Analysis

