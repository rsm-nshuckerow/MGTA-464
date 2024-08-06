DROP TABLE location_subset;
CREATE TABLE location_subset AS
    SELECT *
    FROM location
    ORDER BY city, state LIMIT 50;

UPDATE location_subset
SET City = 'Abbottsburg'
WHERE State = 'New Jersey';


SELECT *
  FROM location_subset
  ORDER BY state, city;

SELECT DISTINCT state
  FROM location_subset
  ORDER BY state;

SELECT DISTINCT city
  FROM location_subset
  ORDER BY city;

SELECT DISTINCT city, state
  FROM location_subset
  ORDER BY city, state;

SELECT count(DISTINCT city), count(DISTINCT state)
  FROM location_subset;

SELECT state, count(DISTINCT city), count(city)
  FROM location_subset
  GROUP BY state;

DROP TABLE location_subset;
CREATE TABLE location_subset AS
    SELECT *
    FROM location
    ORDER BY city, state LIMIT 50;

UPDATE location_subset
SET City = 'Abbottsburg'
WHERE State = 'New Jersey';


SELECT *
  FROM location_subset
  ORDER BY state, city;

SELECT DISTINCT state
  FROM location_subset
  ORDER BY state;

SELECT DISTINCT city
  FROM location_subset
  ORDER BY city;

SELECT DISTINCT city, state
  FROM location_subset
  ORDER BY city, state;

SELECT count(DISTINCT city), count(DISTINCT state)
  FROM location_subset;

SELECT state, count(DISTINCT city), count(city)
  FROM location_subset
  GROUP BY state;
  

EXTRACT(part-of-date FROM field)
EXTRACT(MONTH FROM orderdate)


