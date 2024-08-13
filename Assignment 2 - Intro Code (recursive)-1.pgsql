/*Review PPT for this information (until line 119)
CTEs have a special type: 
RECURSIVE QUERIES
When having table self-joins or other types of hierarchies that can be arbitrarily deep, recursive queries can be very useful.
• Essentially a loop that keeps repeating queries that refers to the previous iteration's result to generate new results.
• A type of CTE that specifies two SELECT statements separated by UNION or UNION ALL.
• When the recursive CTE query runs, the first SELECT generates the initial result set. The second SELECT then references this 
  result set and creates a new result set that feeds back into the second query. The recursion ends when no more rows are returned 
  by the second SELECT.
• Because UNION is used, the non-recursive and the recursive select statements have to create the same columns.

General syntax:
WITH RECURSIVE
  cte_name [(list of field names)] AS(
    select statement 1 (non-recursive)
    UNION [ALL]
    select statement 2 (recursive), which includes a reference to cte_name either in FROM or JOIN
) SELECT * FROM cte_name;
 
Order of execution:
1.  The non-recursive select statement is executed and creates the base result set R0. This result
    is placed in the working table.
2.  While the working table is not empty:
    The recursive select statement is executed with all rows in the working table (new rows from the 
    previous iteration). After executing Ri, all new rows created by Ri replaces the content in 
    the working table and are then used as input in subsequent steps. 
3.  The CTE stacks all rows from all iterations (R0, R1, R2,...Rn) using either UNION or UNION
    ALL (duplicates removed/not removed). The outer CTE query is used to return the
    CTE results, i.e., all rows stacked together.

Simple example:*/
WITH RECURSIVE
  Previous AS(
    SELECT 1 AS Counter
    UNION
    SELECT Previous.Counter + 1         --dot notation not needed, just added for clarity
      FROM Previous
      WHERE Previous.Counter + 1 <= 4)
  SELECT * FROM Previous; 

/*Understanding the Code:
Recursion: R0 (non-recursive select statement, base)
Working Table Before: Empty
Working Table After: 1
SELECT 1 AS Counter

Recursion: R1 (recursive select statement, first round)
Working Table Before: 1 (new rows from R0)
Working Table After: 2
SELECT Previous.Counter + 1    --Previous = R0
  FROM Previous
  WHERE Previous.Counter + 1 <= 4)

Recursion: R2 (recursive select statement, second round)
Working Table Before: 2 (new rows from R1)
Working Table After: 3
SELECT Previous.Counter + 1           --Previous = new rows from R1
  FROM Previous
  WHERE Previous.Counter + 1 <= 4)

Recursion: R3 (recursive select statement, third round)
Working Table Before: 3 (new rows from R2)
Working Table After: 4
SELECT Previous.Counter + 1           --Previous = new rows from R2
  FROM Previous
  WHERE Previous.Counter + 1 <= 4)

Recursion: R4 (recursive select statement, fourth round)
Working Table Before: 4 (new rows from R3)
Working Table After: Empty (because of the WHERE condition)
SELECT Previous.Counter + 1           --Previous = new rows from R3
  FROM Previous
  WHERE Previous.Counter + 1 <= 4)

Note that R4 returns an empty result set, which forces the recursion (the inner CTE 
query) to stop. The outer CTE query is then executed. The outer query is used to 
access the CTE result set (union of all the individual result sets).

This examples actually has some utility... 
1) When building recursive queries, it is easy to get stuck in endless loops. We 
can avoid this by using a counter with a WHERE statement in the recursive select 
statement, just like how we did in this example. Another alternative is to use LIMIT 
in the outer select statement. However, depending on the specific query, this does not 
always work (I usually use both a counter and LIMIT when building a new recursive queries). 
2) Counters can also be useful as an indication of the recursion level. 

We might also want to keep track of prior information or the path. In our example, 
the path was simply 1 --> 2 --> 3, etc., but if we are traversing actual data, then 
the path is typically not as obvious.  I know of two solutions to keep track of paths:
1) Use a text field and concatenate text from the working table (data from the previous
round) with new new data from the current round. To do this add the following,
    - to the base query: '1' AS TextCounterPath
    - to the recursive query: TextCounterPath || '-->' || (counter + 1)::TEXT
2) Use an array and add new data to the array data in the working table (data from previous round)
    - in base query: ARRAY[1] as ArrayCounterPath (the array data type might have to be changed, e.g., ARRAY[]::INTEGER[])
    - in recursive query: ArrayCounterPath || counter + 1 
    - in the outer query: 
        > the array can be printed (e.g., 1,2,3,4) by simply selecting the column
        > the array can also be converted to text with optional delimiter added, e.g., array_to_string(ArrayCounterPath, '-->')
        > a number of other array functions can also be used, e.g., array_length (which could be used to find the total number of levels)

Here is our counter example with path fields added:*/

