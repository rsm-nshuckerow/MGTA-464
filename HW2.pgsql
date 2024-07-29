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
-- has a list of all the customers and their info. Every custoemr appears only once in the table
-- already, so the table already shows distinct counts.

-- Based on the ERD, CustomerID field for CustomerCatergoryMembership, it has a one-to-one relationship
-- with the CustomerID field from the customer table. Meaning, for every customerID in the customercategorymembership
-- table, there is only one customerID in the customer table. 
-- Then, The CustomerCategoryID in the CustomerCategory table can correspond to 
-- multiple CustomerCategoryID in the CustomerCatergoryMembership, However this will not increase
-- the number of rows since it is a left join.

