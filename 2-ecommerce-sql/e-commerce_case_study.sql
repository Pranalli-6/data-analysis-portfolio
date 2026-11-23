/* =====================================================================
   E-COMMERCE SALES ANALYSIS (MySQL)
   ---------------------------------------------------------------------
   Tables
     Customers    (customer_id, name, location)
     Products     (product_id, name, category, price)
     Orders       (order_id, customer_id, order_date, total_amount)
     OrderDetails (order_id, product_id, quantity, price_per_unit)

   Period : March 2023 to February 2024
   Contents
     1. Data exploration
     2. Customer analysis
     3. Product analysis
     4. Sales and revenue trends
     5. Inventory and demand planning
   ===================================================================== */


/* =====================================================================
   1. DATA EXPLORATION
   ===================================================================== */

-- 1.1 Understand the structure of the four tables
DESCRIBE Customers;
DESCRIBE Products;
DESCRIBE Orders;
DESCRIBE OrderDetails;


/* =====================================================================
   2. CUSTOMER ANALYSIS
   ===================================================================== */

-- 2.1 Key markets: the three cities with the most customers
-- Why: decides where to focus marketing and delivery capacity.
-- Finding: Delhi (16), Chennai (15) and Jaipur (11) hold 42 of 100 customers.
SELECT location,
       COUNT(customer_id) AS number_of_customers
FROM Customers
GROUP BY location
ORDER BY COUNT(customer_id) DESC
LIMIT 3;


-- 2.2 Purchase frequency: how many customers placed 1, 2, 3 ... orders
-- Why: shows whether customers come back or buy only once.
-- Finding: counts fall as orders rise (26, 26, 18, 6, 6, 1, 1);
--          most buyers are occasional shoppers with 1 to 3 orders.
WITH orders_per_customer AS (
    SELECT customer_id,
           COUNT(order_id) AS NumberOfOrders
    FROM Orders
    GROUP BY customer_id
)
SELECT NumberOfOrders,
       COUNT(customer_id) AS CustomerCount
FROM orders_per_customer
GROUP BY NumberOfOrders
ORDER BY NumberOfOrders;


-- 2.3 New-customer acquisition: customers making a first purchase each month
-- Why: shows whether marketing is still bringing in new customers.
-- Finding: new customers peaked at 18 in April 2023 and slowed to 1 a month
--          by February 2024, a downward trend.
WITH first_purchase AS (
    SELECT customer_id,
           MIN(LEFT(order_date, 7)) AS FirstPurchaseMonth
    FROM Orders
    GROUP BY customer_id
)
SELECT FirstPurchaseMonth,
       COUNT(customer_id) AS TotalNewCustomers
FROM first_purchase
GROUP BY FirstPurchaseMonth
ORDER BY FirstPurchaseMonth;


/* =====================================================================
   3. PRODUCT ANALYSIS
   ===================================================================== */

-- 3.1 Premium products: average quantity per order of 2 with high revenue
-- Why: spots high-value items that sell in small volumes.
-- Finding: Smartphone (product 1) earns the most among these, about Rs 16.2 lakh.
SELECT product_id,
       AVG(quantity)                  AS AvgQuantity,
       SUM(quantity * price_per_unit) AS TotalRevenue
FROM OrderDetails
GROUP BY product_id
HAVING AVG(quantity) = 2
ORDER BY TotalRevenue DESC;


-- 3.2 Category reach: unique customers buying from each category
-- Why: shows which categories appeal to the widest customer base.
-- Finding: Electronics reaches 79 customers, ahead of Wearable Tech (61)
--          and Photography (45).
SELECT P.category,
       COUNT(DISTINCT O.customer_id) AS unique_customers
FROM Products P
JOIN OrderDetails D ON P.product_id = D.product_id
JOIN Orders O       ON D.order_id   = O.order_id
GROUP BY P.category
ORDER BY unique_customers DESC;


-- 3.3 Low-reach products: bought by fewer than 40% of customers
-- Why: flags a possible mismatch between stock and customer interest.
-- Finding: Smartphone (36 buyers) and Wireless Earbuds (38) fall below the
--          40-customer threshold, which suggests low visibility.
SELECT P.product_id,
       P.name,
       COUNT(DISTINCT O.customer_id) AS UniqueCustomerCount
FROM Products P
JOIN OrderDetails D ON P.product_id = D.product_id
JOIN Orders O       ON D.order_id   = O.order_id
GROUP BY P.product_id, P.name
HAVING COUNT(DISTINCT O.customer_id) < (SELECT COUNT(customer_id) * 0.40
                                        FROM Customers);


/* =====================================================================
   4. SALES AND REVENUE TRENDS
   ===================================================================== */

-- 4.1 Month-on-month change in total sales
-- Why: reveals growth or decline in revenue over time.
-- Finding: sales swing sharply with no steady trend; the largest decline is
--          February 2024 (-74.5%), partly because data ends on 24 February.
WITH monthly_sales AS (
    SELECT LEFT(order_date, 7) AS Month,
           SUM(total_amount)   AS TotalSales
    FROM Orders
    GROUP BY LEFT(order_date, 7)
)
SELECT Month,
       TotalSales,
       ROUND(
           (TotalSales - LAG(TotalSales, 1) OVER (ORDER BY Month))
           / LAG(TotalSales, 1) OVER (ORDER BY Month) * 100
       , 2) AS PercentChange
FROM monthly_sales;


-- 4.2 Month-on-month change in average order value
-- Why: guides pricing and promotions that lift spend per order.
-- Finding: December has the largest rise, about Rs 36,200 above November.
WITH monthly_aov AS (
    SELECT LEFT(order_date, 7)           AS Month,
           ROUND(AVG(total_amount), 2)   AS AvgOrderValue
    FROM Orders
    GROUP BY LEFT(order_date, 7)
)
SELECT Month,
       AvgOrderValue,
       ROUND(AvgOrderValue - LAG(AvgOrderValue, 1) OVER (ORDER BY Month), 2) AS ChangeInValue
FROM monthly_aov
ORDER BY ChangeInValue DESC;


-- 4.3 Peak months: the three months with the highest sales
-- Why: supports planning for stock, marketing and staffing.
-- Finding: September (Rs 29.3 lakh), December (Rs 27.7 lakh) and July
--          (Rs 25.7 lakh) are the peaks.
SELECT LEFT(order_date, 7) AS Month,
       SUM(total_amount)   AS TotalSales
FROM Orders
GROUP BY LEFT(order_date, 7)
ORDER BY TotalSales DESC
LIMIT 3;


/* =====================================================================
   5. INVENTORY AND DEMAND PLANNING
   ===================================================================== */

-- 5.1 Fastest-moving products: top 5 by number of orders
-- Why: shows which products need frequent restocking.
-- Finding: product 7 (Digital SLR Camera) leads with 78 orders.
SELECT product_id,
       COUNT(order_id) AS SalesFrequency
FROM OrderDetails
GROUP BY product_id
ORDER BY SalesFrequency DESC
LIMIT 5;
