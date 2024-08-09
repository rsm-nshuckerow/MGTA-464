-- Practice
SELECT A.CustomerID, A.customername, COALESCE(-SUM(B.paymentamount), 0) AS PaymentTotal
    FROM Customer A LEFT JOIN Payment B USING(CustomerID)
    WHERE A.CustomerID = A.defaultbilltocustomerid
    GROUP BY A.CustomerID;

-- Q1
-- Use the salesorderheader table and the DISTINCT keyword to find out how many customers have placed orders. 
-- In your output show the count and name this field "Number of Customers With Orders". 
-- Your output should return 1 row and the value should 663.

SELECT COUNT(DISTINCT CustomerID) AS "Number of Customers With Orders"
    FROM SalesOrderHeader;

-- Q2
-- Modify query 1 to show how many customers are associated with each salesperson. 
-- Include salespersonpersonid and the count in your output. 
-- Your output should return 10 rows.


SELECT salespersonpersonid, COUNT(DISTINCT CustomerID) AS "Number of Customers With Orders"
    FROM SalesOrderHeader GROUP BY salespersonpersonid;

-- Q3a
-- Use the salesorderheader table and DISTINCT to only show unique customerid and shippinglocationid combinations. 
-- In your output show customerid and shippinglocationid. Your output should return 663 rows.

CREATE VIEW cust AS SELECT DISTINCT CustomerID, ShippingLocationID
    FROM SalesOrderHeader ORDER BY CustomerID, ShippingLocationID;

-- Q3b
SELECT CustomerID, shippinglocationid
    FROM salesorderheader GROUP BY CustomerID, shippinglocationid ORDER BY CustomerID, shippinglocationid;

-- Q4
-- Use the customer, location, and salesorderheader to show all customers shipping addresses. 
-- Note that the location table contains both shipping and billing addresses. 
-- The salesorderheader table is needed to determine if an address is a shipping address. 
-- In your output include customerid from the customer table, customername, streetaddressline1, streetaddressline2, city, state, and zip. 
-- Your results should return 663 rows.
SELECT B.CustomerID, B.customername, C.streetaddressline1, C.streetaddressline2, C.city, C.state, C.zip
    FROM cust A JOIN customer B ON A.CustomerID = B.CustomerID JOIN location C ON A.shippinglocationid = C.locationid;


-- Q5a
SELECT C.customercategoryid, C.customercategoryname, COUNT(A.customerid) AS NumberOfCustomers
    FROM customer A JOIN customercategorymembership B ON A.customerid = B.customerid
    JOIN customercategory C ON B.customercategoryid = C.customercategoryid
    GROUP BY C.customercategoryname, C.customercategoryid;

-- Q5b
SELECT C.customercategoryid, C.customercategoryname, COUNT(DISTINCT A.customerid) AS NumberOfCustomers
    FROM customer A JOIN customercategorymembership B ON A.customerid = B.customerid
    JOIN customercategory C ON B.customercategoryid = C.customercategoryid
    GROUP BY C.customercategoryname, C.customercategoryid;

-- Both Q5a (COUNT) and Q5b (COUNT DISTINCT) have the same results since the customer table
-- has a list of all the customers and their info. Every customer appears only once in the customer table
-- already, so the table already shows distinct counts.

-- Based on the ERD, CustomerID field for CustomerCatergoryMembership, it has a one-to-one relationship
-- with the CustomerID field from the customer table. Meaning, for every customerID in the customercategorymembership
-- table, there is only one customerID in the customer table. 
-- Then, The CustomerCategoryID in the CustomerCategory table can correspond to 
-- multiple CustomerCategoryID in the CustomerCatergoryMembership, However this will not increase
-- the number of rows since it is a left join.

-- Q6
-- The IN operator can be used instead of multiple OR operators in WHERE statements. 
-- The general syntax is:
-- SELECT city, state
  -- FROM location_subset
  -- WHERE state IN('California', 'Arizona', 'Washington');

  -- Modify query 4 to only show customers in Kansas, Colorado, and Utah.  
  -- Use the IN operator in your WHERE statement.

  SELECT B.CustomerID, B.customername, C.streetaddressline1, C.streetaddressline2, C.city, C.state, C.zip
    FROM cust A JOIN customer B ON A.CustomerID = B.CustomerID JOIN location C ON A.shippinglocationid = C.locationid
    WHERE C.state IN('Kansas', 'Colorado', 'Utah');

-- Q7
-- Using the purchaseorderheader table, show purchaseorderid and three columns showing dates. 
-- Two columns using EXTRACT to indicate the orderdate year, name this field "Year", 
-- and the orderdate month, name this field "Month".  
-- One column using DATE_TRUNC to show both the Year and the Month, name field "Year and Month". 
-- Only include purchases from 2013 and 2014.

