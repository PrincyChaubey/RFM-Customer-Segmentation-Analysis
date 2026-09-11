CREATE TABLE online_retail (
    invoice VARCHAR(20),
    stock_code VARCHAR(20),
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    price NUMERIC(10,2),
    customer_id INTEGER,
    country VARCHAR(100),
    revenue NUMERIC(12,2)
);

select count(distinct customer_id) from online_retail

/*Phase 1 — Customer-level RFM
1. What is each customer's most recent purchase date?*/

SELECT
    customer_id,
    MAX(invoice_date) AS last_purchase_date
FROM online_retail
GROUP BY customer_id
ORDER BY customer_id;

select * from online_retail limit 5

2. How many distinct orders has each customer placed?
select customer_id,count(distinct invoice) from online_retail group by customer_id


3. What is each customer total historical spend?

select customer_id ,
       sum(revenue) as total_spend 
from online_retail 
group by customer_id

4. What is the average order value (AOV) for each customer?

select customer_id,
      round(sum(revenue)/count(distinct invoice)::numeric,2) as aov 
from online_retail 
group by customer_id

/*RFM Scoring — Window Functions
5. Using NTILE(4), split customers into quartiles for Recency, Frequency, and Monetary separately 
— who falls into the top 25% on each dimension?*/

--Recency
select * from (select distinct customer_id ,invoice_date,
       ntile(4) over(order by invoice_date desc ) as recency_group 
from online_retail)t
where t.recency_group=1;

--Frequency

select * from (select *,
       ntile(4) over (order by frequency desc) as fre_rank 
from (select customer_id,
             count(invoice)as frequency 
	 from online_retail 
	 group by customer_id )t)u
where u.fre_rank=1;

--Monetary
select * from (select *,
               ntile(4) over (order by total_revenue desc) as revenue_rank 
from (select customer_id,
             sum(revenue) as total_revenue
	 from online_retail 
	 group by customer_id )t)u
where u.revenue_rank=1;

/*6. Combine the three scores into a single RFM segment label per customer 
using CASE (e.g., "Champions," "At Risk," "Lost," "New Customers")*/

with recency as (
    select
        customer_id,
        max(invoice_date) as last_purchase,
        ntile(4) over (
            order by max(invoice_date) desc
        ) as r_rank
    from online_retail
    group by customer_id
),

Frequency as(
             select *,
                  ntile(4) over (order by frequency desc) as f_rank 
            from (select customer_id,
                         count(invoice)as frequency 
	               from online_retail 
	               group by customer_id )t),

	 
Monetary as(select *,
                   ntile(4) over (order by total_revenue desc) as m_rank 
           from (select customer_id,
                         sum(revenue) as total_revenue
	             from online_retail 
	             group by customer_id )t)

select r.customer_id,
       r.r_rank,
	   f.f_rank,
	   m.m_rank,
	   case
	      when r.r_rank=1
	         and f.f_rank =1
	           and m.m_rank =1
			then 'Champions'

	     when  r.r_rank >=2
	         and f.f_rank >=3
	           and m.m_rank >=3
			then 'At Risk'
	
       when  r.r_rank=4
	         and f.f_rank =4
	           and m.m_rank =4
			then 'Lost'

       when  r.r_rank=4
	         and f.f_rank >=3
	         and m.m_rank =4
			then 'New Customers'

	  else 'Others'
	 end as rfm_segment
from recency r 
join frequency f
 on r.customer_id=f.customer_id
join monetary m 
on f.customer_id=m.customer_id;


                                   Phase 4 — Segment-Level Business Analysis
/*7. How many customers fall into each RFM segment, 
and what % of total revenue does each segment represent? 
(This usually reveals that a small % of customers drive a large % of revenue 
   — worth confirming and highlighting.)*/

with recency as (
    select
        customer_id,
        max(invoice_date) as last_purchase,
        ntile(4) over (
            order by max(invoice_date) desc
        ) as r_rank
    from online_retail
    group by customer_id
),

Frequency as(
             select *,
                  ntile(4) over (order by frequency desc) as f_rank 
            from (select customer_id,
                         count(invoice)as frequency 
	               from online_retail 
	               group by customer_id )t),

	 
Monetary as(select *,
                   ntile(4) over (order by total_revenue desc) as m_rank 
           from (select customer_id,
                         sum(revenue) as total_revenue
	             from online_retail 
	             group by customer_id )t)

select 
       t.rfm_segment,
	   count(t.customer_id) as total_customer,
	   sum(t.total_revenue) as total_revenue,
       sUM(t.total_revenue) * 100.0
         / SUM(SUM(t.total_revenue)) OVER () AS segment_percent
