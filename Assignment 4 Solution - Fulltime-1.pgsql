/*25.1) Windowing (OVER CLAUSE)
Both group by and window functions work with groups and performs calculations on those groups.  
When using group by, all rows that have the same value(s) in the field(s) defined by the group 
by clause get grouped together into a single row. The window function, however, keeps each of 
the original rows with aggregations added to each row. In a simple form, this could mean that 
we keep the original rows and fields and add a column(s) with aggregated information.  

For example, say we have a result set from a regular query that shows annual sales for each 
salesperson (i.e., one row for each year and salesperson and a sum of sales), see first exercise 
below. We can then use windowing to also include average sales of all employee (and show average 
sales on each row), see second exercise below.  Note that the calculation of the average requires 
that all rows are grouped together, yet the final result keep each of these rows separated in the 
final result set. To accomplish this output using only groupby, we would need to first calculate 
the average in one query and then join it back with the original data (or use a subquery in the 
list of result columns). Windowing can also be used to reference other rows in the result set based 
on the position of the current row, e.g., the current row uses a value in the row above in a 
calculation (if data is in chronological order then this could for example calculate changes in values).

Similarly to Group By statements, there are two main components to windowing, but there are more 
options in windowing than in regular group by statements:
•	The function to apply to the window (group)
    o	a regular aggregate function, e.g., AVG(), SUM(), etc.
    o	a built-in window function, e.g., lag(), rank(), first_value(), etc.
•	The window definition
    o	a clause that specify grouping fields (works similarly to GROUP BY), e.g., PARTITION BY regular_field_x, regular_field_y
    o	frame specifications used to control, for each row, which rows within each partition should be 
        part of that row’s window (e.g., all the rows in the partition, all the previous rows in the 
        partition excluding the current row, all the previous rows in the partition include the current 
        row, all the subsequent rows in the partition…), e.g., RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    o	ORDER BY defines how to sort the rows within each window.

These components are placed in the list of result columns in the SELECT statement (as opposed to GROUP 
BY statements where only the aggregate function is placed in the list of result columns). These components 
are put together with the keyword OVER() as follows:
SELECT regular_field_1, regular_field_2, window_function(regular_field_1) OVER(window_definition)
    FROM….

For example, this is a select statement with: 
•	three regular fields, 
•	one aggregate function (avg) with a partition by window definition (to partition by State),
•	one built-in window function (rank) with a partition by window definition and a window ORDER BY clause
•	one built-in window function (first_value) with a partition by window definition, a window ORDER BY 
    clause, and a window frame definition

SELECT  EmployeeID, Salary, State, 
        AVG(salary) OVER(PARTITION BY State), 
        RANK() OVER(PARTITION BY State ORDER BY salary), 
        first_value(salary) OVER(PARTITION BY State ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
    FROM...

We will go through these concepts one-by-one in the exercises below. If you feel lost then go back to this overview. Additionally,
the following document (https://learnsql.com/blog/sql-window-functions-cheat-sheet/) provides a great summary of the syntax and 
visual of how this works (but this summary document probably makes more sense after a few exercises).

25.2) Exercise: Before we start with windowing, we will create a view that will be used as input into our windowing analyses. 
Use the SalesOrderHeader and the SalesOrderLine tables to create a view with three columns, SalespersonID, ReportingYear, 
and SalesInMillions. Name the view AnnualSalesPersonSales. SalespersonID is salespersonpersonid, sales is calculated at the 
line item level as quantity*unitprice*(1+taxrate/100). The results should show SalesInMillions as total sales in millions 
for each sales person each year rounded to three decimals. Sort the results by SalesPersonID and Year. Exclude sales from 2016 
as the data does not contain transactions for the entire year 2016.*/

DROP VIEW AnnualSalesPersonSales;

CREATE VIEW AnnualSalesPersonSales AS
SELECT  A.salespersonpersonid AS SalespersonID, 
        EXTRACT(year FROM A.OrderDate) AS ReportingYear, 
        round(SUM(B.quantity*B.unitprice*(1+B.taxrate/100)/1000000)::numeric,3) AS SalesInMillions
    FROM salesorderheader AS A
    JOIN salesorderline AS B USING(OrderID)
    WHERE EXTRACT(year FROM A.OrderDate) <> 2016
    GROUP BY SalespersonID, ReportingYear
    ORDER BY SalespersonID, ReportingYear;

/*25.3) As mentioned earlier, to use the window function in a query, an aggregate function or built-in window 
function is added to the list of result columns in the first part of the select statement. This is then followed
followed by the OVER clause:
•  a regular aggregate function (can also have a FILTER clause), for example: 
SELECT field_y, field_x,  SUM(field_z) OVER()
	FROM…
•	a built-in window function (more about these later), for example: 
SELECT field_y, field_x,  rank() OVER(), last_value(field_z) OVER()
	FROM…

Aggregate Function
Exercise: Use an aggregate function together with the over clause to add a column to the previous results 
that shows average annual salesperson sales (calculate the average across all salesperson and year). In 
the results above, 10 employees have sales in three years and the average sales across all years and all 
employees is 5.912 million.  This average should be included in a new field named AverageSales in the result 
set and repeated for each row. Also include a field that calculates the percentage difference between each 
employee’s sales each month and AverageSales. Name this field PercentDiff.*/

SELECT  *, 
        AVG(SalesInMillions) OVER() AS AverageSales, 
        (SalesInMillions - AVG(SalesInMillions) OVER())/AVG(SalesInMillions) OVER() AS PercentDiff
    FROM AnnualSalesPersonSales

/*25.4) Built-in Window Functions
Postgres (and other databases) contains a number of built-in window functions, see table below. These function 
are not only useful when working with typical window problems (e.g., aggregate functions need to be applied at 
a different grouping levels then the level at which the data is displayed, rolling type analyses (including rolling 
averages), but you will also often see solutions to problems using the over clause simply to get access to these 
functions. In other words, they are very useful!  For example, row numbers, finding the value of the previous row, 
finding the value of the first or last value in a group, etc. are all common tasks but difficult to do without 
using windowing.

List of built-in window functions
Function	                Return Type	        Description
row_number()	            bigint	            number of the current row within its partition, counting from 1

rank()	                    bigint	            rank of the current row with gaps; same as row_number of its first peer

dense_rank()	            bigint	            rank of the current row without gaps; this function counts peer groups

percent_rank()	            double precision	relative rank of the current row: (rank - 1) / (total partition rows - 1)

cume_dist()	                double precision	cumulative distribution: (number of partition rows preceding or peer with current row) / total partition rows

ntile(num_buckets integer)  integer	            integer ranging from 1 to the argument value, dividing the partition as equally as possible

lag(field [,offset          same type as field  returns value from field evaluated at the row that is offset rows before the current row
integer [, default]])	                        within the partition; if there is no such row, instead return default (which must 
                                                be of the same type as field). Both offset and default are evaluated with respect to 
                                                the current row. If omitted, offset defaults to 1 and default to null

lead(field [,offset         same type as field  returns value from field evaluated at the row that is offset rows after the current
integer [, default]])	    	                row within the partition; if there is no such row, instead return default (which
                                                must be of the same type as field). Both offset and default are evaluated with respect
                                                to the current row. If omitted, offset defaults to 1 and default to null

first_value(field)	        same type as field	returns value from field evaluated at the row that is the first row of the window frame

last_value(field)	        same type as field	returns value from field evaluated at the row that is the last row of the window frame

nth_value(field, 
nth integer)	            same type as field	returns value from field evaluated at the row that is the nth row of the window frame (counting from 1); null if no such row

Ranking functions: row_number, rank, and dense_rank 
Differences among row_number, rank, and dense_rank. 
In the table below, the data are sorted by power in descending order.  Note that in the column with power ratings, 
there are rows with the same value in the field that was used to sort the data, these are called peers.  In rank, 
peers are assigned the same rank and the number of peers at each level is used to determine the next rank (so we 
cannot have rank 1, 1, and 2). In dense rank, peers are again assigned the same rank, but the next level is simply 
incremented by one and it does not matter how many peers were in the level above.  In row number, each row is incremented
by one regardless of how many peers are in a single level, i.e., peers are assigned different numbers arbitrarily.
Power   Rank    Dense Rank  Row Number
8000      1          1          1
8000      1          1          2
5400      3          2          3
5000      4          3          4
5000      4          3          5
5000      4          3          6
3200      7          4          7
3000      8          5          8
2000      9          6          9
2000      9          6         10
1800     11          7         11


Exercise: Create a query that returns all the columns from AnnualSalesPersonSales and adds two new fields, Prior Sales 
and Sales Diff. Prior Sales should contain the SalesInMillions value from the row above and Sales Diff should show the 
difference between the SalesInMillions values in the current row and the previous row.*/

SELECT  *, 
        lag(SalesInMillions) OVER() AS "Prior Sales", 
        SalesInMillions-lag(SalesInMillions) OVER() AS "Sales Diff"
    FROM AnnualSalesPersonSales;

/*
25.5) WINDOW
Instead of applying the aggregate or built-in function across all rows in a partition, the function can be applied to specific 
window, i.e., specific rows in the partition as identified by a window frame. While the window definition applies to all rows for the
specific column, each row's window can (and typically does) consist of different rows (e.g., all rows in the partition prior to the
current row).  To define the window the following is added inside the OVER clause (add either or both):
•	PARTITION BY, e.g., OVER(PARTITION BY field_1)
•	Frame Specifications, e.g., OVER(RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)

PARTITION BY 
Similarly to GROUP BY, PARTITION BY, is used to define partitions based on unique combiations of values in the fields specified in 
the PARTITION BY statement. When using partition by, the window function is applied to each partition (group) separately.  When partition 
by is not added in the over clause, then all rows is considered to belong to the same partition.

Exercise: Use the AnnualSalesPersonSales view and add a field that shows average annual sales. For example, the average sales 
in 2013 for the 10 employees is 5.397 million (the value 5.397 will be repeated 10 times since the average is the same for all 
employees in 2013). Name this field Average Annual Sales. In your results also include the lag and row difference results from 
the previous query, but partition this by SalesPersonID. Order the results by SalesPersonID and year.
*/

SELECT  *, 
        AVG(SalesInMillions) OVER(PARTITION BY reportingyear) AS AverageAnnualSales, 
        lag(SalesInMillions) OVER(PARTITION BY SalesPersonID) AS "Prior Sales", 
        SalesInMillions-lag(SalesInMillions) OVER(PARTITION BY SalesPersonID) AS "Sales Diff"
    FROM AnnualSalesPersonSales
    ORDER BY SalesPersonID, reportingyear

/*Note that Average Annual Sales is the same for each year across all employees. However, the lagged sales in the result set does 
not make sense. We would expect the first row for each salesperson to be null and year 2014 rows to pull from year 2013 (and 2015 
from 2014). 

25.6) ORDER BY
The odd results is because the order of the rows in each partition is arbitrary, even when the result set itself is sorted.  
This is not a problem only for lag, all the built-in functions depend on the order of that data.  It is therefore important to 
include an ORDER BY clause in the window definition itself when working with built-in functions. When including an ORDER BY clause 
in the window definition, the rows in each window are sorted based on the ORDER BY before the aggregate function or built-in window 
function is applied.  This sorting does not necessarily effect how the rows are presented in the query.

Exercise:
Change the previous query by adding an ORDER BY clause inside each OVER clause.  
- For the average field, sort each reporting year partition by SalesPersonID (since we are taking an average, the sorting of the rows within a given partition should not matter – 
but it does because something else also changes when we sort… we will look at this after we see the results). 
- For the lag and difference fields, order each SalesPersonID partition by ReportingYear.
*/

SELECT  *, 
        AVG(SalesInMillions) OVER(PARTITION BY reportingyear ORDER BY SalesPersonID) AS AverageAnnualSales, 
        lag(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear) AS "Prior Sales", 
        SalesInMillions-lag(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear) AS "Sales Diff"
    FROM AnnualSalesPersonSales
    ORDER BY SalesPersonID, reportingyear

SELECT  *, 
        AVG(SalesInMillions) OVER(PARTITION BY reportingyear ORDER BY SalesPersonID) AS AverageAnnualSales, 
        lag(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear) AS "Prior Sales", 
        SalesInMillions-lag(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear) AS "Sales Diff"
    FROM AnnualSalesPersonSales
    ORDER BY reportingyear, SalesPersonID
/*

The lagged results now behave as we would expect. However, something odd (or perhaps cool) is going on with the average. Note 
that the averages are no longer consistent for each year for different employees. To more easily understand what is going on, 
let’s order the result set by ReportingYear and then SalesPersonID. Note that we now have a rolling (or expanding) average where 
the average is calculated based on the current row and the previous rows within each partition. This is sometimes exactly, but 
other times not at all, what we want – but this is something we control.  We will talk more about this in the next section.

Default Window
The behavior above changed because the default window frame changed when the ORDER BY was added. Note that aggregate functions 
aggregates over the rows within the current row's window frame. When PARTITION BY is used without ORDER BY then all the rows 
within each group is part of the window frame.  However, when ORDER BY is used (which you need to do when working with built-in 
functions), the window frame by default consists of the current row (and all other peers) and all previous rows in the partition:
With ORDER BY --> the frame is RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
Without ORDER BY --> the frame is ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

The window frame also affect the results of first_value, last_value, and nth_value. If the default window frame is used (with 
ORDER BY as we need it because we are working with built-in functions) then last_value will return the value of the current row 
(and nth value will return null unless n is less than the row_number of the current row). 

1)	For aggregate function:
    a)	Do not use ORDER BY (or frame_clause) if you want to apply the aggregate function to the entire partition
    b)	Use ORDER BY (and control the window frame using the frame_clause) if you want moving/rolling type analyses.
2)	For built-in functions
    a)	Always use ORDER BY
    b)	first_value, last_value, and nth_value consider only the rows within the "window frame"
        - if using last_value and nth_value control the window frame using the frame_clause (the default window frame returns expected results when using first_value)

25.7) Frame Clause
To control what rows aggregate functions and first_value, last_value, and nth_value are applied to within a given partition, the 
frame_clause is used. The general structure of the frame_clause:
function_name OVER (PARTITION BY ... ORDER BY ... frame_clause)

where frame_clause:
frame type BETWEEN frame_start [AND frame_end [ frame_exclusion ]]
 
The frame clause consists of:
•	frame type sets the way a database engine treats input rows. There are three possible values: ROWS, GROUPS, and RANGE. 
    o	For ROWS and GROUPS, the size of the window frame is determine by counting individual rows (ROWS) or peer groups (GROUPS) relative to the current row. 
    o	The RANGE frame type is different. RANGE determines the size of the window frame by looking if values are within some range of values relative to the current row. 
•	frame_start - define where a window frame starts 
    o	UNBOUNDED PRECEDING (include all rows before the current row)
    o	n PRECEDING (include n rows, n groups, or all rows with values that are greater than current_row_value - n before the current row) In ROWS and GROUPS, n is an integer. For range, n is of the same type as the ordering column, but for datetime ordering columns, n is an interval (you can define an interval constant using INTERVAL 'n unit', e.g., INTERVAL '5 Months' or INTERVAL '2 Hours).
    o	CURRENT ROW (include no other rows or groups before the current row/group)
•	frame_end  - defines where a window frame ends
    o	CURRENT ROW ()
    o	n FOLLOWING
    o	UNBOUNDED FOLLOWING
•	frame_exclusion - can be used to specify parts of a window frame that have to be excluded from the calculations.
    o	EXCLUDE CURRENT ROW excludes the current row from the frame
    o	EXCLUDE GROUP excludes the current row and its ordering peers from the frame
    o	EXCLUDE TIES excludes any peers of the current row from the frame, but not the current row itself
    o	For numeric ordering columns it is typically of the same type as the ordering column, but for datetime ordering columns it is an interval.

25.8) To get an idea of how these are implemented and how they differ, I have created the following SELECT statement.*/
DROP VIEW MonthlySalesPersonSales;

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