CREATE VIEW Purchases_2013_2014 AS SELECT purchaseorderid, EXTRACT(YEAR FROM orderdate) AS Year, EXTRACT(MONTH FROM orderdate) AS Month,
    DATE_TRUNC('month', orderdate) AS "Year and Month" FROM purchaseorderheader 
    WHERE EXTRACT(YEAR FROM orderdate) IN(2013, 2014);


-- Q8
-- Create a count of purchase orders (name this field NumberOfOrders) for each month in 2013 and 2014 
-- (based on orderdate). Use the purchaseorderheader table. 
-- In addition to NumberOfOrders, include column(s) to show the year and month.  
-- Create two solutions, one that uses EXTRACT (show a total of three columns in this solution) 
-- and one that uses DATA_TRUNC (show a total of two columns in this solution).

-- Q8a

SELECT 
    EXTRACT(YEAR FROM orderdate) AS Year, 
    EXTRACT(MONTH FROM orderdate) AS Month,
    COUNT(EXTRACT(MONTH FROM orderdate)) AS NumberOfOrders
        FROM purchaseorderheader 
        WHERE EXTRACT(YEAR FROM orderdate) IN(2013, 2014) 
        GROUP BY EXTRACT(MONTH FROM orderdate), EXTRACT(YEAR FROM orderdate);

-- Q8b

SELECT
    DATE_TRUNC('month', orderdate) AS month, 
    COUNT(DATE_TRUNC('month', orderdate)) AS NumberOfOrders
        FROM purchaseorderheader
        WHERE EXTRACT(YEAR FROM orderdate) IN(2013, 2014)
        GROUP BY DATE_TRUNC('month', orderdate);


-- Q9
-- Calculate for each supplier how long it takes on average to receive ordered items 
-- (only including orders that have actually been received). 
-- Name this field "Average Fulfillment Time (hours)". 
-- Also, determine how many orders have been placed and received with each supplier 
-- and how many unique items we order (and have received) from each supplier. 
-- Name these two fields "Number of Orders" and "Number of Unique Items".

CREATE VIEW Purchases AS 
    SELECT A.PurchaseOrderID, B.stockitemid, EXTRACT(EPOCH FROM orderdate) AS OrderDateSeconds, A.supplierid
    FROM purchaseorderheader A JOIN purchaseorderline B ON A.purchaseorderid = B.purchaseorderid;

CREATE VIEW Receiving AS
    SELECT B.purchaseorderid, B.stockitemid, AVG(EXTRACT(EPOCH FROM A.receivingdate)) AS ReceivingDateSeconds
    FROM receivingreportheader A JOIN receivingreportline B ON A.receivingreportid = B.receivingreportid
    GROUP BY B.purchaseorderid, B.stockitemid;

SELECT 
    A.supplierid, 
    round(AVG(B.ReceivingDateSeconds - A.OrderDateSeconds)::numeric/60/60,2) AS "Average Fulfillment Time (Hours)",
    COUNT(DISTINCT A.purchaseorderid) AS "Number of Orders",
    COUNT(DISTINCT A.stockitemid) AS "Number of Items"
    FROM Purchases A INNER JOIN Receiving B 
    ON A.purchaseorderid = B.purchaseorderid AND A.stockitemid = B.stockitemid
    GROUP BY A.supplierid; 


-- Q10a

-- Before we use filter, create a query that show, for each year, 
-- the "Number of Open Orders" and "Number of open order lines in period", as two new fields. 
-- Also include a field that indicates the year (name this field "Year"). 
-- An open order is an order that has not yet been delivered. 
-- You can assume that if the order does not have an invoice 
-- (there is no invoice id in the order header), then it has not yet been delivered.

SELECT
    EXTRACT(YEAR FROM A.orderdate) AS Year,
    COUNT(DISTINCT A.orderid) AS "Number of Open Orders",
    COUNT(*) AS "Number of open order lines in period"
        FROM salesorderheader A 
        JOIN salesorderline B ON A.orderid = B.orderid
        WHERE A.invoiceid IS NULL
        GROUP BY EXTRACT(YEAR FROM A.orderdate);

-- Q10b

-- Modify query 10.a to find only the number of orders rather than order lines. Also pivot the results to instead report the results in one row with four columns:
-- “Number of open orders from 2013”,
-- “Number of open orders from 2014”,
-- “Number of open orders from 2015”, and
-- “Number of open orders from 2016”.
-- Create two solutions, one that uses FILTER and one that uses CASE WHEN.