SELECT EXTRACT(YEAR FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(QUARTER FROM TIMESTAMP '2017-05-17 02:09:30');
SELECT EXTRACT(MONTH FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(WEEK FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(DAY FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(DOY FROM TIMESTAMP '2017-01-01 02:09:30'); -- day of year
SELECT EXTRACT(DOW FROM TIMESTAMP '2017-03-17 02:09:30'); -- day of week - the day of the week (0 - 6; Sunday is 0) 
SELECT EXTRACT(HOUR FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(MINUTE FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(SECOND FROM TIMESTAMP '2017-03-17 02:09:30.052'); --includes fractions
SELECT EXTRACT(epoch FROM TIMESTAMP '2017-03-17 02:09:30'); -- (number of seconds since since 1970-01-01 00:00:00 UTC)

DATE_TRUNC general syntax:
date_trunc('datepart', field)

Example:
date_trunc('month', orderdate)

Some of the options for datepart:
SELECT DATE_TRUNC('second', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('minute', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('hour', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('day', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('week', TIMESTAMP '2017-03-21 02:09:30');
SELECT DATE_TRUNC('month', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('quarter', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('year', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('decade', TIMESTAMP '2017-03-17 02:09:30');


CREATE TABLE date_tester (
    id_field integer,
    orderdate timestamp, 
    deliverydate timestamp);

CREATE TABLE date_tester_dates (
    id_field integer,
    orderdate DATE, 
    deliverydate date);
    
INSERT INTO date_tester (id_field, orderdate, deliverydate)
VALUES
  (1, '2016-06-23 19:10:25', '2016-06-23 19:10:25'),
  (1, '2016-06-23 19:10:25', '2016-06-22 19:10:25'),
  (1, '2016-06-23 19:10:25', '2016-06-20 19:10:25'),
  (2, '2016-06-23 19:10:25', '2016-06-23 00:00:00'),
  (2, '2016-06-23 19:10:25', '2016-06-22 00:00:00'),
  (2, '2016-06-23 19:10:25', '2016-06-21 00:00:00'),
  (3, '2016-06-23 19:10:25', '2016-06-22 19:10:25'),
  (3, '2016-06-23 19:10:25', '2016-06-22 19:10:15'),
  (3, '2016-06-23 19:10:25', '2016-06-22 19:10:00');

INSERT INTO date_tester_dates (id_field, orderdate, deliverydate)
VALUES
  (1, '2016-06-23', '2016-06-22'),
  (1, '2016-06-23', '2016-06-22'),
  (1, '2016-06-23', '2016-06-20'),
  (2, '2016-06-23', '2016-06-21'),
  (2, '2016-06-23', '2016-06-22'),
  (2, '2016-06-25', '2016-06-20'),
  (3, '2016-06-23', '2016-06-21'),
  (3, '2016-06-25', '2016-06-22'),
  (3, '2016-06-27', '2016-06-20'),
  (4, '2016-06-23', '2016-06-21'),
  (4, '2016-06-23', '2016-06-22'),
  (4, '2016-06-23', '2016-06-20');


SELECT DATE_TRUNC('month', orderdate) AS DATE_TRUNC , EXTRACT(MONTH FROM orderdate) AS EXTRACT, orderdate
  FROM date_tester;

--Comparing Dates
-- Here we are comparing two timestamps. This works, but it is not easy to read and difficult to use in calculations.
SELECT avg(orderdate - deliverydate)
FROM date_tester
GROUP BY id_field;

-- This makes it easier to use in calculations (note that epoch returns seconds, so the comparison is in seconds, the first /60 converts it to minutes, the second converts it to hours)
SELECT EXTRACT(EPOCH FROM avg(orderdate - deliverydate))/60/60
FROM date_tester
GROUP BY id_field;

-- I can, however, not round this.
SELECT round(EXTRACT(EPOCH FROM avg(orderdate - deliverydate))/60/60,2)
FROM date_tester
GROUP BY id_field;

-- So need to cast to numeric, which can be rounded.
SELECT round(EXTRACT(EPOCH FROM avg(orderdate - deliverydate))::numeric/60/60,2)
FROM date_tester
GROUP BY id_field;

-- Here we are comparing two dates, which makes it easier to work with in this situation.
SELECT round(avg(orderdate - deliverydate)*24,2)
FROM date_tester_dates
GROUP BY id_field;

--Pivoting Data using CASE WHEN
 
SELECT EXTRACT(YEAR FROM A.orderdate), SUM(B.quantity*B.unitprice*(1+B.taxrate/100)) AS LineItemAmount
  FROM salesorderheader AS A JOIN salesorderline AS B ON A.orderid = B.orderid
  GROUP BY EXTRACT(YEAR FROM A.orderdate);

SELECT 
  'AnnualSales' AS Year,
  SUM(CASE WHEN EXTRACT(YEAR FROM A.orderdate) = 2013 THEN B.quantity*B.unitprice*(1+B.taxrate/100) END) AS Sales2013,
  SUM(CASE WHEN EXTRACT(YEAR FROM A.orderdate) = 2014 THEN B.quantity*B.unitprice*(1+B.taxrate/100) END) AS Sales2014,
  SUM(CASE WHEN EXTRACT(YEAR FROM A.orderdate) = 2015 THEN B.quantity*B.unitprice*(1+B.taxrate/100) END) AS Sales2015,
  SUM(CASE WHEN EXTRACT(YEAR FROM A.orderdate) = 2016 THEN B.quantity*B.unitprice*(1+B.taxrate/100) END) AS Sales2016
    FROM salesorderheader AS A JOIN salesorderline AS B ON A.orderid = B.orderid;


CREATE EXTENSION tablefunc;

/*The crosstab function takes an SQL SELECT statement as a parameter, which must follow the restrictions:
- The SELECT must return 3 columns.
- The first column in the SELECT will be the identifier of every row in the pivot table or final result. In our 
  example from 11, this was year.
- The second column in the SELECT represents the categories in the pivot table. In our example, these categories 
  are the months. Note that the values in this column will expand into many columns in the pivot table. If the 
  second column returns 12 different values (1, 2, 3, etc.) then the pivot table will have 12 columns. 
- The third column in the SELECT represents the value to be assigned to each cell of the pivot table. These are the 
  monthly sales in our example.
- The output has to be ordered by column 1 and then by column 2.
*/

  SELECT * 
  FROM crosstab(
    'SELECT STATEMENT WITH THREE COLUMNS',
    '(SELECT STATEMENT WITH LIST OF DISTINCT VALUES THAT ARE USED TO GROUP ROWS INTO THE DIFFERENT COLUMNS'
    ) 
  AS (
    col_1_name data_type, --Careful with the first column, this is the row identifier, not the first data column
    col_2_name data_type,
    col_3_name data_type,
    .
    .
    .
    col_N_name data_type,
  );

SELECT 
    'AnnualSales', EXTRACT(YEAR FROM A.orderdate), SUM(B.quantity*B.unitprice*(1+B.taxrate/100))
    FROM salesorderheader AS A JOIN salesorderline AS B ON A.orderid = B.orderid 
    GROUP BY EXTRACT(YEAR FROM A.orderdate)
    ORDER BY 1, 2;

SELECT DISTINCT EXTRACT(YEAR FROM A.orderdate)
    FROM salesorderheader AS A JOIN salesorderline AS B ON A.orderid = B.orderid
    ORDER BY 1;

SELECT * 
  FROM crosstab(
    'SELECT 
    ''Annual Sales'', EXTRACT(YEAR FROM A.orderdate), SUM(B.quantity*B.unitprice*(1+B.taxrate/100))
    FROM salesorderheader AS A JOIN salesorderline AS B ON A.orderid = B.orderid 
    GROUP BY EXTRACT(YEAR FROM A.orderdate)
    ORDER BY 1, 2',
    'SELECT DISTINCT EXTRACT(YEAR FROM A.orderdate)
    FROM salesorderheader AS A JOIN salesorderline AS B ON A.orderid = B.orderid
    ORDER BY 1'
    ) 
  AS (
    "Year" Text,
    Sales_2013 NUMERIC,
    Sales_2014 NUMERIC,
    Sales_2015 NUMERIC,
    Sales_2016 NUMERIC
  );

--Common Table Expressions
WITH temp_view_1_name AS (
  SELECT ...
  ),
  temp_view_1_name AS (
    SELECT ...
      FROM query_name1 ...
  ),
  SELECT ...

WITH 
  InvoiceSums AS (
  SELECT EXTRACT(YEAR FROM A.InvoiceDate) AS Year, SUM(B.quantity*B.unitprice*(1+B.taxrate/100)) AS InvoiceTotal
    FROM InvoiceHeader A
    JOIN InvoiceLine B USING (InvoiceID)
    GROUP BY EXTRACT(YEAR FROM A.InvoiceDate)
  ), 
  SalesOrderSums AS (
  SELECT EXTRACT(YEAR FROM A.OrderDate) AS Year, SUM(B.quantity*B.unitprice*(1+B.taxrate/100)) AS OrderTotal
    FROM SalesOrderHeader A
    JOIN SalesOrderLine B USING (OrderID)
    GROUP BY EXTRACT(YEAR FROM A.OrderDate)
  )
  SELECT Year, InvoiceTotal, OrderTotal
    FROM InvoiceSums JOIN SalesOrderSums USING (Year);
  
SELECT ....
  UNION ALL -- UNION ALL allows duplicate rows, UNION only selects distinct rows, the # of columns in the two select statements must match.
SELECT .....;

/*DISTINCT
1) Use the salesorderheader table and the DISTINCT keyword to find out how many customers have placed orders. 
In your output show the count and name this field "Number of Customers With  Orders". Your output should 
return 1 row and the value should 663.*/

SELECT count(DISTINCT customerid) AS "Number of Customers With 
Orders"
 FROM salesorderheader;

/*2) Modify query 1 to show how many customers each salesperson services. Include salespersonpersonid and the 
count in your output. Your output should return 10 rows.*/


SELECT salespersonpersonid, count(DISTINCT customerid) AS "Number of Customers With 
Orders"
 FROM salesorderheader
 GROUP BY salespersonpersonid;

/*3a)	Use the salesorderheader table and DISTINCT to only show unique customerid and shippinglocationid 
 combinations. In your output show customerid and shippinglocationid. Your output should return 663 rows.*/

SELECT DISTINCT customerid, shippinglocationid
  FROM salesorderheader;

/*3b) Create the same result using GROUPBY instead of DISTINCT.*/
SELECT customerid, shippinglocationid
  FROM salesorderheader
  GROUP BY customerid, shippinglocationid;

/*4 Use the customer, location, and salesorderheader to show all customers shipping addresses. Note that the 
location table contains both shipping and billing addresses. The salesorderheader table is needed to 
determine if an address is a shipping address. In your output include customerid from the customer table, 
customername, streetaddressline1, streetaddressline2, city, state, and zip. Your results should return 663 rows
*/

SELECT A.customername, B.streetaddressline1, B.streetaddressline2, B.city, B.state, B.zip
  FROM customer AS A
  INNER JOIN location AS B 
    ON A.customerid = B.customerid
  INNER JOIN (
    SELECT DISTINCT sA.customerid, sA.shippinglocationid
      FROM salesorderheader sA
    ) AS C
    ON A.customerid = C.customerid AND B.locationid = C.shippinglocationid
  ORDER BY A.customerid;

/*5. How many customers are there in each customer category? 
In your results show CustomerCategoryID, CustomerCategoryName, and a new field named NumberOfCustomers.
Create two separate solutions, one that only counts distinct customerIDs and one that counts all rows in each group. Compare the results and look at the ERD diagram - are the results the same? Based on the ERD diagram, are they guaranteed to be the same - why or why not? Why are they the same?*/

SELECT B.CustomerCategoryID, B.CustomerCategoryName, count(A.customerid) AS NumberOfCustomers
  FROM customercategorymembership AS A
    INNER JOIN customercategory AS B ON A.customercategoryid = B.customercategoryid
    GROUP BY B.customercategoryid
    ORDER BY B.customercategoryid;

SELECT B.CustomerCategoryID, B.CustomerCategoryName, count(DISTINCT A.customerid) AS NumberOfCustomers
  FROM customercategorymembership AS A
    INNER JOIN customercategory AS B ON A.customercategoryid = B.customercategoryid
    GROUP BY B.customercategoryid
    ORDER BY B.customercategoryid;

-- The results are the same and the ERD diagram indicates that they should be the same. Notice that while a single customer can be associated with multiple rows in the CustomerCategoryMemebership table, a single customer can only belong to multiple different customer categories and cannot belong to the same customer category multiple times (because of the compositive primary key constraint).

-- IN
SELECT city, state
  FROM location_subset
  WHERE state IN('California', 'Arizona', 'Washington')

DROP TABLE location_subset;

--6) Modify query 4 to only show customers in Kansas, Colorado, and Utah.  Use the IN operator in your WHERE statement.
SELECT A.customername, B.streetaddressline1, B.streetaddressline2, B.city, B.state, B.zip
  FROM customer AS A
  INNER JOIN location AS B 
    ON A.customerid = B.customerid
  INNER JOIN (
    SELECT DISTINCT sA.customerid, sA.shippinglocationid
      FROM salesorderheader sA
    ) AS C
    ON A.customerid = C.customerid AND B.locationid = C.shippinglocationid
  WHERE B.state IN('Kansas', 'Colorado', 'Utah')
  ORDER BY A.customerid;

/* 7.0) EXTRACT and DATE_TRUNC
EXTRACT is used to get a component (or part) of a date/time value (almost like using a 
middle or substr function on a string). DATE_TRUNC truncates (cuts off) a date to a specified date/time 
level (almost like using a LEFT function on a string). For example, assume we have the following value
2021-01-08 11:08:45, then EXTRACT could for example be used to obtain just the minutes, i.e., 8, or 
just the day, i.e., 01, component. DATE_TRUNC could be used to get, for example, the year and the month, i.e., 2021-01
(it would return 2021-01-01 00:00:00), or the year, month, day, and hour, i.e., 2021-01-08 11:00:00. 

In postgres, EXTRACT is the same as DATE_PART (they end up executing the same function). While I like the
name DATE_PART better, because EXTRACT is ANSII we will only use EXTRACT. 

EXTRACT general syntax:
EXTRACT(part-of-date FROM field)
* SQL EXTRACT uses the keyword FROM to separate the field name from the part-of-date values. The field names are considered 
SQL keywords  (you do not need to put them in quotes). The options for part-of-date includes:

Example:
EXTRACT(MONTH FROM orderdate)


SELECT EXTRACT(YEAR FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(QUARTER FROM TIMESTAMP '2017-05-17 02:09:30');
SELECT EXTRACT(MONTH FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(WEEK FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(DAY FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(DOY FROM TIMESTAMP '2017-01-01 02:09:30'); -- day of year
SELECT EXTRACT(DOW FROM TIMESTAMP '2017-03-17 02:09:30'); -- day of week - the day of the week (0 - 6; Sunday is 0) 
SELECT EXTRACT(HOUR FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(MINUTE FROM TIMESTAMP '2017-03-17 02:09:30');
SELECT EXTRACT(SECOND FROM TIMESTAMP '2017-03-17 02:09:30.052'); --includes fractions
SELECT EXTRACT(epoch FROM TIMESTAMP '2017-03-17 02:09:30'); -- (number of seconds since since 1970-01-01 00:00:00 UTC)

DATE_TRUNC general syntax:
date_trunc('datepart', field)

Example:
date_trunc('month', orderdate)

Some of the options for datepart:
SELECT DATE_TRUNC('second', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('minute', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('hour', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('day', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('week', TIMESTAMP '2017-03-21 02:09:30');
SELECT DATE_TRUNC('month', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('quarter', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('year', TIMESTAMP '2017-03-17 02:09:30');
SELECT DATE_TRUNC('decade', TIMESTAMP '2017-03-17 02:09:30');

/*7) Using the purchaseorderheader table, show purchaseorderid and three columns showing dates. Two columns using
EXTRACT to indicate the orderdate year, name this field "Year", and the orderdate month, name this field "Month". 
One column using DATE_TRUNC to show both the Year and the Month, name field "Year and Month". Only include
purchases from 2013 and 2014*/

SELECT  purchaseorderid, 
        orderdate,
        EXTRACT(year FROM orderdate) AS "Year", 
        EXTRACT(month FROM orderdate) AS "Month", 
        DATE_TRUNC('month', orderdate) AS "Year and Month"
FROM purchaseorderheader
WHERE EXTRACT(year FROM orderdate) IN (2013, 2014) 

/* 8) Create a count of purchase orders (name this field NumberOfOrders) for each month in 2013 and 2014 
(based on orderdate). Use the purchaseorderheader table. In addition to NumberOfOrders, include column(s) 
to show the year and month.  Create two solutions, one that uses EXTRACT (show a total of three columns 
in this solution) and one that uses DATA_TRUNC (show a total of two columns in this solution)*/

SELECT EXTRACT(year FROM orderdate) AS OrderYear, EXTRACT(month FROM orderdate) AS OrderMonth, count(1) AS NumberOfOrders
  FROM PurchaseOrderHeader
  WHERE EXTRACT(year FROM orderdate) IN (2013, 2014) 
  GROUP BY OrderYear, OrderMonth
  ORDER BY OrderYear, OrderMonth;

SELECT DATE_TRUNC('month', orderdate) AS OrderYearAndMonth, count(1) AS NumberOfOrders
  FROM PurchaseOrderHeader
  WHERE orderdate BETWEEN '2013-01-01' AND '2015-01-01' 
  GROUP BY OrderYearAndMonth
  ORDER BY OrderYearAndMonth;

/* 9) Calculate for each supplier how long it takes on average to receive ordered items (only including 
orders that have actually been received). Name this field "Average Fulfillment Time (hours)". Also determine
how many orders have been placed with each supplier and how many unique items we order from each supplier. 
Name these two fields "Number of Orders" and "Number of Unique Items". 

Review the ERD diagram and notice that orders and receiving reports are related at the line item level. 
You do, however, also need the header information because you need the dates.  In this exercise, calculate 
the average time to receive each line item.  You do not need to verify that the entire quantity was received 
(you can assume that a receiving report line item was only created if the entire amount was received; a 
backorder was otherwise created and the amount not received was transfered from the old order to the backorder).*/
SELECT  A.supplierid,
        round((AVG(ReceivingDateSeconds-OrderDateSeconds)/60/60)::numeric,2) AS "Average Fulfillment Time (hours)",
        COUNT(DISTINCT A.purchaseorderid) AS "Number of Orders",
        COUNT(DISTINCT A.stockitemid) AS "Number of Unique Items"
  FROM
    (SELECT sA.purchaseorderid, sB.stockitemid, EXTRACT(epoch FROM sA.OrderDate) AS OrderDateSeconds, sA.supplierid
    FROM purchaseorderheader AS sA
    JOIN purchaseorderline AS sB ON sA.purchaseorderid = sB.purchaseorderid) AS A  
  INNER JOIN
    (SELECT sD.purchaseorderid, sD.stockitemid, avg(EXTRACT(epoch FROM sC.receivingdate)) AS ReceivingDateSeconds
    FROM receivingreportheader AS sC
    JOIN receivingreportline AS sD ON sC.receivingreportid = sD.receivingreportid
    GROUP BY sD.purchaseorderid, sD.stockitemid) AS B
  ON A.purchaseorderid = B.purchaseorderid AND A.stockitemid = B.stockitemid
  GROUP BY A.supplierid;


Caution when working with dates:
EPOCH, the number of seconds since 1970-01-01 00:00:00 UTC, cannot round double precision with a specified 
number of decimals, so much cast to numeric first*/.

The below works because all dates are stored as dates rather than times (with includes both dates and times).

CREATE TABLE date_tester (
    id_field integer,
    orderdate timestamp, 
    deliverydate timestamp);

CREATE TABLE date_tester_dates (
    id_field integer,
    orderdate DATE, 
    deliverydate date);
    
INSERT INTO date_tester (id_field, orderdate, deliverydate)
VALUES
  (1, '2016-06-23 19:10:25', '2016-06-23 19:10:25'),
  (1, '2016-06-23 19:10:25', '2016-06-22 19:10:25'),
  (1, '2016-06-23 19:10:25', '2016-06-20 19:10:25'),
  (2, '2016-06-23 19:10:25', '2016-06-23 00:00:00'),
  (2, '2016-06-23 19:10:25', '2016-06-22 00:00:00'),
  (2, '2016-06-23 19:10:25', '2016-06-21 00:00:00'),
  (3, '2016-06-23 19:10:25', '2016-06-22 19:10:25'),
  (3, '2016-06-23 19:10:25', '2016-06-22 19:10:15'),
  (3, '2016-06-23 19:10:25', '2016-06-22 19:10:00');

INSERT INTO date_tester_dates (id_field, orderdate, deliverydate)
VALUES
  (1, '2016-06-23', '2016-06-22'),
  (1, '2016-06-23', '2016-06-22'),
  (1, '2016-06-23', '2016-06-20'),
  (2, '2016-06-23', '2016-06-21'),
  (2, '2016-06-23', '2016-06-22'),
  (2, '2016-06-25', '2016-06-20'),
  (3, '2016-06-23', '2016-06-21'),
  (3, '2016-06-25', '2016-06-22'),
  (3, '2016-06-27', '2016-06-20'),
  (4, '2016-06-23', '2016-06-21'),
  (4, '2016-06-23', '2016-06-22'),
  (4, '2016-06-23', '2016-06-20');


-- Here we are comparing two timestamps. This works, but it is not easy to read and difficult to use in calculations.
SELECT avg(orderdate - deliverydate)
FROM date_tester
GROUP BY id_field;

-- This makes it easier to use in calculations (note that epoch returns seconds, so the comparison is in seconds, the first /60 converts it to minutes, the second converts it to hours)
SELECT EXTRACT(EPOCH FROM avg(orderdate - deliverydate))/60/60
FROM date_tester
GROUP BY id_field;

-- I can, however, not round this.
SELECT round(EXTRACT(EPOCH FROM avg(orderdate - deliverydate))/60/60,2)
FROM date_tester
GROUP BY id_field;

-- So need to cast to numeric, which can be rounded.
SELECT round(EXTRACT(EPOCH FROM avg(orderdate - deliverydate))::numeric/60/60,2)
FROM date_tester
GROUP BY id_field;

-- Here we are comparing two dates, which makes it easier to work with in this situation.
SELECT round(avg(orderdate - deliverydate)*24,2)
FROM date_tester_dates
GROUP BY id_field;


/*FILTER
The filter clause extends aggregate functions (sum, avg, count, …) by allowing a where clause 
for each aggregate function. The result of the aggregate is built from only the rows that satisfy 
the additional where clause too. 
SUM(quantity) FILTER(WHERE <condition>)

However, FILTER is not supported by many DBs (postgresql is one of few that does).
In RDBMSs that do not have FILTER, CASE WHEN can be used instead of FILTER. Because most databases understand
CASE WHEN, it is more important to know how to use CASE WHEN (but FILTER might also be handy).
SUM(CASE WHEN <condition> THEN quantity END)

/* 10a) Before we use filter, create a query that show, for each year, the "Number of Open Orders" and 
"Number of open order lines in period", as two new fields. Also include a field that indicates the year 
(name this field "Year"). An open order is an order that has not yet been delivered. You can assume that 
if the order does not have an invoice (there is no invoice id in the order header), then it has not yet 
been delivered*/

SELECT EXTRACT(YEAR FROM A.orderdate) AS Year, count(DISTINCT A.orderid) AS "Number of Open Orders", count(1) AS "Number of open order lines in period"
  FROM salesorderheader AS A
  JOIN salesorderline AS B
  ON A.orderid = B.orderid
  WHERE A.invoiceid IS NULL
  GROUP BY Year;

/*10b) Modify query 10.a to find only the number of orders rather than order lines. Also pivot the results to 
instead report the results in one row with four columns: 
    “Number of open orders from 2013”, 
    “Number of open orders from 2014”, 
    “Number of open orders from 2015”, and 
    “Number of open orders from 2016”.
  Create two solutions, one that uses FILTER and one that uses CASE WHEN.*/

-- Filter Solution:
SELECT 
    count(A.orderid) FILTER (WHERE EXTRACT(YEAR FROM A.orderdate) = 2013) AS "Number of open orders from 2013",
    count(A.orderid) FILTER (WHERE EXTRACT(YEAR FROM A.orderdate) = 2014) AS "Number of open orders from 2014",
    count(A.orderid) FILTER (WHERE EXTRACT(YEAR FROM A.orderdate) = 2015) AS "Number of open orders from 2015",
    count(A.orderid) FILTER (WHERE EXTRACT(YEAR FROM A.orderdate) = 2016) AS "Number of open orders from 2016"
  FROM salesorderheader AS A
  WHERE A.invoiceid IS NULL;

-- Here is a slightly clearner looking (or perhaps not) version:
SELECT 
    count(A.orderid) FILTER (WHERE Year = 2013) AS "Number of open orders from 2013",
    count(A.orderid) FILTER (WHERE Year = 2014) AS "Number of open orders from 2014",
    count(A.orderid) FILTER (WHERE Year = 2015) AS "Number of open orders from 2015",
    count(A.orderid) FILTER (WHERE Year = 2016) AS "Number of open orders from 2016"
  FROM (SELECT OrderID, InvoiceID, EXTRACT(YEAR FROM orderdate) AS Year FROM salesorderheader) AS A
  WHERE A.invoiceid IS NULL;

-- CASE WHEN Solution:
SELECT 
    count(CASE WHEN EXTRACT(YEAR FROM A.orderdate) = 2013 THEN A.orderid END) AS "Number of open orders from 2013",
    count(CASE WHEN EXTRACT(YEAR FROM A.orderdate) = 2014 THEN A.orderid END) AS "Number of open orders from 2014",
    count(CASE WHEN EXTRACT(YEAR FROM A.orderdate) = 2015 THEN A.orderid END) AS "Number of open orders from 2015",
    count(CASE WHEN EXTRACT(YEAR FROM A.orderdate) = 2016 THEN A.orderid END) AS "Number of open orders from 2016"
  FROM salesorderheader AS A
  WHERE A.invoiceid IS NULL

/*11 Now let's create a table with monthly sales where we each row is for a different year (and one column indicate which sum
year it is) and the columns indicating months. Name the month columns "Jan Sales (in millions)", "Feb Sales (in millions)", etc. 
Show sales in millions (divide the sales total by 1M and round to two decimals (note that rounding to specific decimals only 
works for data type numeric - so you need to cast to numeric). Line item totals (sales) is calculated as quantity*unitprice*(1+taxrate/100)*/

SELECT 
  A.SalesYear AS Year, 
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=1)::numeric,2) as "Jan Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=2)::numeric,2) as "Feb Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=3)::numeric,2) as "Mar Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=4)::numeric,2) as "April Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=5)::numeric,2) as "May Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=6)::numeric,2) as "June Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=7)::numeric,2) as "July Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=8)::numeric,2) as "Aug Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=9)::numeric,2) as "Sep Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=10)::numeric,2) as "Oct Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=11)::numeric,2) as "Nov Sales (in millions)",
  round(SUM(A.Sales) FILTER(WHERE A.SalesMonth=12)::numeric,2) as "Dec Sales (in millions)"
  FROM 
    (SELECT 
      EXTRACT(YEAR FROM sA.orderdate) AS SalesYear,
      EXTRACT(Month FROM sA.orderdate) AS SalesMonth,
      sB.quantity*sB.unitprice*(1+sB.taxrate/100)/1000000 AS Sales
    FROM salesorderheader AS sA
    INNER JOIN salesorderline AS sB
    ON sA.orderid = sB.orderid) A
  GROUP BY SalesYear