SELECT  SalesPersonID, ReportingYear, ReportingMonth,
        round(AVG(SalesInMillions) OVER()::numeric,3) AS "Average Annual Sales",
        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID)::numeric,3) AS "PARTITION",
        round((AVG(SalesInMillions) OVER SalesPersonYearAndMonthUntilCurrentRow)::numeric,3) AS "P, OB",
        round((AVG(SalesInMillions) OVER SalesPersonYearAndMonthUntilCurrentRow)::numeric,3) AS "P, OB, RUP",
        round((AVG(SalesInMillions) OVER SalesPersonYearAndMonthUntilCurrentRow)::numeric,3) AS "P, OB, RBUPCR",
        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS 3 PRECEDING)::numeric,3) AS "P, OB, R3P",
        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS 3 PRECEDING EXCLUDE CURRENT ROW)::numeric,3) AS "P, OB, R3P, ECR",
        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY TruncMonth RANGE INTERVAL '3 months' PRECEDING)::numeric,3) AS "P, OB, Ra3IP",
        round(AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingMonth RANGE 3 PRECEDING)::numeric, 3) AS "P, OB, Ra3IntP"
    FROM MonthlySalesPersonSales
    WHERE reportingmonth <> 10 AND ReportingYear = 2013
    WINDOW SalesPersonYearAndMonthUntilCurrentRow AS (PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    ORDER BY SalesPersonID, ReportingYear, ReportingMonth;

/*The instructions in word format contain tables with the results with highlighted columns to go with the comments. These tables 
have been removed from this solutions document as the formatting does not work in this document (I still have included one table without
highlightning).  The following comments are listed in sequential order following the order of columns in the result set along with the 
part of the SQL statement that created the result:

(1) (2)    (3)   (4)     (5)     (6)     (7)     (8)     (9)    (10)     (11)    (12)    (13)   
2	2013	1	0.461	0.450	0.459	0.461	0.461	0.461	0.461	null	0.461	0.461
2	2013	2	0.285	0.450	0.459	0.373	0.373	0.373	0.373	0.461	0.373	0.373
2	2013	3	0.399	0.450	0.459	0.382	0.382	0.382	0.382	0.373	0.382	0.382
2	2013	4	0.481	0.450	0.459	0.407	0.407	0.407	0.407	0.382	0.407	0.407
2	2013	5	0.555	0.450	0.459	0.436	0.436	0.436	0.430	0.388	0.430	0.430
2	2013	6	0.439	0.450	0.459	0.437	0.437	0.437	0.469	0.478	0.469	0.469
2	2013	7	0.534	0.450	0.459	0.451	0.451	0.451	0.502	0.492	0.502	0.502
2	2013	8	0.381	0.450	0.459	0.442	0.442	0.442	0.477	0.509	0.477	0.477
2	2013	9	0.537	0.450	0.459	0.452	0.452	0.452	0.473	0.451	0.473	0.473
2	2013	11	0.468	0.450	0.459	0.454	0.454	0.454	0.480	0.484	0.462	0.462
2	2013	12	0.508	0.450	0.459	0.459	0.459	0.459	0.474	0.462	0.504	0.504
3	2013	1	0.561	0.450	0.485	0.561	0.561	0.561	0.561	null	0.561	0.561

1) SalesPersonID
2) ReportingYear
3) ReportingMonth
4) SalesInMillions

5)	AVG(SalesInMillions) OVER() AS "Average Annual Sales"
    Comment: 
    OVER() treats all data as being in one partition and as there is not ORDER BY all rows are in the window frame. 
    This generates of one average of SalesInMillions for the entire table. Notice that SalesPersonID 2 has the same average 
    for all rows and that this is the same as for SalesPersonID 3.

6) AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID) AS "PARTITION",
    Comment: 
    Similar to the previous statement, but the average is calculated for each unique value of SalesPersonID. Notive that 
    SalesPersonID 2 has the same average (shown in the column PARTITION) in all rows and that this is different from 
    SalesPersonID 3 (and different from the average in the Average Annual Sales column). 

7) AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth) AS "P, OB",
    Comment: 
    Groups are still generated for each SalesPersonID, but because of the ORDER BY the average is now an average that is 
    calculated over an expanding window (for each row, the average is calculated based on row values from the beginning 
    of the partition through the current row).

8) AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS UNBOUNDED PRECEDING) AS "P, OB, RUP",
9) AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "P, OB, RBUPCR",
    Comment: 
    These two statements are identical and also identical to the previous statement (P, OB) because the default value for frame_start 
    and frame_end when ORDER BY is included is UNBOUNDED PRECEDING and CURRENT ROW, respectively. 

10) AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS 3 PRECEDING) AS "P, OB, R3P",
    Comment: 
    The window frame in this statement is defined to be three rows above the current row through the current row. Each average is 
    as such calculated using the current row only for the first row in the frame (as there are no earlier rows available), the first 
    and the second row for the second row, the first three rows for the third row, and then the current row and three previous rows 
    for the remaining rows.  
    
11) AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingYear, ReportingMonth ROWS 3 PRECEDING EXCLUDE CURRENT ROW) AS "P, OB, R3P, ECR",
    Comment: 
    This statement differs from the prior average by excluding the current row. So we now get a null value on the first row as there 
    are no prior rows and the current row is excluded. The second row is the average of a single value (the value from the first row), 
    the third row averages the first two rows, and the remaining rows averages the three previous rows.

12) AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY TruncMonth RANGE INTERVAL '3 months' PRECEDING) AS "P, OB, Ra3IP",
    Comment: 
    Here we define a range instead of a fixed number of rows. The range is calculate from the current row and 3 months before. In 
    this statement INTERVAL '3 months' creates an interval constant, which is required for RANGE when ORDER BY sorts by a DATETIME 
    field. Because we selected 3 months and each row is a single month we end up taking averages of three rows as long as there are 
    not months missing.  If a month is missing, e.g., note that in the where clause we used month <> 10, the interval still includes 
    rows from the three prior months (if available) and creates an average. But since one of the prior three months is missing when 
    averaging for rows with month 11 and 12, the average is now only based on two values. This is as opposed to ROW 3 PRECEDING, 
    which pulls the prior three rows no matter what months they are. So in rows and 11 and 12, the averages are based on a row that 
    contains values from 4 months ago.

13) AVG(SalesInMillions) OVER(PARTITION BY SalesPersonID ORDER BY ReportingMonth RANGE 3 PRECEDING) AS "P, OB, Ra3IntP"
    Comment: 
    In this specific query, this statement produces the same results as the previous statement. However, since RANGE only works 
    with one field in the ORDER BY, the results would have been different if we had not used WHERE ReportingYear = 2013. If we 
    had not then ORDER BY ReportingMonth would have sorted month 1 for all years before month 2 for all years, month 2 for all 
    years before month 3 for all years, etc. If we then took the current month, e.g., month 5, and created a range from 5-3 
    through 5, i.e., 2 through 5, we would end up averaging all years months 2, 3, 4, and 5 for rows with month 5. 
  

25.9) Named Window Definitions
Finally, when using windowing functions, the same window (as defined by PARTITION BY, ORDER BY, and frame clause) is often used for multiple fields in a single SELECT statement. To increase readability and reduce the risk of errors, the definition of the window (i.e., what goes inside the over clause), can be named and defined in a separate WINDOW clause. The WINDOW clause, if used, is placed after any HAVING clause and before any ORDER BY and referenced by name in the OVER statement. 
Instead of:
SELECT 	field_y, 
	field_x, 
	function_1_name OVER (PARTITION BY... ORDER BY... frame_clause),
	function_2_name OVER (same window definition as above)
FROM
…
HAVING field… 
ORDER BY field…

We can use:
SELECT 	field_y, 
	field_x, 
	function_1_name OVER WindowName,
	function_2_name OVER WindowName
FROM
…
HAVING filed…
WINDOW WindowName AS (PARTITION BY... ORDER BY... frame_clause)
ORDER BY field…

25.10) Exercise: Create a query that shows information about monthly customer payments for different customer categories. In your output show CustomerCategoryName (from the CustomerCategory table), TruncatedMonth based on PaymentDate (from the Payment table), and the fields below based on PaymentAmount (from the Payment Table). Use name windows when two or more fields have (or can have) them same window definition:
•	Cumulative total for each year and customer category "Running Total - Annual”
•	Percentage difference between current month and the first month in the year for each customer category "Percent change from beginning of year" (the first month does not necessarily have to be January if this data is missing)
•	Cumulative total for each quarter and customer category, name this field "Running Total - Quarterly")
•	3-month total for each customer category. If one (two) month is missing, then the total payments should be calculate based on two (one) months. Name this field "3-Month Total Payments"
•	3-month average payments for each customer category name. If one (two) month is missing then the average should be calculated based on two months (one month). Name this field "Average Monthly Payments (3-Month Moving Average)". 
•	Percentage difference between previous month payment and current month payment (if a month is missing then take the value from 2 months ago, if that is also missing then return null) for each customer category. Name this field, "Percentage Change".*/

WITH MonthlyCustomerCategoryPayments AS (
    SELECT CustomerCategoryName, DATE_TRUNC('Month', PaymentDate) AS TruncatedMonth, SUM(-PaymentAmount) AS MonthlyPaymentAmount
        FROM Payment A
        JOIN CustomerCategoryMembership B USING(CustomerID)
        JOIN CustomerCategory C USING(CustomerCategoryID)
        WHERE EXTRACT(Year FROM PaymentDate) <> 2016
        GROUP BY CustomerCategoryName, DATE_TRUNC('Month', PaymentDate)
        ORDER BY CustomerCategoryName, TruncatedMonth)
    SELECT 
            CustomerCategoryName,
            TruncatedMonth,
            MonthlyPaymentAmount,
            SUM(MonthlyPaymentAmount) OVER CustomerCategoryAndTruncY_OrderByTruncM_TopToCurrent AS "Running Total - Annual",
            (MonthlyPaymentAmount - first_value(MonthlyPaymentAmount) OVER CustomerCategoryAndTruncY_OrderByTruncM_TopToCurrent)/first_value(MonthlyPaymentAmount) OVER CustomerCategoryAndTruncY_OrderByTruncM_TopToCurrent AS "Percent change from beginning of year",
            SUM(MonthlyPaymentAmount) OVER CustomerCategoryAndTruncQ_OrderByTruncM_TopToCurrent AS "Running Total - Quarterly",
            SUM(MonthlyPaymentAmount) OVER CustomerCategory_OrderByTruncM_MinusTwoToCurrent AS "3-Month Total Payments",
            AVG(MonthlyPaymentAmount) OVER CustomerCategory_OrderByTruncM_MinusTwoToCurrent AS "Average Monthly Payments (3-Month Moving Average)"
        FROM MonthlyCustomerCategoryPayments
        WINDOW 
            CustomerCategoryAndTruncY_OrderByTruncM_TopToCurrent AS (PARTITION BY CustomerCategoryName, DATE_TRUNC('Year', TruncatedMonth) ORDER BY TruncatedMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
            CustomerCategoryAndTruncQ_OrderByTruncM_TopToCurrent AS (PARTITION BY CustomerCategoryName, DATE_TRUNC('Quarter', TruncatedMonth) ORDER BY TruncatedMonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
            CustomerCategory_OrderByTruncM_MinusTwoToCurrent AS (PARTITION BY CustomerCategoryName ORDER BY TruncatedMonth RANGE BETWEEN INTERVAL '2 months' PRECEDING AND CURRENT ROW);

/*
26) Strings Functions (and pattern matching using similar)
Overview:
Because we do not have a lot of interesting text data in the database, I decided that we will work on a 
very difficult problem that has no perfect solution - address parsing and address matching! The reason 
why parsing is difficult is that addresses can contain non-standard components and many different combinations 
of standard components.  One reason for matching being difficult is that abbreviation are often used in 
addresses and addresses are often misspelled.  Luckily, the addresses in our data are fairly uniform. 
While you may be able to use a similar approach that we are taking to parse addresses in real life, you 
might instead want do it manually, use an API, another programming language, or a combination of these 
options. However, the learning objective is not to teach you how to parse addresses, but to learn SQL in 
a fun problem that we can all relate to (and that with these caveats, may have a practical application). 

After we have parsed the address, we will compare it to a list of employees to see if an employee address 
matches a supplier address, which could indicate a potential problem (an employee using company funds to 
purchase from him/herself or from another member of the same household). We will actually not be using 
supplier addresses as we have so few, so we will instead use customer addresses (but pretend that these 
are supplier addresses to make the problem more fun). Other similar analyses could be performed to find 
other potential exceptions, e.g., finding ghost employees by comparing a list of departed employees to 
a payroll list. 

To facilitate the matching algorithm, parse out and to standardize things like street direction and street 
prefixes and suffixes. Street names are more difficult to standardize but they can be compared to lists of 
known streets. Alternatively, when matching on street name fuzzy matching can be used to counter misspelled 
or alternative spellings of name. For example, 455 S 8th Ave = 455 S 8th Avenue would return False (and so 
would other combinations like S Eight Ave and South 8th Ave). 

I again want to iterate that while we will do some pretty cool things that might help us even in real life, 
we will get nowhere close to a perfect matching algorithm. You can even improve on what we are doing by 
using the same approaches that we are using, but you should also consider other approaches that were mentioned 
earlier, e.g., manual matching, API, etc.

Before we start, run the SQL code in the Assignment3_Problem2_CreateTables.psql file (see course website). 
This code will create an employee table and a table with standard street suffixes.

26.1) Remove Address with PO Boxes
Filter out all rows in the location table with streetaddressline1 that start with the string 'PO Box'.  
We are assuming that we are not interested in addresses with PO Boxes. Use the function LEFT(string, n) 
and the pattern matching keyword LIKE. Left returns the first n characters from string.  Note that since 
we are not using a wildcard (i.e., _ or %), we do not need to use LIKE, we could just use =. However, 
since we are working with text it seemed appropriate. In your output return streetaddressline2.
*/

SELECT streetaddressline2
    FROM location
    WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'

/*26.2) StreetNumberExtraction
We are next going to extract the street number. In your solution, use a WITH statement and use 
the previous query that removed PO Box addresses as the first temporary view and name it NotPoBox. 
Then use NotPoBox as input into a query that will extract street numbers. Name the field with the 
extracted data StreetNumber and the temporary view StreetNumberExtraction. You can assume that 
the street number is the first component in streetaddressline2 (after the removal of PO BOX addresses) 
before the first space and that this is a number. In addition to extracting street numbers, also 
include the original streetaddressline2 and a field containing all text to the right of the street 
number (use  SUBSTRING and POSITION for this). Name this new field RightOfStreetNumber.

To extract this part of the string use SUBSTRING and POSITION (LEFT would be more natural, but we 
have already been introduce to left. There are also other options, e.g., SPLIT_PART, that can be 
used for this but that I will not cover.):
> SUBSTRING (string, start_position, length)
Returns a substring of string starting at start_position and having length number of characters.

> POSITION(sub_string IN string)
Returns an integer representing the location of sub_string in string. We could also use 
STRPOS(sub_string, string), but it is the same thing as POSITION and while I like the format better 
it is a postgresql extension and might not work with other databases.*/

WITH
    NotPoBox AS(
    SELECT streetaddressline2
        FROM location
        WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'),
    StreetNumberExtraction AS(
    SELECT  streetaddressline2,
            SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2)-1) AS StreetNumber,
            SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2)+1) AS RightOfStreetNumber
        FROM NotPoBox)
    SELECT * FROM StreetNumberExtraction;

/*The first expression uses -1 because POSITION returns the location of the space, but we do not want to 
include the space in the street number. Since we want information to the left of the space, we need to 
remove 1 from the length argument of SUBSTRING to stop the substring before (rather than after) the space. 
The second expression uses +1 because POSITION again finds the location of the space and since we now 
want information to the right of the space, we add 1 to move one step beyond the space.

Locating street number using LEFT:*/
SELECT streetaddressline1, streetaddressline2, LEFT(streetaddressline2, POSITION(' ' in streetaddressline2)) AS StreetNumber
    FROM location;

/*26.3) Validate Street Number
The extracted number should be the street number, but we want to validate that what we extract are numbers. 
Create a new temporary view named StreetNumberCheck to the Common Table Expression. In this query, include a 
field named StreetNumber (it will 'replace' the StreetNumber field that is used as input into this query) 
that is populated with the street number if the street number only contains numbers, otherwise null. Note 
that some RDBMS have utility functions like ISNUMERIC, but postgresql does not have this. In postgresql, 
one way to handle this is to use regex, but I want to wait with regex until later in this tutorial. There 
are, however, two other simpler pattern matching options, LIKE and SIMILAR, that might work:
1)	We have already used LIKE, which matches on exact matches and wildcards % (any character and any 
    number of characters) and _ (any character, but only one). ILIKE works like LIKE but performs a case 
    insensitive match. LIKE, however, is not useful for this specific task.
2)	SIMILAR uses SQL regular expressions, which is a cross between LIKE and REGEX. Just as in LIKE, 
    SIMILAR uses _ and %, but also adds some additional functionality that we can use to check if the string
    only contains numbers:
| denotes alternation (either of two alternatives).
* denotes repetition of the previous item zero or more times.
+ denotes repetition of the previous item one or more times.
? denotes repetition of the previous item zero or one time.
{m} denotes repetition of the previous item exactly m times.
{m,} denotes repetition of the previous item m or more times.
{m,n} denotes repetition of the previous item at least m and not more than n times.
Parentheses () can be used to group items into a single logical item.
Brackets [...] specifies a character class (returns true if any of the items inside the square brackets match).

The following two statements result in the same outcome:*/
SELECT '1' SIMILAR TO '[0-9]' AS Comparison 
SELECT '1' SIMILAR TO '1|2|3|4|5|6|7|8|9|0' AS Comparison 
/*(the parentheses are not needed here since we are only trying to find a single digit)
However, the syntax above only work for checking a single character. To check for one or more characters + is added:
*/
SELECT '1459' SIMILAR TO '[0-9]+' AS Comparison; 

/*However, the following does not work as it only checks for one character of 1-9 or one or more of 
character 0, i.e., the + only applies to the last element, the 0:*/
SELECT '145' SIMILAR TO '1|2|3|4|5|6|7|8|9|0+'

/*To fix this we need to group the items together by placing the expression inside parentheses:*/
SELECT '145' SIMILAR TO '(1|2|3|4|5|6|7|8|9|0)+'
*/

WITH
    NotPoBox AS(
    SELECT streetaddressline2
        FROM location
        WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'),
    StreetNumberExtraction AS(
    SELECT  streetaddressline2,
            SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2)-1) AS StreetNumber,
            SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2)+1) AS RightOfStreetNumber
        FROM NotPoBox),
    StreetNumberCheck AS(
    SELECT *, 
            CASE WHEN StreetNumber SIMILAR TO '[0-9]+'
            THEN streetnumber
            ELSE NULL 
            END AS StreetNumber
        FROM StreetNumberExtraction)
 
    SELECT * FROM StreetNumberCheck;

