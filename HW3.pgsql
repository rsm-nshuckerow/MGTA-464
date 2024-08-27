-- Q20a
CREATE TABLE employees (
                employee_id serial PRIMARY KEY,
                full_name VARCHAR NOT NULL,
                manager_id INT
);
INSERT INTO employees (employee_id, full_name, manager_id)
  VALUES
    (1, 'Michael North', NULL),
    (2, 'Megan Berry', 1),
    (3, 'Sarah Berry', 1),
    (4, 'Zoe Black', 1),
    (5, 'Tim James', 1),
    (6, 'Bella Tucker', 2),
    (7, 'Ryan Metcalfe', 2),
    (8, 'Max Mills', 2),
    (9, 'Benjamin Glover', 2),
    (10, 'Carolyn Henderson', 3),
    (11, 'Nicola Kelly', 3),
    (12, 'Alexandra Climo', 3),
    (13, 'Dominic King', 3),
    (14, 'Leonard Gray', 4),
    (15, 'Eric Rampling', 4),
    (16, 'Piers Paige', 7),
    (17, 'Ryan Henderson', 7),
    (18, 'Frank Tucker', 8),
    (19, 'Nathan Ferguson', 8),
    (20, 'Kevin Rampling', 10);

SELECT * FROM employees;

WITH MeganBerry AS(
    SELECT employee_id, full_name, manager_id
    FROM employees
    WHERE full_name = 'Megan Berry'
),
DirectReports AS (
    SELECT E.employee_id, E.full_name, E.manager_id
    FROM employees E
    INNER JOIN MeganBerry mb ON E.manager_id = mb.employee_id
),
IndirectReports AS (
    SELECT I.employee_id, I.full_name, I.manager_id
    FROM employees I
    INNER JOIN DirectReports dr ON I.manager_id = dr.employee_id
)

SELECT * FROM MeganBerry
UNION
SELECT * FROM DirectReports
UNION
SELECT * FROM IndirectReports;

-- Q20b
WITH RECURSIVE MB_Hierarchy AS(
    SELECT employee_id, full_name, manager_id
    FROM employees
    WHERE full_name = 'Megan Berry' 

    UNION

    SELECT I.employee_id, I.full_name, I.manager_id
    FROM employees I
    INNER JOIN MB_Hierarchy mb ON I.manager_id = mb.employee_id
)

SELECT * FROM MB_hierarchy;

-- Q20c
WITH RECURSIVE MB_Hierarchy AS (
    SELECT employee_id, full_name, manager_id,
    ARRAY[]::VARCHAR[] AS Managers,
    0 AS NumberofManagers
    FROM employees
    WHERE full_name = 'Megan Berry'

    UNION

    SELECT e.employee_id, e.full_name, e.manager_id,
    ARRAY_APPEND(mb.Managers, mb.full_name) AS Managers,
    mb.NumberofManagers + 1 AS NumberofManagers
    FROM employees e INNER JOIN MB_Hierarchy mb ON e.manager_id = mb.employee_id
)

SELECT * FROM MB_Hierarchy;


-- Q21a

-- First, only include sales which are the original order with a backorder, 
-- meaning the backorderid itself is not referenced in the result.

SELECT
    A.orderid, A.orderdate, A.backorderid
    FROM salesorderheader AS A
    LEFT JOIN salesorderheader AS B ON A.orderid = B.backorderid
    WHERE B.backorderid IS NULL AND A.backorderid IS NOT NULL;

-- Step 2
-- Find the order info for the backordered items

WITH Backordered_Items AS (
    SELECT
        A.orderid, A.orderdate, A.backorderid
        FROM salesorderheader AS A
        LEFT JOIN salesorderheader AS B ON A.orderid = B.backorderid
        WHERE B.backorderid IS NULL AND A.backorderid IS NOT NULL
),
Backorder_info AS (
    SELECT
        B.orderid, B.orderdate, B.backorderid
        FROM Backordered_Items AS A
        JOIN salesorderheader AS B ON B.orderid = A.backorderid
)
SELECT * FROM Backordered_Items
UNION
SELECT * FROM Backorder_info
ORDER BY orderid;


-- Step 3

