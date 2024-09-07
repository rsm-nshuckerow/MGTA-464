-- Before we start with windowing, we will create a view[1] that will be used as input into our windowing analyses: 
-- Use the SalesOrderHeader and the SalesOrderLine tables to create a view with three columns, 
-- SalespersonID, ReportingYear, and SalesInMillions.   
-- Name the view AnnualSalesPersonSales. SalespersonID is salespersonpersonid, sales is calculated at the line item level
-- as quantity*unitprice*(1+taxrate/100). 
-- The results should show SalesInMillions as total sales in millions for each sales person each year rounded to 
-- three decimals. Sort the results by SalesPersonID and Year. 
-- Exclude sales from 2016 as the data does not contain transactions for the entire year 2016.

DROP VIEW IF EXISTS AnnualSalesPersonSales;

CREATE VIEW AnnualSalesPersonSales AS (
    SELECT salespersonpersonid AS Salespersonid, 
           EXTRACT(YEAR FROM OrderDate) AS ReportingYear, 
           ROUND((SUM(Quantity*UnitPrice*(1+TaxRate/100))/1000000)::numeric, 3) AS SalesInMillions
    FROM SalesOrderHeader A
    JOIN SalesOrderLine B
    ON A.orderid = B.orderid
    WHERE EXTRACT(YEAR FROM OrderDate) != 2016
    GROUP BY salespersonpersonid, ReportingYear
    ORDER BY salespersonpersonid, ReportingYear
);

SELECT * FROM AnnualSalesPersonSales;

-- 25.2

SELECT *, AVG(salesinmillions) OVER() AS AverageSales,
((salesinmillions - AVG(salesinmillions) OVER())/AVG(salesinmillions) OVER())*100 AS PercentDiff
FROM annualsalespersonsales;

-- 25.4
SELECT *, LAG(salesinmillions, 1) OVER(PARTITION BY salespersonid) AS PriorSales,
(salesinmillions - LAG(salesinmillions, 1) OVER(PARTITION BY salespersonid)) AS SalesDiff,
AVG(salesinmillions) OVER(PARTITION BY reportingyear)
FROM annualsalespersonsales
ORDER BY salespersonid, reportingyear;

-- 

SELECT *, LAG(salesinmillions, 1) OVER(PARTITION BY salespersonid ORDER BY reportingyear) AS PriorSales,
(salesinmillions - LAG(salesinmillions, 1) OVER(PARTITION BY salespersonid ORDER BY reportingyear)) AS SalesDiff,
AVG(salesinmillions) OVER(PARTITION BY reportingyear)
FROM annualsalespersonsales
ORDER BY reportingyear, salespersonid;

--

CREATE VIEW MonthlySalesPersonSales AS

SELECT  A.salespersonpersonid AS SalespersonID, 

        EXTRACT(year FROM A.OrderDate) AS ReportingYear, 

        EXTRACT(month FROM A.OrderDate) AS ReportingMonth,

        DATE_TRUNC('month', A.OrderDate) AS TruncMonth,

        round(SUM(B.quantity*B.unitprice*(1+B.taxrate/100)/1000000)::numeric,3) AS SalesInMillions

    FROM salesorderheader AS A

    JOIN salesorderline AS B USING(OrderID)

    WHERE EXTRACT(year FROM A.OrderDate) <> 2016

    GROUP BY SalespersonID, ReportingYear, ReportingMonth,  DATE_TRUNC('month', A.OrderDate)

    ORDER BY SalespersonID, ReportingYear;

SELECT * FROM MonthlySalesPersonSales;

