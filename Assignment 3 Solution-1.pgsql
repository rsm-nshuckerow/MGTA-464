/*20) Recursive queries
-	When having table self-joins or other types of hierarchies that can be arbitrarily deep, recursive queries can be very useful.
- Essentialy a loop that keeps repeating queries that refers to the previous iteration's result to generate new results.
- A type of CTE that specifies two SELECT statements separated by UNION or UNION ALL.
-	When the recursive CTE query runs, the first SELECT generates the intital result set. The second SELECT then references this 
  result set and creates a new result set that then keeps feeding back into the second query. The recursion ends when no more rows 
  are returned from the second SELECT.
- Because UNION is used, the non-recursive and the recursive select statements have to create the same columns.

General syntax:
WITH RECURSIVE 
  cte_name AS(
    select statement 1 (non-recursive)
    UNION [ALL]
    select statement 2 (recursive), which includes a reference to cte_name either in FROM or JOIN
) SELECT * FROM cte_name;

Order of execution:
1) The non-recursive select statement is executed and creates the base result set R0.
2) While Ri is not empty:
    The recursive select statement is executed with Ri as an input and returns the result set Ri+1 as output.
3) The last select statement is executed to create final result, which is a UNION (or UNION ALL) of all previous result set (R0, R1, … Rn). 

We will next create a table to look at this in more detail:
CREATE TABLE employees (
	employee_id serial PRIMARY KEY,
	full_name VARCHAR NOT NULL,
	manager_id INT
);

INSERT INTO employees (employee_id,	full_name, manager_id)
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
*/
With
megan_id As (
select * 
  from employees 
  where full_name = 'Megan Berry'),
  
direct_under_megan AS (
Select A.* 
  from employees A
  where A.manager_id = megan_id.employee_id)/*,

direct_direct_under_megan as (
select B.* 
  from employees B 
  where B.manager_id in direct_under_megan.employee_id)*/

SELECT * FROM megan_id
UNION
SELECT * FROM direct_under_megan
UNION
SELECT * FROM direct_direct_under_megan
ORDER BY employee_id;

Take a look at the data and make sure that you notice the relationship between manager_id and employee_id. For example:
1) Who have Michael North as their direct manager?
    - Megan Berry, Sarah Berry, Zoe Black, and Tim James
2) Who has Megan Berry as their direct manager? 
    - Bella Tucker, Ryan Metcalfe, Max Mills, and Benjamin Glover
3) Who has a manager that has Megan Berry as a manager?
    - Piers Paige (via Ryan Metcalfe),Ryan Henderson (via Ryan Metcalfe), Frank Tucker (via Max Mills), and Nathan Ferguson (via Max Mills)	

20a) Exercise
Let's say we want create a query to find out all the employees that work under Megan Berry, e.g., the people in the answers to questions
1 and 2 above.  In the result include both Megan Berry and all the employees that work under her. 

First write a regular (non recursive) CTE query to extract these employees.employee_id. Because we have three levels, you need three select
statement to extract the rows and one select statement to stack them together:
1) This first select statement should extract the row with Megan Berry. 
2) The second select statement extract rows with manager_ids that are equal the employee_id in the first result set, i.e., it should find 
   rows that have Megan Berry as the manager. 
3) The third select statement should find all the rows with manager_ids that are equal to an employee_id in the second result set, so it 
   should find all employees that have managers that have Megan Berry as a manager (the explanation of the corresponding recursive query shows 
   the expect output from EACH select statement in more detail). 
4) The fourth select statement should stack the results from 1, 2, and 3 together.*/

WITH
  manager AS (
    SELECT * FROM employees
      WHERE employee_id = 2),
  subordinates_1 AS (
    SELECT A.* FROM employees A
      JOIN manager B ON A.manager_id = B.employee_id),
  subordinates_2 AS (
    SELECT A.* FROM employees A
      JOIN subordinates_1 B ON A.manager_id = B.employee_id)
  SELECT * FROM manager
    UNION
  SELECT * FROM subordinates_1
    UNION
  SELECT * FROM subordinates_2
  ORDER BY employee_id;

