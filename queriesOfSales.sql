-- @conn sales_db
--Analysing data:

/*Calculating total number of order(rows)*/
SELECT COUNT(*) FROM orders;

--Data Cleaning:

/*Fix date*/
UPDATE orders
SET clean_date =
CASE 
    WHEN OrderDate LIKE '%/%'
        THEN '20' || substr(OrderDate, 7, 2) || '-'
             || substr(OrderDate, 1, 2) || '-'
             || substr(OrderDate, 4, 2) || ' '
             || substr(OrderDate, 10)
    WHEN OrderDate LIKE '%-%'
        THEN substr(OrderDate, 7, 4) || '-'
             || substr(OrderDate, 1, 2) || '-'
             || substr(OrderDate, 4, 2) || ' '
             || substr(OrderDate, 12)
END;

/*Fix quantity*/
--ALTER TABLE orders ADD QuantityOfOrders REAL;
UPDATE orders 
SET QuantityOfOrders = CAST(QuantityOrdered as INT);

/*Fix Price*/
--ALTER TABLE orders ADD COLUMN Price REAL;
UPDATE orders
SET Price = CAST(PriceEach AS FLOAT);

/*Extract city*/
--ALTER table orders add city text;
UPDATE orders SET city = TRIM(
    SUBSTRING(
        PurchaseAddress, 
        instr(PurchaseAddress, ',')+2,
        instr(SUBSTRING(
            PurchaseAddress, 
            instr(PurchaseAddress, ',')+2),',')-1
    )
);

/*Create sales column*/
--ALTER TABLE orders add sales REAL;
UPDATE orders 
SET sales = Price * QuantityOfOrders;

/*Removing duplicates*/
DELETE FROM orders 
WHERE rowid IN(
    SELECT rowid FROM (
        SELECT rowid, ROW_NUMBER() OVER 
        (PARTITION BY OrderID, Product
        )AS rn 
        FROM orders
    ) 
    WHERE rn > 1
);

--Analysing queries:

/*Sum of sales(the amount earned) by selling the products*/
SELECT SUM(sales) AS total_revenue
FROM orders;

--Quantity of each product sold:

/*This query helps in analysing the production/manufacturing of products according to necessity. 
In this database, AAA batteries(4 pack) are sold more indicating strong demand compared to other products
whereas production of LG Washing Machine is lower, indicating low demand.*/
SELECT product, SUM(QuantityOfOrders) as total_quantity
FROM orders
GROUP BY product
ORDER BY total_quantity DESC;

/*The below query helps in analysing the revenue collected from each product.
By comparing the previous query and this one, 
we can observe that even though the quantity of Macbook Pro Laptop sold is lesser,
the revenue collection is more, which indicates that the Macbook Pro laptop is high-priced.
This shows that high-priced products contribute significantly to total revenue.*/
SELECT Product, SUM(sales) 
as RevenueColl FROM orders 
GROUP BY Product 
ORDER BY RevenueColl DESC;

/*The below query calculates the revenue collected per each city.
Here, San Francisco collects revenue the most. 
This highlights the demand differences by cities.*/
SELECT city, sum(sales) as RevenuePerCity
FROM orders 
GROUP BY city 
ORDER BY RevenuePerCity DESC;

--Time analysis:

/*This query calculates the number of orders that have taken place in a particular hour.
By this, we can observe that the highest number of orders are at 19:00 (7 pm). */
SELECT 
STRFTIME('%H', clean_date) AS hour,
COUNT(*) AS total_orders
FROM orders
GROUP BY hour
ORDER BY total_orders DESC;

/*This query calculates total orders in the time ranges 
and helps in estimating when most of the sales happened.*/
SELECT case 
    when CAST(STRFTIME('%H', clean_date) as INTEGER) BETWEEN 6 and 11
        then 'morning'
    when CAST(STRFTIME('%H', clean_date) as INTEGER) BETWEEN 12 and 16
        then 'afternoon'  
    when CAST(STRFTIME('%H', clean_date) as INTEGER) BETWEEN 17 and 20
        then 'evening' 
    when CAST(STRFTIME('%H', clean_date) as INTEGER) BETWEEN 21 and 23
        then 'night'
    else 'midnight'
END as timeRange,
count(*) as total_salesInTimeRange
from orders
GROUP BY timeRange 
ORDER BY total_salesInTimeRange desc;

/*This query calculates the revenue collected for each month 
that helps in understanding trends. */
SELECT 
    STRFTIME('%m', clean_date) AS month,
    SUM(sales) AS revenue
FROM orders
GROUP BY month
ORDER BY month;

--Advanced:

/*The following query fetches the products bought together 
and the number of orders that those two products are together. 
This is helpful in understanding frequently purchased product combinations,
which can indicate customer buying patterns.*/
SELECT 
    a.Product as Product1,
    b.Product as Product2,
    COUNT(*) as frequency 
    FROM orders a
    join orders b on a.OrderID = b.OrderID
    AND a.Product < b.Product
    GROUP BY Product1, Product2 
    ORDER BY frequency DESC;

/*The below query calculates the sales based on days and total sales. 
'Running_total' calculates the sales upto that day 
whereas 'daily_sales' calculates the sales happened on that particular day.*/
SELECT 
    DATE(clean_date) AS day,
    SUM(sales) AS daily_sales,
    SUM(SUM(sales)) OVER (
        ORDER BY DATE(clean_date)
    ) AS running_total
FROM orders
GROUP BY day;

/*This query fetches the top products sold in every city.
Here the products that are most sold in each city are being calculated. 
This helps you in understanding trends and demands in each city. */
SELECT *
FROM (
    SELECT 
        city,
        Product,
        SUM(QuantityOfOrders) AS total_sold,
        RANK() OVER (
            PARTITION BY city 
            ORDER BY SUM(QuantityOfOrders) DESC
        ) AS rank
    FROM orders
    GROUP BY city, Product
)
WHERE rank = 1; 