/*12) Postgres crosstab function
Postgres has a function called crosstab that simplifies the creation of crosstab reports like we did in 11. 
To use the this function you first need to run this statement:
CREATE EXTENSION tablefunc;

The crosstab function takes an SQL SELECT statement as a parameter, which must follow the restrictions:
- The SELECT must return 3 columns.
- The first column in the SELECT will be the identifier of every row in the pivot table or final result. In our 
  example from 11, this was year.
- The second column in the SELECT represents the categories in the pivot table. In our example, these categories 
  are the months. Note that the values in this column will expand into many columns in the pivot table. If the 
  second column returns 12 different values (1, 2, 3, etc.) then the pivot table will have 12 columns. 
- The third column in the SELECT represents the value to be assigned to each cell of the pivot table. These are the 
  monthly sales in our example.
- The output has to be ordered by column 1 and then by column 2.

The crosstab function is invoked in a SELECT statement's FROM clause. In addition to the SELECT statement that 
conforms to the requirements above, we must also define the categories, names, and data types of the columns that 
will go into the final result. This can be done a few ways, but here is one approach when the Field Names are not
the same as the categories used to define which column a value belongs to (in our example, the categories are 
the months 1, 2, 3, etc., but the Field Names are Jan, Feb, etc). In the field name list the column that defines 
the row categories also needs to be included (in our example this is year).

SELECT * 
  FROM crosstab(
    'SELECT STATEMENT WITH THREE COLUMNS',
    '(SELECT STATEMENT WITH LIST OF DISTINCT VALUES THAT ARE USED TO GROUP ROWS INTO THE DIFFERENT COLUMNS'
    ) 
  AS (
    col_1_name data_type,
    col_2_name data_type,
    col_3_name data_type,
    .
    .
    .
    col_N_name data_type,
  );
  
As a first step, rewrite the select statement in 11 to create these three columns:
*/