/*20b) But what if we have additional levels? This gets complex very quickly and we have to write a separate select statement for each level, which means 
we need to know how many levels there are. This is exactly when recursive queries are useful. Let's rewrite our CTE query as a CTE recursive query.*/
WITH RECURSIVE subordinates AS(
  SELECT * FROM employees
    WHERE employee_id = 2
  UNION
  SELECT A.* FROM employees A
    JOIN subordinates B ON A.manager_id = B.employee_id)
  SELECT * FROM subordinates;

/*So what happens here?
In the first iteration, the query runs the first select statement (the non-recursive term) and returns the base result set: 
employee_id   full_name     manager_id
2	            Megan Berry	  1

In the second iteration, the base result is passed into the second select (the recursive term) and returns the first recursive result set:
employee_id   full_name       manager_id
6	            Bella Tucker	  2
7	            Ryan Metcalfe	  2
8	            Max Mills	      2
9	            Benjamin Glover	2

In the third iteration, the first recursive result (the result set from the second iteration) is passed into the second select 
(the recursive term) and returns the second recursive result set:
6	16	Piers Paige	7
7	17	Ryan Henderson	7
8	18	Frank Tucker	8
9	19	Nathan Ferguson	8

In the fourth iteration, the second recursive result is passed into the second select, but this returns no results (no rows in the employees table have manager_ids equal to an employee_id in this result set) 

21) Modify the query bin 20 to keep track of "relatives". To accomplish this, create an array using the key word
ARRAY[] (name this array Managers) and in each iteration add manager full_name to the Managers array (i.e., full_name || Managers).
Because the array is initially empty you need to cast it to varchar (it by default otherwise figures out the type based on the 
elements in the array). Also keep track of how many layers of managers each employee has above them (how many iterations have the
recursive query been repeated) by creating a new field and initially setting this to 0 and then adding 1 to this field 
in each iteration. Name this field, NumberOfManagers. In addition to these two fields, show employee_id and full_name and
show all employees (start the recursion at the highest manager level.*/

WITH RECURSIVE subordinates AS(
  SELECT employee_id, full_name, ARRAY[]::text[] As Managers, 0 As NumberOfManagers
    FROM employees
    WHERE manager_id IS NULL
  UNION
  SELECT A.employee_id, A.full_name, Managers || (' ' || B.full_name), NumberOfManagers + 1 
    FROM employees A
    JOIN subordinates B ON A.manager_id = B.employee_id)
  SELECT * FROM subordinates;

DROP TABLE employees;

/* 21) Some orders have back order ids, and some of these orders even have backorders. There are no business rules
that limits how deep this goes. Use a recursive to find all backorders and show their backorder history (e.g., what 
orders were backordered to create the specific backorder). In the result, only include backorders that is the third time 
the order had to be backordered, i.e, only include backorders for orders that have been backordered and then the backorder
got backordered, and then this backorder of the backorder got backordered (I am just having fun with this...). In your output 
show orderid, orderdate, backorderid, a list showing parent rders (name this field backorderlist), and a field showing how many
times it has been backordered (name this field depth). Also in your final results make sure that you do not show the original 
orders or backorders that were subsequently backordered.

In the first step, create a regular query that finds order information for backorders, include orderid, orderedate, backorderid
of the backordered order and orderid, orderedate, backorderid from the order's backorder. Only include orders that have been 
backordered twice.

Here is a visual of the sales irder header tabel with the most relevant fields:
OrderID     OrderDate     BackOrderID
  1         1/10/2021         
  2         1/10/2021          5
  3         1/12/2021          6
  4         1/13/2021         
  5         1/14/2021          7
  6         1/14/2021         
  7         1/15/2021         13
  8         1/15/2021         12
  9         1/15/2021         
 10         1/16/2021         
 11         1/16/2021         
 12         1/17/2021         
 13         1/17/2021

Here we can see that order 2, 3, 5, 7, and 8 have been backordered. Interestingly, order 2 was backordered, 
and the backorder (order 5) of order 2 ended up also being backordered (order 7), and the backorder (order 7) abbrev
of order 5 also ended up being backordered (order 13) - evidently some items were difficult to fulfill). In the questions
above, you are asked to only show backorders that are for orders that have been backordered two or more times. And you want
include the most current backorder when there is a chain of backorders.  So in our example we would like to display order 13
and a list consisting of 7, 5, and 2 (that indicates that 13 came from 7, that came from 5, that came from 2).  We also want 
a variable that indicates how many times the order has already been backordered, e.g., 3 for order 13. Only show this one row; do not
show (a) rows 2, 3, 5, 7, and 8 because they were themselves backordered, (b) rows 1, 4, 6, 9, 10, and 11 because 
they are not backorders, or (c) rows 6 and 12 because they are the first time the items were backordered. 

In this analysis we as such need to join the SalesOrderHeader with itself. Let's, however, first identify 
all orders that have backorders (no self-join yet) but that themselves were not backorders (this is our initial set
of orders), and output OrderID, OrderDate, and BackOrderID:*/

