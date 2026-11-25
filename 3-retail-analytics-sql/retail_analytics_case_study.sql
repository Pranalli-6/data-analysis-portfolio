/* =====================================================================
   RETAIL ANALYTICS CASE STUDY (MySQL)
   ---------------------------------------------------------------------
   Business goal
     Clean a retail company's transaction data, then find what sells,
     when it sells, and which customers drive the revenue.

   Tables
     sales_transaction (TransactionID, CustomerID, ProductID,
                        QuantityPurchased, TransactionDate, Price)
     product_inventory (ProductID, ProductName, Category, StockLevel, Price)
     customer_profiles (CustomerID, Age, Gender, Location, JoinDate)

   Data size : 5,002 raw transactions, 200 products, 1,000 customer profiles
   Period    : 1 January 2023 to 28 July 2023

   Contents
     1. Data cleaning and validation
     2. Product and category performance
     3. Sales trend
     4. Customer behaviour and segmentation
   ===================================================================== */


/* =====================================================================
   1. DATA CLEANING AND VALIDATION
   ===================================================================== */

-- 1.1 Duplicate transactions
-- Check: find transaction IDs that appear more than once.
-- Finding: 2 transaction IDs are duplicated, so 5,002 raw rows become 5,000.
SELECT TransactionID,
       COUNT(*) AS occurrences
FROM sales_transaction
GROUP BY TransactionID
HAVING COUNT(*) > 1;

-- Fix: keep one copy of every row, then swap the clean table in.
CREATE TABLE sales_transaction_dedup AS
SELECT DISTINCT TransactionID, CustomerID, ProductID,
                QuantityPurchased, TransactionDate, Price
FROM sales_transaction;

DROP TABLE sales_transaction;
RENAME TABLE sales_transaction_dedup TO sales_transaction;

-- Verify: the row count should now be 5,000.
SELECT COUNT(*) AS rows_after_cleaning
FROM sales_transaction;


-- 1.2 Price mismatches between transactions and the product catalogue
-- Check: list transactions whose price differs from the inventory price.
-- Finding: 20 transactions, all for product 51, were recorded at 9312.00
--          instead of 93.12 (a 100x entry error). They overstated total
--          sales from about 702 thousand to about 1.21 million.
SELECT S.TransactionID,
       S.ProductID,
       S.Price AS TransactionPrice,
       P.Price AS InventoryPrice
FROM sales_transaction S
JOIN product_inventory P ON S.ProductID = P.ProductID
WHERE S.Price <> P.Price;

-- Fix: treat the inventory price as the source of truth.
UPDATE sales_transaction S
JOIN product_inventory P ON S.ProductID = P.ProductID
SET S.Price = P.Price
WHERE S.Price <> P.Price;

-- Verify: this should now return no rows.
SELECT COUNT(*) AS remaining_mismatches
FROM sales_transaction S
JOIN product_inventory P ON S.ProductID = P.ProductID
WHERE S.Price <> P.Price;


-- 1.3 Missing customer locations
-- Check: count profiles with a missing location.
-- Finding: 13 of 1,000 profiles have no location.
SELECT COUNT(*) AS missing_location
FROM customer_profiles
WHERE Location IS NULL OR TRIM(Location) = '';

-- Fix: label them "Unknown" instead of leaving blanks.
UPDATE customer_profiles
SET Location = 'Unknown'
WHERE Location IS NULL OR TRIM(Location) = '';


-- 1.4 Transaction dates stored as text
-- Check: dates arrive as text in DD/MM/YY format (for example 01/01/23).
-- Fix: build a table with a true DATE column, then swap it in.
CREATE TABLE sales_transaction_dated AS
SELECT *,
       STR_TO_DATE(TransactionDate, '%d/%m/%y') AS TransactionDate_updated
FROM sales_transaction;

DROP TABLE sales_transaction;
RENAME TABLE sales_transaction_dated TO sales_transaction;

-- Verify: the new column should show dates in YYYY-MM-DD format.
SELECT TransactionID, TransactionDate, TransactionDate_updated
FROM sales_transaction
LIMIT 5;


/* =====================================================================
   2. PRODUCT AND CATEGORY PERFORMANCE
   ===================================================================== */

-- 2.1 Units sold and sales by product
-- Why: shows which products carry the revenue.
-- Finding: product 17 leads with 100 units and 9,450 in sales.
SELECT ProductID,
       SUM(QuantityPurchased)          AS TotalUnitsSold,
       SUM(QuantityPurchased * Price)  AS TotalSales
FROM sales_transaction
GROUP BY ProductID
ORDER BY TotalSales DESC;


-- 2.2 Category performance
-- Why: shows which categories deserve marketing support.
-- Finding: Home & Kitchen leads with 217,756 (31.0% of sales), followed by
--          Electronics (25.3%), Clothing (23.2%) and Beauty & Health (20.5%).
SELECT P.Category,
       SUM(S.QuantityPurchased)             AS TotalUnitsSold,
       SUM(S.QuantityPurchased * S.Price)   AS TotalSales
FROM sales_transaction S
JOIN product_inventory P ON S.ProductID = P.ProductID
GROUP BY P.Category
ORDER BY TotalSales DESC;


-- 2.3 Top 10 products by revenue
-- Why: identifies the high-sales products to protect and promote.
-- Finding: the top 10 together make up only 10.3% of sales, so revenue is
--          spread across a broad catalogue.
SELECT ProductID,
       SUM(QuantityPurchased * Price) AS TotalRevenue
FROM sales_transaction
GROUP BY ProductID
ORDER BY TotalRevenue DESC
LIMIT 10;