from (
	   select r.customer_id,
       r.r_rank,
	   f.f_rank,
	   m.m_rank,
	   m.total_revenue,
	   case
	      when r.r_rank=1
	         and f.f_rank =1
	           and m.m_rank =1
			then 'Champions'

	     when  r.r_rank >=2
	         and f.f_rank >=2
	           and m.m_rank >=3
			then 'At Risk'
	
       when  r.r_rank=4
	         and f.f_rank =4
	           and m.m_rank =4
			then 'Lost'

       when  r.r_rank=4
	         and f.f_rank >=3
			then 'New Customers'

	  else 'Others'
	 end as rfm_segment
from recency r 
join frequency f
 on r.customer_id=f.customer_id
join monetary m 
on f.customer_id=m.customer_id
)t

group by t.rfm_segment
order by segment_percent desc;


/*8. What is the average order value by segment 
— do "Champions" actually spend more per order, or just more often?*/

with recency as (
    select
        customer_id,
        max(invoice_date) as last_purchase,
        ntile(4) over (
            order by max(invoice_date) desc
        ) as r_rank
    from online_retail
    group by customer_id
),

Frequency as(
             select *,
                  ntile(4) over (order by frequency desc) as f_rank 
            from (select customer_id,
                         count(invoice)as frequency 
	               from online_retail 
	               group by customer_id )t),

	 
Monetary as(select *,
                   ntile(4) over (order by total_revenue desc) as m_rank 
           from (select customer_id,
                         sum(revenue) as total_revenue
	             from online_retail 
	             group by customer_id )t),

rfm_segments as (
    select
        r.customer_id,

        case
            when r.r_rank = 1
                 and f.f_rank = 1
                 and m.m_rank = 1
                then 'Champions'

            when r.r_rank = 4
                 and f.f_rank = 4
                 and m.m_rank = 4
                then'Lost'

            when r.r_rank >= 2
                 and f.f_rank >= 2
                 and m.m_rank >= 3
                then 'At Risk'

            when r.r_rank = 1
                 and f.f_rank >= 3
                then 'New Customers'

            else 'Others'
        end as  rfm_segment

    from recency r
    join frequency f
        on r.customer_id = f.customer_id
    join monetary m
        on r.customer_id = m.customer_id
),

customers_order as (
                 select customer_id,
				        count(distinct invoice) as total_orders,
				        sum(revenue) as total_revenue
				 from online_retail
				 group by customer_id
)

select
    r.rfm_segment,
    round(avg(c.total_revenue / nullif(c.total_orders, 0)),2) as avg_order_value
from rfm_segments r
join customers_order c
    on r.customer_id = c.customer_id
group by r.rfm_segment
order by  avg_order_value desc;



/*9. Which segment has the largest gap between customer count and revenue contribution 
(i.e., punching above or below their weight)?*/

with recency as (
    select
        customer_id,
        max(invoice_date) as last_purchase,
        ntile(4) over (
            order by max(invoice_date) desc
        ) as r_rank
    from online_retail
    group by customer_id
),

Frequency as(
             select *,
                  ntile(4) over (order by frequency desc) as f_rank 
            from (select customer_id,
                         count(distinct invoice)as frequency 
	               from online_retail 
	               group by customer_id )t),

	 
Monetary as(select *,
                   ntile(4) over (order by total_revenue desc) as m_rank 
           from (select customer_id,
                         sum(revenue) as total_revenue
	             from online_retail 
	             group by customer_id )t)

select 
       t.rfm_segment,
	   count(t.customer_id) as total_customer,
	   round(COUNT(t.customer_id) * 100.0
        / SUM(COUNT(t.customer_id)) OVER (),2) AS customer_percent,
	   sum(t.total_revenue) as total_revenue,
       round(sum(t.total_revenue) * 100.0
         / sum(sum(t.total_revenue)) Over (),2) as segment_percent,
	   round(abs(
        (
            sum(t.total_revenue) * 100.0
            / sum(sum(t.total_revenue)) over ()
        )
        -
        (
            count(t.customer_id) * 100.0
            / sum(count(t.customer_id)) over ()
        )
    ),2) as gap
from (
	   select r.customer_id,
       r.r_rank,
	   f.f_rank,
	   m.m_rank,
	   m.total_revenue,
	   case
	      when r.r_rank=1
	         and f.f_rank =1
	           and m.m_rank =1
			then 'Champions'

	 	
       when  r.r_rank=4
	         and f.f_rank =4
	           and m.m_rank =4
			then 'Lost'

	     when  r.r_rank >=2
	         and f.f_rank >=2
	           and m.m_rank >=3
			then 'At Risk'
	
       
       when  r.r_rank=1
	         and f.f_rank >=3
			then 'New Customers'

	  else 'Others'
	 end as rfm_segment
from recency r 
join frequency f
 on r.customer_id=f.customer_id
join monetary m 
on f.customer_id=m.customer_id
)t