SELECT A.Orderid, A.OrderDate, A.backorderid
  FROM salesorderheader AS A
  LEFT JOIN salesorderheader AS B
  ON A.OrderID = B.backorderid
  WHERE B.backorderid IS NULL AND A.backorderid IS NOT NULL;

SELECT A.Orderid, A.OrderDate, A.backorderid
  FROM salesorderheader AS A
  LEFT JOIN salesorderheader AS B
  ON A.OrderID = B.backorderid
  WHERE B.backorderid IS NULL AND A.backorderid IS NOT NULL;
  

SELECT A.Orderid, A.OrderDate, A.backorderid FROM salesorderheader A;
/*With only the second part of the where statement, we would get:
OrderID     OrderDate     BackOrderID
  2         1/10/2021          5
  3         1/12/2021          6
  5         1/14/2021          7
  7         1/15/2021         13
  8         1/15/2021         12

But because OrderIDs 5 and 7 are equal to BackOrderID in other rows these two rows are removed by the first
part of the WHERE statement.
OrderID     OrderDate     BackOrderID
  2         1/10/2021          5
  3         1/12/2021          6
  8         1/15/2021         12

Then let's add this to a CTE and add another select statement that uses this result to find the order
information (using the salesorderheader table) associated with the backorder id of the backordered items.*/
WITH 
  Originals AS(
    SELECT A.Orderid, A.OrderDate, A.backorderid
      FROM salesorderheader AS A
      LEFT JOIN salesorderheader AS B
      ON A.OrderID = B.backorderid
      WHERE B.backorderid IS NULL AND A.backorderid IS NOT NULL),
  BackOrders AS(
    SELECT B.Orderid, B.OrderDate, B.backorderid
      FROM Originals AS A
      JOIN salesorderheader B
      ON A.backorderid = B.orderid)
  SELECT * FROM Originals
  UNION
  SELECT * FROM BackOrders
  ORDER BY Orderid;


/*This then returns the following:
OrderID     Order Date    BackOrderID       BackOrder_OrderID   BackOrder_Date    BackOrder_BackOrderID
  2         1/10/2021          5                    
  3         1/12/2021          6        
  8         1/15/2021         12                                  
  5         1/14/2021          7
  6         1/14/2021               
  12        1/17/2021

To follow the entire chain we need to add another SELECT statement to find out more information about orderid 7.
This select statement will, apart from table references, look identical to the second CTE statement, so this is 
our recursive component. This is, of course already getting out of hand and we do not even know how many levels 
this can go.  Additionally, we want information about the chain of the orders. So let's write this as a 
recursive query. First without the list of orders and worrying about only showing the deepest level.*/
WITH RECURSIVE BackOrders AS(
  SELECT A.Orderid, A.OrderDate, A.backorderid
    FROM salesorderheader AS A
    LEFT JOIN salesorderheader AS B
    ON A.OrderID = B.backorderid
    WHERE B.backorderid IS NULL AND A.backorderid IS NOT NULL
  UNION    
  SELECT B.Orderid, B.OrderDate, B.backorderid
    FROM BackOrders AS A
    JOIN salesorderheader B
    ON A.backorderid = B.orderid)
  SELECT * FROM BackOrders
  ORDER BY Orderid;
  
