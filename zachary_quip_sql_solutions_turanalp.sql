-- This file contains Mehmet Emin Turanalp's solutions to SQL exercises in Zachary Thomas's post at https://quip.com/2gwZArKuWk7W .
-- Tested in POSTGRESQL
-- More solutions to Hackerrank SQL questions are available at https://github.com/eturanalp/SQL_problems

--#1: MoM Percent Change 
-----------------------------------------
--CREATE TABLE logins ( 
--	user_id INT NOT NULL,
--    date DATE);
--INSERT INTO logins VALUES(1,'2020-03-15');
--INSERT INTO logins VALUES(2,'2020-04-16');
--INSERT INTO logins VALUES(3,'2020-04-16');
--INSERT INTO logins VALUES(1,'2020-05-16');
--INSERT INTO logins VALUES(2,'2020-05-16');
--INSERT INTO logins VALUES(3,'2020-05-16');
--SELECT * FROM logins;

WITH login_months(month, ucount,rank) AS
  (SELECT to_date(CONCAT(date_part('year',date),'-',date_part('month',date),'-','01'),'YYYY-MM-DD') as month, 
       COUNT(DISTINCT(user_id)) as ucount, 
	   RANK() OVER(ORDER BY to_date(CONCAT(date_part('year',date),'-',date_part('month',date),'-','01'),'YYYY-MM-DD')) 
   FROM logins
   GROUP BY month)
SELECT lm1.month as month, lm2.month as following_month , lm1.ucount, lm2.ucount, 100*(lm2.ucount-lm1.ucount)/lm1.ucount::float as percent_change
FROM login_months lm1
LEFT JOIN login_months lm2 ON lm1.rank + 1 =lm2.rank;

-- INSERT INTO logins VALUES(4,'2019-12-16');
-- INSERT INTO logins VALUES(5,'2019-12-16');
-- INSERT INTO logins VALUES(6,'2019-12-18');
-- INSERT INTO logins VALUES(4,'2020-01-02');

--Note that unlike Zachary's solution, this links months even if there is break in the sequence(e.g. between 2020-01 and 2020-03).
--Sample output:
--"2019-12-01"	"2020-01-01"	3	1	-66.6666666666667
--"2020-01-01"	"2020-03-01"	1	1	0
--"2020-03-01"	"2020-04-01"	1	2	100
--"2020-04-01"	"2020-05-01"	2	3	50
--"2020-05-01"		3		
 
 
--#2: Tree Structure Labeling
------------------------------------------

-- CREATE TABLE tree(
--   node int NOT NULL,
--   parent int
--   );
-- INSERT INTO tree VALUES(1,2);
-- INSERT INTO tree VALUES(2,5);
-- INSERT INTO tree VALUES(3,5);
-- INSERT INTO tree VALUES(4,3);
-- INSERT INTO tree VALUES(5,NULL);
-- INSERT INTO tree VALUES(6,3);
-- INSERT INTO tree VALUES(7,4);

--SELECT * FROM tree;
SELECT node, MAX(label) as label
FROM (
   SELECT t1.node as node, t1.parent as parent, t2.node as child, 
       CASE WHEN t1.parent IS NULL THEN 'Root'
	        WHEN t2.node IS NULL then 'Leaf'
			ELSE 'Inner'
			END as label
   FROM tree t1
   LEFT JOIN tree t2 ON t1.node=t2.parent) t
GROUP BY t.node


--#3: Retained Users Per Month (multi-part)
--------------------------------------------------
--Part 1
SELECT CONCAT(date_part('year',date),'-',date_part('month',date)) month_, COUNT(DISTINCT(login1.user_id))
FROM logins login1
WHERE EXISTS(
	SELECT * FROM logins login2 
	WHERE login1.user_id=login2.user_id AND 
          date_trunc('month',login1.date) = date_trunc('month',login2.date) + interval '1 month')
GROUP BY month_;

--Part 2
SELECT date_trunc('month',login1.date) + interval '1 month' month_, COUNT(DISTINCT(login1.user_id))
FROM logins login1
WHERE NOT EXISTS(
	SELECT * FROM logins login2 
	WHERE login1.user_id=login2.user_id AND 
          date_trunc('month',login1.date) = date_trunc('month',login2.date) - interval '1 month')
GROUP BY month_;

--Part 3
SELECT CONCAT(date_part('year',date),'-',date_part('month',date)) month_, COUNT(DISTINCT(login1.user_id))
FROM logins login1
WHERE 
  NOT EXISTS(  --churned last month or earlier
 	SELECT * FROM logins login2 
 	WHERE login1.user_id=login2.user_id AND 
           date_trunc('month',login1.date) = date_trunc('month',login2.date) + interval '1 month')
  AND EXISTS ( --was active before
 	SELECT * FROM logins login2 
 	WHERE login1.user_id=login2.user_id AND 
           date_trunc('month',login1.date) > date_trunc('month',login2.date) + interval '1 month')
 GROUP BY month_;
 
 
 --#4: Cumulative Sums
 -----------------------------------------
 -- CREATE TABLE transactions (
-- date date NOT NULL,
-- cash_flow int NOT NULL);
-- INSERT INTO transactions VALUES('2020-01-01',-1000);
-- INSERT INTO transactions VALUES('2020-01-01',-100);
-- INSERT INTO transactions VALUES('2020-01-01',50);
SELECT date, SUM(cash_flow) OVER(order by date ASC rows between unbounded preceding and current row) as total
FROM transactions
ORDER BY date ASC