WITH RECURSIVE
  Previous AS(
    SELECT 1 AS counter, 1::TEXT AS TextCounterPath, ARRAY[1] as ArrayCounterPath
    UNION
    SELECT counter + 1, TextCounterPath || '-->' || (counter + 1)::TEXT, ArrayCounterPath || counter + 1  
      FROM Previous
      WHERE counter + 1 <= 4)
  SELECT *, array_to_string(ArrayCounterPath, '-->'), array_length(ArrayCounterPath, 1) FROM Previous; 







/*More complex example:

Let's assume we have the following table named ProductOrders:*/
--DROP TABLE ProductOrders;

CREATE TABLE ProductOrders (
  OrderID	integer,
  ProductID	integer,
  Quantity	integer,
  RequiredDate date
);

INSERT INTO ProductOrders
  VALUES 
    (20152,	     3,	      10,        '1/8/2022'),
    (20152,	     4,	      30,        '1/8/2022'),
    (20152,	    17,	      10,        '1/8/2022'),
    (20153,	     3,	      20,        '1/12/2022'),
    (20154,	     6,	      10,        '1/15/2022'),
    (20154,	     4,	      40,        '1/15/2022'),
    (20154,	     3,	      20,        '1/15/2022');

--Also assume we have a table called BillOfMaterials:


CREATE TABLE BillOfMaterials (
  ProductID	integer,
  PartID	integer,
  Quantity	integer
);

INSERT INTO BillOfMaterials
  VALUES 
    (1,            8,           4),
    (1,            9,           2),
    (1,           11,          10),
    (3,           10,           4),
    (3,           11,           8),
    (4,           10,           5),
    (4,           12,           6),
    (5,            9,           8),
    (5,           10,           8),
    (6,           12,           1),
    (6,           13,           8),
    (7,            8,           3),
    (7,            9,           2),
    (7,           10,           4),
    (8,           14,           3),
    (8,           13,           5),
    (8,           15,           6),
    (10,          15,           5),
    (10,          16,           7),
    (14,          16,           4),
    (14,          17,           3),
    (16,          17,           3);

/*Now create a recursive query that shows, for each ordered product all the parts 
that are needed to manufacture the product. In the final table, only include parts 
that have no subparts. The output should show the original orderid, the product 
that was ordered, and (on separate rows) all the parts that are needed to manufacture 
the ordered product and the quantity that is needed of the part.  Also include two 
fields, one for the product chain and one for total quantity of sub-parts needed 
for each part in the chain. This is what the table should look like:

OrderID Order_ProductID, Part_ProductID  QuantityNeeded  PartList
20152	     3	                11      	      80	        3 --> 11
20152	     3        	        15	           200	        3 --> 10 --> 15
20152	     3	                17      	     840	        3 --> 10 --> 16 --> 17	
20152	     4                 	12          	 180	        4 --> 12
20152	     4        	        15          	 750	        4 --> 10 --> 15	
20152	     4	                17      	    3150	        4 --> 10 --> 16 --> 17	
20152	     17	                17      	      10	        0	
20153	     3	                11          	 160        	3 --> 11
20153	     3                	15          	 400	        3 --> 10 --> 15	
20153	     3                	17          	1680        	3 --> 10 --> 16 --> 17	
20154	     3        	        11          	 160        	3 --> 11
20154	     3        	        15          	 400        	3 --> 10 --> 15
20154	     3        	        17          	1680	        3 --> 10 --> 16	--> 17
20154	     4        	        12          	 240	        4 --> 12	
20154	     4	                15          	1000	        4 --> 10 --> 15	
20154	     4	                17      	    4200	        4 --> 10 --> 16	--> 17
20154	     6         	        12              10	        6 --> 12	
20154	     6         	        13          	  80	        6 --> 13

** Examine the two understanding tabs in the Excel spreadsheet then continue below. **


The following solution results in more complex code than needed, but I think 
it is more intuitive in the beginning as it is more focused on the BOM table 
in the recursion (this was not my first solution, see below for alternatives).

In the first step find BillOfMaterials records for products that were ordered. We
only need to expand these products:*/