SELECT 
  A.SalesYear AS Year, 
  A.SalesMonth AS Month, 
  round(SUM(A.Sales)::numeric,2) as Sales
  FROM 
    (SELECT 
      EXTRACT(YEAR FROM sA.orderdate) AS SalesYear,
      EXTRACT(Month FROM sA.orderdate) AS SalesMonth,
      sB.quantity*sB.unitprice*(1+sB.taxrate/100)/1000000 AS Sales
    FROM salesorderheader AS sA
    INNER JOIN salesorderline AS sB
    ON sA.orderid = sB.orderid) A
  GROUP BY SalesYear, SalesMonth
  ORDER BY 1, 2;

/*Next write a query that returns UNIQUE months from the OrderHeader table, i.e., the query should 
return a signle column with the values 1, 2, 3,... 12.*/
SELECT DISTINCT EXTRACT(MONTH FROM orderdate) 
      FROM salesorderheader 
      ORDER BY 1

/*Finally, use these two queries and the crosstab template above to create a crosstab report.  For the field
names, simple use Jan, Feb, Mar, etc. and make the datatype numeric.*/
SELECT * 
  FROM crosstab(
    'SELECT 
      A.SalesYear AS Year, 
      A.SalesMonth AS Month, 
      round(SUM(A.Sales)::numeric,2) as Sales
      FROM 
        (SELECT 
          EXTRACT(YEAR FROM sA.orderdate) AS SalesYear,
          EXTRACT(Month FROM sA.orderdate) AS SalesMonth,
          sB.quantity*sB.unitprice*(1+sB.taxrate/100)/1000000 AS Sales
        FROM salesorderheader AS sA
        INNER JOIN salesorderline AS sB
        ON sA.orderid = sB.orderid) A
      GROUP BY SalesYear, SalesMonth
      ORDER BY 1, 2',
    'SELECT DISTINCT EXTRACT(MONTH FROM orderdate) 
      FROM salesorderheader 
      ORDER BY 1'
    ) 
  AS (
    "Year" int,
    "Jan" numeric,
    "Feb" numeric,
    "Mar" numeric,
    "April" numeric,
    "May" numeric,
    "June" numeric,
    "July" numeric,
    "Aug" numeric,
    "Sep" numeric,
    "Oct" numeric,
    "Nov" numeric,
    "Dec" numeric
  );

