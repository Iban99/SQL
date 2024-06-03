-- ************************************ QUERIES VARIAS ************************************** --

------------------------------------- QUERY 1 --------------------------------------------------------
/* +-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| name        | varchar |
| department  | varchar |
| managerId   | int     |
+-------------+---------+
id is the primary key (column with unique values) for this table.
Each row of this table indicates the name of an employee, their department, and the id of their manager.
If managerId is null, then the employee does not have a manager.
No employee will be the manager of themself.
 

Write a solution to find managers with at least five direct reports.

Return the result table in any order.

The result format is in the following example. */

with managers as( 
    select managerID, count(*) recuento
    from Employee
    group by managerID
    having count(*) >= 5
)
select e.name
from Employee e
join managers m
    on e.id = m.managerID;

   
------------------------------------- QUERY 2 --------------------------------------------------------
/*Table: Signups

+----------------+----------+
| Column Name    | Type     |
+----------------+----------+
| user_id        | int      |
| time_stamp     | datetime |
+----------------+----------+
user_id is the column of unique values for this table.
Each row contains information about the signup time for the user with ID user_id.
 

Table: Confirmations

+----------------+----------+
| Column Name    | Type     |
+----------------+----------+
| user_id        | int      |
| time_stamp     | datetime |
| action         | ENUM     |
+----------------+----------+
(user_id, time_stamp) is the primary key (combination of columns with unique values) for this table.
user_id is a foreign key (reference column) to the Signups table.
action is an ENUM (category) of the type ('confirmed', 'timeout')
Each row of this table indicates that the user with ID user_id requested a confirmation message at time_stamp and that confirmation message was either confirmed ('confirmed') or expired without confirming ('timeout').
 

The confirmation rate of a user is the number of 'confirmed' messages divided by the total number of requested confirmation messages. The confirmation rate of a user that did not request any confirmation messages is 0. Round the confirmation rate to two decimal places.

Write a solution to find the confirmation rate of each user.

Return the result table in any order. */
   
select s.user_id, 
    round(avg(case when action = 'confirmed' then 1 else 0 end),2) as confirmation_rate
from Signups s 
left join Confirmations c
    on s.user_id = c.user_id
group by s.user_id
order by confirmation_rate;


------------------------------------- QUERY 3 --------------------------------------------------------
/* Assume you're given a table containing information on Facebook user actions. Write a query to 
obtain number of monthly active users (MAUs) in July 2022, including the month in numerical format "1, 2, 3".

Hint:
	An active user is defined as a user who has performed actions such as 'sign-in', 'like', or 'comment' 
	in both the current month and the previous month.

user_actions Table:
ColumnName	Type
user_id		integer
event_id	integer
event_type	string ("sign-in, "like", "comment")
event_date	datetime

*/
select date_part('month', mes_actual.event_date) as mth,
  count(distinct mes_actual.user_id) as monthly_active_users
from user_actions as mes_previo
join user_actions as mes_actual
  on mes_previo.user_id = mes_actual.user_id
    and date_part('year', mes_previo.event_date) = date_part('year', mes_actual.event_date)
    and date_part('month', mes_previo.event_date) = date_part('month', mes_actual.event_date - interval '1 month')
where
  mes_actual.event_date >= '07-01-2022'
  and mes_actual.event_date < '08-01-2022'
group by date_part('month', mes_actual.event_date);


------------------------------------- QUERY 4 --------------------------------------------------------
/*Given a table of tweet data over a specified time period, calculate the 3-day rolling average of tweets 
for each user. Output the user ID, tweet date, and rolling averages rounded to 2 decimal places.

A rolling average, also known as a moving average or running mean is a time-series technique that examines 
trends in data over a specified period of time.
In this case, we want to determine how the tweet count for each user changes over a 3-day period.

tweets Table:
ColumnName	Type
user_id		integer
tweet_date	timestamp
tweet_count	integer 
*/
select user_id, 
  tweet_date,
  round(avg(tweet_count) over(partition by user_id 
                        order by tweet_date 
                        rows between 2 preceding and current row),2) as rolling_avg_3d
from tweets;


------------------------------------- QUERY 5 --------------------------------------------------------
/* Assume you're given a table containing data on Amazon customers and their spending on products 
in different category, write a query to identify the top two highest-grossing products within each 
category in the year 2022. The output should include the category, product, and total spend.

product_spend Table:
ColumnName			Type
category			string
product				string
user_id				integer
spend				decimal
transaction_date	timestamp
*/
with ranking as(
  SELECT category, 
    product, 
    sum(spend) total_spend,
    dense_rank() over (partition by category order by sum(spend) desc) as rango
  from product_spend
  where date_part('year', transaction_date) = '2022'
  group by product, category
  order by category, product
)
select category, product, total_spend
from ranking
where rango IN(1,2)
order by category, total_spend desc;


------------------------------------- QUERY 6 --------------------------------------------------------
/* As part of an ongoing analysis of salary distribution within the company, your manager has 
requested a report identifying high earners in each department. A 'high earner' within a 
department is defined as an employee with a salary ranking among the top three unique salaries 
within that department.

You're tasked with identifying these high earners across all departments. Write a query to display 
the employee's name along with their department name and salary. In case of duplicates, sort the 
results by department ID and salary in descending order. If multiple employees have the same salary, 
then order them alphabetically.

Note: Ensure to utilize the appropriate ranking window function to handle duplicate salaries effectively.

employee Schema:
column_name 	type		description
employee_id		integer		The unique ID of the employee.
name			string		The name of the employee.
salary			integer		The salary of the employee.
department_id	integer		The department ID of the employee.
manager_id		integer		The manager ID of the employee.

department Schema:
column_name		type		description
department_id	integer		The department ID of the employee.
name			string		The name of the department.

 */
with ranking as (
  SELECT e.department_id as departmentID, 
    d.department_name as department_name,
    e.employee_id as employee_id, 
    e.name as name,
    e.salary as salary,
    dense_rank() over(partition by e.department_id order by e.salary desc) as rango
  from employee e
  left join department d
    on e.department_id = d.department_id 
  group by e.department_id, d.department_name, e.employee_id, e.name, e.salary
  order by e.department_id
)
select department_name, name, salary
from ranking
where rango <= 3
order by departmentID, salary desc, name;