SELECT DISTINCT A.ProductID, B.PartID, B.Quantity, A.ProductID::TEXT || '-->' || B.PartID::TEXT, 1
  FROM ProductOrders AS A 
    JOIN BillOfMaterials AS B 
    ON A.ProductID = B.ProductID;

/*Now add the recursive step. When we did this by hand, we took the PartID
of the rows identified in the previous step and found corresponding
ProductIDs in the BOM table. So let's try the same thing here, i.e., let's 
join the working table (BOM_Explosion) PartID with the BOM table ProductID
and then output this into the working table. I also have to decide what to
do with TotalQuantity field and PartList. I will multiply the TotalQuantity 
value from the previous round (stored in the working table) with Quantity 
from the BOM table and add '-->' and PartID from the BOM table to the 
PartList variable (just like we did by hand):*/

WITH RECURSIVE
  BOM_Explosion (ProductID, PartID, TotalQuantity, PartList, Counter) AS(
  SELECT DISTINCT A.ProductID, B.PartID, B.Quantity, A.ProductID::TEXT || '-->' || B.PartID::TEXT, 1
    FROM ProductOrders AS A 
      JOIN BillOfMaterials AS B 
      ON A.ProductID = B.ProductID
    UNION
    SELECT B.ProductID, B.PartID, A.TotalQuantity*B.Quantity, A.PartList || '-->' || B.PartID::TEXT, Counter + 1
      FROM BOM_Explosion AS A 
        JOIN BillOfMaterials AS B
        ON A.PartID = B.ProductID
      WHERE Counter < 5)
    SELECT A.* FROM BOM_Explosion AS A;

/* This kind of worked. However, note that the ProductID cannot be used to 
merge the results back to the ProductOrders table. If we joined the these 
recursion results with the ProductOrders table, we would only get results 
from the first iteration of the recursion, and we really want the entire 
paths. What do we do here? What value would be useful for relating these 
rows back to the ProductOrders table? 

What we need is the original ProductID. We can keep this information 
throught out each loop by simply outputting the previous ProductID. We 
can do this in a new field, however note that we do not use the previous 
ProductID anywhere in the recursion, (we use the previous PartID), so we 
do not need to keep track of the previous ProductID and we might as well 
just replace the previous ProductID with the original ProductID.*/

WITH RECURSIVE
  BOM_Explosion (ProductID, PartID, TotalQuantity, PartList, Counter) AS(
  SELECT DISTINCT A.ProductID, B.PartID, B.Quantity, A.ProductID::TEXT || '-->' || B.PartID::TEXT, 1
    FROM ProductOrders AS A 
      JOIN BillOfMaterials AS B 
      ON A.ProductID = B.ProductID
    UNION
    SELECT A.ProductID /*This was previous B.ProductID*/, B.PartID, A.TotalQuantity*B.Quantity, A.PartList || '-->' || B.PartID::TEXT, Counter + 1
      FROM BOM_Explosion AS A 
        JOIN BillOfMaterials AS B
        ON A.PartID = B.ProductID
      WHERE Counter < 5)
    SELECT A.* FROM BOM_Explosion AS A;

/*
** Let's go through this query one recursion step at a time (Excel).**

Back to the results. We still will have a problem when trying to merge 
this result with the ProductOrders table as the results gives us not only 
the complete paths but also paths that are later expanded furter. In the
results, we are only interested in showing what the lowest level Parts
that are needed to fulfill the ordered products. In other words, we 
only want rows representing paths that cannot be expanded furter. 

How do we know if a row in the final results could be expanded further?
Perhaps better way to ask, is there a way to tell if a row cannot be 
expanded further? 
Answer: Rows with PartIDs that do not have matching records in the 
ProductID column in the BOM table. 

How do we find rows that do not have matching records in another table?
(Answer: anti-join, i.e., LEFT OUTER JOIN with WHERE B. IS NULL */ 