SELECT
    COUNT(CASE WHEN EXTRACT(YEAR FROM orderdate) = 2013 THEN orderid END) AS "2013",
    COUNT(CASE WHEN EXTRACT(YEAR FROM orderdate) = 2014 THEN orderid END) AS "2014",
    COUNT(CASE WHEN EXTRACT(YEAR FROM orderdate) = 2015 THEN orderid END) AS "2015",
    COUNT(CASE WHEN EXTRACT(YEAR FROM orderdate) = 2016 THEN orderid END) AS "2016"
    FROM salesorderheader WHERE invoiceid IS NULL;

SELECT
    COUNT(orderid) FILTER(WHERE EXTRACT(YEAR FROM orderdate) = 2013) AS "2013",
    COUNT(orderid) FILTER(WHERE EXTRACT(YEAR FROM orderdate) = 2014) AS "2014",
    COUNT(orderid) FILTER(WHERE EXTRACT(YEAR FROM orderdate) = 2015) AS "2015",
    COUNT(orderid) FILTER(WHERE EXTRACT(YEAR FROM orderdate) = 2016) AS "2016"
    FROM salesorderheader WHERE invoiceid IS NULL;

-- Q11
CREATE VIEW Sales AS 
    SELECT 
        A.orderid,
        EXTRACT(YEAR FROM A.orderdate) AS Sales_Year,
        EXTRACT(MONTH FROM A.orderdate) AS Sales_Month,
        B.quantity*B.unitprice*(1+B.taxrate/100) AS Sales
            FROM salesorderheader A
            JOIN salesorderline B ON A.orderid = B.orderid;



SELECT
    A.sales_year,
    round(SUM(Sales) FILTER(WHERE Sales_Month = 1)::numeric/1000000, 2) AS "Jan Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 2)::numeric/1000000, 2) AS "Feb Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 3)::numeric/1000000, 2) AS "Mar Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 4)::numeric/1000000, 2) AS "Apr Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 5)::numeric/1000000, 2) AS "May Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 6)::numeric/1000000, 2) AS "Jun Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 7)::numeric/1000000, 2) AS "Jul Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 8)::numeric/1000000, 2) AS "Aug Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 9)::numeric/1000000, 2) AS "Sept Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 10)::numeric/1000000, 2) AS "Oct Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 11)::numeric/1000000, 2) AS "Nov Sales (in millions)",
    round(SUM(Sales) FILTER(WHERE Sales_Month = 12)::numeric/1000000, 2) AS "Dec Sales (in millions)"
    FROM Sales A
    GROUP BY Sales_Year;

-- Q13

SELECT customerid, -paymentamount AS Payment_Amount
    FROM payment 
    ORDER BY Payment_Amount DESC
    OFFSET 5 LIMIT 10;

-- Q14

SELECT customerid, SUM(-paymentamount) AS total_customer_payment
    FROM payment
    GROUP BY customerid
    ORDER BY total_customer_payment ASC
    OFFSET 5 LIMIT 10;

-- Q15
-- Step 1
CREATE VIEW Sales_by_Customer AS 
    SELECT C.defaultbilltocustomerid, SUM(B.quantity*B.unitprice*(1+B.taxrate/100)) as Total_Sales
    FROM salesorderheader A
    JOIN salesorderline B ON A.orderid = B.orderid
    JOIN customer C ON A.customerid = C.customerid
    GROUP BY C.defaultbilltocustomerid;

DROP VIEW Sales_by_Customer;

CREATE VIEW Payments_by_Customer AS
    SELECT customerid, SUM(-paymentamount) AS total_customer_payment
    FROM payment
    GROUP BY customerid;

DROP VIEW Payments_by_Customer;

-- Step 2
SELECT A.defaultbilltocustomerid, A.Total_Sales-B.total_customer_payment AS net
    FROM Sales_by_Customer A 
    JOIN Payments_by_Customer B ON A.defaultbilltocustomerid = B.customerid;

-- Step 3

SELECT A.defaultbilltocustomerid, A.Total_Sales-COALESCE(B.total_customer_payment,0) AS net
    FROM Sales_by_Customer A 
    JOIN Payments_by_Customer B ON A.defaultbilltocustomerid = B.customerid;

-- Step 4

CREATE VIEW Sales_by_Customer_Location AS 
    SELECT C.defaultbilltocustomerid, D.state, SUM(B.quantity*B.unitprice*(1+B.taxrate/100)) as Total_Sales
    FROM salesorderheader A
    JOIN salesorderline B ON A.orderid = B.orderid
    JOIN customer C ON A.customerid = C.customerid
    JOIN location D on C.defaultbilltocustomerid = D.customerid
    WHERE D.state IN('Kansas', 'Colorado', 'Utah')
    GROUP BY C.defaultbilltocustomerid, D.state;

DROP VIEW Sales_by_Customer_Location;

CREATE VIEW Payments_by_Customer_Location AS
    SELECT A.customerid, SUM(-A.paymentamount) AS total_customer_payment
    FROM payment A
    GROUP BY A.customerid;