/*
26.4) Extract Street Suffix
Next, we are going to extract the street suffix (e.g., street, road, etc.). We are going to assume it 
is one word and it is the last word in the string. Add another temporary view named StreetSuffixExtraction 
to the Common Table Expression that extracts the last word in the RightOfStreetNumber field. There is no 
function in postgres to search for substrings from the right (regex could be used to locate the last 
occurrence of a space or the text to the right of the last occurrence of a space, but I still want to wait 
a little longer before we look at regex).  However, postgres has a function called REVERSE that reverses 
the order of the characters in a string. Use this function along with RIGHT(string, n) and POSITION to 
extract all characters to the right of the last space. Name this new field StreetSuffix.

Westridge Blue Rd
dR eulB .....
*/
WITH 
    NotPoBox AS(
    SELECT  streetaddressline2
        FROM location
        WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'),
    StreetNumberExtraction AS(
    SELECT  streetaddressline2, 
            SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2)-1) AS StreetNumber, -- The position returns the location of the space, we do not want to include the space in the street number so we remove 1 from the length to stop pulling characters before (not including) the space
            SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2)+1) AS RightOfStreetNumber --We again do not want to include the space, so we add one to the startlocation to move one step beyond the space
        FROM NotPoBox),
    StreetNumberCheck AS(
    SELECT  *, 
            CASE WHEN StreetNumber SIMILAR TO '[0-9]+' 
                THEN  StreetNumber 
                ELSE NULL 
            END AS CheckedStreetNumber
        FROM StreetNumberExtraction),
    StreetSuffixExtraction AS(
    SELECT  *,
            RIGHT(RightOfStreetNumber, POSITION(' ' IN REVERSE(RightOfStreetNumber))-1) AS StreetSuffix
        FROM StreetNumberCheck)
    SELECT * FROM StreetSuffixExtraction
/*

26.5) Validate Street Suffix 
Now validate the extracted street suffix. We will first run SQL code to created 
a table, StreetSuffixMapping. This table contains valid street suffixes and standard codes for the same 
(or very similar) suffixes that are just spelled differently, e.g., st vs street. The various potential 
spellings are located in a field called Written and the Standard suffixes are in a field called Standard. 
For example:
Written		Standard
St		      ST
Street		  ST

*/
CREATE TABLE StreetSuffixMapping (
    Written text,
    Standard text
);

INSERT INTO StreetSuffixMapping(Written, Standard) VALUES 
 ('ALLEE', 'ALY'),
 ('ALLEY', 'ALY'),
 ('ALLY', 'ALY'),
 ('ALY', 'ALY'),
 ('ANEX', 'ANX'),
 ('ANNEX', 'ANX'),
 ('ANNX', 'ANX'),
 ('ANX', 'ANX'),
 ('ARC', 'ARC'),
 ('ARCADE', 'ARC'),
 ('AV', 'AVE'),
 ('AVE', 'AVE'),
 ('AVEN', 'AVE'),
 ('AVENU', 'AVE'),
 ('AVENUE', 'AVE'),
 ('AVN', 'AVE'),
 ('AVNUE', 'AVE'),
 ('BAYOO', 'BYU'),
 ('BAYOU', 'BYU'),
 ('BCH', 'BCH'),
 ('BEACH', 'BCH'),
 ('BEND', 'BND'),
 ('BND', 'BND'),
 ('BLF', 'BLF'),
 ('BLUF', 'BLF'),
 ('BLUFF', 'BLF'),
 ('BLUFFS', 'BLF'),
 ('BOT', 'BTM'),
 ('BTM', 'BTM'),
 ('BOTTM', 'BTM'),
 ('BOTTOM', 'BTM'),
 ('BLVD', 'BLVD'),
 ('BOUL', 'BLVD'),
 ('BOULEVARD', 'BLVD'),
 ('BOULV', 'BLVD'),
 ('BR', 'BR'),
 ('BRNCH', 'BR'),
 ('BRANCH', 'BR'),
 ('BRDGE', 'BRG'),
 ('BRG', 'BRG'),
 ('BRIDGE', 'BRG'),
 ('BRK', 'BRK'),
 ('BROOK', 'BRK'),
 ('BROOKS', 'BRK'),
 ('BURG', 'BG'),
 ('BURGS', 'BG'),
 ('BYP', 'BYP'),
 ('BYPA', 'BYP'),
 ('BYPAS', 'BYP'),
 ('BYPASS', 'BYP'),
 ('BYPS', 'BYP'),
 ('CAMP', 'CP'),
 ('CP', 'CP'),
 ('CMP', 'CP'),
 ('CANYN', 'CYN'),
 ('CANYON', 'CYN'),
 ('CNYN', 'CYN'),
 ('CAPE', 'CPE'),
 ('CPE', 'CPE'),
 ('CAUSEWAY', 'CSWY'),
 ('CAUSWA', 'CSWY'),
 ('CSWY', 'CSWY'),
 ('CEN', 'CTR'),
 ('CENT', 'CTR'),
 ('CENTER', 'CTR'),
 ('CENTR', 'CTR'),
 ('CENTRE', 'CTR'),
 ('CNTER', 'CTR'),
 ('CNTR', 'CTR'),
 ('CTR', 'CTR'),
 ('CENTERS', 'CTR'),
 ('CIR', 'CIR'),
 ('CIRC', 'CIR'),
 ('CIRCL', 'CIR'),
 ('CIRCLE', 'CIR'),
 ('CRCL', 'CIR'),
 ('CRCLE', 'CIR'),
 ('CIRCLES', 'CIR'),
 ('CLF', 'CLF'),
 ('CLIFF', 'CLF'),
 ('CLFS', 'CLF'),
 ('CLIFFS', 'CLF'),
 ('CLB', 'CLB'),
 ('CLUB', 'CLB'),
 ('COMMON', 'CMN'),
 ('COMMONS', 'CMN'),
 ('COR', 'COR'),
 ('CORNER', 'COR'),
 ('CORNERS', 'COR'),
 ('CORS', 'CORS'),
 ('COURSE', 'CORS'),
 ('CRSE', 'CRSE'),
 ('COURT', 'CT'),
 ('CT', 'CT'),
 ('COURTS', 'CTS'),
 ('CTS', 'CTS'),
 ('COVE', 'CV'),
 ('CV', 'CV'),
 ('COVES', 'CV'),
 ('CREEK', 'CRK'),
 ('CRK', 'CRK'),
 ('CRESCENT', 'CRES'),
 ('CRES', 'CRES'),
 ('CRSENT', 'CRES'),
 ('CRSNT', 'CRES'),
 ('CREST', 'CRST'),
 ('CRST', 'CRST'),
 ('CROSSING', 'XING'),
 ('CRSSNG', 'XING'),
 ('XING', 'XING'),
 ('CROSSROAD', 'XRD'),
 ('CROSSROADS', 'XRD'),
 ('CURVE', 'CURV'),
 ('DALE', 'DL'),
 ('DL', 'DL'),
 ('DAM', 'DM'),
 ('DM', 'DM'),
 ('DIV', 'DV'),
 ('DIVIDE', 'DV'),
 ('DV', 'DV'),
 ('DVD', 'DV'),
 ('DR', 'DR'),
 ('DRIV', 'DR'),
 ('DRIVE', 'DR'),
 ('DRV', 'DR'),
 ('DRIVES', 'DR'),
 ('EST', 'EST'),
 ('ESTATE', 'EST'),
 ('ESTATES', 'EST'),
 ('ESTS', 'ESTS'),
 ('EXP', 'EXPY'),
 ('EXPR', 'EXPY'),
 ('EXPRESS', 'EXPY'),
 ('EXPRESSWAY', 'EXPY'),
 ('EXPW', 'EXPY'),
 ('EXPY', 'EXPY'),
 ('EXT', 'EXT'),
 ('EXTENSION', 'EXT'),
 ('EXTN', 'EXT'),
 ('EXTNSN', 'EXT'),
 ('EXTS', 'EXT'),
 ('FALL', 'FALL'),
 ('FALLS', 'FALL'),
 ('FLS', 'FALL'),
 ('FERRY', 'FRY'),
 ('FRRY', 'FRY'),
 ('FRY', 'FRY'),
 ('FIELD', 'FLD'),
 ('FLD', 'FLD'),
 ('FIELDS', 'FLD'),
 ('FLDS', 'FLD'),
 ('FLAT', 'FLT'),
 ('FLT', 'FLT'),
 ('FLATS', 'FLT'),
 ('FLTS', 'FLT'),
 ('FORD', 'FRD'),
 ('FRD', 'FRD'),
 ('FORDS', 'FRD'),
 ('FOREST', 'FRST'),
 ('FORESTS', 'FRST'),
 ('FRST', 'FRST'),
 ('FORG', 'FRG'),
 ('FORGE', 'FRG'),
 ('FRG', 'FRG'),
 ('FORGES', 'FRG'),
 ('FORK', 'FRK'),
 ('FRK', 'FRK'),
 ('FORKS', 'FRK'),
 ('FRKS', 'FRK'),
 ('FORT', 'FT'),
 ('FRT', 'FT'),
 ('FT', 'FT'),
 ('FREEWAY', 'FWY'),
 ('FREEWY', 'FWY'),
 ('FRWAY', 'FWY'),
 ('FRWY', 'FWY'),
 ('FWY', 'FWY'),
 ('GARDEN', 'GDN'),
 ('GARDN', 'GDN'),
 ('GRDEN', 'GDN'),
 ('GRDN', 'GDN'),
 ('GARDENS', 'GDN'),
 ('GDNS', 'GDN'),
 ('GRDNS', 'GDN'),
 ('GATEWAY', 'GTWY'),
 ('GATEWY', 'GTWY'),
 ('GATWAY', 'GTWY'),
 ('GTWAY', 'GTWY'),
 ('GTWY', 'GTWY'),
 ('GLEN', 'GLN'),
 ('GLN', 'GLN'),
 ('GLENS', 'GLN'),
 ('GREEN', 'GRN'),
 ('GRN', 'GRN'),
 ('GREENS', 'GRN'),
 ('GROV', 'GRV'),
 ('GROVE', 'GRV'),
 ('GRV', 'GRV'),
 ('GROVES', 'GRV'),
 ('HARB', 'HBR'),
 ('HARBOR', 'HBR'),
 ('HARBR', 'HBR'),
 ('HBR', 'HBR'),
 ('HRBOR', 'HBR'),
 ('HARBORS', 'HBR'),
 ('HAVEN', 'HVN'),
 ('HVN', 'HVN'),
 ('HT', 'HTS'),
 ('HTS', 'HTS'),
 ('HIGHWAY', 'HWY'),
 ('HIGHWY', 'HWY'),
 ('HIWAY', 'HWY'),
 ('HIWY', 'HWY'),
 ('HWAY', 'HWY'),
 ('HWY', 'HWY'),
 ('HILL', 'HL'),
 ('HL', 'HL'),
 ('HILLS', 'HL'),
 ('HLS', 'HL'),
 ('HLLW', 'HOLW'),
 ('HOLLOW', 'HOLW'),
 ('HOLLOWS', 'HOLW'),
 ('HOLW', 'HOLW'),
 ('HOLWS', 'HOLW'),
 ('INLT', 'INLT'),
 ('IS', 'IS'),
 ('ISLAND', 'IS'),
 ('ISLND', 'IS'),
 ('ISLANDS', 'IS'),
 ('ISLNDS', 'IS'),
 ('ISS', 'ISLE'),
 ('ISLE', 'ISLE'),
 ('ISLES', 'ISLE'),
 ('JCT', 'JCT'),
 ('JCTION', 'JCT'),
 ('JCTN', 'JCT'),
 ('JUNCTION', 'JCT'),
 ('JUNCTN', 'JCT'),
 ('JUNCTON', 'JCT'),
 ('JCTNS', 'JCT'),
 ('JCTS', 'JCT'),
 ('JUNCTIONS', 'JCT'),
 ('KEY', 'KY'),
 ('KY', 'KY'),
 ('KEYS', 'KY'),
 ('KYS', 'KY'),
 ('KNL', 'KNL'),
 ('KNOL', 'KNL'),
 ('KNOLL', 'KNL'),
 ('KNLS', 'KNL'),
 ('KNOLLS', 'KNL'),
 ('LK', 'LK'),
 ('LAKE', 'LK'),
 ('LKS', 'LK'),
 ('LAKES', 'LK'),
 ('LAND', 'LAND'),
 ('LANDING', 'LNDG'),
 ('LNDG', 'LNDG'),
 ('LNDNG', 'LNDG'),
 ('LANE', 'LN'),
 ('LN', 'LN'),
 ('LGT', 'LGT'),
 ('LIGHT', 'LGT'),
 ('LIGHTS', 'LGT'),
 ('LF', 'LF'),
 ('LOAF', 'LF'),
 ('LCK', 'LCK'),
 ('LOCK', 'LCK'),
 ('LCKS', 'LCK'),
 ('LOCKS', 'LCK'),
 ('LDG', 'LDG'),
 ('LDGE', 'LDG'),
 ('LODG', 'LDG'),
 ('LODGE', 'LDG'),
 ('LOOP', 'LOOP'),
 ('LOOPS', 'LOOP'),
 ('MALL', 'MALL'),
 ('MNR', 'MNR'),
 ('MANOR', 'MNR'),
 ('MANORS', 'MNR'),
 ('MNRS', 'MNR'),
 ('MEADOW', 'MDW'),
 ('MDW', 'MDW'),
 ('MDWS', 'MDW'),
 ('MEADOWS', 'MDW'),
 ('MEDOWS', 'MDW'),
 ('MEWS', 'MEWS'),
 ('MILL', 'ML'),
 ('MILLS', 'ML'),
 ('MISSN', 'MSN'),
 ('MSSN', 'MSN'),
 ('MOTORWAY', 'MSN'),
 ('MNT', 'MT'),
 ('MT', 'MT'),
 ('MOUNT', 'MT'),
 ('MNTAIN', 'MT'),
 ('MNTN', 'MT'),
 ('MOUNTAIN', 'MT'),
 ('MOUNTIN', 'MT'),
 ('MTIN', 'MT'),
 ('MTN', 'MT'),
 ('MNTNS', 'MT'),
 ('MOUNTAINS', 'MT'),
 ('NCK', 'NCK'),
 ('NECK', 'NCK'),
 ('ORCH', 'ORCH'),
 ('ORCHARD', 'ORCH'),
 ('ORCHRD', 'ORCH'),
 ('OVAL', 'OVAL'),
 ('OVL', 'OVAL'),
 ('OVERPASS', 'OPAS'),
 ('PARK', 'PARK'),
 ('PRK', 'PARK'),
 ('PARKS', 'PARK'),
 ('PARKWAY', 'PKWY'),
 ('PARKWY', 'PKWY'),
 ('PKWAY', 'PKWY'),
 ('PKWY', 'PKWY'),
 ('PKY', 'PKWY'),
 ('PARKWAYS', 'PKWY'),
 ('PKWYS', 'PKWY'),
 ('PASS', 'PASS'),
 ('PASSAGE', 'PSGE'),
 ('PATH', 'PATH'),
 ('PATHS', 'PATH'),
 ('PIKE', 'PIKE'),
 ('PIKES', 'PIKE'),
 ('PINE', 'PNE'),
 ('PINES', 'PNE'),
 ('PNES', 'PNE'),
 ('PLACE', 'PL'),
 ('PL', 'PL'),
 ('PLAIN', 'PLNS'),
 ('PLN', 'PLNS'),
 ('PLAINS', 'PLNS'),
 ('PLNS', 'PLNS'),
 ('PLAZA', 'PLZ'),
 ('PLZ', 'PLZ'),
 ('PLZA', 'PLZ'),
 ('POINT', 'PT'),
 ('PT', 'PT'),
 ('POINTS', 'PT'),
 ('PTS', 'PT'),
 ('PORT', 'PRT'),
 ('PRT', 'PRT'),
 ('PORTS', 'PRT'),
 ('PRTS', 'PRT'),
 ('PR', 'PR'),
 ('PRAIRIE', 'PR'),
 ('PRR', 'PR'),
 ('RAD', 'RADL'),
 ('RADIAL', 'RADL'),
 ('RADIEL', 'RADL'),
 ('RADL', 'RADL'),
 ('RAMP', 'RAMP'),
 ('RANCH', 'RNCH'),
 ('RANCHES', 'RNCH'),
 ('RNCH', 'RNCH'),
 ('RNCHS', 'RNCH'),
 ('RAPID', 'RPD'),
 ('RPD', 'RPD'),
 ('RAPIDS', 'RPD'),
 ('RPDS', 'RPD'),
 ('REST', 'RST'),
 ('RST', 'RST'),
 ('RDG', 'RDG'),
 ('RDGE', 'RDG'),
 ('RIDGE', 'RDG'),
 ('RDGS', 'RDG'),
 ('RIDGES', 'RDG'),
 ('RIV', 'RIV'),
 ('RIVER', 'RIV'),
 ('RVR', 'RIV'),
 ('RIVR', 'RIV'),
 ('RD', 'RD'),
 ('ROAD', 'RD'),
 ('ROADS', 'RD'),
 ('RDS', 'RD'),
 ('ROUTE', 'RTE'),
 ('ROW', 'ROW'),
 ('RUE', 'RUE'),
 ('RUN', 'RUN'),
 ('SHL', 'SHL'),
 ('SHOAL', 'SHL'),
 ('SHLS', 'SHL'),
 ('SHOALS', 'SHL'),
 ('SHOAR', 'SHR'),
 ('SHORE', 'SHR'),
 ('SHR', 'SHR'),
 ('SHOARS', 'SHR'),
 ('SHORES', 'SHR'),
 ('SHRS', 'SHR'),
 ('SKYWAY', 'SKWY'),
 ('SPG', 'SPG'),
 ('SPNG', 'SPG'),
 ('SPRING', 'SPG'),
 ('SPRNG', 'SPG'),
 ('SPGS', 'SPG'),
 ('SPNGS', 'SPG'),
 ('SPRINGS', 'SPG'),
 ('SPRNGS', 'SPG'),
 ('SPUR', 'SPUR'),
 ('SPURS', 'SPUR'),
 ('SQ', 'SQ'),
 ('SQR', 'SQ'),
 ('SQRE', 'SQ'),
 ('SQU', 'SQ'),
 ('SQUARE', 'SQ'),
 ('SQRS', 'SQ'),
 ('SQUARES', 'SQ'),
 ('STA', 'STA'),
 ('STATION', 'STA'),
 ('STATN', 'STA'),
 ('STN', 'STA'),
 ('STRA', 'STRA'),
 ('STRAV', 'STRA'),
 ('STRAVEN', 'STRA'),
 ('STRAVENUE', 'STRA'),
 ('STRAVN', 'STRA'),
 ('STRVN', 'STRA'),
 ('STRVNUE', 'STRA'),
 ('STREAM', 'STRM'),
 ('STREME', 'STRM'),
 ('STRM', 'STRM'),
 ('STREET', 'ST'),
 ('STRT', 'ST'),
 ('ST', 'ST'),
 ('STR', 'ST'),
 ('STREETS', 'ST'),
 ('SMT', 'SMT'),
 ('SUMIT', 'SMT'),
 ('SUMITT', 'SMT'),
 ('SUMMIT', 'SMT'),
 ('TER', 'TER'),
 ('TERR', 'TER'),
 ('TERRACE', 'TER'),
 ('THROUGHWAY', 'TRWY'),
 ('TRACE', 'TRCE'),
 ('TRACES', 'TRCE'),
 ('TRCE', 'TRCE'),
 ('TRACK', 'TRAK'),
 ('TRACKS', 'TRAK'),
 ('TRAK', 'TRAK'),
 ('TRK', 'TRAK'),
 ('TRKS', 'TRAK'),
 ('TRAFFICWAY', 'TRFY'),
 ('TRAIL', 'TRL'),
 ('TRAILS', 'TRL'),
 ('TRL', 'TRL'),
 ('TRLS', 'TRL'),
 ('TRAILER', 'TRL'),
 ('TRLR', 'TRLR'),
 ('TRLRS', 'TRLR'),
 ('TUNEL', 'TUNL'),
 ('TUNL', 'TUNL'),
 ('TUNLS', 'TUNL'),
 ('TUNNEL', 'TUNL'),
 ('TUNNELS', 'TUNL'),
 ('TUNNL', 'TUNL'),
 ('TRNPK', 'TPKE'),
 ('TURNPIKE', 'TPKE'),
 ('TURNPK', 'TPKE'),
 ('UNDERPASS', 'UPAS'),
 ('UN', 'UN'),
 ('UNION', 'UN'),
 ('UNIONS', 'UN'),
 ('VALLEY', 'VLY'),
 ('VALLY', 'VLY'),
 ('VLLY', 'VLY'),
 ('VLY', 'VLY'),
 ('VALLEYS', 'VLY'),
 ('VLYS', 'VLY'),
 ('VDCT', 'VIA'),
 ('VIA', 'VIA'),
 ('VIADCT', 'VIA'),
 ('VIADUCT', 'VIA'),
 ('VIEW', 'VW'),
 ('VW', 'VW'),
 ('VIEWS', 'VW'),
 ('VWS', 'VW'),
 ('VILL', 'VLG'),
 ('VILLAG', 'VLG'),
 ('VILLAGE', 'VLG'),
 ('VILLG', 'VLG'),
 ('VILLIAGE', 'VLG'),
 ('VLG', 'VLG'),
 ('VILLAGES', 'VLG'),
 ('VLGS', 'VLG'),
 ('VILLE', 'VL'),
 ('VL', 'VL'),
 ('VIS', 'VIS'),
 ('VIST', 'VIS'),
 ('VISTA', 'VIS'),
 ('VST', 'VIS'),
 ('VSTA', 'VIS'),
 ('WALK', 'WALK'),
 ('WALKS', 'WALK'),
 ('WALL', 'WALL'),
 ('WY', 'WAY'),
 ('WAY', 'WAY'),
 ('WAY', 'WAY'),
 ('WAYS', 'WAY'),
 ('WL', 'WL'),
 ('WELL', 'WL'),
 ('WELLS', 'WL'),
 ('WLS', 'WLS');