/* 13) OFFSET and LIMIT
We have already been introduced to LIMIT, which can be used to define how many rows to return.
Limit is often used when working with large dataset and the query is being build (to reduce 
execution times), when only a sample of the output needs to be examined, or when we are only
interested in seing the top or bottom of the results (also requires ORDER BY).

OFFSET is used in the same part of the SELECT statement as LIMIT and is used to specify a 
a certain number of rows to skip before returning the result set, e.g.,
ORDER BY sales_total DESC OFFSET 20 LIMIT 10 can be used to return the 21st through 30th
rows with the largest sales_total. 

Exercise: use the payment table and show the 6th through the 15th largest customer payments.
Note that customer payments are listed as negative numbers (in your results show them as positive
numbers). In your output include customerid and paymentamount. Your output should contain 10 rows.*/

SELECT customerid, -paymentamount AS "Payment Amount"
  FROM payment
  ORDER BY -paymentamount Desc
  LIMIT 10 OFFSET 5;


/*14) Use the payment table and show the customers with the 6th through the 15th smallest total payments.
-- In your output include customerid and name the field containg the total of each customers payments 
"total_customer_payment".  Your output should contain 10 rows.*/

SELECT customerid, SUM(-paymentamount) AS total_customer_payment
  FROM payment
  GROUP BY customerid
  ORDER BY total_customer_payment Asc OFFSET 5 LIMIT 10 ;