-- 2.4 Ten slowest-selling products (at least one unit sold)
-- Why: flags stock that may need a promotion or a review.
-- Finding: product 142 sells least with 27 units; every one of the 200
--          products sold at least once.
SELECT ProductID,
       SUM(QuantityPurchased) AS TotalUnitsSold
FROM sales_transaction
GROUP BY ProductID
HAVING SUM(QuantityPurchased) >= 1
ORDER BY TotalUnitsSold ASC
LIMIT 10;


/* =====================================================================
   3. SALES TREND
   ===================================================================== */

-- 3.1 Daily sales trend
-- Why: shows the day-by-day revenue pattern.
-- Finding: about 24 transactions a day; the best day was 15 March 2023
--          with 4,516 in sales.
SELECT TransactionDate_updated                    AS DATETRANS,
       COUNT(TransactionID)                       AS Transaction_count,
       SUM(QuantityPurchased)                     AS TotalUnitsSold,
       ROUND(SUM(QuantityPurchased * Price), 2)   AS TotalSales
FROM sales_transaction
GROUP BY TransactionDate_updated
ORDER BY DATETRANS DESC;


-- 3.2 Month-on-month sales growth
-- Why: shows whether the company is growing.
-- Finding: monthly sales stay near 100 thousand from January to June
--          (February -7.29%, March +6.81%). July looks 10.99% lower only
--          because the data ends on 28 July.
WITH monthly_sales AS (
    SELECT MONTH(TransactionDate_updated)           AS month,
           ROUND(SUM(QuantityPurchased * Price), 2) AS Total_sales
    FROM sales_transaction
    GROUP BY MONTH(TransactionDate_updated)
)
SELECT month,
       Total_sales,
       LAG(Total_sales, 1) OVER (ORDER BY month) AS previous_month_sales,
       ROUND(
           (Total_sales - LAG(Total_sales, 1) OVER (ORDER BY month))
           / LAG(Total_sales, 1) OVER (ORDER BY month) * 100
       , 2) AS mom_growth_percentage
FROM monthly_sales
ORDER BY month;


/* =====================================================================
   4. CUSTOMER BEHAVIOUR AND SEGMENTATION
   ===================================================================== */

-- 4.1 Purchase frequency: transactions per customer
-- Why: shows how often customers buy.
-- Finding: 989 of 1,000 profiles bought at least once, about 5.1
--          transactions each; most customers made 3 to 6.
SELECT CustomerID,
       COUNT(TransactionID) AS NumberOfTransactions
FROM sales_transaction
GROUP BY CustomerID
ORDER BY NumberOfTransactions DESC;


-- 4.2 High-frequency, high-spend customers
-- Why: identifies the customers worth rewarding.
-- Finding: only 18 customers made more than 10 purchases and spent over
--          1,000; the top customer is 936 (12 transactions, 2,834 spent).
SELECT CustomerID,
       COUNT(TransactionID)           AS NumberOfTransactions,
       SUM(QuantityPurchased * Price) AS TotalSpent
FROM sales_transaction
GROUP BY CustomerID
HAVING COUNT(TransactionID) > 10
   AND SUM(QuantityPurchased * Price) > 1000
ORDER BY TotalSpent DESC;


-- 4.3 Occasional customers: two transactions or fewer
-- Why: identifies customers to bring back with re-engagement offers.
-- Finding: 130 customers fall in this group; together they generate only
--          4.2% of sales.
SELECT CustomerID,
       COUNT(TransactionID)           AS NumberOfTransactions,
       SUM(QuantityPurchased * Price) AS TotalSpent
FROM sales_transaction
GROUP BY CustomerID
HAVING COUNT(TransactionID) <= 2
ORDER BY NumberOfTransactions ASC, TotalSpent DESC;


-- 4.4 Repeat purchases of the same product
-- Why: shows which customers come back to the same product.
-- Finding: 70 customer-product pairs repeat (68 customers); no pair
--          repeats more than 3 times.
SELECT CustomerID,
       ProductID,
       COUNT(TransactionID) AS TimesPurchased
FROM sales_transaction
GROUP BY CustomerID, ProductID
HAVING COUNT(TransactionID) > 1
ORDER BY TimesPurchased DESC;


-- 4.5 Customer loyalty: time between first and last purchase
-- Why: measures how long customers stay active.
-- Finding: 950 customers bought on more than one day; the average span is
--          about 130 days and the longest is 208 days.
SELECT CustomerID,
       MIN(TransactionDate_updated) AS FirstPurchase,
       MAX(TransactionDate_updated) AS LastPurchase,
       DATEDIFF(MAX(TransactionDate_updated),
                MIN(TransactionDate_updated)) AS DaysBetweenPurchases
FROM sales_transaction
GROUP BY CustomerID
HAVING DaysBetweenPurchases > 0
ORDER BY DaysBetweenPurchases DESC;


-- 4.6 Customer segments by total quantity purchased
-- Why: lets marketing target each group differently.
-- Rule: 1-10 units = Low, 11-30 units = Med, more than 30 units = High.
CREATE TABLE customer_segment AS
SELECT CustomerID,
       SUM(QuantityPurchased) AS TotalQuantity,
       CASE
           WHEN SUM(QuantityPurchased) BETWEEN 1 AND 10 THEN 'Low'
           WHEN SUM(QuantityPurchased) BETWEEN 11 AND 30 THEN 'Med'
           WHEN SUM(QuantityPurchased) > 30 THEN 'High'
       END AS CustomerSegment
FROM sales_transaction
GROUP BY CustomerID;

-- Finding: 423 Low, 559 Med and 7 High customers. The Med segment
--          generates about 75% of sales.
SELECT CustomerSegment,
       COUNT(*) AS NumberOfCustomers
FROM customer_segment
GROUP BY CustomerSegment;