/*Add another temporary view named StreetSuffixCheck to the CTE that validates that the field StreetSuffix 
has a matching value in the Written column in StreetSuffixMapping. If the extracted suffix is located in 
the written column then it is considered 
to be a valid suffix. For valid StreetSuffix values, include the corresponding standard value (i.e., the 
value from Standard in StreetSuffixMapping) in a new field named Standard. If there is not match then 
populate this field with a null value for that row. The standard values will help improve matching 
addresses later. In this SELECT statement also include a new field named StreetName that contains all 
the text between the street number and the street suffix.
*/

WITH 
    NotPoBox AS(
    SELECT  streetaddressline2
        FROM location
        WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'),
    StreetNumberExtraction AS(
    SELECT  streetaddressline2, 
            SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2)-1) AS StreetNumber, -- The position returns the location of the space, we do not want to include the space in the street number so we remove 1 from the length to stop pulling characters before (not including) the space
            SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2)+1) AS RightOfStreetNumber --We again do not want to include the space, so we add one to the startlocation to move one step beyond the space
        FROM NotPoBox),
    StreetNumberCheck AS(
    SELECT  *, 
            CASE WHEN StreetNumber SIMILAR TO '[0-9]+' 
                THEN  StreetNumber 
                ELSE NULL 
            END AS CheckedStreetNumber
        FROM StreetNumberExtraction),
    StreetSuffixExtraction AS(
    SELECT  *,
            RIGHT(rightofstreetnumber, POSITION(' ' IN REVERSE(rightofstreetnumber))-1) AS StreetSuffix
        FROM StreetNumberCheck),
    StreetSuffixCheck AS (
    SELECT  *,
            Standard,
            LEFT(rightofstreetnumber, LENGTH(rightofstreetnumber)-LENGTH(streetsuffix)-1) AS StreetName
        FROM StreetSuffixExtraction A
        LEFT JOIN StreetSuffixMapping B
            ON UPPER(A.StreetSuffix)=B.Written
    )
    SELECT * FROM StreetSuffixCheck
/*

Matching (Including Fuzzy String Matching)
Before we can perform the matching described at the beginning of the problem we need to create an 
table, employee_table, with employee addresses.*/
CREATE TABLE IF NOT EXISTS employee_table (
    FirstName TEXT,
    LastName TEXT,
    company_name TEXT,
    StreetNumber INT,
    StreetName TEXT,
    StreetSuffix TEXT,
    city TEXT,
    county TEXT,
    state TEXT,
    zip INT,
    phone1 TEXT,
    phone2 TEXT,
    Jobcat INT,
    Salary INT,
    Job_Time INT
);

