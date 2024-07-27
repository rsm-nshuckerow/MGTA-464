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
SELECT B.CustomerID, B.customername, C.streetaddressline1, C.streetaddressline2, C.city, C.state, C.zip
    FROM cust A JOIN customer B ON A.CustomerID = B.CustomerID JOIN location C ON A.shippinglocationid = C.locationid;