WITH RECURSIVE
  BOM_Explosion (ProductID, PartID, TotalQuantity, PartList, Counter) AS(
  SELECT DISTINCT A.ProductID, B.PartID, B.Quantity, A.ProductID::TEXT || '-->' || B.PartID::TEXT, 1
    FROM ProductOrders AS A 
      JOIN BillOfMaterials AS B 
      ON A.ProductID = B.ProductID
    UNION
    SELECT A.ProductID, B.PartID, A.TotalQuantity*B.Quantity, A.PartList || '-->' || B.PartID::TEXT, Counter + 1
      FROM BOM_Explosion AS A 
        JOIN BillOfMaterials AS B
        ON A.PartID = B.ProductID
      WHERE Counter < 5)
    SELECT A.* 
    FROM BOM_Explosion AS A
      LEFT JOIN BillOfMaterials AS B      --New Code
      ON A.PartID = B.ProductID           --New Code
      WHERE B.ProductID IS NULL;          --New Code
      
/*We now have the BOM explosion of products that were ordered, but we do
not know how much were ordered (items can be ordered multipled times and
each order is typically for multiple units as indicated in the quantity
field in ProductOrders). To get this information we need to merge the 
CTE recursion results with the ProductOrders table.*/

WITH RECURSIVE
  BOM_Explosion (ProductID, PartID, TotalQuantity, PartList, Counter) AS(
    SELECT DISTINCT A.ProductID, B.PartID, B.Quantity, A.ProductID::TEXT || '-->' || B.PartID::TEXT, 1
      FROM ProductOrders AS A 
        JOIN BillOfMaterials AS B 
        ON A.ProductID = B.ProductID
    UNION
    SELECT A.ProductID, B.PartID, A.TotalQuantity*B.Quantity, A.PartList || '-->' || B.PartID::TEXT, Counter + 1
      FROM BOM_Explosion AS A 
        JOIN BillOfMaterials AS B
        ON A.PartID = B.ProductID
      WHERE Counter < 5)
    SELECT A.OrderID, A.ProductID, B.PartID, A.Quantity*B.TotalQuantity, B.PartList, B.Counter --Some new code
      FROM ProductOrders AS A           --New code
      JOIN BOM_Explosion AS B           --New code
        ON A.ProductID = B.ProductID    --New code
      LEFT JOIN BillOfMaterials AS C
        ON B.PartID = C.ProductID
        WHERE C.ProductID IS NULL
        ORDER BY A.OrderID, B.ProductID, B.PartID; --New code

/*This is pretty good but we are missing something... look at 
the OrderID column and the ProductID column and compare this to 
the original ProductOrders table. What are we missing?

Answer: We are missing products that do no have any subparts, 
e.g., productid 17. This is because the BOM explosion recursion 
does not (as expected) contain any information for such products.

We do however still want these products in our results. How do we make
sure to include all the rows from one table even if there are some rows
in that table that does not have any matching rows in the second table?
Answer: LEFT OUTER JOIN */

WITH RECURSIVE
  BOM_Explosion (ProductID, PartID, TotalQuantity, PartList, Counter) AS(
    SELECT DISTINCT A.ProductID, B.PartID, B.Quantity, A.ProductID::TEXT || '-->' || B.PartID::TEXT, 1
      FROM ProductOrders AS A 
        JOIN BillOfMaterials AS B 
        ON A.ProductID = B.ProductID
    UNION
    SELECT A.ProductID, B.PartID, A.TotalQuantity*B.Quantity, A.PartList || '-->' || B.PartID::TEXT, Counter + 1
      FROM BOM_Explosion AS A 
        JOIN BillOfMaterials AS B
        ON A.PartID = B.ProductID
      WHERE Counter < 5)
    SELECT A.OrderID, A.ProductID, B.PartID, A.Quantity*B.TotalQuantity, B.PartList, B.Counter
      FROM ProductOrders AS A           
      LEFT JOIN BOM_Explosion AS B       --Modified code
        ON A.ProductID = B.ProductID    
      LEFT JOIN BillOfMaterials AS C
        ON B.PartID = C.ProductID
        WHERE C.ProductID IS NULL
        ORDER BY A.OrderID, B.ProductID, B.PartID;