/*15) Create a query that shows that difference between each customers total orders and total payments. Only 
show customers in 'Kansas', 'Colorado' and 'Utah' and only show the customers with the 6th through the 15th 
largest differences. Note that some customers have the parent organization pay for their orders (the customerid of
the organization paying for the order is given in the default-bill-to-customerid of the salesorderheader table). 
To accurately compare orders to payments, therefore add these organizations' orders to their parent organization 
(and only include organizations in your analysis that have both payments and orders). Also, if a bill-to-customer 
has made at least one more order but has not made any payments (there are no such customers in the database, but
if there were, your code should still work), then consider payment amount to be 0 for this customer.

Consider building the query in the following steps.

-- CREATE A QUERY THAT FIRST JOINS AND GROUPS AND SHOW WHAT THE PROBLEM WITH THIS IS!

-- Step 1
-- Calculate sum of all orders for each customer that is later billed for the order (i.e., the default-bill-to-customerid 
as indicated in the customer table).*/

SELECT defaultbilltocustomerid, SUM(quantity*unitprice*(1+taxrate/100)) AS TotalOrders
  FROM salesorderheader A 
  JOIN salesorderline B ON A.orderid = B.orderid
  JOIN customer C ON A.customerid = C.customerid
  GROUP BY defaultbilltocustomerid;