group by t.rfm_segment
order by gap desc;



                                      --Time-Based / Trend Questions
/*10. How many new customers are acquired each month, 
using MIN(InvoiceDate) per customer to identify their first purchase?*/
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_date) AS first_purchase_date
    FROM online_retail
    GROUP BY customer_id
)

SELECT
    DATE_TRUNC('month', first_purchase_date) AS month,
    COUNT(customer_id) AS new_customers
FROM first_purchase
GROUP BY DATE_TRUNC('month', first_purchase_date)
ORDER BY month;

/*11. What's the repeat purchase rate — what % of customers who bought once ever bought again? 
(Compare COUNT of customers with Frequency = 1 vs. Frequency > 1)*/

with Frequency_per_customer as(
                       select customer_id,
                              count(distinct invoice)as frequency 
	               from online_retail 
	               group by customer_id )

select 
       count(case when frequency =1 then 1 end) as "Non-repeat" ,
	   count(case when frequency >1  then 1 end) as "repeated-customers",
	   round(count(case when frequency >1  then 1 end) *100.0/count(customer_id),2) as repeate_percent
from Frequency_per_customer


                        --Product/Geography Angle (optional, adds business depth)
/*12. Which country generates the highest total revenue, and 
does that country also have the highest average Frequency per customer, or just more one-time buyers?*/

WITH customer_frequency AS (
    SELECT
        country,
        customer_id,
        COUNT(DISTINCT invoice) AS frequency
    FROM online_retail
    GROUP BY country, customer_id
),

country_analysis AS (
    SELECT
        country,
        SUM(frequency) AS total_orders,
        AVG(frequency) AS avg_frequency,
        COUNT(customer_id) AS total_customers,
        COUNT(CASE WHEN frequency = 1 THEN 1 END) AS one_time_buyers
    FROM customer_frequency
    GROUP BY country
),

country_revenue AS (
    SELECT
        country,
        SUM(revenue) AS total_revenue
    FROM online_retail
    GROUP BY country
)

SELECT
    r.country,
    r.total_revenue,
    a.total_customers,
    a.avg_frequency,
    a.one_time_buyers
FROM country_revenue r
JOIN country_analysis a
    ON r.country = a.country
ORDER BY r.total_revenue DESC;



/*12. What are the top 10 products by total revenue (Quantity × UnitPrice), 
and do they differ between "Champions" and "At Risk" segments?*/



WITH recency AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase,
        NTILE(4) OVER (
            ORDER BY MAX(invoice_date) DESC
        ) AS r_rank
    FROM online_retail
    GROUP BY customer_id
),

frequency AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY frequency DESC) AS f_rank
    FROM (
        SELECT
            customer_id,
            COUNT(DISTINCT invoice) AS frequency
        FROM online_retail
        GROUP BY customer_id
    ) t
),

monetary AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY total_revenue DESC) AS m_rank
    FROM (
        SELECT
            customer_id,
            SUM(revenue) AS total_revenue
        FROM online_retail
        GROUP BY customer_id
    ) t
),

rfm_segments AS (
    SELECT
        r.customer_id,

        CASE
            WHEN r.r_rank = 1
                 AND f.f_rank = 1
                 AND m.m_rank = 1
                THEN 'Champions'

            WHEN r.r_rank = 4
                 AND f.f_rank = 4
                 AND m.m_rank = 4
                THEN 'Lost'

            WHEN r.r_rank >= 2
                 AND f.f_rank >= 2
                 AND m.m_rank >= 3
                THEN 'At Risk'

            WHEN r.r_rank = 1
                 AND f.f_rank >= 3
                THEN 'New Customers'

            ELSE 'Others'
        END AS rfm_segment

    FROM recency r
    JOIN frequency f
        ON r.customer_id = f.customer_id
    JOIN monetary m
        ON f.customer_id = m.customer_id
),

product_revenue AS (
    SELECT
        r.rfm_segment,
        o.stock_code,
        o.description,
        SUM(o.revenue) AS total_revenue
    FROM online_retail o
    JOIN rfm_segments r
        ON o.customer_id = r.customer_id
    WHERE r.rfm_segment IN ('Champions', 'At Risk')
    GROUP BY
        r.rfm_segment,
        o.stock_code,
        o.description
),

ranked_products AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY rfm_segment
               ORDER BY total_revenue DESC
           ) AS product_rank
    FROM product_revenue
)

SELECT
    rfm_segment,
    product_rank,
    stock_code,
    description,
    total_revenue
FROM ranked_products
WHERE product_rank <= 10
ORDER BY rfm_segment, product_rank

/*14. What is the total historical revenue represented by customers in the "At Risk" segment 
(high past Frequency/Monetary, but poor Recency)? This is the number that tells a business 
"here's exactly how much revenue is at stake if we don't win these customers back."*/

