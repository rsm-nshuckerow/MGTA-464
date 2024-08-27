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

SELECT 
    customercategoryname, 
    DATE_TRUNC('month', paymentdate) AS "Date",
    SUM(paymentamount) OVER Cumulative AS "Running Totle - Annual"

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
WINDOW
    Cumulative AS (PARTITION BY DATE_TRUNC('year', paymentdate))
;