SELECT  SalesPersonID, ReportingYear, ReportingMonth,

        round(AVG(SalesInMillions) OVER()::numeric,3) AS "Average Annual Sales",

        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID)::numeric,3) AS "PARTITION",

        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth)::numeric,3) AS "P, OB",

        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS UNBOUNDED PRECEDING)::numeric,3) AS "P, OB, RUP",

        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)::numeric,3) AS "P, OB, RBUPCR",

        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS 3 PRECEDING)::numeric,3) AS "P, OB, R3P",

        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS 3 PRECEDING EXCLUDE CURRENT ROW)::numeric,3) AS "P, OB, R3P, ECR",

        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY TruncMonth RANGE INTERVAL '3 months' PRECEDING)::numeric,3) AS "P, OB, Ra3IP",

        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingMonth RANGE 3 PRECEDING)::numeric, 3) AS "P, OB, Ra3IntP"

    FROM MonthlySalesPersonSales

    WHERE reportingmonth <> 10 AND ReportingYear = 2013

    ORDER BY SalesPersonID, ReportingYear, ReportingMonth;


-- 25.10
WITH payments_2016 AS (
    SELECT
        customercategoryname,
        SUM(-paymentamount) AS Total_paid,
        DATE_TRUNC('month', paymentdate) AS payment_date
    FROM 
        payment A
    JOIN 
        customercategorymembership B
        ON A.customerid = B.customerid
    JOIN
        customercategory C
        ON B.customercategoryid = C.customercategoryid
    WHERE 
        EXTRACT(YEAR FROM paymentdate) != 2016
    GROUP BY
        customercategoryname, DATE_TRUNC('month', paymentdate)
    ORDER BY
        customercategoryname, DATE_TRUNC('month', paymentdate)
)

SELECT
     customercategoryname,
     payment_date,
     Total_paid,
     SUM(Total_paid) OVER Cumulative AS "Running Total - Annual",
     (Total_paid - first_value(Total_paid) OVER Cumulative)/first_value(Total_paid) OVER Cumulative AS "Percent Change from Beginning of Year",
     SUM(Total_paid) OVER Cumulative_Quarter AS "Running Total - Quarterly",
     SUM(Total_paid) OVER Three_Month_Total AS "3-month Total",
     AVG(Total_paid) OVER Three_Month_Total AS "3-month Moving Average"
FROM
    payments_2016
WINDOW
    Cumulative AS (PARTITION BY customercategoryname, EXTRACT(YEAR FROM payment_date) ORDER BY payment_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    Cumulative_Quarter AS (PARTITION BY customercategoryname, DATE_TRUNC('Quarter', payment_date) ORDER BY payment_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    Three_Month_Total AS (PARTITION BY customercategoryname ORDER BY payment_date RANGE BETWEEN INTERVAL '2 months' PRECEDING AND CURRENT ROW);

-- 26.1 & 26.2

WITH NotPOBox AS (
    SELECT * 
    FROM location
    WHERE LEFT(streetaddressline1, 2) NOT LIKE 'PO'
),
StreetNumberExtraction AS (
    SELECT 
        SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2) -1) AS StreetNumber,
        SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2) +1) AS RightOfStreetNumber,
        streetaddressline2
    FROM
        NotPOBox 
)

SELECT * FROM StreetNumberExtraction;

-- 26.3

WITH NotPOBox AS (
    SELECT * 
    FROM location
    WHERE LEFT(streetaddressline1, 2) NOT LIKE 'PO'
),
StreetNumberExtraction AS (
    SELECT 
        SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2) -1) AS StreetNumber,
        SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2) +1) AS RightOfStreetNumber,
        streetaddressline2
    FROM
        NotPOBox 
),
StreetNumberCheck AS(
    SELECT *,
        CASE
            WHEN StreetNumber SIMILAR TO '[0-9]+'
            THEN StreetNumber
            ELSE NULL
            END AS StreetNumber
    FROM
        StreetNumberExtraction
)

SELECT * FROM StreetNumberCheck;

-- 26.4

WITH NotPOBox AS (
    SELECT * 
    FROM location
    WHERE LEFT(streetaddressline1, 2) NOT LIKE 'PO'
),
StreetNumberExtraction AS (
    SELECT 
        SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2) -1) AS StreetNumber,
        SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2) +1) AS RightOfStreetNumber,
        streetaddressline2
    FROM
        NotPOBox 
),
StreetNumberCheck AS(
    SELECT *,
        CASE
            WHEN StreetNumber SIMILAR TO '[0-9]+'
            THEN StreetNumber
            ELSE NULL
            END AS StreetNumber
    FROM
        StreetNumberExtraction
),
StreetSuffixExtraction AS(
    SELECT *,
        REVERSE(SUBSTRING(REVERSE(streetaddressline2), 1, POSITION(' ' IN REVERSE(streetaddressline2)) -1)) AS StreetSuffix
    FROM
        StreetNumberCheck
)