DROP VIEW Payments_by_Customer_Location;

SELECT A.defaultbilltocustomerid, A.state, A.Total_Sales-COALESCE(B.total_customer_payment,0) AS net
    FROM Sales_by_Customer_Location A 
    JOIN Payments_by_Customer_Location B 
    ON A.defaultbilltocustomerid = B.customerid
    ORDER BY net DESC OFFSET 5 LIMIT 10;


-- Q16

WITH customers_with_orders AS (
    SELECT DISTINCT CustomerID, ShippingLocationID
    FROM SalesOrderHeader ORDER BY CustomerID, ShippingLocationID
)
SELECT B.CustomerID, B.customername, C.streetaddressline1, C.streetaddressline2, C.city, C.state, C.zip
    FROM customers_with_orders A 
    JOIN customer B ON A.CustomerID = B.CustomerID 
    JOIN location C ON A.shippinglocationid = C.locationid
    WHERE C.state IN('Kansas', 'Colorado', 'Utah');


-- Q17

WITH Customer_Sales AS (
    SELECT C.defaultbilltocustomerid, D.state, SUM(B.quantity*B.unitprice*(1+B.taxrate/100)) as Total_Sales
    FROM salesorderheader A
    JOIN salesorderline B ON A.orderid = B.orderid
    JOIN customer C ON A.customerid = C.customerid
    JOIN location D on C.defaultbilltocustomerid = D.customerid
    WHERE D.state IN('Kansas', 'Colorado', 'Utah')
    GROUP BY C.defaultbilltocustomerid, D.state
),
Customer_Payments AS (
    SELECT A.customerid, SUM(-A.paymentamount) AS total_customer_payment
    FROM payment A
    GROUP BY A.customerid
)
SELECT A.defaultbilltocustomerid, A.state, A.Total_Sales-COALESCE(B.total_customer_payment,0) AS net
    FROM Customer_Sales A 
    JOIN Customer_Payments B 
    ON A.defaultbilltocustomerid = B.customerid
    ORDER BY net DESC OFFSET 5 LIMIT 10;

-- Q18

WITH Customer_Sales AS (
    SELECT C.defaultbilltocustomerid, D.state, SUM(B.quantity*B.unitprice*(1+B.taxrate/100)) as Total_Sales
    FROM salesorderheader A
    JOIN salesorderline B ON A.orderid = B.orderid
    JOIN customer C ON A.customerid = C.customerid
    JOIN location D on C.defaultbilltocustomerid = D.customerid
    WHERE D.state IN('Kansas', 'Colorado', 'Utah')
    GROUP BY C.defaultbilltocustomerid, D.state
),
Customer_Payments AS (
    SELECT A.customerid, SUM(-A.paymentamount) AS total_customer_payment
    FROM payment A
    GROUP BY A.customerid
),
Sales_and_Payments AS (
    SELECT A.defaultbilltocustomerid, A.state, A.Total_Sales-COALESCE(B.total_customer_payment,0) AS net
    FROM Customer_Sales A 
    JOIN Customer_Payments B 
    ON A.defaultbilltocustomerid = B.customerid
)
SELECT * FROM Sales_and_Payments ORDER BY net DESC OFFSET 5 LIMIT 10;

-- Q19
WITH Customer_Sales AS (
    SELECT C.defaultbilltocustomerid, D.state, SUM(B.quantity*B.unitprice*(1+B.taxrate/100)) as Total_Sales
    FROM salesorderheader A
    JOIN salesorderline B ON A.orderid = B.orderid
    JOIN customer C ON A.customerid = C.customerid
    JOIN location D on C.defaultbilltocustomerid = D.customerid
    WHERE D.state IN('Kansas', 'Colorado', 'Utah')
    GROUP BY C.defaultbilltocustomerid, D.state
),
Customer_Payments AS (
    SELECT A.customerid, SUM(-A.paymentamount) AS total_customer_payment
    FROM payment A
    GROUP BY A.customerid
),
Sales_and_Payments AS (
    SELECT A.defaultbilltocustomerid, A.state, A.Total_Sales-COALESCE(B.total_customer_payment,0) AS net
    FROM Customer_Sales A 
    JOIN Customer_Payments B 
    ON A.defaultbilltocustomerid = B.customerid
),
Top_5 AS ( 
    SELECT *, 'Top' AS "Type" FROM Sales_and_Payments ORDER BY net DESC LIMIT 5
),
Bottom_5 AS (
    SELECT *, 'Bottom' AS "Type" FROM Sales_and_Payments ORDER BY net ASC LIMIT 5
)
SELECT * FROM Top_5
UNION
SELECT * FROM Bottom_5
ORDER BY net DESC;