WITH RECURSIVE Backordered AS (
    SELECT
            A.orderid, A.orderdate, A.backorderid,
            ARRAY[]::INTEGER[] AS backorders,
            0 AS NumberofBackorders
    FROM salesorderheader AS A
    LEFT JOIN salesorderheader AS B ON A.orderid = B.backorderid
    WHERE B.backorderid IS NULL AND A.backorderid IS NOT NULL

    UNION

    SELECT
        B.orderid, B.orderdate, B.backorderid,
        A.orderid || A.backorders,
        NumberofBackorders+1
    FROM Backordered AS A
    JOIN salesorderheader B ON A.backorderid = B.orderid
)
SELECT * FROM Backordered
WHERE NumberofBackorders > 1 AND backorderid IS NULL
ORDER BY orderid;

--Q22a
SELECT 
    C.suppliercategoryname, A.suppliername, A.phonenumber
    FROM supplier A
    JOIN suppliercategorymembership B ON A.supplierid = B.supplierid
    JOIN suppliercategory C ON B.suppliercategoryid = C.suppliercategoryid
    WHERE C.suppliercategoryname IN('Toy Supplier', 'Novelty Goods Supplier');

-- Q22b

SELECT 
    A.suppliername, A.phonenumber, ('Toy Supplier or Novelty Goods Supplier') AS suppliercategoryname
    FROM supplier A
    WHERE
        EXISTS(
            SELECT
                B.supplierid
                FROM suppliercategorymembership B
                JOIN suppliercategory C ON B.suppliercategoryid = C.suppliercategoryid
                WHERE C.suppliercategoryname IN('Toy Supplier', 'Novelty Goods Supplier') AND
                A.supplierid = B.supplierid
        );

-- Q22c

SELECT 
    A.suppliername, A.phonenumber, ('Toy Supplier or Novelty Goods Supplier') AS suppliercategoryname
    FROM supplier A
    WHERE A.supplierid =  ANY(
        SELECT B.supplierid
        FROM suppliercategorymembership B
        JOIN suppliercategory C ON B.suppliercategoryid = C.suppliercategoryid
        WHERE C.suppliercategoryname IN('Toy Supplier', 'Novelty Goods Supplier')
    );

-- Q23

SELECT 
    F.suppliercategoryname, 
    EXTRACT(YEAR FROM B.orderdate) AS "Year", 
    EXTRACT(MONTH FROM B.orderdate) AS "Month",
    round(SUM(orderedouters*expectedouterunitprice/1000000)::numeric,2) AS Total_Purchases
    FROM purchases A
    JOIN purchaseorderheader B ON A.purchaseorderid = B.purchaseorderid
    JOIN purchaseorderline C ON B.purchaseorderid = C.purchaseorderid
    JOIN supplier D ON A.supplierid = D.supplierid
    JOIN suppliercategorymembership E ON D.supplierid = E.supplierid
    JOIN suppliercategory F ON E.suppliercategoryid = F.suppliercategoryid
    GROUP BY F.suppliercategoryname, "Year", "Month";


SELECT 
    COALESCE(F.suppliercategoryname, 'Total'),
    EXTRACT(YEAR FROM B.orderdate) AS "Year", 
    EXTRACT(MONTH FROM B.orderdate) AS "Month",
    round(SUM(C.orderedouters*C.expectedouterunitprice/1000000)::numeric,2) AS Total_Purchases
    FROM purchaseorderheader B
    JOIN purchaseorderline C ON B.purchaseorderid = C.purchaseorderid
    JOIN suppliercategorymembership E ON B.supplierid = E.supplierid
    JOIN suppliercategory F ON E.suppliercategoryid = F.suppliercategoryid
    GROUP BY ROLLUP (F.suppliercategoryname, "Year", "Month")
    ORDER BY F.suppliercategoryname, "Year", "Month";

SELECT 
    COALESCE(F.suppliercategoryname, 'Total'),
    EXTRACT(YEAR FROM B.orderdate) AS "Year", 
    EXTRACT(MONTH FROM B.orderdate) AS "Month",
    round(SUM(C.orderedouters*C.expectedouterunitprice/1000000)::numeric,2) AS Total_Purchases
    FROM purchaseorderheader B
    JOIN purchaseorderline C ON B.purchaseorderid = C.purchaseorderid
    JOIN suppliercategorymembership E ON B.supplierid = E.supplierid
    JOIN suppliercategory F ON E.suppliercategoryid = F.suppliercategoryid
    GROUP BY CUBE (F.suppliercategoryname, "Year", "Month")
    ORDER BY F.suppliercategoryname, "Year", "Month";