SELECT * FROM StreetSuffixExtraction;

-- 26.5

WITH NotPOBox AS (
    SELECT * 
    FROM location
    WHERE LEFT(streetaddressline1, 2) NOT LIKE 'PO'
),
StreetNumberExtraction AS (
    SELECT 
        SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2) -1) AS StreetNumber,
        SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2) +1) AS RightOfStreetNumber,
        streetaddressline2
    FROM
        NotPOBox 
),
StreetNumberCheck AS(
    SELECT *,
        CASE
            WHEN StreetNumber SIMILAR TO '[0-9]+'
            THEN StreetNumber
            ELSE NULL
            END AS StreetNumber
    FROM
        StreetNumberExtraction
),
StreetSuffixExtraction AS(
    SELECT *,
        REVERSE(SUBSTRING(REVERSE(streetaddressline2), 1, POSITION(' ' IN REVERSE(streetaddressline2)) -1)) AS StreetSuffix
    FROM
        StreetNumberCheck
),
StreetSuffixCheck AS(
    SELECT *,
        LEFT(rightofstreetnumber, LENGTH(rightofstreetnumber)-LENGTH(streetsuffix) -1) AS StreetName
    FROM
        StreetSuffixExtraction A
    JOIN
        StreetSuffixMapping B
        ON UPPER(A.streetsuffix) = B.Written
)

SELECT * FROM StreetSuffixCheck;

-- 27.1

WITH NotPOBox AS (
    SELECT * 
    FROM location
    WHERE LEFT(streetaddressline1, 2) NOT LIKE 'PO'
),
StreetNumberExtraction AS (
    SELECT 
        SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2) -1) AS StreetNumber,
        SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2) +1) AS RightOfStreetNumber,
        streetaddressline2
    FROM
        NotPOBox 
),
StreetNumberCheck AS(
    SELECT *,
        CASE
            WHEN StreetNumber SIMILAR TO '[0-9]+'
            THEN StreetNumber
            ELSE NULL
            END AS StreetNumber
    FROM
        StreetNumberExtraction
),
StreetSuffixExtraction AS(
    SELECT *,
        REVERSE(SUBSTRING(REVERSE(streetaddressline2), 1, POSITION(' ' IN REVERSE(streetaddressline2)) -1)) AS StreetSuffix
    FROM
        StreetNumberCheck
),
StreetSuffixCheck AS(
    SELECT *,
        LEFT(rightofstreetnumber, LENGTH(rightofstreetnumber)-LENGTH(streetsuffix) -1) AS StreetName
    FROM
        StreetSuffixExtraction A
    JOIN
        StreetSuffixMapping B
        ON UPPER(A.streetsuffix) = B.Written
)

SELECT 
    'StreetNameMatch' AS MatchType,
    A.streetaddressline2,
    A.streetname,
    B.streetnumber,
    B.streetname,
    B.streetsuffix
FROM
    StreetSuffixCheck A
JOIN
    employee_table B
    ON A.streetname = B.streetname
;

-- 27.2

WITH NotPOBox AS (
    SELECT * 
    FROM location
    WHERE LEFT(streetaddressline1, 2) NOT LIKE 'PO'
),
StreetNumberExtraction AS (
    SELECT 
        SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2) -1) AS StreetNumber,
        SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2) +1) AS RightOfStreetNumber,
        streetaddressline2
    FROM
        NotPOBox 
),
StreetNumberCheck AS(
    SELECT *,
        CASE
            WHEN StreetNumber SIMILAR TO '[0-9]+'
            THEN StreetNumber
            ELSE NULL
            END AS CheckedStreetNumber
    FROM
        StreetNumberExtraction
),
StreetSuffixExtraction AS(
    SELECT *,
        REVERSE(SUBSTRING(REVERSE(streetaddressline2), 1, POSITION(' ' IN REVERSE(streetaddressline2)) -1)) AS StreetSuffix
    FROM
        StreetNumberCheck
),
StreetSuffixCheck AS(
    SELECT A.*,
        Standard,
        LEFT(rightofstreetnumber, LENGTH(rightofstreetnumber)-LENGTH(streetsuffix) -1) AS StreetName
    FROM
        StreetSuffixExtraction A
    JOIN
        StreetSuffixMapping B
        ON UPPER(A.streetsuffix) = B.Written
)

