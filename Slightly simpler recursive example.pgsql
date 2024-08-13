DROP TABLE Simple_BillOfMaterials;

CREATE TABLE Simple_BillOfMaterials (
  ProductID	integer,
  PartID	integer,
  Quantity  integer
);

INSERT INTO Simple_BillOfMaterials
  VALUES 
    (1,  3, 2),
    (1,  4, 5),
    (2,  4, 3),
    (2,  5, 8),
    (2,  6, 3),
    (3,  7, 3),
    (5,  8, 1),
    (6,  8, 4),
    (6,  9, 2),
    (9, 10, 1);

SELECT * FROM Simple_BillOfMaterials;
/*The table above shows products and their parts. A part can have sub-parts, e.g., notice that id 3 is a part on row 1
and a product on row 6 (a single product can also have multiple sub-parts and sub-parts can also have sub-parts,
which can have sub-parts and so on. There is no rule to specify how deep this can go. In the data above,
notice the following relationships:
1 --> 3 --> 7
1 --> 4
2 --> 4
2 --> 5 --> 8
2 --> 6 --> 8
2 --> 6 --> 9 --> 10

Our goal is to write a query that traverses over these paths.

We will start simple. First note that there are two products (product ids 1 and 2) that are not part of any other
products (we will later start the BOM explosion with these products). Write 
a query to locate these products (the query should find all products that have
ProductID that is not a PartID of another product) and the parts of these two products.*/

SELECT DISTINCT A.ProductID, A.PartID
    FROM Simple_BillOfMaterials AS A LEFT JOIN Simple_BillOfMaterials AS B
    ON A.ProductID = B.PartID
    WHERE B.PartID IS NULL;

/*Write a CTE that starts with the select statement above and then uses a second select
statement to locate the parts of the parts located in the first query. In the outer query,
simply show the results from the second query.*/
WITH 
    BOM_Explosion_Initial_Query AS
        (SELECT A.ProductID, A.PartID
        FROM Simple_BillOfMaterials AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.ProductID = B.PartID
        WHERE B.PartID IS NULL),
    BOM_Explosion_Parts_SubParts AS
        (SELECT B.ProductID, B.PartID
        FROM BOM_Explosion_Initial_Query AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID)
SELECT * FROM BOM_Explosion_Parts_SubParts;

/*Notice that the data indicates that product 2 has a part that has a part that has a part.
Write a third inner CTE select statement to also locate this part.*/ 
WITH 
    BOM_Explosion_Initial_Query AS
        (SELECT A.ProductID, A.PartID
        FROM Simple_BillOfMaterials AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.ProductID = B.PartID
        WHERE B.PartID IS NULL),
    BOM_Explosion_Parts_SubParts AS
        (SELECT B.ProductID, B.PartID
        FROM BOM_Explosion_Initial_Query AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID
        FROM BOM_Explosion_Parts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID)
SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts;

/*Write a fourth inner CTE select statement that checks if there are any additional
sub-parts (since there are not, this query should return an empty result set).*/ 
WITH 
    BOM_Explosion_Initial_Query AS
        (SELECT A.ProductID, A.PartID
        FROM Simple_BillOfMaterials AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.ProductID = B.PartID
        WHERE B.PartID IS NULL),
    BOM_Explosion_Parts_SubParts AS
        (SELECT B.ProductID, B.PartID
        FROM BOM_Explosion_Initial_Query AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID
        FROM BOM_Explosion_Parts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID
        FROM BOM_Explosion_Parts_SubParts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID)
SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts_SubParts;

/*Update the query to UNION all the results from the four inner CTEs.*/
WITH 
    BOM_Explosion_Initial_Query AS
        (SELECT A.ProductID, A.PartID
        FROM Simple_BillOfMaterials AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.ProductID = B.PartID
        WHERE B.PartID IS NULL),
    BOM_Explosion_Parts_SubParts AS
        (SELECT B.ProductID, B.PartID
        FROM BOM_Explosion_Initial_Query AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID
        FROM BOM_Explosion_Parts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID
        FROM BOM_Explosion_Parts_SubParts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID)