--#5: Rolling Averages
-----------------------------------------
--CREATE TABLE signups (
--   date date NOT NULL,
--   sign_ips int NOT NULL);
--
-- INSERT INTO signups VALUES('2020-01-01',10);
-- INSERT INTO signups VALUES('2020-01-02',20);
-- INSERT INTO signups VALUES('2020-01-03',30);
-- INSERT INTO signups VALUES('2020-01-04',40);
-- INSERT INTO signups VALUES('2020-01-05',50);

SELECT date,
       AVG(sign_ips) OVER(ORDER BY date ASC rows between 6 preceding and current row) as avg
FROM signups
ORDER BY date ASC;


--#6: Multiple Join Conditions
-------------------------------------------
-- CREATE TABLE emails (
--    id int NOT NULL PRIMARY KEY,
--    subject varchar(50),
--    from_ varchar(50) NOT NULL,
--    to_ varchar(50) NOT NULL,
--    timestamp timestamp WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL);
   
-- INSERT INTO emails VALUES(1,'Yosemite','zach@g.com','thomas@g.com','2018-01-02 12:45:03');
-- INSERT INTO emails VALUES(2,'Big Sur','sarah@g.com','thomas@g.com','2018-01-02 16:30:01');
-- INSERT INTO emails VALUES(3,'Yosemite','thomas@g.com','zach@g.com','2018-01-02 16:35:04');
-- INSERT INTO emails VALUES(4,'Running','jill@g.com','zach@g.com','2018-01-03 08:12:45');
-- INSERT INTO emails VALUES(5,'Yosemite','zach@g.com','thomas@g.com','2018-01-03 14:02:01');
-- INSERT INTO emails VALUES(6,'Yosemite','thomas@g.com','zach@g.com','2018-01-03 15:01:05');
-- INSERT INTO emails VALUES(7,'Yosemite','zach@g.com','thomas@g.com','2018-01-04 01:35:04');
-- INSERT INTO emails VALUES(8,'Yosemite','zach@g.com','thomas@g.com','2018-01-05 01:35:04');

SELECT e1id as id , response_time
FROM (
  SELECT e1.id as e1id, e2.id as e2id, e2.timestamp-e1.timestamp as response_time, ROW_NUMBER() OVER (PARTITION BY e1.id ORDER BY e2.timestamp ASC) as rn 
  FROM emails e1
  JOIN emails e2 ON e1.subject=e2.subject AND e1.from_=e2.to_ AND e2.from_='zach@g.com'
  WHERE e1.to_='zach@g.com' AND e2.timestamp>e1.timestamp ) from_to
WHERE rn=1;

-- #1: Histograms
----------------------------------------------
-- CREATE TABLE sessions (
--   session_id int PRIMARY KEY,
--   length_seconds int NOT NULL);

-- INSERT INTO sessions VALUES(1,23);
-- INSERT INTO sessions VALUES(2,8);
-- INSERT INTO sessions VALUES(3,45);
-- INSERT INTO sessions VALUES(4,34);
-- INSERT INTO sessions VALUES(5,89);
-- INSERT INTO sessions VALUES(6,83);
-- INSERT INTO sessions VALUES(7,4);
-- INSERT INTO sessions VALUES(8,5);

WITH 
min AS
( SELECT MIN(length_seconds) FROM sessions),
max as 
( SELECT MAX(length_seconds) FROM sessions),
buckets as
( SELECT session_id, 
         CAST (round(((length_seconds::float-min+0.001)/(max-min-0.001)) *10) as integer) as bin,
         min+(round(((length_seconds::float-min+0.001)/(max-min-0.001)) *10))::int*9 as binstring
  FROM min, max, sessions)
SELECT bin,binstring, COUNT(session_id)
FROM buckets
GROUP BY bin,binstring
ORDER BY bin

-- #2: CROSS JOIN (multi-part)
--PArt 2
-----------------------------------------------------

-- CREATE TABLE state_streams (
--    state varchar(2) NOT NULL,
--    total_streams int NOT NULL);

-- INSERT INTO state_streams VALUES('NC',34569);
-- INSERT INTO state_streams VALUES('SC',33999);
-- INSERT INTO state_streams VALUES('CA',98324);
-- INSERT INTO state_streams VALUES('MA',19345);
-- INSERT INTO state_streams VALUES('NJ',19745);

SELECT * 
FROM state_streams s1, state_streams s2
WHERE s1.total_streams<s2.total_streams AND s1.total_streams+1000>s2.total_streams


--#3: Advancing Counting
----------------------------------------------------
-- CREATE TABLE "table" (
--    "user" int NOT NULL,
--    class char NOT NULL);

-- INSERT INTO "table" VALUES(1,'a');
-- INSERT INTO "table" VALUES(1,'b');
-- INSERT INTO "table" VALUES(1,'b');
-- INSERT INTO "table" VALUES(2,'b');
-- INSERT INTO "table" VALUES(3,'a');
-- INSERT INTO "table" VALUES(4,'b');

SELECT class, COUNT("user")
FROM (
   SELECT "user", COUNT(DISTINCT(class)) as cc, MAX(class) as class
   FROM "table"
   GROUP BY "user") ccc
GROUP BY class;
-- Probably by coincidence this works because the max of {a,b} is b, the max of {b} is b and the max of {a} is a.
   