-- Step 2
-- Using the code from step 1 and the code from the previous query that calculated total payments for each customer, calculate the
-- difference between total orders and total payments for each bill-to-customer.
SELECT B.customerid, A.TotalOrders - B.total_customer_payment AS Net, A.TotalOrders, B.total_customer_payment
  FROM (
    SELECT defaultbilltocustomerid, SUM(quantity*unitprice*(1+taxrate/100)) AS TotalOrders
      FROM salesorderheader A 
      JOIN salesorderline B ON A.orderid = B.orderid
      JOIN customer C ON A.customerid = C.customerid
      GROUP BY defaultbilltocustomerid) AS A
  JOIN (
    SELECT customerid, SUM(-paymentamount) AS total_customer_payment
      FROM payment
      GROUP BY customerid) AS B
  ON A.defaultbilltocustomerid = B.customerid

/*Step 3
If a bill-to-customer has made at least one more order but has not made any payments (there are no such customers in the database, 
but if there were, your code should still work), then consider payment amount to be 0 for this customer*/

SELECT B.customerid, A.TotalOrders - COALESCE(B.total_customer_payment, 0) AS Net, A.TotalOrders, COALESCE(B.total_customer_payment, 0)
  FROM (
    SELECT defaultbilltocustomerid, SUM(quantity*unitprice*(1+taxrate/100)) AS TotalOrders
      FROM salesorderheader A 
      JOIN salesorderline B ON A.orderid = B.orderid
      JOIN customer C ON A.customerid = C.customerid
      GROUP BY defaultbilltocustomerid) AS A
  LEFT JOIN (
    SELECT customerid, SUM(-paymentamount) AS total_customer_payment
      FROM payment
      GROUP BY customerid) AS B
  ON A.defaultbilltocustomerid = B.customerid


/* Step 4 Now, state (consider if it is better to place this inside the subquery or at the end of the outer query) and top.*/
SELECT B.customerid, A.state, A.TotalOrders - COALESCE(B.total_customer_payment, 0) AS Net, A.TotalOrders, COALESCE(B.total_customer_payment, 0)
  FROM (
    SELECT sC.defaultbilltocustomerid, sD.state, SUM(sB.quantity*sB.unitprice*(1+sB.taxrate/100)) AS TotalOrders
      FROM salesorderheader sA 
      JOIN salesorderline sB ON sA.orderid = sB.orderid
      JOIN customer sC ON sA.customerid = sC.customerid
      JOIN location sD ON sC.defaultbilltocustomerid = sD.customerid
      WHERE sD.state IN ('Kansas','Colorado','Utah')
      GROUP BY sC.defaultbilltocustomerid, sD.state) AS A
  LEFT JOIN (
    SELECT customerid, SUM(-paymentamount) AS total_customer_payment
      FROM payment
      GROUP BY customerid) AS B
  ON A.defaultbilltocustomerid = B.customerid
  ORDER BY Net Desc OFFSET 5 LIMIT 10;

/* 16) Common Table Expressions
When using multiple sub-queries, I tend to find it difficult to understand the code. I generally think it is 
easier to read the code if I replace the sub-queries with views.  However, when I have views it is more difficult
to see the code that generated the view and also to change this code. Another alternative to views and subqueries,
that provides a mix of the two is common-table-expressions (CTE). CTE is something in between views and subqueries,
where the views are created within the same expression as the primary select statement. As with views, the select 
statements are named and can be reused (but only within the CTE), but they are not stored in the schema as views are.  
It is helpful to think of these select statements as temporary views that are created inside the same common-table-exression. 

The general structure of CTE is:
WITH temp_view_1_name AS (
  SELECT ...
  ),
  temp_view_1_name AS (
    SELECT ...
      FROM query_name1 ...
  ),
  SELECT ...

So this start by naming a temporary view and then defining this view as a select statement. This can be followed
by more temprorary views that can reference the previous expressions. The last part of the CTE is a SELECT query 
that use the previous expressions.

As an exercise, rewrite the following SQL code (from question 6):
SELECT A.customername, B.streetaddressline1, B.streetaddressline2, B.city, B.state, B.zip
  FROM customer AS A
  INNER JOIN location AS B 
    ON A.customerid = B.customerid
  INNER JOIN (
    SELECT DISTINCT sA.customerid, sA.shippinglocationid
      FROM salesorderheader sA
    ) AS C
    ON A.customerid = C.customerid AND B.locationid = C.shippinglocationid
  WHERE B.state IN('Kansas', 'Colorado', 'Utah')
  ORDER BY A.customerid;*/
   

WITH customers_with_orders AS (
  SELECT DISTINCT sA.customerid, sA.shippinglocationid
      FROM salesorderheader sA
  )
  SELECT A.customername, B.streetaddressline1, B.streetaddressline2, B.city, B.state, B.zip
  FROM customer AS A
  INNER JOIN location AS B 
    ON A.customerid = B.customerid
  INNER JOIN customers_with_orders AS C
    ON A.customerid = C.customerid AND B.locationid = C.shippinglocationid
  WHERE B.state IN('Kansas', 'Colorado', 'Utah')
  ORDER BY A.customerid;


/*17) Now let's move onto something a little more complex. Let's rewrite query 15.
SELECT B.customerid, A.state, A.TotalOrders - COALESCE(B.total_customer_payment, 0) AS Net, A.TotalOrders, COALESCE(B.total_customer_payment, 0)
  FROM (
    SELECT sC.defaultbilltocustomerid, sD.state, SUM(sB.quantity*sB.unitprice*(1+sB.taxrate/100)) AS TotalOrders
      FROM salesorderheader sA 
      JOIN salesorderline sB ON sA.orderid = sB.orderid
      JOIN customer sC ON sA.customerid = sC.customerid
      JOIN location sD ON sC.defaultbilltocustomerid = sD.customerid
      WHERE sD.state IN ('Kansas','Colorado','Utah')
      GROUP BY sC.defaultbilltocustomerid, sD.state) AS A
  LEFT JOIN (
    SELECT customerid, SUM(-paymentamount) AS total_customer_payment
      FROM payment
      GROUP BY customerid) AS B
  ON A.defaultbilltocustomerid = B.customerid
  ORDER BY Net Desc OFFSET 5 LIMIT 10;*/