/*I next add the two variables that keep track of prior order ids and recursion depth*/
WITH RECURSIVE BackOrders AS(
  SELECT A.Orderid, A.OrderDate, A.backorderid, ARRAY[]::INTEGER[] as backorderlist, 0 AS depth 
    FROM salesorderheader AS A
    LEFT JOIN salesorderheader AS B
    ON A.OrderID = B.backorderid
    WHERE B.backorderid IS NULL AND A.backorderid IS NOT NULL
  UNION    
  SELECT B.Orderid, B.OrderDate, B.backorderid, A.orderid || A.backorderlist, depth+1 
    FROM BackOrders AS A
    JOIN salesorderheader B
    ON A.backorderid = B.orderid)
  SELECT * FROM BackOrders
  ORDER BY Orderid;

/*I finally add a WHERE statement that only keeps the "final" backorders (the bottom level of a chain) and
that also only shows backorder chains that are two levels or more.*/
WITH RECURSIVE BackOrders AS(
  SELECT A.Orderid, A.OrderDate, A.backorderid, ARRAY[]::INTEGER[] as backorderlist, 0 AS depth 
    FROM salesorderheader AS A
    LEFT JOIN salesorderheader AS B
    ON A.OrderID = B.backorderid
    WHERE B.backorderid IS NULL AND A.backorderid IS NOT NULL
  UNION    
  SELECT B.Orderid, B.OrderDate, B.backorderid, A.orderid || A.backorderlist, depth+1 
    FROM BackOrders AS A
    JOIN salesorderheader B
    ON A.backorderid = B.orderid)
  SELECT * FROM BackOrders
  WHERE depth>1 AND backorderid IS NULL
  ORDER BY Orderid;


/*22) Subquery expression functions: EXISTS, IN, NOT IN, ANY/SOME, and ALL

Find all suppliers with suppliercategory Toy Supplier or Novelty Goods Supplier. 
In the results include suppliercategoryname, suppliername, and phonenumber.

IN
In earlier exercises, we used the IN operator to replace ORs in WHERE statements, 
e.g., WHERE state IN('Kansas', 'Utah', 'Colorado'). The IN operator can also take a subquery 
that returns only one column as input. The results of the subquery is used similarly to how 
the list of values were used in the previous IN example. 

General Syntax:
SELECT column_name(s)
FROM table_name
WHERE column_name IN (subquery);*/

SELECT A.suppliername, A.phonenumber, ('Toy Supplier or Novelty Goods Supplier') AS suppliercategoryname
  FROM supplier A
  WHERE A.supplierid IN(
    SELECT B.supplierid
      FROM suppliercategorymembership B
      JOIN suppliercategory C
      ON B.suppliercategoryid = C.suppliercategoryid
      WHERE C.suppliercategoryname IN('Toy Supplier', 'Novelty Goods Supplier')); 

-- NOT IN
    
SELECT A.suppliername, A.phonenumber, ('Toy Supplier or Noverly Goods Supplier') AS suppliercategoryname
  FROM supplier A
  WHERE A.supplierid NOT IN(
    SELECT B.supplierid
      FROM suppliercategorymembership B
      JOIN suppliercategory C
      ON B.suppliercategoryid = C.suppliercategoryid
      WHERE C.suppliercategoryname IN('Toy Supplier', 'Novelty Goods Supplier')); 
  
/*Let's use EXISTS instead:
EXISTS is used in WHERE statements to check if a subquery returns any rows. If the subquery 
returns a row then EXISTS returns true. EXISTS is often used in correlated queries. A correlated 
query is a subquery that depends on the outer query for its values and is executed once for each 
row evaluated by the outer query.

General Syntax:
SELECT column_name(s)
FROM table_name
WHERE EXISTS
(correlated subquery);*/