/*While we now see ProductID 17, it contains NULL values in all
columns that come from the recursion.  We at least want the quantity
information. For quantity we will use the quantity ordered instead 
of the total for products that do not have sub-components. While the
other fields could probably be kept as-is, for practice purposes we 
will use the ordered ProductID for PartID and PartList. For counter 
we will return 0 to indicate that this row was not part of the 
recursion (or keep it as null).*/
WITH RECURSIVE
  BOM_Explosion (ProductID, PartID, TotalQuantity, PartList, Counter) AS(
    SELECT DISTINCT A.ProductID, B.PartID, B.Quantity, A.ProductID::TEXT || '-->' || B.PartID::TEXT, 1
      FROM ProductOrders AS A 
        JOIN BillOfMaterials AS B 
        ON A.ProductID = B.ProductID
    UNION
    SELECT A.ProductID, B.PartID, A.TotalQuantity*B.Quantity, A.PartList || '-->' || B.PartID::TEXT, Counter + 1
      FROM BOM_Explosion AS A 
        JOIN BillOfMaterials AS B
        ON A.PartID = B.ProductID
      WHERE Counter < 5)
    SELECT A.OrderID, A.ProductID, COALESCE(B.PartID, A.ProductID), A.Quantity*COALESCE(B.TotalQuantity, 1), COALESCE(B.PartList, A.ProductID::Text), COALESCE(B.Counter, 0) --Modified code
      FROM ProductOrders AS A
      LEFT JOIN BOM_Explosion AS B
        ON A.ProductID = B.ProductID
      LEFT JOIN BillOfMaterials AS C
        ON B.PartID = C.ProductID
        WHERE C.ProductID IS NULL
        ORDER BY A.OrderID, B.ProductID, B.PartID;

/*Here is the same solution but instead of keeping track of the original productID
inside the recursion, I store the path elements in an array. The first element 
in the array represent the original productid.*/

WITH RECURSIVE
  BOM_Explosion (PartID, TotalQuantity, PartList, Counter) AS(
    SELECT DISTINCT B.PartID, B.Quantity, ARRAY[A.ProductID, B.PartID], 1
      FROM ProductOrders AS A 
        JOIN BillOfMaterials AS B ON A.ProductID = B.ProductID
    UNION
    SELECT B.PartID, A.TotalQuantity*B.Quantity, A.PartList || B.PartID, Counter + 1
      FROM BOM_Explosion AS A 
        JOIN BillOfMaterials AS B
        ON A.PartID = B.ProductID
      WHERE Counter < 10)
    SELECT A.OrderID, A.ProductID, COALESCE(B.PartID, A.ProductID) AS PartID, COALESCE(A.Quantity*B.TotalQuantity, A.Quantity) AS QuantityNeeded, COALESCE(array_to_string(B.PartList, '-->'), A.ProductID::TEXT) AS ProductExplosion, COALESCE(B.Counter, 0) AS RecursionLevel 
      FROM ProductOrders AS A
      LEFT JOIN BOM_Explosion AS B
        ON A.ProductID = B.PartList[1]
      LEFT JOIN BillOfMaterials AS C
        ON B.PartID = C.ProductID
        WHERE C.ProductID IS NULL
        ORDER BY A.OrderID, A.ProductID, B.PartID;
 
/*Here is an alternative that was actually my first solution. This query avoids some of 
the complexity of the outer query by instead keeping track of orderid, ordered quantity, 
etc. within the recursion. The downside is that each order of the same product has to 
be exploded rather than each product (that has been ordered at least once) is exploded 
only once. 

We start by defining the CTE fields and the base query (I also added a counter, so that 
I can avoid getting stuck in loops):*/

WITH RECURSIVE
  BOM_Explosion (OrderID, Order_ProductID, Part_ProductID, QuantityNeeded, PartList, Counter) AS(
    SELECT OrderID, ProductID, ProductID, Quantity, ARRAY[ProductID], 1
      FROM ProductOrders
    UNION [ALL]
    select statement 2 (recursive), which includes a reference to cte_name either in FROM or JOIN
) SELECT * FROM cte_name;