SELECT 
    'StreetNameMatch' AS MatchType,
    A.streetaddressline2,
    A.streetname,
    B.streetnumber,
    B.streetname,
    B.streetsuffix
FROM
    StreetSuffixCheck A
JOIN
    employee_table B
    ON A.streetname = B.streetname

UNION

SELECT
    'FullStreetAddressMatch' AS MatchType,
    A.streetaddressline2,
    A.streetname,
    B.streetnumber,
    B.streetname,
    B.streetsuffix
FROM
    StreetSuffixCheck A
JOIN
    employee_table B
    ON A.streetname = B.streetname
    AND A.streetnumber::int = B.streetnumber
    AND A.standard = B.streetsuffix;

-- 27.3

WITH NotPOBox AS (
    SELECT * 
    FROM location
    WHERE LEFT(streetaddressline1, 2) NOT LIKE 'PO'
),
StreetNumberExtraction AS (
    SELECT 
        SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2) -1) AS StreetNumber,
        SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2) +1) AS RightOfStreetNumber,
        streetaddressline2
    FROM
        NotPOBox 
),
StreetNumberCheck AS(
    SELECT *,
        CASE
            WHEN StreetNumber SIMILAR TO '[0-9]+'
            THEN StreetNumber
            ELSE NULL
            END AS CheckedStreetNumber
    FROM
        StreetNumberExtraction
),
StreetSuffixExtraction AS(
    SELECT *,
        REVERSE(SUBSTRING(REVERSE(streetaddressline2), 1, POSITION(' ' IN REVERSE(streetaddressline2)) -1)) AS StreetSuffix
    FROM
        StreetNumberCheck
),
StreetSuffixCheck AS(
    SELECT A.*,
        Standard,
        LEFT(rightofstreetnumber, LENGTH(rightofstreetnumber)-LENGTH(streetsuffix) -1) AS StreetName
    FROM
        StreetSuffixExtraction A
    JOIN
        StreetSuffixMapping B
        ON UPPER(A.streetsuffix) = B.Written
)

SELECT 
    'StreetNameMatch' AS MatchType,
    A.streetaddressline2,
    A.streetname,
    B.streetnumber,
    B.streetname,
    B.streetsuffix
FROM
    StreetSuffixCheck A
JOIN
    employee_table B
    ON A.streetname = B.streetname

UNION

SELECT
    'FullStreetAddressMatch' AS MatchType,
    A.streetaddressline2,
    A.streetname,
    B.streetnumber,
    B.streetname,
    B.streetsuffix
FROM
    StreetSuffixCheck A
JOIN
    employee_table B
    ON A.streetname = B.streetname
    AND A.streetnumber::int = B.streetnumber
    AND A.standard = B.streetsuffix

UNION

SELECT
    'StreetNameAndNumberMatchSoundexDifference' AS MatchType,
    A.streetaddressline2,
    A.streetname,
    B.streetnumber,
    B.streetname,
    B.streetsuffix
FROM
    StreetSuffixCheck A
JOIN
    employee_table B
    ON A.streetnumber::int = B.streetnumber
    WHERE
        DIFFERENCE(A.streetname, B.streetname) > 3

UNION

SELECT
    'LevenshteinMatch' AS MatchType,
    A.streetaddressline2,
    A.streetname,
    B.streetnumber,
    B.streetname,
    B.streetsuffix
FROM
    StreetSuffixCheck A
JOIN
    employee_table B
    ON A.streetnumber::int = B.streetnumber
    WHERE
        levenshtein_less_equal(A.streetname, B.streetname, 1) < 2;