WITH recency AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase,
        NTILE(4) OVER (
            ORDER BY MAX(invoice_date) DESC
        ) AS r_rank
    FROM online_retail
    GROUP BY customer_id
),

frequency AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY frequency DESC) AS f_rank
    FROM (
        SELECT
            customer_id,
            COUNT(DISTINCT invoice) AS frequency
        FROM online_retail
        GROUP BY customer_id
    ) t
),

monetary AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY total_revenue DESC) AS m_rank
    FROM (
        SELECT
            customer_id,
            SUM(revenue) AS total_revenue
        FROM online_retail
        GROUP BY customer_id
    ) t
),

rfm_segments AS (
    SELECT
        r.customer_id,
		m.total_revenue as revenue,

        CASE
            WHEN r.r_rank = 1
                 AND f.f_rank = 1
                 AND m.m_rank = 1
                THEN 'Champions'

            WHEN r.r_rank = 4
                 AND f.f_rank = 4
                 AND m.m_rank = 4
                THEN 'Lost'

            WHEN r.r_rank >= 2
                 AND f.f_rank >= 2
                 AND m.m_rank >= 3
                THEN 'At Risk'

            WHEN r.r_rank = 1
                 AND f.f_rank >= 3
                THEN 'New Customers'

            ELSE 'Others'
        END AS rfm_segment

    FROM recency r
    JOIN frequency f
        ON r.customer_id = f.customer_id
    JOIN monetary m
        ON f.customer_id = m.customer_id
)

select rfm_segment,
       sum(revenue) as segment_revenue
from rfm_segments
where rfm_segment='At Risk';

	   
/* 15. Which customers should the business contact first?*/

WITH recency AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase,
        NTILE(4) OVER (
            ORDER BY MAX(invoice_date) DESC
        ) AS r_rank
    FROM online_retail
    GROUP BY customer_id
),

frequency AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY frequency DESC) AS f_rank
    FROM (
        SELECT
            customer_id,
            COUNT(DISTINCT invoice) AS frequency
        FROM online_retail
        GROUP BY customer_id
    ) t
),

monetary AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY total_revenue DESC) AS m_rank
    FROM (
        SELECT
            customer_id,
            SUM(revenue) AS total_revenue
        FROM online_retail
        GROUP BY customer_id
    ) t
)

SELECT
    r.customer_id,
    r.last_purchase,
    f.frequency,
    m.total_revenue,
    r.r_rank,
    f.f_rank,
    m.m_rank
FROM recency r
JOIN frequency f
    ON r.customer_id = f.customer_id
JOIN monetary m
    ON f.customer_id = m.customer_id

WHERE r.r_rank >= 2
  AND f.f_rank >= 2
  AND m.m_rank >= 3

ORDER BY m.total_revenue DESC
limit 50;

                               ----creating view for powerbi
CREATE VIEW customer_rfm AS

WITH recency AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase,
        NTILE(4) OVER (
            ORDER BY MAX(invoice_date) DESC
        ) AS r_rank
    FROM online_retail
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),

frequency AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS frequency,
        NTILE(4) OVER (
            ORDER BY COUNT(DISTINCT invoice) DESC
        ) AS f_rank
    FROM online_retail
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),

monetary AS (
    SELECT
        customer_id,
        SUM(revenue) AS total_revenue,
        NTILE(4) OVER (
            ORDER BY SUM(revenue) DESC
        ) AS m_rank
    FROM online_retail
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)

SELECT
    r.customer_id,
    r.last_purchase,
    f.frequency,
    m.total_revenue,
    r.r_rank,
    f.f_rank,
    m.m_rank,

    CASE
        WHEN r.r_rank = 1
             AND f.f_rank = 1
             AND m.m_rank = 1
            THEN 'Champions'

        WHEN r.r_rank = 4
             AND f.f_rank = 4
             AND m.m_rank = 4
            THEN 'Lost'

        WHEN r.r_rank >= 2
             AND f.f_rank >= 2
             AND m.m_rank >= 3
            THEN 'At Risk'

        WHEN r.r_rank = 1
             AND f.f_rank >= 3
            THEN 'New Customers'

        ELSE 'Others'
    END AS rfm_segment

FROM recency r
JOIN frequency f
    ON r.customer_id = f.customer_id
JOIN monetary m
    ON r.customer_id = m.customer_id;


SELECT *
FROM customer_rfm;


                                  --view for monthly_new_customers

CREATE OR REPLACE VIEW monthly_new_customers AS
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_date) AS first_purchase_date
    FROM online_retail
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    DATE_TRUNC('month', first_purchase_date) AS month,
    COUNT(*) AS new_customers
FROM first_purchase
GROUP BY DATE_TRUNC('month', first_purchase_date)
ORDER BY month;

SELECT *
FROM monthly_new_customers;