INSERT INTO employee_table VALUES
    ('James','Bar','Benton, John B Jr',6,'Harvey Milk ','St','New Orleans','Orleans','LA',70116,'504-621-8927','504-845-1427',3,93700,26),
    ('Josephine','Darakjy','Chanay, Jeffrey A Esq',808,'Tilden ','St','Brighton','Livingston','MI',48116,'810-292-9388','810-374-9840',9,65600,54),
    ('Art','Venere','Chemel, James L Cpa',952,'Golden Haven ','Dr','Bridgeport','Gloucester','NJ',8014,'856-636-8749','856-264-4130',8,112200,65),
    ('Lenna','Paprocki','Feltz Printing Service',502,'Penford ','Ct','Anchorage','Anchorage','AK',99501,'907-385-4412','907-921-2010',7,60000,10),
    ('Donette','Foller','Printing Dimensions',4039,'Arce ','Ct','Hamilton','Butler','OH',45011,'513-570-1893','513-549-4561',8,96100,50),
    ('Simona','Morasca','Chapman, Ross E Esq',48,'Jane ','St','Ashland','Ashland','OH',44805,'419-503-2484','419-800-6759',2,118300,114),
    ('Mitsue','Tollner','Morlong Associates',8533,'Acorn ','St','Chicago','Cook','IL',60632,'773-573-6914','773-924-8565',5,88300,90),
    ('Leota','Dilliard','Commercial Press',61,'Vista Del Agua ','Way','San Jose','Santa Clara','CA',95111,'408-752-3500','408-813-1105',3,85000,28),
    ('Sage','Wieser','Truhlar And Truhlar Attys',7114,'Market ','St','Sioux Falls','Minnehaha','SD',57105,'605-414-2147','605-794-4895',5,48400,67),
    ('Kris','Marrier','King, Christopher A Esq',4811,'Elm ','St','Baltimore','Baltimore City','MD',21224,'410-655-8723','410-804-4694',7,47200,86),
    ('Minna','Amigon','Dorl, James J Esq',48,'Aero ','Dr','Kulpsville','Montgomery','PA',19443,'215-874-1229','215-422-8694',12,56000,46),
    ('Kiley','Caldarera','Feiner Bros',5886,'Gobat ','Ave','Los Angeles','Los Angeles','CA',90034,'310-498-5651','310-254-3084',12,141000,4),
    ('Graciela','Ruta','Buckley Miller & Wright',3581,'Ocean Ridge ','Way','Chagrin Falls','Geauga','OH',44023,'440-780-8425','440-579-7763',6,92600,36),
    ('Cammy','Albares','Rousseaux, Michael Esq',7481,'Vinaruz ','Pl','Laredo','Webb','TX',78045,'956-537-6195','956-841-7216',4,56100,220),
    ('Mattie','Poquette','Century Communications',47,'Arequipa ','St','Phoenix','Maricopa','AZ',85013,'602-277-4385','602-953-6360',7,70700,81),
    ('Meaghan','Garufi','Bolton, Wilbur Esq',277,'Corsini ','Cir','Mc Minnville','Warren','TN',37110,'931-313-9635','931-235-7959',3,123700,82),
    ('Gladys','Rim','T M Byxbee Company Pc',281,'Joshua ','Pl','Milwaukee','Milwaukee','WI',53207,'414-661-9598','414-377-2880',12,89200,49),
    ('Yuki','Whobrey','Farmers Insurance Group',7472,'Borego ','St','Taylor','Wayne','MI',48180,'313-288-7937','313-341-4470',4,63700,25),
    ('Fletcher','Flosi','Post Box Services Plus',736,'Sabina ','Dr','Rockford','Winnebago','IL',61109,'815-828-2147','815-426-5657',10,71700,8),
    ('Bette','Nicka','Sport En Art',2278,'Rolling Meadows ','Ct','Aston','Delaware','PA',19014,'610-545-3615','610-492-4643',6,75500,2),
    ('Veronika','Inouye','C 4 Network Inc',69,'Normal ','St','San Jose','Santa Clara','CA',95111,'408-540-1785','408-813-4592',7,154700,63),
    ('Willard','Kolmetz','Ingalls, Donald R Esq',8,'Pabellon ','Ct','Irving','Dallas','TX',75062,'972-303-9197','972-896-4882',14,71000,11),
    ('Maryann','Royster','Franklin, Peter L Esq',98,'Atwater ','St','Albany','Albany','NY',12204,'518-966-7987','518-448-8982',5,82600,42),
    ('Alisha','Slusarski','Wtlz Power 107 Fm',26,'Capehart ','St','Middlesex','Middlesex','NJ',8846,'732-658-3154','732-635-3453',5,61300,78),
    ('Allene','Iturbide','Ledecky, David Esq',583,'Foothill ','Blvd','Stevens Point','Portage','WI',54481,'715-662-6764','715-530-9863',9,61400,93),
    ('Chanel','Caudy','Professional Image Inc',52,'Pasternack ','Pl','Shawnee','Johnson','KS',66218,'913-388-2079','913-899-1103',5,86400,10),
    ('Ezekiel','Chui','Sider, Donald C Esq',462,'Dale Grove ','Ln','Easton','Talbot','MD',21601,'410-669-1642','410-235-8738',1,59900,52),
    ('Willow','Kusko','U Pull It',94,'Harbor ','Dr','New York','New York','NY',10011,'212-582-4976','212-934-5167',10,52900,79),
    ('Bernardo','Figeroa','Clark, Richard Cpa',691,'Del Sol ','Ln','Conroe','Montgomery','TX',77301,'936-336-3951','936-597-3614',2,49900,59),
    ('Ammie','Corrio','Moskowitz, Barry S',9,'Marker ','Rd','Columbus','Franklin','OH',43215,'614-801-9788','614-648-3265',6,89600,88),
    ('Francine','Vocelka','Cascade Realty Advisors Inc',197,'Park Vista ','Ct','Las Cruces','Dona Ana','NM',88011,'505-977-3911','505-335-5293',11,47400,93),
    ('Ernie','Stenseth','Knwz Newsradio',2061,'Wittman ','Way','Ridgefield Park','Bergen','NJ',7660,'201-709-6245','201-387-9093',13,91700,170),
    ('Albina','Glick','Giampetro, Anthony D',55,'Moore ','St','Dunellen','Middlesex','NJ',8812,'732-924-7882','732-782-6701',2,54100,90),
    ('Alishia','Sergi','Milford Enterprises Inc',92,'Aquila ','Ave','New York','New York','NY',10025,'212-860-1579','212-753-2740',15,92100,64),
    ('Solange','Shinko','Mosocco, Ronald A',27,'Gallegos ','Ct','Metairie','Jefferson','LA',70002,'504-979-9175','504-265-8174',10,84100,46),
    ('Jose','Stockham','Tri State Refueler Co',166,'Samantha ','Ct','New York','New York','NY',10011,'212-675-8570','212-569-4233',11,77700,39),
    ('Rozella','Ostrosky','Parkway Company',504,'Palm ','Ave','Camarillo','Ventura','CA',93012,'805-832-6163','805-609-1531',15,54000,58),
    ('Valentine','Gillian','Fbs Business Finance',135,'Upper Hillside ','Dr','San Antonio','Bexar','TX',78204,'210-812-9597','210-300-6244',3,114700,166),
    ('Kati','Rulapaugh','Eder Assocs Consltng Engrs Pc',84,'Flores ','Rd','Abilene','Dickinson','KS',67410,'785-463-7829','785-219-7724',4,73800,83),
    ('Youlanda','Schemmer','Tri M Tool Inc',7717,'Horton ','Ave','Prineville','Crook','OR',97754,'541-548-8197','541-993-2611',4,70900,16),
    ('Dyan','Oldroyd','International Eyelets Inc',811,'Bernadine ','Pl','Overland Park','Johnson','KS',66204,'913-413-4604','913-645-8918',14,50500,15),
    ('Roxane','Campain','Rapid Trading Intl',91,'Mott ','St','Fairbanks','Fairbanks North Star','AK',99708,'907-231-4722','907-335-6568',9,71400,70),
    ('Lavera','Perin','Abc Enterprises Inc',86,'Harbor ','Dr','Miami','Miami-Dade','FL',33196,'305-606-7291','305-995-2078',11,97200,60),
    ('Erick','Ferencz','Cindy Turner Associates',5978,'Allew ','Way','Fairbanks','Fairbanks North Star','AK',99712,'907-741-1044','907-227-6777',9,90800,1),
    ('Fatima','Saylors','Stanton, James D Esq',493,'Cajon ','Way','Hopkins','Hennepin','MN',55343,'952-768-2416','952-479-2375',14,84700,69),
    ('Jina','Briddick','Grace Pastries Inc',26,'Eads ','Ave','Boston','Suffolk','MA',2128,'617-399-5124','617-997-5771',8,55400,68),
    ('Kanisha','Waycott','Schroer, Gene E Esq',3535,'Playa Solana ','Pl','Los Angeles','Los Angeles','CA',90006,'323-453-2780','323-315-7314',11,53600,71),
    ('Emerson','Bowley','Knights Inn',26,'Ithaca ','Pl','Madison','Dane','WI',53711,'608-336-7444','608-658-7940',7,75400,7),
    ('Blair','Malet','Bollinger Mach Shp & Shipyard',91,'Seifert ','St','Philadelphia','Philadelphia','PA',19132,'215-907-9111','215-794-4519',2,103500,34),
    ('Brock','Bolognia','Orinda News',21,'Coral Sand ','Dr','New York','New York','NY',10003,'212-402-9216','212-617-5063',11,53400,11),
    ('Lorrie','Nestle','Ballard Spahr Andrews',20,'Mt Adelbert ','Dr','Tullahoma','Coffee','TN',37388,'931-875-6644','931-303-6041',14,83800,15),
    ('Sabra','Uyetake','Lowy Limousine Service',67,'Cloudview ','Pl','Columbia','Richland','SC',29201,'803-925-5213','803-681-3678',2,84400,8),
    ('Marjory','Mastella','Vicon Corporation',6210,'Azure Coast ','Dr','Wayne','Delaware','PA',19087,'610-814-5533','610-379-7125',1,62500,7),
    ('Karl','Klonowski','Rossi, Michael M',300,'Big Dipper ','Way','Flemington','Hunterdon','NJ',8822,'908-877-6135','908-470-4661',4,59800,257),
    ('Tonette','Wenner','Northwest Publishing',44,'Pipilo ','St','Westbury','Nassau','NY',11590,'516-968-6051','516-333-4861',5,57600,74),
    ('Amber','Monarrez','Branford Wire & Mfg Co',4265,'De La Madrid ','Ave','Jenkintown','Montgomery','PA',19046,'215-934-8655','215-329-6386',13,48900,236),
    ('Shenika','Seewald','East Coast Marketing',5570,'A',' St','Van Nuys','Los Angeles','CA',91405,'818-423-4007','818-749-8650',6,65700,89),
    ('Delmy','Ahle','Wye Technologies Inc',281,'Bristol Bay ','Ct','Providence','Providence','RI',2909,'401-458-2547','401-559-8961',14,71900,164),
    ('Deeanna','Juhas','Healy, George W Iv',906,'Gila ','Ct','Huntingdon Valley','Montgomery','PA',19006,'215-211-9589','215-417-9563',9,57300,53),
    ('Blondell','Pugh','Alpenlite Inc',1054,'Kestrel ','St','Providence','Providence','RI',2904,'401-960-8259','401-300-8122',13,54100,86),
    ('Jamal','Vanausdal','Hubbard, Bruce Esq',823,'Alkaid ','Dr','Monroe Township','Middlesex','NJ',8831,'732-234-1546','732-904-2931',4,98900,49),
    ('Cecily','Hollack','Arthur A Oliver & Son Inc',273,'Wellesly ','Ave','Austin','Travis','TX',78731,'512-486-3817','512-861-3814',6,84500,138),
    ('Carmelina','Lindall','George Jessop Carter Jewelers',33,'Segovia ','Via','Littleton','Douglas','CO',80126,'303-724-7371','303-874-5160',13,49700,91),
    ('Maurine','Yglesias','Schultz, Thomas C Md',55,'Rancho ','Del','Milwaukee','Milwaukee','WI',53214,'414-748-1374','414-573-7719',11,58600,59),
    ('Tawna','Buvens','H H H Enterprises Inc',2467,'Robleda ','Cove','New York','New York','NY',10009,'212-674-9610','212-462-9157',5,67300,38),
    ('Penney','Weight','Hawaiian King Hotel',62,'San Fernando ','St','Anchorage','Anchorage','AK',99515,'907-797-9628','907-873-2882',1,62000,219),
    ('Elly','Morocco','Killion Industries',3,'Arnott ','St','Erie','Erie','PA',16502,'814-393-5571','814-420-3553',4,71100,79),
    ('Ilene','Eroman','Robinson, William J Esq',9335,'Foxborough ','St','Glen Burnie','Anne Arundel','MD',21061,'410-914-9018','410-937-4543',7,117000,60),
    ('Vallie','Mondella','Private Properties',85,'Pinewood ','St','Boise','Ada','ID',83707,'208-862-5339','208-737-8439',1,53300,9),
    ('Kallie','Blackwood','Rowley Schlimgen Inc',4812,'Cerro Gordo ','Ave','San Francisco','San Francisco','CA',94104,'415-315-2761','415-604-7609',8,219900,4),
    ('Johnetta','Abdallah','Forging Specialties',3210,'Venice ','Ct','Chapel Hill','Orange','NC',27514,'919-225-9345','919-715-3791',9,59100,82),
    ('Bobbye','Rhym','Smits, Patricia Garity',842,'Stimson ','Ct','San Carlos','San Mateo','CA',94070,'650-528-5783','650-811-9032',12,57500,97),
    ('Micaela','Rhymes','H Lee Leonard Attorney At Law',35,'Midbluff ','Ave','Concord','Contra Costa','CA',94520,'925-647-3298','925-522-7798',2,86200,47),
    ('Tamar','Hoogland','A K Construction Co',58,'Michelangelo ','Via','London','Madison','OH',43140,'740-343-8575','740-526-5410',15,48700,14),
    ('Moon','Parlato','Ambelang, Jessica M Md',7143,'San Pasqual Valley ','Rd','Wellsville','Allegany','NY',14895,'585-866-8313','585-498-4278',10,50000,46),
    ('Laurel','Reitler','Q A Service',47,'Ellentown ','Rd','Baltimore','Baltimore City','MD',21215,'410-520-4832','410-957-6903',13,69600,52),
    ('Delisa','Crupi','Wood & Whitacre Contractors',1731,'Gingerwood ','Cove','Newark','Essex','NJ',7105,'973-354-2040','973-847-9611',1,87500,77),
    ('Viva','Toelkes','Mark Iv Press Ltd',6667,'Beagle ','Pl','Chicago','Cook','IL',60647,'773-446-5569','773-352-3437',15,49800,93),
    ('Elza','Lipke','Museum Of Science & Industry',38,'Memike ','Pl','Newark','Essex','NJ',7104,'973-927-3447','973-796-3667',9,68000,8),
    ('Devorah','Chickering','Garrison Ind',59,'Tern ','Dr','Clovis','Curry','NM',88101,'505-975-8559','505-950-1763',1,61500,52),
    ('Timothy','Mulqueen','Saronix Nymph Products',40,'Old Sycamore ','Dr','Staten Island','Richmond','NY',10309,'718-332-6527','718-654-7063',13,95200,43),
    ('Arlette','Honeywell','Smc Inc',98,'Lotus ','St','Jacksonville','Duval','FL',32254,'904-775-4480','904-514-9918',10,48800,87),
    ('Dominque','Dickerson','E A I Electronic Assocs Inc',520,'Belle Haven ','Dr','Hayward','Alameda','CA',94545,'510-993-3758','510-901-7640',14,64100,23),
    ('Lettie','Isenhower','Conte, Christopher A Esq',7545,'Tierrasanta ','Blvd','Beachwood','Cuyahoga','OH',44122,'216-657-7668','216-733-8494',10,248600,2),
    ('Myra','Munns','Anker Law Office',52,'Riverton ','Pl','Euless','Tarrant','TX',76040,'817-914-7518','817-451-3518',14,64000,76),
    ('Stephaine','Barfield','Beutelschies & Company',485,'Vail ','Ct','Gardena','Los Angeles','CA',90247,'310-774-7643','310-968-1219',5,53900,58),
    ('Lai','Gato','Fligg, Kenneth I Jr',849,'Canyon Bluff ','Ct','Evanston','Cook','IL',60201,'847-728-7286','847-957-4614',1,86700,87),
    ('Stephen','Emigh','Sharp, J Daniel Esq',21,'Creekbridge ','Pl','Akron','Summit','OH',44302,'330-537-5358','330-700-2312',14,59900,16),
    ('Tyra','Shields','Assink, Anne H Esq',85,'Castello ','Cir','Philadelphia','Philadelphia','PA',19106,'215-255-1641','215-228-8264',9,114100,82),
    ('Tammara','Wardrip','Jewel My Shop Inc',64,'Santillana ','Way','Burlingame','San Mateo','CA',94010,'650-803-1936','650-216-5075',11,72000,49),
    ('Cory','Gibes','Chinese Translation Resources',18,'Berger ','Ave','San Gabriel','Los Angeles','CA',91776,'626-572-1096','626-696-2777',5,48000,1),
    ('Danica','Bruschke','Stevens, Charles T',66,'Tragar ','Pl','Waco','McLennan','TX',76708,'254-782-8569','254-205-1422',11,57400,17),
    ('Wilda','Giguere','Mclaughlin, Luther W Cpa',832,'Allenbrook ','Way','Anchorage','Anchorage','AK',99501,'907-870-5536','907-914-9482',2,68500,80),
    ('Elvera','Benimadho','Tree Musketeers',41,'Amadita ','Ln','San Jose','Santa Clara','CA',95110,'408-703-8505','408-440-8447',12,57200,83),
    ('Carma','Vanheusen','Springfield Div Oh Edison Co',477,'Milbrae ','St','San Leandro','Alameda','CA',94577,'510-503-7169','510-452-4835',4,114100,9),
    ('Malinda','Hochard','Logan Memorial Hospital',6206,'Neale ','St','Indianapolis','Marion','IN',46202,'317-722-5066','317-472-2412',5,85100,31),
    ('Natalie','Fern','Kelly, Charles G Esq',317,'Mocking Bird ','Dr','Rock Springs','Sweetwater','WY',82901,'307-704-8713','307-279-3793',1,51400,26),
    ('Lisha','Centini','Industrial Paper Shredders Inc',501,'Golden Haven ','Dr','Mc Lean','Fairfax','VA',22102,'703-235-3937','703-475-7568',15,73400,292),
    ('Arlene','Klusman','Beck Horizon Builders',80,'Rollsreach ','Dr','New Orleans','Orleans','LA',70112,'504-710-5840','504-946-1807',13,75000,8),
    ('Alease','Buemi','Porto Cayo At Hawks Cay',60,'La Trucha ','St','Boulder','Boulder','CO',80303,'303-301-4946','303-521-9860',5,60100,37),
    ('Louisa','Cronauer','Pacific Grove Museum Ntrl Hist',131,'Lone Star ','St','San Leandro','Alameda','CA',94577,'510-828-7047','510-472-7758',12,215600,18),
    ('Angella','Cetta','Bender & Hatley Pc',4732,'Gilmartin ','Dr','Honolulu','Honolulu','HI',96817,'808-892-7943','808-475-2310',15,79200,2),
    ('Cyndy','Goldammer','Di Cristina J & Son',68,'Sandleford ','Way','Burnsville','Dakota','MN',55337,'952-334-9408','952-938-9457',8,104700,76),
    ('Rosio','Cork','Green Goddess',44,'Palo Verde ','Rd','High Point','Guilford','NC',27263,'336-243-5659','336-497-4407',3,88200,1),
    ('Celeste','Korando','American Arts & Graphics',91,'Sierra View ','Way','Lynbrook','Nassau','NY',11563,'516-509-2347','516-365-7266',11,70900,61),
    ('Twana','Felger','Opryland Hotel',355,'Otay Valley ','Rd','Portland','Washington','OR',97224,'503-939-3153','503-909-7167',2,83600,9),
    ('Estrella','Samu','Marking Devices Pubg Co',94,'Mt Bolanas ','Ct','Beloit','Rock','WI',53511,'608-976-7199','608-942-8836',9,62000,22),
    ('Donte','Kines','W Tc Industries Inc',76,'Delany ','Dr','Worcester','Worcester','MA',1602,'508-429-8576','508-843-1426',5,51300,6),
    ('Tiffiny','Steffensmeier','Whitehall Robbins Labs Divsn',1093,'W Quince ','St','Miami','Miami-Dade','FL',33133,'305-385-9695','305-304-6573',13,49900,66),
    ('Edna','Miceli','Sampler',216,'Big Springs ','Way','Erie','Erie','PA',16502,'814-460-2655','814-299-2877',2,60300,67),
    ('Sue','Kownacki','Juno Chefs Incorporated',38,'Carlisle ','Dr','Mesquite','Dallas','TX',75149,'972-666-3413','972-742-4000',13,71600,52),
    ('Jesusa','Shin','Carroccio, A Thomas Esq',20,'Togan ','Ave','Tullahoma','Coffee','TN',37388,'931-273-8709','931-739-1551',11,78500,91),
    ('Rolland','Francescon','Stanley, Richard L Esq',8170,'Patten ','St','Paterson','Passaic','NJ',7501,'973-649-2922','973-284-4048',9,48200,163),
    ('Pamella','Schmierer','K Cs Cstm Mouldings Windows',73,'Stoneview ','Ct','Homestead','Miami-Dade','FL',33030,'305-420-8970','305-575-8481',13,71100,92),
    ('Glory','Kulzer','Comfort Inn',91,'Cotorro ','Rd','Owings Mills','Baltimore','MD',21117,'410-224-9462','410-916-8015',5,60500,87),
    ('Shawna','Palaspas','Windsor, James L Esq',67,'Metropolitan ','Dr','Thousand Oaks','Ventura','CA',91362,'805-275-3566','805-638-6617',13,70600,77),
    ('Brandon','Callaro','Jackson Shields Yeiser',30,'Village Ridge ','Rd','Honolulu','Honolulu','HI',96819,'808-215-6832','808-240-5168',13,96900,30),
    ('Scarlet','Cartan','Box, J Calvin Esq',3605,'Alta Bahia ','Ct','Albany','Dougherty','GA',31701,'229-735-3378','229-365-9658',2,64700,40),
    ('Oretha','Menter','Custom Engineering Inc',40,'Alamitos ','Ave','Boston','Suffolk','MA',2210,'617-418-5043','617-697-6024',15,45800,66),
    ('Ty','Smith','Bresler Eitel Framg Gllry Ltd',2175,'Dafter ','Pl','Hackensack','Bergen','NJ',7601,'201-672-1553','201-995-3149',8,73700,8),
    ('Xuan','Rochin','Carol, Drake Sparks Esq',66,'Cajon ','Way','San Mateo','San Mateo','CA',94403,'650-933-5072','650-247-2625',5,62600,47),
    ('Lindsey','Dilello','Biltmore Investors Bank',7447,'Choctaw ','Dr','Ontario','San Bernardino','CA',91761,'909-639-9887','909-589-1693',10,89200,54),
    ('Devora','Perez','Desco Equipment Corp',34,'Russell ','Dr','Oakland','Alameda','CA',94606,'510-955-3016','510-755-9274',5,77800,79),
    ('Vallie','Blackwood','Lux Properties',25,'Kasesallu','St','Boise','Ada','ID',83707,'208-862-5339','208-737-8439',1,53300,9),
    ('Kallie', 'Mondella','ABC Inc',372,'Joo','Ln','San Francisco','San Francisco','CA',94104,'415-315-2761','415-604-7609',8,219900,4),
    ('Herman','Demesa','Merlin Electric Co',84,'Del Mar Heights ','Rd','Troy','Rensselaer','NY',12180,'518-497-2940','518-931-7852',11,93800,19),
    ('Rory','Papasergi','Bailey Cntl Co Div Babcock',56,'Keystone ','Ct','Clarks Summit','Lackawanna','PA',18411,'570-867-7489','570-469-8401',6,58500,71),
    ('Talia','Riopelle','Ford Brothers Wholesale Inc',89,'Bayamon ','Rd','Orange','Essex','NJ',7050,'973-245-2133','973-818-9788',14,82900,26),
    ('Van','Shire','Cambridge Inn',8,'Tyrolean ','Rd','Pittstown','Hunterdon','NJ',8867,'908-409-2890','908-448-1209',6,89300,68),
    ('Lucina','Lary','Matricciani, Albert J Jr',8576,'Newell ','St','Cocoa','Brevard','FL',32922,'321-749-4981','321-632-4668',4,65600,53),
    ('Bok','Isaacs','Nelson Hawaiian Ltd',440,'Prairie Mound ','Way','Bronx','Bronx','NY',10468,'718-809-3762','718-478-8568',3,75100,12),
    ('Rolande','Spickerman','Neland Travel Agency',8052,'Rincon ','St','Pearl City','Honolulu','HI',96782,'808-315-3077','808-526-5863',11,95100,9),
    ('Howard','Paulas','Asendorf, J Alan Esq',58,'Ocean Cove ','Dr','Denver','Denver','CO',80231,'303-623-4241','303-692-3118',3,73700,5),
    ('Kimbery','Madarang','Silberman, Arthur L Esq',773,'Rexview ','Dr','Rockaway','Morris','NJ',7866,'973-310-1634','973-225-6259',5,62700,36),
    ('Thurman','Manno','Honey Bee Breeding Genetics &',59,'San Anselmo ','St','Absecon','Atlantic','NJ',8201,'609-524-3586','609-234-8376',2,76800,242),
    ('Becky','Mirafuentes','Wells Kravitz Schnitzer',11,'Radenz ','Ct','Plainfield','Union','NJ',7062,'908-877-8409','908-426-8272',13,116200,83),
    ('Beatriz','Corrington','Prohab Rehabilitation Servs',1600,'Piatto ','Way','Middleboro','Plymouth','MA',2346,'508-584-4279','508-315-3867',12,80200,81),
    ('Marti','Maybury','Eldridge, Kristin K Esq',55,'Monument ','Rd','Chicago','Cook','IL',60638,'773-775-4522','773-539-1058',11,120400,62),
    ('Nieves','Gotter','Vlahos, John J Esq',1368,'Ritva ','Pl','Portland','Multnomah','OR',97202,'503-527-5274','503-455-3094',14,61000,31),
    ('Leatha','Hagele','Ninas Indian Grs & Videos',34,'Activity ','Rd','Dallas','Dallas','TX',75227,'214-339-1809','214-225-5850',13,57900,82),
    ('Valentin','Klimek','Schmid, Gayanne K Esq',5606,'Senda Luna Llena ','Ct','Chicago','Cook','IL',60604,'312-303-5453','312-512-2338',1,78200,86),
    ('Melissa','Wiklund','Moapa Valley Federal Credit Un',250,'Miramar ','Ct','Findlay','Hancock','OH',45840,'419-939-3613','419-254-4591',6,65900,37),
    ('Sheridan','Zane','Kentucky Tennessee Clay Co',10,'Evergreen ','St','Riverside','Riverside','CA',92501,'951-645-3605','951-248-6822',10,59700,88),
    ('Bulah','Padilla','Admiral Party Rentals & Sales',64,'4th ','St','Waco','McLennan','TX',76707,'254-463-4368','254-816-8417',7,101100,50),
    ('Audra','Kohnert','Nelson, Karolyn King Esq',4,'Danvers ','Cir','Nashville','Davidson','TN',37211,'615-406-7854','615-448-9249',4,80200,69),
    ('Daren','Weirather','Panasystems',530,'Jocatal ','Ct','Milwaukee','Milwaukee','WI',53216,'414-959-2540','414-838-3151',4,86900,79),
    ('Fernanda','Jillson','Shank, Edward L Esq',210,'Silver Acacia ','Pl','Preston','Caroline','MD',21655,'410-387-5260','410-724-6472',12,101200,100),
    ('Gearldine','Gellinger','Megibow & Edwards',19,'Hadden Hall ','Ct','Irving','Dallas','TX',75061,'972-934-6914','972-821-7118',14,61600,7),
    ('Chau','Kitzman','Benoff, Edward Esq',5824,'Jardin ','Rd','Beverly Hills','Los Angeles','CA',90212,'310-560-8022','310-969-7230',3,124500,94),
    ('Theola','Frey','Woodbridge Free Public Library',32,'High ','Ave','Massapequa','Nassau','NY',11758,'516-948-5768','516-357-3362',11,75600,149),
    ('Cheryl','Haroldson','New York Life John Thune',924,'Sanddollar ','Ct','Atlantic City','Atlantic','NJ',8401,'609-518-7697','609-263-9243',1,55400,32),
    ('Laticia','Merced','Alinabal Inc',220,'Greenwich ','Dr','Cincinnati','Hamilton','OH',45203,'513-508-7371','513-418-1566',15,75400,8),
    ('Carissa','Batman','Poletto, Kim David Esq',78,'Malcolm ','Dr','Eugene','Lane','OR',97401,'541-326-4074','541-801-5717',7,79800,39),
    ('Lezlie','Craghead','Chang, Carolyn Esq',721,'Jenkins ','St','Smithfield','Johnston','NC',27577,'919-533-3762','919-885-2453',9,53600,21),
    ('Ozell','Shealy','Silver Bros Inc',55,'Redford ','Pl','New York','New York','NY',10002,'212-332-8435','212-880-8865',7,71900,25),
    ('Arminda','Parvis','Newtec Inc',3119,'Bonita ','Rd','Phoenix','Maricopa','AZ',85017,'602-906-9419','602-277-3025',3,85400,34),
    ('Reita','Leto','Creative Business Systems',4361,'Veracruz ','Ct','Indianapolis','Marion','IN',46240,'317-234-1135','317-787-5514',13,121700,203),
    ('Yolando','Luczki','Dal Tile Corporation',80,'Miramar ','Rd','Syracuse','Onondaga','NY',13214,'315-304-4759','315-640-6357',4,71900,60),
    ('Lizette','Stem','Edward S Katz',88,'Twin Trails ','Dr','Cherry Hill','Camden','NJ',8002,'856-487-5412','856-702-3676',3,84700,53),
    ('Gregoria','Pawlowicz','Oh My Goodknits Inc',74,'Caneridge ','Rd','Garden City','Nassau','NY',11530,'516-212-1915','516-376-4230',1,76000,87),
    ('Carin','Deleo','Redeker, Debbie',88,'Royal Island ','Way','Little Rock','Pulaski','AR',72202,'501-308-1040','501-409-6072',9,54900,4),
    ('Chantell','Maynerich','Desert Sands Motel',76,'Onstad ','St','Saint Paul','Ramsey','MN',55101,'651-591-2583','651-776-9688',1,67900,8),
    ('Dierdre','Yum','Cummins Southern Plains Inc',75,'Merton ','Ct','Philadelphia','Philadelphia','PA',19134,'215-325-3042','215-346-4666',8,89500,82),
    ('Larae','Gudroe','Lehigh Furn Divsn Lehigh',4657,'Maple ','St','Houma','Terrebonne','LA',70360,'985-890-7262','985-261-5783',6,121700,95),
    ('Latrice','Tolfree','United Van Lines Agent',535,'Mobley ','St','Ronkonkoma','Suffolk','NY',11779,'631-957-7624','631-998-2102',12,71800,79),
    ('Kerry','Theodorov','Capitol Reporters',170,'Spring Tide ','Pl','Sacramento','Sacramento','CA',95827,'916-591-3277','916-770-7448',11,55100,39),
    ('Dorthy','Hidvegi','Kwik Kopy Printing',42,'Milbrae ','St','Boise','Ada','ID',83704,'208-649-2373','208-690-3315',9,71400,33),
    ('Fannie','Lungren','Centro Inc',1959,'Pine Manor ','Ct','Round Rock','Williamson','TX',78664,'512-587-5746','512-528-9933',7,85300,55),
    ('Evangelina','Radde','Campbell, Jan Esq',1991,'Chelsea ','St','Philadelphia','Philadelphia','PA',19123,'215-964-3284','215-417-5612',1,122100,68),
    ('Novella','Degroot','Evans, C Kelly Esq',5331,'Box Canyon ','Rd','Hilo','Hawaii','HI',96720,'808-477-4775','808-746-1865',5,80800,11),
    ('Clay','Hoa','Scat Enterprises',8,'Makaha ','Way','Reno','Washoe','NV',89502,'775-501-8109','775-848-9135',9,229700,279),
    ('Jennifer','Fallick','Nagle, Daniel J Esq',666,'Spray ','St','Wheeling','Cook','IL',60090,'847-979-9545','847-800-3054',5,68100,7),
    ('Irma','Wolfgramm','Serendiquity Bed & Breakfast',77,'Tuxford ','Dr','Randolph','Morris','NJ',7869,'973-545-7355','973-868-8660',4,70300,63),
    ('Eun','Coody','Ray Carolyne Realty',598,'San Pedro ','Ave','Spartanburg','Spartanburg','SC',29301,'864-256-3620','864-594-4578',2,74400,95),
    ('Sylvia','Cousey','Berg, Charles E',619,'Nazareth ','Dr','Hampstead','Carroll','MD',21074,'410-209-9545','410-863-8263',1,116900,9),
    ('Nana','Wrinkles','Ray, Milbern D',68,'Al Bahr ','Dr','Mount Vernon','Westchester','NY',10553,'914-855-2115','914-796-3775',10,72200,90),
    ('Layla','Springe','Chadds Ford Winery',36,'Dickinson ','St','New York','New York','NY',10011,'212-260-3151','212-253-7448',12,59500,24),
    ('Joesph','Degonia','A R Packaging',760,'Old Spring ','Ct','Berkeley','Alameda','CA',94710,'510-677-9785','510-942-5916',14,57200,37),
    ('Annabelle','Boord','Corn Popper',25,'Lucinda ','St','Concord','Middlesex','MA',1742,'978-697-6263','978-289-7717',11,102700,59),
    ('Stephaine','Vinning','Birite Foodservice Distr',902,'Acacia Grove ','Way','San Francisco','San Francisco','CA',94104,'415-767-6596','415-712-9530',6,73100,10),
    ('Nelida','Sawchuk','Anchorage Museum Of Hist & Art',80,'Redwood Creek ','Ln','Paramus','Bergen','NJ',7652,'201-971-1638','201-247-8925',10,120600,91),
    ('Marguerita','Hiatt','Haber, George D Md',877,'Vista Canon ','Ct','Oakley','Contra Costa','CA',94561,'925-634-7158','925-541-8521',2,58300,87),
    ('Carmela','Cookey','Royal Pontiac Olds Inc',28,'Montebello ','Way','Chicago','Cook','IL',60623,'773-494-4195','773-297-9391',5,71000,78),
    ('Junita','Brideau','Leonards Antiques Inc',758,'Arroyo Sorrento ','Rd','Cedar Grove','Essex','NJ',7009,'973-943-3423','973-582-5469',1,47900,63),
    ('Claribel','Varriano','Meca',1197,'Mt Castle ','Ave','Perrysburg','Wood','OH',43551,'419-544-4900','419-573-2033',12,54000,13),
    ('Benton','Skursky','Nercon Engineering & Mfg Inc',2696,'Darview ','Ln','Gardena','Los Angeles','CA',90248,'310-579-2907','310-694-8466',1,123000,47),
    ('Hillary','Skulski','Replica I',334,'Harmarsh ','St','Homosassa','Citrus','FL',34448,'352-242-2570','352-990-5946',1,87400,65),
    ('Merilyn','Bayless','20 20 Printing Inc',39,'Catherine ','Ave','Santa Clara','Santa Clara','CA',95054,'408-758-5015','408-346-2180',14,62800,80),
    ('Teri','Ennaco','Publishers Group West',9,'La Salle ','St','Hazleton','Luzerne','PA',18201,'570-889-5187','570-355-1665',12,74400,98),
    ('Merlyn','Lawler','Nischwitz, Jeffrey L Esq',196,'Craig ','Rd','Jersey City','Hudson','NJ',7304,'201-588-7810','201-858-9960',13,78800,34),
    ('Georgene','Montezuma','Payne Blades & Wellborn Pa',7101,'Grant ','St','San Ramon','Contra Costa','CA',94583,'925-615-5185','925-943-3449',6,48900,81),
    ('Jettie','Mconnell','Coldwell Bnkr Wright Real Est',39,'Alta Vista ','St','Bridgewater','Somerset','NJ',8807,'908-802-3564','908-602-5258',3,88500,37),
    ('Lemuel','Latzke','Computer Repair Service',4835,'Cascade ','St','Bohemia','Suffolk','NY',11716,'631-748-6479','631-291-4976',8,86700,58),
    ('Melodie','Knipp','Fleetwood Building Block Inc',7587,'Relindo ','Ct','Thousand Oaks','Ventura','CA',91362,'805-690-1682','805-810-8964',3,113900,34),
    ('Candida','Corbley','Colts Neck Medical Assocs Inc',28,'Cerrissa ','St','Somerville','Somerset','NJ',8876,'908-275-8357','908-943-6103',4,52300,78),
    ('Karan','Karpin','New England Taxidermy',38,'Siesta ','Dr','Beaverton','Washington','OR',97005,'503-940-8327','503-707-5812',13,78700,16),
    ('Andra','Scheyer','Ludcke, George O Esq',369,'Brook ','Ln','Salem','Marion','OR',97302,'503-516-2189','503-950-3068',12,51500,62),
    ('Felicidad','Poullion','Mccorkle, Tom S Esq',23,'San Antonio Rose ','Ct','Riverton','Burlington','NJ',8077,'856-305-9731','856-828-6021',8,101500,50),
    ('Belen','Strassner','Eagle Software Inc',9665,'Napa ','St','Douglasville','Douglas','GA',30135,'770-507-8791','770-802-4003',1,91800,61),
    ('Gracia','Melnyk','Juvenile & Adult Super',69,'Roundup ','Ave','Jacksonville','Duval','FL',32216,'904-235-3633','904-627-4341',8,79900,231),
    ('Jolanda','Hanafan','Perez, Joseph J Esq',102,'Raven Ridge ','Pl','Bangor','Penobscot','ME',4401,'207-458-9196','207-233-6185',7,77600,81),
    ('Barrett','Toyama','Case Foundation Co',88,'Knight ','Dr','Kennedale','Tarrant','TX',76060,'817-765-5781','817-577-6151',6,63900,45),
    ('Helga','Fredicks','Eis Environmental Engrs Inc',81,'Cessna ','St','Buffalo','Erie','NY',14228,'716-752-4114','716-854-9845',6,63200,8),
    ('Ashlyn','Pinilla','Art Crafters',232,'Snowbond ','St','Opa Locka','Miami-Dade','FL',33054,'305-670-9628','305-857-5489',10,119000,39),
    ('Fausto','Agramonte','Marriott Hotels Resorts Suites',41,'Friars ','Rd','New York','New York','NY',10038,'212-313-1783','212-778-3063',1,61300,92),
    ('Ronny','Caiafa','Remaco Inc',777,'Baja ','Ct','Philadelphia','Philadelphia','PA',19103,'215-605-7570','215-511-3531',15,70100,85),
    ('Marge','Limmel','Bjork, Robert D Jr',256,'Cumana ','Way','Crestview','Okaloosa','FL',32536,'850-430-1663','850-330-8079',1,89700,90),
    ('Norah','Waymire','Carmichael, Jeffery L Esq',32,'La France ','St','San Francisco','San Francisco','CA',94107,'415-306-7897','415-874-2984',12,66600,48),
    ('Aliza','Baltimore','Andrews, J Robert Esq',45,'La Paz ','Dr','San Jose','Santa Clara','CA',95132,'408-504-3552','408-425-1994',6,105900,55),
    ('Mozell','Pelkowski','Winship & Byrne',39,'Parkside ','Ct','South San Francisco','San Mateo','CA',94080,'650-947-1215','650-960-1069',11,69100,85),
    ('Viola','Bitsuie','Burton & Davis',62,'Asbury ','Ct','Northridge','Los Angeles','CA',91325,'818-864-4875','818-481-5787',5,99300,73),
    ('Franklyn','Emard','Olympic Graphic Arts',46,'Overpark ','Rd','Philadelphia','Philadelphia','PA',19103,'215-558-8189','215-483-3003',4,60200,56),
    ('Willodean','Konopacki','Magnuson',728,'Katherine ','Ct','Lafayette','Lafayette','LA',70506,'337-253-8384','337-774-7564',6,164100,209),
    ('Beckie','Silvestrini','A All American Travel Inc',77,'Menorca ','Way','Dearborn','Wayne','MI',48126,'313-533-4884','313-390-7855',11,89700,55),
    ('Rebecka','Gesick','Polykote Inc',35,'Mason Heights ','Ln','Austin','Travis','TX',78754,'512-213-8574','512-693-8345',11,121100,56),
    ('Frederica','Blunk','Jets Cybernetics',77,'Perseus ','Rd','Dallas','Dallas','TX',75207,'214-428-2285','214-529-1949',3,57000,87),
    ('Glen','Bartolet','Metlab Testing Services',3478,'Naples ','St','Vashon','King','WA',98070,'206-697-5796','206-389-1482',11,51400,55),
    ('Freeman','Gochal','Kellermann, William T Esq',9910,'Mcdowell ','Ct','Coatesville','Chester','PA',19320,'610-476-3501','610-752-2683',7,108300,9),
    ('Vincent','Meinerding','Arturi, Peter D Esq',162,'Claymont ','Ct','Philadelphia','Philadelphia','PA',19143,'215-372-1718','215-829-4221',1,100900,60),
    ('Rima','Bevelacqua','Mcauley Mfg Co',872,'Grunion Run ','Dr','Gardena','Los Angeles','CA',90248,'310-858-5079','310-499-4200',2,117100,232),
    ('Glendora','Sarbacher','Defur Voran Hanley Radcliff',527,'Evening Sky ','Ct','Rohnert Park','Sonoma','CA',94928,'707-653-8214','707-881-3154',11,103300,61),
    ('Avery','Steier','Dill Dill Carr & Stonbraker Pc',68,'Santaluz Village Green ','N','Orlando','Orange','FL',32803,'407-808-9439','407-945-8566',4,50700,258),
    ('Cristy','Lother','Kleensteel',9778,'Clover ','Cir','Escondido','San Diego','CA',92025,'760-971-4322','760-465-4762',11,48200,44),
    ('Nicolette','Brossart','Goulds Pumps Inc Slurry Pump',250,'Peacock ','Dr','Westborough','Worcester','MA',1581,'508-837-9230','508-504-6388',8,222800,24),
    ('Tracey','Modzelewski','Kansas City Insurance Report',871,'Mariners ','Way','Conroe','Montgomery','TX',77301,'936-264-9294','936-988-8171',10,48000,95),
    ('Virgina','Tegarden','Berhanu International Foods',2783,'Thimble ','Ct','Milwaukee','Milwaukee','WI',53226,'414-214-8697','414-411-5744',11,51400,33),
    ('Tiera','Frankel','Roland Ashcroft',9627,'Pacific Center ','Blvd','El Monte','Los Angeles','CA',91731,'626-636-4117','626-638-4241',15,75100,74),
    ('Alaine','Bergesen','Hispanic Magazine',8390,'La Crescentia ','Dr','Yonkers','Westchester','NY',10701,'914-300-9193','914-654-1426',10,50700,31),
    ('Earleen','Mai','Little Sheet Metal Co',360,'Manya ','St','Dallas','Dallas','TX',75227,'214-289-1973','214-785-6750',1,56100,97),
    ('Leonida','Gobern','Holmes, Armstead J Esq',324,'College Gardens ','Ct','Biloxi','Harrison','MS',39530,'228-235-5615','228-432-4635',15,115700,2),
    ('Ressie','Auffrey','Faw, James C Cpa',24,'Road To ','Bali','Miami','Miami-Dade','FL',33134,'305-604-8981','305-287-4743',13,132300,88),
    ('Justine','Mugnolo','Evans Rule Company',314,'Amber View ','Point','New York','New York','NY',10048,'212-304-9225','212-311-6377',1,114700,35),
    ('Eladia','Saulter','Tyee Productions Inc',14,'Seagrove ','St','Ramsey','Bergen','NJ',7446,'201-474-4924','201-365-8698',9,83700,53),
    ('Chaya','Malvin','Dunnells & Duvall',15,'Rowlett ','Ave','Ann Arbor','Washtenaw','MI',48103,'734-928-5182','734-408-8174',10,45500,72),
    ('Gwenn','Suffield','Deltam Systems Inc',98,'Comalette ','Ln','Deer Park','Suffolk','NY',11729,'631-258-6558','631-295-9879',15,70700,16),
    ('Salena','Karpel','Hammill Mfg Co',44,'Kane ','St','Canton','Stark','OH',44707,'330-791-8557','330-618-2579',13,65000,18),
    ('Yoko','Fishburne','Sams Corner Store',340,'Ives ','Ct','New Haven','New Haven','CT',6511,'203-506-4706','203-840-8634',6,45100,76),
    ('Taryn','Moyd','Siskin, Mark J Esq',78,'Noyes ','St','Fairfax','Fairfax City','VA',22030,'703-322-4041','703-938-7939',4,55100,3),
    ('Katina','Polidori','Cape & Associates Real Estate',10,'Carrollton ','Sqr','Wilmington','Middlesex','MA',1887,'978-626-2978','978-679-7429',9,89600,3),
    ('Rickie','Plumer','Merrill Lynch',301,'Sprinter ','Ln','Toledo','Lucas','OH',43613,'419-693-1334','419-313-5571',9,61400,110),
    ('Alex','Loader','Sublett, Scott Esq',65,'Pocahontas ','Ave','Tacoma','Pierce','WA',98409,'253-660-7821','253-875-9222',10,97900,88),
    ('Lashon','Vizarro','Sentry Signs',36,'Marabelle ','Rd','Roseville','Placer','CA',95661,'916-741-7884','916-289-4526',10,120500,98),
    ('Lauran','Burnard','Professionals Unlimited',30,'Jasmine Crest ','Ln','Riverton','Fremont','WY',82501,'307-342-7795','307-453-7589',2,115000,17),
    ('Ceola','Setter','Southern Steel Shelving Co',226,'Sterling Grove ','Ln','Warren','Knox','ME',4864,'207-627-7565','207-297-5029',6,83000,30),
    ('My','Rantanen','Bosco, Paul J',71,'Antonio ','Dr','Richboro','Bucks','PA',18954,'215-491-5633','215-647-2158',4,113500,39),
    ('Lorrine','Worlds','Longo, Nicholas J Esq',85,'N Rim ','Ct','Tampa','Hillsborough','FL',33614,'813-769-2939','813-863-6467',12,67100,10),
    ('Peggie','Sturiale','Henry County Middle School',50,'Stevenson ','Way','El Cajon','San Diego','CA',92020,'619-608-1763','619-695-8086',5,85600,94),
    ('Marvel','Raymo','Edison Supply & Equipment Co',48,'Judson ','Ct','College Station','Brazos','TX',77840,'979-718-8968','979-809-5770',3,118700,165),
    ('Daron','Dinos','Wolf, Warren R Esq',72,'Del Mesonero ','Way','Highland Park','Lake','IL',60035,'847-233-3075','847-265-6609',8,95500,163),
    ('An','Fritz','Linguistic Systems Inc',101,'Beatrice ','St','Atlantic City','Atlantic','NJ',8401,'609-228-5265','609-854-7156',13,83300,64),
    ('Portia','Stimmel','Peace Christian Center',410,'Thrush ','St','Bridgewater','Somerset','NJ',8807,'908-722-7128','908-670-4712',8,69400,85),
    ('Rhea','Aredondo','Double B Foods Inc',52,'Hadden Hall ','Ct','Brooklyn','Kings','NY',11226,'718-560-9537','718-280-4183',11,68900,7);