-- Adding the next layer by joining ProductIDs to PartIDs
WITH RECURSIVE
  BOM_Explosion (OrderID, Order_ProductID, Part_ProductID, QuantityNeeded, PartList, Counter) AS(
    SELECT OrderID, ProductID, ProductID, Quantity, ARRAY[ProductID], 1
      FROM ProductOrders
    UNION
    SELECT A.OrderID, A.Order_ProductID, B.PartID, A.QuantityNeeded*B.Quantity, A.PartList || B.PartID, Counter + 1 
      FROM BOM_Explosion AS A
      JOIN BillOfMaterials AS B
      ON A.Part_ProductID = B.ProductID
      WHERE Counter < 6)
    SELECT * FROM BOM_Explosion
    ORDER BY OrderID, Order_ProductID, Part_ProductID;

--Now only keep rows where a part does not have sub-parts (the partid is not also a productid):
WITH RECURSIVE
  BOM_Explosion (OrderID, Order_ProductID, Part_ProductID, QuantityNeeded, PartList, Counter) AS(
    SELECT OrderID, ProductID, ProductID, Quantity, ARRAY[ProductID], 1
      FROM ProductOrders
    UNION
    SELECT A.OrderID, A.Order_ProductID, B.PartID, A.QuantityNeeded*B.Quantity, A.PartList || B.PartID, Counter + 1 
      FROM BOM_Explosion AS A 
        JOIN BillOfMaterials AS B
        ON A.Part_ProductID = B.ProductID
      WHERE Counter < 6)
    SELECT A.* 
      FROM BOM_Explosion AS A
        LEFT JOIN BillOfMaterials AS B
        ON A.Part_ProductID = B.ProductID
        WHERE B.ProductID IS NULL;

--And sort the output and format the array output:
WITH RECURSIVE
  BOM_Explosion (OrderID, Order_ProductID, Part_ProductID, QuantityNeeded, PartList, Counter) AS(
    SELECT OrderID, ProductID, ProductID, Quantity, ARRAY[ProductID], 1
      FROM ProductOrders
    UNION
    SELECT A.OrderID, A.Order_ProductID, B.PartID, A.QuantityNeeded*B.Quantity, A.PartList || B.PartID, Counter + 1 
      FROM BOM_Explosion AS A 
        JOIN BillOfMaterials AS B
        ON A.Part_ProductID = B.ProductID
      WHERE Counter < 3)
    SELECT A.OrderID, A.Order_ProductID, A.Part_ProductID, A.QuantityNeeded, array_to_string(A.PartList, '-->'), A.Counter
      FROM BOM_Explosion AS A
        LEFT JOIN BillOfMaterials AS B
        ON A.Part_ProductID = B.ProductID
      WHERE B.ProductID IS NULL
      ORDER BY A.OrderID, A.Order_ProductID, A.Part_ProductID;

--Here is an alternative solution that starts with adding partid from the BOM table already in R0
WITH RECURSIVE
  BOM_Explosion (OrderID, Order_ProductID, Part_ProductID, QuantityNeeded, PartList, Counter) AS(
    SELECT OrderID, A.ProductID, COALESCE(B.PartID,A.ProductID), A.Quantity*COALESCE(B.Quantity,1), A.ProductID::TEXT || '-->' || B.PartID::TEXT, 1
      FROM ProductOrders AS A
      LEFT JOIN BillOfMaterials AS B
        ON A.ProductID = B.ProductID
    UNION
    SELECT A.OrderID, A.Order_ProductID, B.PartID, A.QuantityNeeded*B.Quantity, A.PartList || '-->' || B.PartID::TEXT, Counter + 1 
      FROM BOM_Explosion AS A 
        JOIN BillOfMaterials AS B
        ON A.Part_ProductID = B.ProductID
      WHERE Counter < 10)
    SELECT A.* 
      FROM BOM_Explosion AS A
      LEFT JOIN BillOfMaterials AS B
        ON A.Part_ProductID = B.ProductID
        WHERE B.ProductID IS NULL
        ORDER BY A.OrderID, A.Order_ProductID, A.Part_ProductID;