SELECT * FROM BOM_Explosion_Initial_Query 
UNION
SELECT * FROM BOM_Explosion_Parts_SubParts
UNION
SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts
UNION
SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts_SubParts;

/*This appears to not be very useful, as we just returned the original table. However,
we are actually traversing the original table step-by-step, and we can use this to do things
like documenting the path that we took, e.g., 1-->3-->5-->8, only traverse certain paths, e.g.,
by only exploding certain products, keeping running totals of numeric fields when we traverse, etc.
Let's explore how to keep track of the path. To do this use a text string similar to what was presented
in the power point (if needed, convert numeric values to text using ::TEXT, concatenate values using ||)*/ 
WITH 
    BOM_Explosion_Initial_Query AS
        (SELECT A.ProductID, A.PartID, A.ProductID::TEXT || ' --> ' || A.PartID::TEXT AS Path
        FROM Simple_BillOfMaterials AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.ProductID = B.PartID
        WHERE B.PartID IS NULL),
    BOM_Explosion_Parts_SubParts AS
        (SELECT B.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path
        FROM BOM_Explosion_Initial_Query AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path
        FROM BOM_Explosion_Parts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path
        FROM BOM_Explosion_Parts_SubParts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID)
SELECT * FROM BOM_Explosion_Initial_Query 
UNION
SELECT * FROM BOM_Explosion_Parts_SubParts
UNION
SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts
UNION
SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts_SubParts;

/*That is better. Now also keep track of the quantity required of each sub-part. For example,
one unit of product 1 requires two units of product 3 which requires three units of product 7, which means 
that to manufacture one unit of product 1 we need six units of product 7 (plus other parts).*/

WITH 
    BOM_Explosion_Initial_Query AS
        (SELECT A.ProductID, A.PartID, A.ProductID::TEXT || ' --> ' || A.PartID::TEXT AS Path, A.Quantity AS Quantity_Needed
        FROM Simple_BillOfMaterials AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.ProductID = B.PartID
        WHERE B.PartID IS NULL),
    BOM_Explosion_Parts_SubParts AS
        (SELECT B.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path, A.Quantity_Needed * B.Quantity AS Quantity_Needed
        FROM BOM_Explosion_Initial_Query AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path, A.Quantity_Needed * B.Quantity AS Quantity_Needed
        FROM BOM_Explosion_Parts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path, A.Quantity_Needed * B.Quantity AS Quantity_Needed
        FROM BOM_Explosion_Parts_SubParts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID)
SELECT * FROM BOM_Explosion_Initial_Query 
UNION
SELECT * FROM BOM_Explosion_Parts_SubParts
UNION
SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts
UNION
SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts_SubParts;

/*Now let's assume we only want to keep results showing the endpoints of each path, e.g., for path 1 --> 3 --> 7
we do not want to include the row showing 1 --> 3 in our results. Endpoints are defined as all rows that have a
part id that cannot be expanded further, e.g., the part_id is not listed in the product id column. This means that we want
to locate all rows with part ids that have not matching product id, which is an anti-join. To do this, move the UNION select
statement into the CTE as an inner select and create a new outer select that locates the endpoints.  Order this output in 
ascending order by productid and then partid.*/