INSERT INTO "employee_table" VALUES
    ('Benedict','Sama','Alexander & Alexander Inc',40,'Bella Pacific ','Row','Saint Louis','Saint Louis City','MO',63104,'314-787-1588','314-858-4832',3,50500,94),
    ('Alyce','Arias','Fairbanks Scales',30,'Forward ','St','Stockton','San Joaquin','CA',95207,'209-317-1801','209-242-7022',5,110100,28),
    ('Heike','Berganza','Cali Sportswear Cutting Dept',28,'Cave ','St','Little Falls','Passaic','NJ',7424,'973-936-5095','973-822-8827',1,81500,6),
    ('Carey','Dopico','Garofani, John Esq',25,'Lambert ','Way','Indianapolis','Marion','IN',46220,'317-578-2453','317-441-5848',5,63200,61),
    ('Dottie','Hellickson','Thompson Fabricating Co',856,'Latina ','Way','Seattle','King','WA',98133,'206-540-6076','206-295-5631',14,54000,18),
    ('Deandrea','Hughey','Century 21 Krall Real Estate',9482,'Shafter ','St','Burlington','Alamance','NC',27215,'336-822-7652','336-467-3095',9,85100,73),
    ('Kimberlie','Duenas','Mid Contntl Rlty & Prop Mgmt',171,'Chicago ','St','Hays','Ellis','KS',67601,'785-629-8542','785-616-1685',7,54800,61),
    ('Martina','Staback','Ace Signs Inc',99,'Morley ','Way','Orlando','Orange','FL',32822,'407-471-6908','407-429-2145',6,62100,54),
    ('Skye','Fillingim','Rodeway Inn',2,'Camphor ','Ln','Minneapolis','Hennepin','MN',55401,'612-508-2655','612-664-6304',8,84600,10),
    ('Jade','Farrar','Bonnet & Daughter',5704,'Cloud ','Way','Columbia','Richland','SC',29201,'803-352-5387','803-975-3405',5,46000,3),
    ('Charlene','Hamilton','Oshins & Gibbons',69,'Sturgeon ','Ct','Santa Rosa','Sonoma','CA',95407,'707-300-1771','707-821-8037',3,56700,46),
    ('Geoffrey','Acey','Price Business Services',64,'Summerdale ','Rd','Palatine','Cook','IL',60067,'847-222-1734','847-556-2909',3,76400,15),
    ('Stevie','Westerbeck','Wise, Dennis W Md',8570,'Gildred ','Sqr','Costa Mesa','Orange','CA',92626,'949-867-4077','949-903-3898',4,197700,12),
    ('Pamella','Fortino','Super 8 Motel',217,'Murray Ridge ','Rd','Denver','Denver','CO',80212,'303-404-2210','303-794-1341',13,66800,73),
    ('Harrison','Haufler','John Wagner Associates',66,'Crescent ','Dr','New Haven','New Haven','CT',6515,'203-801-6193','203-801-8497',7,52800,55),
    ('Johnna','Engelberg','Thrifty Oil Co',9174,'Ashmore ','Ave','Bothell','Snohomish','WA',98021,'425-986-7573','425-700-3751',12,98200,43),
    ('Buddy','Cloney','Larkfield Photo',940,'Arborlake ','Way','Strongsville','Cuyahoga','OH',44136,'440-989-5826','440-327-2093',15,117100,26),
    ('Dalene','Riden','Silverman Planetarium',604,'Rytko ','St','Plaistow','Rockingham','NH',3865,'603-315-6839','603-745-7497',15,119200,88),
    ('Jerry','Zurcher','J & F Lumber',5007,'Citadel ','Cir','Satellite Beach','Brevard','FL',32937,'321-518-5938','321-597-2159',9,74200,100),
    ('Haydee','Denooyer','Cleaning Station Inc',1403,'Lewiston ','St','New York','New York','NY',10016,'212-792-8658','212-782-3493',11,68800,33),
    ('Joseph','Cryer','Ames Stationers',2,'Madison ','Ave','Huntington Beach','Orange','CA',92647,'714-584-2237','714-698-2170',3,69400,96),
    ('Deonna','Kippley','Midas Muffler Shops',5368,'Pennsylvania ','Ave','Southfield','Oakland','MI',48075,'248-913-4677','248-793-4966',8,174600,10),
    ('Raymon','Calvaresi','Seaboard Securities Inc',908,'Albemarle ','St','Indianapolis','Marion','IN',46222,'317-825-4724','317-342-1532',7,86000,30),
    ('Alecia','Bubash','Petersen, James E Esq',389,'The Preserve ','Way','Wichita Falls','Wichita','TX',76301,'940-276-7922','940-302-3036',8,114000,97),
    ('Ma','Layous','Development Authority',67,'Torrey Pines Science ','Park','North Haven','New Haven','CT',6473,'203-721-3388','203-564-1543',4,45200,33),
    ('Detra','Coyier','Schott Fiber Optics Inc',92,'Gehring ','Ct','Aberdeen','Harford','MD',21001,'410-739-9277','410-259-2118',15,73000,58),
    ('Terrilyn','Rodeigues','Stuart J Agins',95,'Callaghan ','Cir','New Orleans','Orleans','LA',70130,'504-463-4384','504-635-8518',5,49000,79),
    ('Salome','Lacovara','Mitsumi Electronics Corp',2014,'Vista Del Agua ','Way','Richmond','Richmond City','VA',23219,'804-550-5097','804-858-1011',1,89400,2),
    ('Garry','Keetch','Italian Express Franchise Corp',545,'Mandarin ','Cove','Southampton','Bucks','PA',18966,'215-979-8776','215-846-9046',5,98600,71),
    ('Matthew','Neither','American Council On Sci & Hlth',26,'Argo ','Ct','Shakopee','Scott','MN',55379,'952-651-7597','952-906-4597',8,92100,17),
    ('Theodora','Restrepo','Kleri, Patricia S Esq',228,'Dinamica ','Way','Miami','Miami-Dade','FL',33136,'305-936-8226','305-573-1085',14,88900,126),
    ('Noah','Kalafatis','Twiggs Abrams Blanchard',4800,'Fashion Valley ','Rd','Milwaukee','Milwaukee','WI',53209,'414-263-5287','414-660-9766',3,56100,71),
    ('Carmen','Sweigard','Maui Research & Technology Pk',34,'Goen ','Pl','Somerset','Somerset','NJ',8873,'732-941-2621','732-445-6940',6,113800,57),
    ('Lavonda','Hengel','Bradley Nameplate Corp',50,'Brant ','St','Fargo','Cass','ND',58102,'701-898-2154','701-421-7080',3,50600,243),
    ('Junita','Stoltzman','Geonex Martel Inc',62,'Tulip ','Ln','Carson City','Carson City','NV',89701,'775-638-9963','775-578-1214',14,64200,86),
    ('Herminia','Nicolozakes','Sea Island Div Of Fstr Ind Inc',10,'Gaylord ','Pl','Scottsdale','Maricopa','AZ',85254,'602-954-5141','602-304-6433',15,109500,223),
    ('Casie','Good','Papay, Debbie J Esq',76,'Fostoria ','Ct','Nashville','Davidson','TN',37211,'615-390-2251','615-825-4297',3,68900,84),
    ('Reena','Maisto','Lane Promotions',96,'Deer Canyon ','Ct','Salisbury','Wicomico','MD',21801,'410-351-1863','410-951-2667',1,76100,98);