SELECT A.suppliername, A.phonenumber, ('Toy Supplier or Novelty Goods Supplier') AS suppliercategoryname
  FROM supplier A
  WHERE EXISTS(
    SELECT B.supplierid
      FROM suppliercategorymembership B
      JOIN suppliercategory C
      ON B.suppliercategoryid = C.suppliercategoryid
      WHERE C.suppliercategoryname IN('Toy Supplier', 'Novelty Goods Supplier')
      AND A.supplierid = B.supplierid); 

-- And finally join:
SELECT A.suppliername, A.phonenumber, C.suppliercategoryname
  FROM supplier A
  JOIN suppliercategorymembership B
  ON A.supplierid = B.supplierid
  JOIN suppliercategory C
  ON B.suppliercategoryid = C.suppliercategoryid
  WHERE C.suppliercategoryname IN('Toy Supplier', 'Novelty Goods Supplier'); 

/*Differences in performance and readability among IN, EXISTS, and JOIN depend on the context. If
performance is important then evaluate performance. Otherwise, JOIN provide more flexibility (e.g., control 
join type, having access to all variable).

ANY (SOME)
ANY is also used in WHERE statements in a similar way to IN, but instead of simply checking for equality
between values, it can also use other operators, e.g., > and <.  SOME is a synonym for ANY. Note that IN is 
equivalent to =ANY (but that ANY can  also use other operators).

General Syntax:
SELECT column_name(s)
FROM table_name
WHERE column_name comparison_operator ANY (subquery);
*/

SELECT A.supplierid, A.suppliername, A.phonenumber, ('Toy Supplier or Novelty Goods Supplier') AS suppliercategoryname
  FROM supplier A
  WHERE A.supplierid = ANY(
    SELECT B.supplierid
      FROM suppliercategorymembership B
      JOIN suppliercategory C
      ON B.suppliercategoryid = C.suppliercategoryid
      WHERE C.suppliercategoryname IN('Toy Supplier', 'Novelty Goods Supplier')); 


/*ALL
ALL is used similarly to ANY, but instead of only one comparison having to return TRUE, all
comparisons have to return TRUE.
SELECT column_name(s)
FROM table_name
WHERE column_name comparison_operator ALL  (subquery);
*/

SELECT A.supplierid, A.suppliername, A.phonenumber, ('Toy Supplier or Novelty Goods Supplier') AS suppliercategoryname
  FROM supplier A
  WHERE A.supplierid = ALL(
    SELECT B.supplierid
      FROM suppliercategorymembership B
      JOIN suppliercategory C
      ON B.suppliercategoryid = C.suppliercategoryid
      WHERE C.suppliercategoryname IN('Toy Supplier', 'Novelty Goods Supplier')); 
      
/*23
Additional GROUP BY operators: GROUPING SETS, ROLLUP, and CUBE.
These additional GROUP BY options can be useful when grouping by multiple fields. When group by is defined with 
multiple columns then rows with the same values in all the columns in the group by statements are grouped together with
the result set containing one row for each unique combination of values in the group by columns. The result set, however,
does not show the components that makes up these groups. GROUPING SETS, ROLLUP, and CUBE can be used to create result sets
that contain information about these components.*/


SELECT -sum(PaymentAmount), EXTRACT(year FROM paymentdate) AS "Year", EXTRACT(month FROM paymentdate)  AS "Month" 
FROM Payment
GROUP BY "Year","Month"
ORDER BY "Year","Month"

/*GROUPING SETS
Instead of the combination of column values, the result set contains subtotal for each of the field values 
and a grand total of all the matching rows (but no subtotal for the combination of column values).*/

SELECT -sum(PaymentAmount), EXTRACT(year FROM paymentdate) AS "Year", EXTRACT(month FROM paymentdate)  AS "Month" 
FROM Payment
GROUP BY GROUPING SETS("Year","Month")
ORDER BY "Year","Month"

/*ROLLUP
Create a hierarchical rollup starting with the first field in the group by, then the second field, etc., i.e, ROLLUP creates
totals for a hierarchy of values where each level of the hierarchy is an aggregation of the values in the level below it.*/

