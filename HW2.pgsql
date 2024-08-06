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

SELECT round(AVG(B.ReceivingDateSeconds - A.OrderDateSeconds)::numeric/60/60,2),
    A.supplierid FROM Purchases A INNER JOIN Receiving B 
    ON A.purchaseorderid = B.purchaseorderid AND A.stockitemid = B.stockitemid
    GROUP BY A.supplierid; 