UPDATE employee_table SET 
    StreetSuffix=
    (SELECT DISTINCT Standard 
        FROM StreetSuffixMapping 
        WHERE UPPER(employee_table.StreetSuffix)=UPPER(StreetSuffixMapping.Written));

/*
27.1) Regular Match on Street Names
We are now going to use the extracted address information (from what we are pretending to be supplier 
addresses) and compare it to the employee table (this table already contains extracted and validated 
data) to see if we have any employees that the company may also be purchasing from.  Below the temporary 
views in the CTE, add a SELECT statement that compares the streetname from StreetSuffixCheck to the 
streetname in the Employee_Table using a regular equality operator. Only keep rows where there is a 
match. In your results create a new field called MatchType and populate it with a string saying 
'StreetNameMatch'. Also include streetaddressline2 and streetname from StreetSuffixCheck and streetnumber, 
streetname, and streetsuffix from Employee_Table.
*/
WITH 
    NotPoBox AS(
    SELECT  streetaddressline2
        FROM location
        WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'),
    StreetNumberExtraction AS(
    SELECT  streetaddressline2, 
            SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2)-1) AS StreetNumber, -- The position returns the location of the space, we do not want to include the space in the street number so we remove 1 from the length to stop pulling characters before (not including) the space
            SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2)+1) AS RightOfStreetNumber --We again do not want to include the space, so we add one to the startlocation to move one step beyond the space
        FROM NotPoBox),
    StreetNumberCheck AS(
    SELECT  *, 
            CASE WHEN StreetNumber SIMILAR TO '[0-9]+' 
                THEN  StreetNumber 
                ELSE NULL 
            END AS CheckedStreetNumber
        FROM StreetNumberExtraction),
    StreetSuffixExtraction AS(
    SELECT  *,
            RIGHT(rightofstreetnumber, POSITION(' ' IN REVERSE(rightofstreetnumber))-1) AS StreetSuffix
        FROM StreetNumberCheck),
    StreetSuffixCheck AS (
    SELECT  *,
            Standard,
            LEFT(rightofstreetnumber, LENGTH(rightofstreetnumber)-LENGTH(streetsuffix)-1) AS StreetName
        FROM StreetSuffixExtraction A
        LEFT JOIN StreetSuffixMapping B
            ON UPPER(A.StreetSuffix)=B.Written
    )
    SELECT 'StreetNameMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B ON A.StreetName = B.StreetName
/*
27.2) Regular Match on Street Numbers, Names, and Suffixes
Stack the results from the query above together with a new query (use UNION) that matches on all address 
components (again using a regular equality operator), i.e., streetname, streetnumber, and standard from 
StreetSuffixCheck and streetname, streetnumber, and streetsuffix from Employee_Table. Include the same 
field sas in 3.1 (for MatchType, use the string 'FullStreetAddressMatch'.
*/
WITH 
    NotPoBox AS(
    SELECT  streetaddressline2
        FROM location
        WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'),
    StreetNumberExtraction AS(
    SELECT  streetaddressline2, 
            SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2)-1) AS StreetNumber, -- The position returns the location of the space, we do not want to include the space in the street number so we remove 1 from the length to stop pulling characters before (not including) the space
            SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2)+1) AS RightOfStreetNumber --We again do not want to include the space, so we add one to the startlocation to move one step beyond the space
        FROM NotPoBox),
    StreetNumberCheck AS(
    SELECT  *, 
            CASE WHEN StreetNumber SIMILAR TO '[0-9]+' 
                THEN  StreetNumber 
                ELSE NULL 
            END AS CheckedStreetNumber
        FROM StreetNumberExtraction),
    StreetSuffixExtraction AS(
    SELECT  *,
            RIGHT(rightofstreetnumber, POSITION(' ' IN REVERSE(rightofstreetnumber))-1) AS StreetSuffix
        FROM StreetNumberCheck),
    StreetSuffixCheck AS (
    SELECT  A.*,
            Standard,
            LEFT(rightofstreetnumber, LENGTH(rightofstreetnumber)-LENGTH(streetsuffix)-1) AS StreetName
        FROM StreetSuffixExtraction A
        LEFT JOIN StreetSuffixMapping B
            ON UPPER(A.StreetSuffix)=B.Written
    )
    SELECT 'StreetNameMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B ON A.StreetName = B.StreetName
    UNION
    SELECT 'FullStreetAddressMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B 
            ON A.StreetName = B.StreetName
            AND A.streetnumber::int = B.streetnumber
            AND A.standard = B.streetsuffix
       /*
27.3) Fuzzy String Matching - Overview
While the matches above returned some results, we are relying on matching street names being spelled the 
same way in the two tables (and the extracted values being correct – we will, however, not address this 
any further below). Fuzzy string matching can be used to match strings that instead are similar, e.g., 
if two strings mean the same thing but are spelled differently, then a regular equality comparison will 
return FALSE. In fuzzy string matching, if the two stings are sufficiently similar then a fuzzy match 
may return TRUE. There are a few commonly used functions implemented in most major databases. In 
postgres, this include SOUNDEX(string), Double Metaphone, i.e., dmetaphone(string), and 
LEVENSHTEIN(string_1, string_2).  Of these three, SOUNDEX is the oldest and typically provides the worse 
performance.  The results of fuzzy matches typically has to be checked manually. For data where complete 
manual verification is not cost effective, validating a sample of the results might provide some 
indication of the performance of the fuzzy matching and which method provides the best results. 
LEVENSHTEIN outputs a distance score and different cutoffs can be evaluated using the manually verified 
sample (alternatively, the results can be rank ordered according to this score).

Soundex and Double Metaphone takes a string as input and creates a sounds like string, which is created 
following a number of hardcoded rules about how different letter and combination of letters, depending 
on their location in words, generally sound. To compare two strings, each string therefore needs to be 
convereted and then compared. Levenshtein create a distance score between two strings by calculating the 
minimum number of edits required to transform one string into the other. Edits are considered at the 
character level, and can include substitutions, deletions, and insertions.

To use these functions the following code is needed:
CREATE EXTENSION fuzzystrmatch;

To see what values are returned by the different functions, we will create a small table with a number 
of names that have some level of similarity to Johan. 

CREATE TABLE s (nm text);
INSERT INTO s VALUES ('john');
INSERT INTO s VALUES ('joan');
INSERT INTO s VALUES ('wobbly');
INSERT INTO s VALUES ('jack');
INSERT INTO s VALUES ('jonas');
INSERT INTO s VALUES ('johan');
INSERT INTO s VALUES ('johannes');
INSERT INTO s VALUES ('johann');
INSERT INTO s VALUES ('hannes');
INSERT INTO s VALUES ('yowan');

Then run the following query that displays the name from each row as well as the string Johan converted 
using soundex and dmetaphone. I also use a function that returns a SoundExDifference score and 
LEVENSHTEIN(). Both these functions take two strings as input and compared them. Finally, running 
LEVENSHTEIN and calculating scores for dissimilar variables is time consuming and typically unnessary. 
By using a function called levenshtein_less_equal, a max score is passed into the function that is then 
used to stop comparisons when the distance score is above the max score. So for example, if I know that 
I will only consider distance scores below 8 to be similar then it is not helpful to know the exact 
distance score when the distance score is higher than 8 (but it can be very costly to calculate these 
scores).

SELECT 
    *, 
    soundex(nm) AS SoundEx_Field, 
    soundex('Johan') AS SoundEx_Johan, 
    dmetaphone(nm) AS DoubleMetaphone_Field,
    dmetaphone('Johan') AS DoubleMetaphone_Johan,
    dmetaphone_alt(nm) AS DoubleMetaphoneAlt_Field,
    dmetaphone_alt('Johan') AS DoubleMetaphoneAlt_Johan,
    difference(s.nm, 'Johan') AS SoundExDifference, 
    LEVENSHTEIN(s.nm, 'Johan') AS Levenshtein,
    levenshtein_less_equal(nm, 'Johan', 2)
    FROM s;

Examples of using fuzzy matching in WHERE statement
SELECT * 
    FROM s 
    WHERE dmetaphone(nm) =  dmetaphone('Johan');

Example of using fuzzy matching in JOIN … ON statement (it is also possible to use old style joins where 
both tables are referenced in FROM and the ON logic is implemented in a WHERE statement instead). Assume 
e have a second table, FirstNames_Table, with names in a field called Name that we want to match to the 
values in the nm column of table s then:
SELECT * 
    FROM s AS A 
    JOIN FirstNames_Table AS B
    ON dmetaphone(A.nm) =  dmetaphone(B.Name);

27.4) SoundEX Difference Matching
Create another SELECT statement (and combine with the other select statements using UNION). In this 
query, use the soundex DIFFERENCE() function to find similar streetnames (use a difference score above 
3 as the cutoff). Also make sure that the streetnumbers match. Include the same fields as in 3.3 (for 
MatchType, use the string 'StreetNameAndNumberMatchSoundexDifference'.
*/
WITH 
    NotPoBox AS(
    SELECT  streetaddressline2
        FROM location
        WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'),
    StreetNumberExtraction AS(
    SELECT  streetaddressline2, 
            SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2)-1) AS StreetNumber, -- The position returns the location of the space, we do not want to include the space in the street number so we remove 1 from the length to stop pulling characters before (not including) the space
            SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2)+1) AS RightOfStreetNumber --We again do not want to include the space, so we add one to the startlocation to move one step beyond the space
        FROM NotPoBox),
    StreetNumberCheck AS(
    SELECT  *, 
            CASE WHEN StreetNumber SIMILAR TO '[0-9]+' 
                THEN  StreetNumber 
                ELSE NULL 
            END AS CheckedStreetNumber
        FROM StreetNumberExtraction),
    StreetSuffixExtraction AS(
    SELECT  *,
            RIGHT(rightofstreetnumber, POSITION(' ' IN REVERSE(rightofstreetnumber))-1) AS StreetSuffix
        FROM StreetNumberCheck),
    StreetSuffixCheck AS (
    SELECT  A.*,
            Standard,
            LEFT(rightofstreetnumber, LENGTH(rightofstreetnumber)-LENGTH(streetsuffix)-1) AS StreetName
        FROM StreetSuffixExtraction A
        LEFT JOIN StreetSuffixMapping B
            ON UPPER(A.StreetSuffix)=B.Written
    )
    SELECT 'StreetNameMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B ON A.StreetName = B.StreetName
    UNION
    SELECT 'FullStreetAddressMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B 
            ON A.StreetName = B.StreetName
            AND A.streetnumber::int = B.streetnumber
            AND A.standard = B.streetsuffix
    UNION
    SELECT 'StreetNameAndNumberMatchSoundexDifference' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B 
            ON A.streetnumber::int = B.streetnumber
        WHERE difference(A.StreetName, B.StreetName)>3;
            