WITH 
  Customer_Order_Sums AS (
  SELECT sC.defaultbilltocustomerid, sD.state, SUM(sB.quantity*sB.unitprice*(1+sB.taxrate/100)) AS TotalOrders
      FROM salesorderheader sA 
      JOIN salesorderline sB ON sA.orderid = sB.orderid
      JOIN customer sC ON sA.customerid = sC.customerid
      JOIN location sD ON sC.defaultbilltocustomerid = sD.customerid
      WHERE sD.state IN ('Kansas','Colorado','Utah')
      GROUP BY sC.defaultbilltocustomerid, sD.state),
  Customer_Payment_Sums AS (
    SELECT customerid, SUM(-paymentamount) AS total_customer_payment
      FROM payment
      GROUP BY customerid)
  SELECT B.customerid, A.state, A.TotalOrders - COALESCE(B.total_customer_payment, 0) AS Net, A.TotalOrders, COALESCE(B.total_customer_payment, 0)
    FROM Customer_Order_Sums AS A
    LEFT JOIN Customer_Payment_Sums AS B
    ON A.defaultbilltocustomerid = B.customerid
    ORDER BY Net Desc OFFSET 5 LIMIT 10;


/*18) We can also rewrite this so that one of the commone table expression reference the other common table expressions. 
In this exercise, change the code below (the CTE from 17) to join the results from the first two expressions in a third temporary view.
Have the final select statement only order, limit, and offset the data.

WITH 
  Customer_Order_Sums AS (
  SELECT sC.defaultbilltocustomerid, sD.state, SUM(sB.quantity*sB.unitprice*(1+sB.taxrate/100)) AS TotalOrders
      FROM salesorderheader sA 
      JOIN salesorderline sB ON sA.orderid = sB.orderid
      JOIN customer sC ON sA.customerid = sC.customerid
      JOIN location sD ON sC.defaultbilltocustomerid = sD.customerid
      WHERE sD.state IN ('Kansas','Colorado','Utah')
      GROUP BY sC.defaultbilltocustomerid, sD.state),
  Customer_Payment_Sums AS (
    SELECT customerid, SUM(-paymentamount) AS total_customer_payment
      FROM payment
      GROUP BY customerid)
  SELECT B.customerid, A.state, A.TotalOrders - COALESCE(B.total_customer_payment, 0) AS Net, A.TotalOrders, COALESCE(B.total_customer_payment, 0)
    FROM Customer_Order_Sums AS A
    LEFT JOIN Customer_Payment_Sums AS B
    ON A.defaultbilltocustomerid = B.customerid
    ORDER BY Net Desc OFFSET 5 LIMIT 10;*/

WITH 
  Customer_Order_Sums AS (
  SELECT sC.defaultbilltocustomerid, sD.state, SUM(sB.quantity*sB.unitprice*(1+sB.taxrate/100)) AS TotalOrders
      FROM salesorderheader sA 
      JOIN salesorderline sB ON sA.orderid = sB.orderid
      JOIN customer sC ON sA.customerid = sC.customerid
      JOIN location sD ON sC.defaultbilltocustomerid = sD.customerid
      WHERE sD.state IN ('Kansas','Colorado','Utah')
      GROUP BY sC.defaultbilltocustomerid, sD.state),
  Customer_Payment_Sums AS (
    SELECT customerid, SUM(-paymentamount) AS total_customer_payment
      FROM payment
      GROUP BY customerid),
  Customer_Orders_Minus_Payments AS (
    SELECT B.customerid, A.state, A.TotalOrders - COALESCE(B.total_customer_payment, 0) AS Net, A.TotalOrders, COALESCE(B.total_customer_payment, 0)
      FROM Customer_Order_Sums AS A
      LEFT JOIN Customer_Payment_Sums AS B
      ON A.defaultbilltocustomerid = B.customerid
  )
  SELECT *
    FROM Customer_Orders_Minus_Payments
    ORDER BY Net Desc OFFSET 5 LIMIT 10;

 
/*SET operators
UNION - The UNION operator only keeps distinct values (across all values in the result set and it does not 
 care from which select statement they came, i.e., if there are duplicates in the first, the second, or 
 across both then they will be filtered out) by default.)
UNION ALL - Keeps duplicate values
INTERSECT - Keeps rows that are common to all the queries (removes duplicates)
EXCEPT - The EXCEPT operator lists the rows in the first that are not in the second (removes duplicates)

- Each query must have the same number of columns, column order, and data types. 
- The output column names are referred from the first query, which means that each query may have different
column names (the stacking is not done based on column names, it is done based on order).
- The ORDER BY clause goes at the end of the entire SET expression and applies to the entire set.

19) Modify the query CTE in question 18 and create a list of the top 10 and bottom 10 customers in terms of 
difference between orders sums and payment sums. In the output also include a column that indicates if the
row came from the top or the bottom query (name this field Type).*/

WITH 
  Customer_Order_Sums AS (
  SELECT sC.defaultbilltocustomerid, sD.state, SUM(sB.quantity*sB.unitprice*(1+sB.taxrate/100)) AS TotalOrders
      FROM salesorderheader sA 
      JOIN salesorderline sB ON sA.orderid = sB.orderid
      JOIN customer sC ON sA.customerid = sC.customerid
      JOIN location sD ON sC.defaultbilltocustomerid = sD.customerid
      WHERE sD.state IN ('Kansas','Colorado','Utah')
      GROUP BY sC.defaultbilltocustomerid, sD.state),
  Customer_Payment_Sums AS (
    SELECT customerid, SUM(-paymentamount) AS total_customer_payment
      FROM payment
      GROUP BY customerid),
  Customer_Orders_Minus_Payments AS (
    SELECT B.customerid, A.state, A.TotalOrders - COALESCE(B.total_customer_payment, 0) AS Net, A.TotalOrders, COALESCE(B.total_customer_payment, 0)
      FROM Customer_Order_Sums AS A
      LEFT JOIN Customer_Payment_Sums AS B
      ON A.defaultbilltocustomerid = B.customerid
  ),
    Top_Customers AS (
    SELECT *, 'Top' AS "Type"
      FROM Customer_Orders_Minus_Payments
      ORDER BY Net Desc LIMIT 10
  ),
    Bottom_Customers AS (
    SELECT *, 'Bottom' AS "Type"
      FROM Customer_Orders_Minus_Payments
      ORDER BY Net Asc LIMIT 10
  )
  SELECT * FROM Top_Customers
  UNION
  SELECT * FROM Bottom_Customers
  ORDER BY net DESC;