SELECT -sum(PaymentAmount), EXTRACT(year FROM paymentdate) AS "Year", EXTRACT(month FROM paymentdate)  AS "Month" 
FROM Payment
GROUP BY ROLLUP("Year","Month")
ORDER BY "Year","Month"

CUBE
Get all the possible combinations.*/
SELECT -sum(PaymentAmount), EXTRACT(year FROM paymentdate) AS "Year", EXTRACT(month FROM paymentdate)  AS "Month" 
FROM Payment
GROUP BY CUBE("Year","Month")
ORDER BY "Year","Month"

/*24) Create a query that shows suppliercategoryname, Year, Month, Total Purchases (in millions). Total Purchases 
is defined as orderedouters*expectedouterunitprice/1000000 for each suppliercategoryname, Year and Month. In other
words, show for each supplier category monthly total purchases. Show the results ordered by categoryname, year, 
and then month. You can assume that each supplier only belongs to one suppliercategory (according to the ERD it 
is possible that each supplier can belong to multiple supplier categories). To answer this question you need to 
join four tables, one set of joins to obtain the suppliercategory for each order and one set of joins to get the 
orderdate and the total amount of the order. This could all be done in one statements, but use a CTE with two 
temporary views, one for each set of joins described above.*/



SELECT D.suppliercategoryname, EXTRACT(YEAR FROM A.orderdate) AS "Year", EXTRACT(MONTH FROM A.orderdate) "Month", round((SUM(B.orderedouters*B.expectedouterunitprice)/1000000)::numeric,2) AS "Total Purchases (in millions)"
FROM purchaseorderheader A
JOIN purchaseorderline B ON A.purchaseorderid = B.purchaseorderid
JOIN suppliercategorymembership C ON A.supplierid = C.supplierid
JOIN suppliercategory D ON C.suppliercategoryid = D.suppliercategoryid
GROUP BY suppliercategoryname, "Year", "Month"
ORDER BY suppliercategoryname, "Year", "Month"


SELECT D.suppliercategoryname, EXTRACT(YEAR FROM A.orderdate) AS "Year", EXTRACT(MONTH FROM A.orderdate) "Month", round((SUM(B.orderedouters*B.expectedouterunitprice)/1000000)::numeric,2) AS "Total Purchases (in millions)"
FROM purchaseorderheader A
JOIN purchaseorderline B ON A.purchaseorderid = B.purchaseorderid
JOIN suppliercategorymembership C ON A.supplierid = C.supplierid
JOIN suppliercategory D ON C.suppliercategoryid = D.suppliercategoryid
GROUP BY GROUPING SETS (suppliercategoryname, "Year", "Month")
ORDER BY suppliercategoryname, "Year", "Month"

SELECT D.suppliercategoryname, EXTRACT(YEAR FROM A.orderdate) AS "Year", EXTRACT(MONTH FROM A.orderdate) "Month", round((SUM(B.orderedouters*B.expectedouterunitprice)/1000000)::numeric,2) AS "Total Purchases (in millions)"
FROM purchaseorderheader A
JOIN purchaseorderline B ON A.purchaseorderid = B.purchaseorderid
JOIN suppliercategorymembership C ON A.supplierid = C.supplierid
JOIN suppliercategory D ON C.suppliercategoryid = D.suppliercategoryid
GROUP BY ROLLUP (suppliercategoryname, "Year", "Month")
ORDER BY suppliercategoryname, "Year", "Month"

SELECT D.suppliercategoryname, EXTRACT(YEAR FROM A.orderdate) AS "Year", EXTRACT(MONTH FROM A.orderdate) "Month", round((SUM(B.orderedouters*B.expectedouterunitprice)/1000000)::numeric,2) AS "Total Purchases (in millions)"
FROM purchaseorderheader A
JOIN purchaseorderline B ON A.purchaseorderid = B.purchaseorderid
JOIN suppliercategorymembership C ON A.supplierid = C.supplierid
JOIN suppliercategory D ON C.suppliercategoryid = D.suppliercategoryid
GROUP BY CUBE (suppliercategoryname, "Year", "Month")
ORDER BY suppliercategoryname, "Year", "Month"