/*
27.5) Levenshtein Distance Matching
Create another SELECT statement (and combine with the other select statements using UNION). Use the 
levenshtein_less_equal function to find similar streetnames (use a distance score of less than 2). 
Include the same fields as in 3.4 (for MatchType, use the string 'LevenshteinMatch'.
*/
WITH 
    NotPoBox AS(
    SELECT  streetaddressline2
        FROM location
        WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'),
    StreetNumberExtraction AS(
    SELECT  streetaddressline2, 
            SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2)-1) AS StreetNumber, -- The position returns the location of the space, we do not want to include the space in the street number so we remove 1 from the length to stop pulling characters before (not including) the space
            SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2)+1) AS RightOfStreetNumber --We again do not want to include the space, so we add one to the startlocation to move one step beyond the space
        FROM NotPoBox),
    StreetNumberCheck AS(
    SELECT  *, 
            CASE WHEN StreetNumber SIMILAR TO '[0-9]+' 
                THEN  StreetNumber 
                ELSE NULL 
            END AS CheckedStreetNumber
        FROM StreetNumberExtraction),
    StreetSuffixExtraction AS(
    SELECT  *,
            RIGHT(rightofstreetnumber, POSITION(' ' IN REVERSE(rightofstreetnumber))-1) AS StreetSuffix
        FROM StreetNumberCheck),
    StreetSuffixCheck AS (
    SELECT  A.*,
            Standard,
            LEFT(rightofstreetnumber, LENGTH(rightofstreetnumber)-LENGTH(streetsuffix)-1) AS StreetName
        FROM StreetSuffixExtraction A
        LEFT JOIN StreetSuffixMapping B
            ON UPPER(A.StreetSuffix)=B.Written
    )
    SELECT 'StreetNameMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B ON A.StreetName = B.StreetName
    UNION
    SELECT 'FullStreetAddressMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B 
            ON A.StreetName = B.StreetName
            AND A.streetnumber::int = B.streetnumber
            AND A.standard = B.streetsuffix
    UNION
    SELECT 'StreetNameAndNumberMatchSoundexDifference' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B 
            ON A.streetnumber::int = B.streetnumber
        WHERE difference(A.StreetName, B.StreetName)>3
    UNION
    SELECT 'LevenshteinMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A, Employee_Table AS B 
        WHERE levenshtein_less_equal(A.StreetName, B.StreetName,1)<2

/*
27.6) Double Metaphone Matching
Create another SELECT statement (and combine with the other select statements using UNION). Use the 
dmetaphone function to find similar streetnames. Also make sure that the streetnumbers match. Include 
the same fields as in 3.5 (for MatchType, use the string 'StreetNameandNumberDoubleMetaphoneMatch'.*/

WITH 
    NotPoBox AS(
    SELECT  streetaddressline2
        FROM location
        WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'),
    StreetNumberExtraction AS(
    SELECT  streetaddressline2, 
            SUBSTRING(streetaddressline2, 1, POSITION(' ' IN streetaddressline2)-1) AS StreetNumber, -- The position returns the location of the space, we do not want to include the space in the street number so we remove 1 from the length to stop pulling characters before (not including) the space
            SUBSTRING(streetaddressline2, POSITION(' ' IN streetaddressline2)+1) AS RightOfStreetNumber --We again do not want to include the space, so we add one to the startlocation to move one step beyond the space
        FROM NotPoBox),
    StreetNumberCheck AS(
    SELECT  *, 
            CASE WHEN StreetNumber SIMILAR TO '[0-9]+' 
                THEN  StreetNumber 
                ELSE NULL 
            END AS CheckedStreetNumber
        FROM StreetNumberExtraction),
    StreetSuffixExtraction AS(
    SELECT  *,
            RIGHT(rightofstreetnumber, POSITION(' ' IN REVERSE(rightofstreetnumber))-1) AS StreetSuffix
        FROM StreetNumberCheck),
    StreetSuffixCheck AS (
    SELECT  A.*,
            Standard,
            LEFT(rightofstreetnumber, LENGTH(rightofstreetnumber)-LENGTH(streetsuffix)-1) AS StreetName
        FROM StreetSuffixExtraction A
        LEFT JOIN StreetSuffixMapping B
            ON UPPER(A.StreetSuffix)=B.Written
    )
    SELECT 'StreetNameMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B ON A.StreetName = B.StreetName
    UNION
    SELECT 'FullStreetAddressMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B 
            ON A.StreetName = B.StreetName
            AND A.streetnumber::int = B.streetnumber
            AND A.standard = B.streetsuffix
    UNION
    SELECT 'StreetNameAndNumberMatchSoundexDifference' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B 
            ON A.streetnumber::int = B.streetnumber
        WHERE difference(A.StreetName, B.StreetName)>3
    UNION
    SELECT 'LevenshteinMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A, Employee_Table AS B 
        WHERE levenshtein_less_equal(A.StreetName, B.StreetName,1)<2
    UNION
    SELECT 'StreetNameandNumberDoubleMetaphoneMatch' AS MatchType, A.streetaddressline2, A.streetname, B.streetnumber, B.streetname, B.streetsuffix
        FROM StreetSuffixCheck AS A
        JOIN Employee_Table AS B 
            ON dmetaphone(A.StreetName) = dmetaphone(B.StreetName)
            AND A.streetnumber::int = B.streetnumber
    ORDER BY MatchType;

/*28) Pattern Matching (REGEX)
28.1 Overview, Exact Matches, and Quantifiers 
Overview
Regex is used similarly to how LIKE and SIMILAR, e.g., in WHERE and CASE WHEN logical comparisons. Posgres also has some specialized functions (see 
the bottom of this section) that use regex.  In this tutorial we will use SUBSTRING(string, regex), which returns a substring of string that matches
the pattern defined in regex. We will first start with a brief overview of regex and then use SUBSTRING(string, regex) to extract, street number, 
street name, and street suffix. In addition to using SUBSTRING, we will sometimes also use regexp_match at the same time as SUBSTRING to understand 
what is captured by REGEX and what is returned by SUBSTRING.

Exact Matches*/
SELECT SUBSTRING('XY122334Z', 'X'); --Returns X
SELECT SUBSTRING('XY122334Z', 'XY'); --Returns XY
SELECT SUBSTRING('XY122334Z', 'A'); --Returns null

/*Quantifiers
1) * means a sequence of 0 or more
2) + a sequence of 1 or more
3) ? a sequence of 0 or 1
4) {n} a sequence of n
5) {n,m} a sequence of n to m

If RE matches more than one substring of a given string, the RE matches the substring with the earliest starting point in the string. If 
RE can match more than one substring starting at that point, the longest possible match is taken (unless non-greedy behavior is used).
*/

SELECT SUBSTRING('XY122334Z', '2+'); 
-- Searches for at least one occurrence of 2, after it finds a 2 it attempts to match as many 2s as possible (regex is greedy after it has found a match). Returns 22.

SELECT SUBSTRING('XY122334Z', '2*'); 
-- The very first character satisfies the criteria to find 0 2s, but since this match contains nothing, an empty string is returned.

SELECT SUBSTRING('22XY122334Z', '2*'); 
/*This time regex finds a 2 immediately (notice that I changed the string on the left) and after it has found a match it is greedy and 
consumes as much as possible. Returns 22.*/

SELECT SUBSTRING('XY122334Z', '2{1,2}'); 
--Returns 22

/*28.2 Capturing Groups and Bracket Expressions
By placing part of a regular expression inside parentheses, you can group that part of the regular expression together. This allows 
you to apply a quantifier to the entire group or to restrict alternation to part of the regex. Parentheses also create a numbered capturing 
group, which stores substrings that match the regex pattern inside the parentheses. When using SUBSTRING, if multiple capturing groups match 
then the results from the first capturing group is returned.
*/

SELECT SUBSTRING('XY122334Z', '(X)(Y)'); 
--Here we have X in one capturing group and Y in a second capturing group - the first capturing group is returned
SELECT regexp_match('XY122334Z', '(X)(Y)'); 
--Here we have X in one capturing group and Y in a second capturing group

SELECT SUBSTRING('XY122334Z', 'X(Y)'); 
-- We now only have one capturing group, (Y), so Y is returned. Here X, however has to precede Y. 

SELECT regexp_match('XY122334Z', 'X(Y)'); 
--We now only have one capturing group

SELECT SUBSTRING('XY122334Z', 'X(Z)'); 
--Returns null because the pattern XZ does not appear in the string

--Bracket Expressions
-- In the code below, the square brackets act as OR
SELECT SUBSTRING('X9Y122334Z', '[0123]'); 

--Here we use 0-9 as a shortcut for says any character between 0 and 9 (inclusive)
SELECT SUBSTRING('X9Y122334Z', '[0-9]'); 
-- 9 is returned - while multiple patterns can be identified, regex returns the pattern with the earliest starting point
SELECT SUBSTRING('X9Y122334Z', '[0-9]{2}'); 
-- 12 is returned - The curly brackets are saying that exactly 2 sequential matches should be found.

SELECT SUBSTRING('X9Y122334Z', '[0-9]{2,4}');
/*1223 is returned - The curly brackets are saying that between 2 and 4 characters should match. While regex returns the pattern with the earliest 
matching location, regex is greedy and tries to consume as much of the string as possible (making the match as long as possible).*/

SELECT SUBSTRING('X9Y122334Z', '[0-9]{2,4}?'); 
/*12 is returned - The question mark makes regex non-greedy, which means it tries to consume as few characters as possible and not instead returns the 
shortest match (still with the first starting point).*/

/*Combining capturing groups, bracket expression (OR), and quantifiers
 --'Y([0-9]{1,3})'
 --Find a Y followed by any character between 0 and 9 and 1 to 3 of those characters:*/
SELECT SUBSTRING('XY122334Z', 'Y([0-9]{1,3})'); --Returns 122
SELECT SUBSTRING('XYX12233Z', 'Y([0-9]{1,3})'); --Returns null

--If you also want to return the Y then use:
SELECT SUBSTRING('XY122334Z', '(Y[0-9]{1,3})'); --Returns Y122

/*
28.3 REGEX Search Behavior 
As noted earlier, in the event that an RE matches more than one substring of a given string, the RE matches the one starting earliest in the string. If the 
RE could match more than one substring starting at that point, either the longest possible match or the shortest possible match will be taken, depending on 
whether the RE is greedy or non-greedy.
*/
-- With two matches in the same string, the first match is returned.
SELECT SUBSTRING('XY122338___XY3324XZ', 'Y([0-9]{1,3})'); 
--We now have two potential starting positions. The match with the earliest starting position is returned, i.e., 122.
/*
To instead capture the last group we can use a wild card '.'. The period means any character. Other common wildcards include (I am also repeating the 
period to make it easier to find this information):
•	.	means any single character
•	\d means any single digit (the same as [0-9] and [0123456789)
•	\s	 means any single space
•	\w	means any single number, letter, or underscore

You can also form wildcards using square brackets, similarly to \d and [0-9] meaning the same thing.*/

SELECT SUBSTRING('XY122338___XY3324XYZ', '.*Y([0-9]{1,3})'); 
/*
Remember that . means any character and that * means 0 or more of the item (or capturing group) immediately before it, so .* means 0 or more of any character. 
Here regex finds a match right away and continues eating “any characters” until it encounters a Y. Because it is greedy it consumes as much as possible and therefore 
matches on the second Y (notice that it does not match on the third Y as this Y is not followed by digits). So it therefore returns 332.

-- To control what part of the matching group is returned, you can change regex to be non-greedy by placing a ? after the quantifier.

--Example of greedy*/
SELECT SUBSTRING('XY122338___XY3324XZ', 'Y.*([0-9]{1,3})'); 
/*There are still two starting positions, but the are also a number of matches for the first starting position (the Y can be followed by any number of 
characters, including digits, so the first 1 can even be skipped). Here regex again starts at the first matching location but then consumes as many 
characters as possible. As 0-9 has to match between 1 and 3 times the most characters that regex can consume makes it find the very last single digit 
and 4 is returned.

--Example of non-greedy*/
SELECT SUBSTRING('XY122338___XY3324XZ', 'Y.*?([0-9]{1,3})');
/*Now regex is asked to consume as few characters as possible and 1 is returned.

-- However!
 --'Y?([0-9]{1,3})'
 --? Now mean find 0 or one Y followed by any character between 0 and 9 and 1 to 3 of those characters
*/
SELECT SUBSTRING('XY122338___XY3324XZ', 'Y?([0-9]{1,3})');
SELECT SUBSTRING('XYX122338___XY3324XZ', 'Y?([0-9]{1,3})');
/*Both these version return 122. The first line finds the first Y that is then followed by numbers and returns the numbers (excludes the Y as it is not 
in the capturing group). The second line does not find a match with the first Y as it is not followed by numbers. It does, however match these numbers 
as it find a match for no Y followed by digits. (It also finds matches for Y332, but the start position of this match is later so it is not returned). 
Since the Y is optional, it is in the beginning of the pattern, and it is not inside a capturing group, then we might as well remove the 'Y?'.*/

--Let’s move 'Y?' inside the capturing group:
SELECT SUBSTRING('XY122338___XY3324XZ', '(Y?[0-9]{1,3})');
SELECT SUBSTRING('XYX122338___XY3324XZ', '(Y?[0-9]{1,3})');
/*The two SUBSTRINGS now return Y112 and 122, respectively. Just like in the previous example, the first line finds Y followed by numbers, but now returns Y112 
because the Y and the numbers are part of the capturing group. The second line acts just like in the previous example.

Some important regex that are not part of the assignment:

Escape	Description
^	matches at the beginning of the string
$	matches at the end of the string
\A	matches only at the beginning of the string
\Z	matches only at the end of the string 
\m	matches only at the beginning of a word
\M	matches only at the end of a word
\y	matches only at the beginning or end of a word
\Y	matches only at a point that is not the beginning or end of a word
(?=re)	positive lookahead matches at any point where a substring matching re begins (AREs only)
(?!re)	negative lookahead matches at any point where no substring matching re begins (AREs only)

28.4 Regex in Postgres (tutorial also include instructions for first exercise below)
Integrating regex in postgres

In regular comparisons, e.g., WHERE, CASE WHEN, etc.
•	~  case sensitive match
•	~* case insensitive match
•	!~  case sensitive match, and returns true if the regex does not match any part of the string
•	!~*  case insensitive match; returns true if the regex does not match any part of the string
regexp_split_to_table(subject, pattern[, flags])
regexp_split_to_array(subject, pattern[, flags]) 
With regexp_replace(subject, pattern, replacement [, flags]) you can replace regex matches in a string. If you omit the flags parameter, the regex is applied 
case sensitively, and only the first match is replaced. If you set the flags to 'i', the regex is applied case insensitively. The 'g' flag (for “global”) causes 
all regex matches in the string to be replaced. You can combine both flags as 'gi'.

28.5 Exercises (tutorial for second and third exercise)
•	From streetaddressline2 use SUBSTRING with regex and extract street number and make sure it is numeric (you can assume it is all the digits before the first 
    space in streetaddressline2).
•	From streetaddressline2 use SUBSTRING with regex and the suffix (you can assume it is the last set of characters following the last space in streetaddressline2.
•	From streetaddressline2 use SUBSTRING with regex and extract the streetname, you can assume it is all the character between the first and last spaces.
*/

SELECT 

WITH 
    NotPoBox AS(
    SELECT  streetaddressline2
        FROM location
        WHERE LEFT(streetaddressline1, 6) NOT LIKE 'PO Box'),
    StreetParsing AS(
    SELECT  streetaddressline2, 
            SUBSTRING(streetaddressline2, '[0-9]+\s') AS StreetNumber,
            SUBSTRING(streetaddressline2, '.*\s([a-zA-Z]+)') AS StreetSuffix,
            SUBSTRING(streetaddressline2, '[0-9]+\s(.*\s)') AS StreetName

        FROM NotPoBox)
    SELECT * FROM StreetParsing

SELECT SUBSTRING('1234 Hello World Street', '[0-9]+\s(.*\s)')