WITH 
    BOM_Explosion_Initial_Query AS
        (SELECT A.ProductID, A.PartID, A.ProductID::TEXT || ' --> ' || A.PartID::TEXT AS Path, A.Quantity AS Quantity_Needed
        FROM Simple_BillOfMaterials AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.ProductID = B.PartID
        WHERE B.PartID IS NULL),
    BOM_Explosion_Parts_SubParts AS
        (SELECT B.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path, A.Quantity_Needed * B.Quantity AS Quantity_Needed
        FROM BOM_Explosion_Initial_Query AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path, A.Quantity_Needed * B.Quantity AS Quantity_Needed
        FROM BOM_Explosion_Parts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts_SubParts AS
        (SELECT B.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path, A.Quantity_Needed * B.Quantity AS Quantity_Needed
        FROM BOM_Explosion_Parts_SubParts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion AS
        (SELECT * FROM BOM_Explosion_Initial_Query 
        UNION
        SELECT * FROM BOM_Explosion_Parts_SubParts
        UNION
        SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts
        UNION
        SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts_SubParts)
    SELECT A.* 
        FROM BOM_Explosion AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID
        WHERE B.ProductID IS NULL
        ORDER BY Productid, Partid;


/*Notice that the ProductID shown is not always the original ProductID that the path
started with. Update the query to output the original ProductID instead (note that
we output the product if from the right table when locating sub-parts. However,
we do not do anything with this productid so we might as well just keep displaying
the product id from the left table (which in our setup is the information from the previous
result). */ 
WITH 
    BOM_Explosion_Initial_Query AS
        (SELECT A.ProductID, A.PartID, A.ProductID::TEXT || ' --> ' || A.PartID::TEXT AS Path, A.Quantity AS Quantity_Needed
        FROM Simple_BillOfMaterials AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.ProductID = B.PartID
        WHERE B.PartID IS NULL),
    BOM_Explosion_Parts_SubParts AS
        (SELECT A.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path, A.Quantity_Needed * B.Quantity AS Quantity_Needed
        FROM BOM_Explosion_Initial_Query AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts AS
        (SELECT A.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path, A.Quantity_Needed * B.Quantity AS Quantity_Needed
        FROM BOM_Explosion_Parts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion_Parts_SubParts_SubParts_SubParts AS
        (SELECT A.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path, A.Quantity_Needed * B.Quantity AS Quantity_Needed
        FROM BOM_Explosion_Parts_SubParts_SubParts AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID),
    BOM_Explosion AS
        (SELECT * FROM BOM_Explosion_Initial_Query 
        UNION
        SELECT * FROM BOM_Explosion_Parts_SubParts
        UNION
        SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts
        UNION
        SELECT * FROM BOM_Explosion_Parts_SubParts_Subparts_SubParts)
    SELECT A.* 
        FROM BOM_Explosion AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID
        WHERE B.ProductID IS NULL
        ORDER BY Productid, Partid;

/*That looks better. However, this is a little crazy with all the inner CTEs. Additionally, it
will not work if other products have deeper part-id paths, which is especially a problem since
we do not have a rule that specifies how deep these paths can be.  Also note how repetitive the
second to fourth inner select statements are. They are identical except that they change the FROM
table to use the previous select statement as input. The clear solution here is to use a recursive
CTE query instead. When creating the recursive CTE also add a counter and add a WHERE clause in the 
recursive select statement that makes sure that the recursion is stopped after a certain number of 
iterations, e.g., Counter < 5.*/ 

WITH RECURSIVE
    BOM_Explosion AS
        (SELECT A.ProductID, A.PartID, A.ProductID::TEXT || ' --> ' || A.PartID::TEXT AS Path, A.Quantity AS Quantity_Needed, 1 AS Counter
        FROM Simple_BillOfMaterials AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.ProductID = B.PartID
        WHERE B.PartID IS NULL
        UNION
        SELECT A.ProductID, B.PartID, A.Path || ' --> ' || B.PartID::TEXT AS Path, A.Quantity_Needed * B.Quantity AS Quantity_Needed, Counter + 1
        FROM BOM_Explosion AS A JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID
        WHERE Counter < 5)
    SELECT A.* 
        FROM BOM_Explosion AS A LEFT JOIN Simple_BillOfMaterials AS B
        ON A.PartID = B.ProductID
        WHERE B.ProductID IS NULL
        ORDER BY Productid, Partid;

/*Note that this code is almost identical to what we had in the regular CTE with a few changes:
- adding RECURSIVE, 
- only keeping the first and second inner select statements and combining them with UNION (instead of keeping 
  them as separate CTE definitions, i.e., remove the comma and separating parentheses), also keep the outer select,
- removing all inner names and instead naming the entire CTE (we actually only have one inner CTE definition),
- referring to the new CTE name in the recursive select statement (second select statement),
- The counter was also added (which is not needed for the query to work)