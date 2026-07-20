create table amazon_analysis.customers
(
customer_id varchar primary key,
customer_unique_id varchar,
customer_zip_code_prefix integer
)

select * from amazon_analysis.customers 

create  table amazon_analysis.seller
(
seller_id varchar primary key,
seller_zip_code_prefix integer,
seller_city varchar,
seller_state varchar
)

copy amazon_analysis.seller 
from 'D:\sql data\seller.csv'
DELIMITER ','
CSV HEADER;

alter table amazon_analysis.seller
drop column seller_city, drop column seller_state

select * from amazon_analysis.seller

create table amazon_analysis.order_items
(
order_id varchar,
order_item_id integer,
product_id varchar,
seller_id varchar,
shipping_limit_date timestamp,
price integer,
freight_value integer
)

alter table amazon_analysis.order_items
alter column price type numeric(10,2),
alter column freight_value type numeric(10,2);

select * from amazon_analysis.order_items

create table amazon_analysis.payments
(
order_id varchar,
payment_sequential integer,
payment_type varchar,
payment_installments integer,
payment_value integer,
constraint payments_pk primary key (order_id, payment_sequential)
)

alter table amazon_analysis.payments
alter column payment_value type numeric(10,2);

select * from amazon_analysis.payments 

create table amazon_analysis.orders(
order_id varchar,
customer_id varchar,
order_status varchar,
order_purchase_timestamp timestamp,
order_approved_at timestamp,
order_deliver_carrier_date timestamp,
order_delivered_customer_date timestamp,
order_estimated_delivery_date timestamp
)

select * from amazon_analysis.orders 

create table amazon_analysis.products
(
product_id varchar primary key,
product_category_name varchar,
product_name_lenght integer,
product_description_lenght integer,
product_photos_qty integer,
product_weight_g integer,
product_length_cm integer,
product_height_cm integer,
product_width_cm integer
)

select * from amazon_analysis.products


--Analysis - I

/*
Q1.Round the average payment values to integer (no decimal) for each payment type and 
display the results sorted in ascending order.
*/

SELECT payment_type,round(AVG(payment_value), 0) AS rounded_avg_payment
FROM amazon_analysis.payments
GROUP BY payment_type
ORDER BY rounded_avg_payment ASC

/*
Q2. Calculate the percentage of total orders for each payment type, rounded to one decimal place, 
and display them in descending order.
*/

select payment_type,round(count(*) * 100.0 / (select count(*) from amazon_analysis.payments),1)
as percentage_orders
from amazon_analysis.payments
group by payment_type
order by percentage_orders desc


/*
Q3.Identify all products priced between 100 and 500 BRL that contain the word 'Smart' in their name.
Display these products, sorted by price in descending order. (order items + products)
*/

select p.product_id,p.product_category_name,oi.price
from amazon_analysis.products p
join amazon_analysis.order_items oi
on p.product_id = oi.product_id
where oi.price between 100 and 500
and p.product_category_name ilike '%Smart%'
order by oi.price desc


/*
Q4.Determine the top 3 months with the highest total sales value, rounded to the nearest integer.(order+order_items)
*/

select date_trunc('month', o.order_purchase_timestamp) as month,
round(sum(oi.price)) as total_sales
from amazon_analysis.orders o
join amazon_analysis.order_items oi
on o.order_id = oi.order_id
group by month
Order by total_sales DESC
limit 3


/*
Q5.Find categories where the difference between the maximum and minimum product prices is greater than 500 BRL.(product + order_items)
*/

select p.product_category_name,
max(oi.price) as max_price,
min(oi.price) as min_price,
max(oi.price) - min(oi.price) as price_difference
from amazon_analysis.products p
join amazon_analysis.order_items oi
on p.product_id = oi.product_id
group by p.product_category_name
having max(oi.price) - min(oi.price) > 500
order by price_difference desc




/*
Q6.Identify the payment types with the least variance in transaction amounts,sorting by the smallest standard 
deviation first.
*/

select payment_type,round(STDDEV(payment_value), 2) AS std_deviation
from amazon_analysis.payments
group by payment_type
order by std_deviation asc

/*
Q7.Retrieve the list of products where the product category name is missing or contains only a single character.
*/

select product_id, product_category_name
from amazon_analysis.products
where product_category_name is null
or length(trim(product_category_name)) <= 1


--Analysis - II


/*
Q1.Segment order values into three ranges: orders less than 200 BRL, between 200 and 1000 BRL, and over 1000 BRL. 
Calculate the count of each payment type within these ranges and display the results in descending order of count
*/

select case when payment_value < 200 then 'Less than 200 BRL'
when payment_value between 200 AND 1000 then '200 - 1000 BRL'
else 'Over 1000 BRL'
end as order_range,payment_type, count (*) as payment_count
from amazon_analysis.payments
group by order_range, payment_type
order by payment_count DESC

/*
Q2.Calculate the minimum, maximum, and average price for each category, and list them in descending order 
by the average price. (order_items + products)
*/

select p.product_category_name,
min(oi.price) as min_price,
max(oi.price) as max_price,
round(avg(oi.price), 2) as avg_price
from amazon_analysis.products p
join amazon_analysis.order_items oi
on p.product_id = oi.product_id
group by p.product_category_name
order by avg_price desc



/*
Q3.Find all customers with more than one order, and display their customer unique IDs along with the total number of 
orders they have placed. (orders + customers)
*/

select c.customer_unique_id,count(o.order_id) as total_orders
from amazon_analysis.customers c
join amazon_analysis.orders o
on c.customer_id = o.customer_id
group by c.customer_unique_id
having count(o.order_id) > 1
order by total_orders desc


/*
Q4.Use a temporary table to define these categories and join it with the customers table to update and display 
the customer types.
*/

with cte as (
select c.customer_id,c.customer_unique_id,
count(o.order_id) as total_orders
from amazon_analysis.customers c
join amazon_analysis.orders o
on c.customer_id = o.customer_id
group by c.customer_id, c.customer_unique_id
)
select customer_unique_id,total_orders,
case when total_orders = 1 then 'New'
when total_orders between 2 and 4 then 'Returning'
else 'Loyal'
end as customer_type
from cte
order by total_orders desc

/*
Q5.Use joins between the tables to calculate the total revenue for each product category. Display the top 5 
categories.(product + order items)
*/

select p.product_category_name, round(sum(oi.price)) as total_revenue
from amazon_analysis.products p
join amazon_analysis.order_items oi
on p.product_id=oi.product_id
group by p.product_category_name
order by total_revenue desc
limit 5
 



--Analysis - III


/*
Q1.Use a subquery to calculate total sales for each season (Spring, Summer, Autumn, Winter) based on order purchase 
dates, and display the results. Spring is in the months of March, April and May. Summer is from June to August 
and Autumn is between September and November and rest months are Winter. (order + order_items)
*/

select season,round(sum(total_sales)) as total_sales
from
(
select case 
when extract(month from o.order_purchase_timestamp) in (3,4,5) then 'Spring'
when extract(month from o.order_purchase_timestamp) in (6,7,8) then 'Summer'
when extract(month from o.order_purchase_timestamp) in (9,10,11) then 'Autumn'
else 'Winter'
end as season,
oi.price as total_sales
from amazon_analysis.orders o
JOIN amazon_analysis.order_items oi
ON o.order_id = oi.order_id
) 
as seasonal_sales
group by season
order by total_sales desc


/*
Q2.Write a query that uses a subquery to filter products with a total quantity sold above the average quantity.
*/


SELECT p.product_id,
count(oi.order_item_id) as total_quantity_sold
from amazon_analysis.products p
join amazon_analysis.order_items oi
on p.product_id = oi.product_id
group by p.product_id
having count (oi.order_item_id) > (
    select avg (product_quantity)
    from (
        select count(order_item_id) as product_quantity
        from amazon_analysis.order_items
        group by product_id
    ) as avg_table
)
order by total_quantity_sold desc


/*
Q3.Run a query to calculate total revenue generated each month and identify periods of peak and low sales. Export the 
data to Excel and create a graph to visually represent revenue changes across the months. 
*/

with cte as (
select date_trunc('month', o.order_purchase_timestamp) as month,
sum(oi.price) as total_revenue
from amazon_analysis.orders o
join amazon_analysis.order_items oi
on o.order_id = oi.order_id
where extract(year from o.order_purchase_timestamp) = 2018
group by date_trunc('month', o.order_purchase_timestamp)
)
select to_char(month, 'YYYY-MM') as month,
round(total_revenue, 0) as total_revenue,
case 
when total_revenue = (select max(total_revenue) from cte)
then 'Peak Sales'
when total_revenue = (select min(total_revenue) from cte)
then 'Low Sales'
else 'Normal'
end as sales_period
from cte
order by month




/*
Q4.Create a segmentation based on purchase frequency: ‘Occasional’ for customers with 1-2 orders, ‘Regular’ for
3-5 orders, and ‘Loyal’ for more than 5 orders. Use a CTE to classify customers and their count and generate 
a chart in Excel to show the proportion of each segment.
*/

with customer_orders as (
select c.customer_unique_id,
count(o.order_id) as total_orders
from amazon_analysis.customers c
join amazon_analysis.orders o
on c.customer_id = o.customer_id
group by c.customer_unique_id
),
customer_segments as (
select 
case 
when total_orders between 1 and 2 then 'Occasional'
when total_orders between 3 and 5 then 'Regular'
else 'Loyal'
end as customer_type
from customer_orders
)
select customer_type,
count(*) as count
from customer_segments
group by customer_type





/*
Q5.You are required to rank customers based on their average order value (avg_order_value) to find the top 20 
customers.
*/


select customer_unique_id,ROUND(avg_order_value, 2) as avg_order_value,
dense_rank() over (order by avg_order_value desc) as customer_rank
from (
select c.customer_unique_id,
avg(order_value) as avg_order_value
from (
select o.order_id,o.customer_id,
sum(oi.price) as order_value
from amazon_analysis.orders o
join amazon_analysis.order_items oi
on o.order_id = oi.order_id
group by o.order_id, o.customer_id
) 
as order_totals
join amazon_analysis.customers c
on order_totals.customer_id = c.customer_id
group by c.customer_unique_id
) 
as customer_avg
order by avg_order_value desc
limit 20


/*
Q6.Calculate monthly cumulative sales for each product from the date of its first sale. Use a recursive CTE to compute 
the cumulative sales (total_sales) for each product month by month.
*/

with recursive monthly_sales as (
select oi.product_id, DATE_TRUNC('month', o.order_purchase_timestamp) as month,
sum(oi.price) as monthly_total
from amazon_analysis.orders o
join amazon_analysis.order_items oi
on o.order_id = oi.order_id
group by oi.product_id, month
),

ordered_sales as (
select product_id,
month, monthly_total, 
row_number() over (partition by product_id order by month) as rn
from monthly_sales
),

recursive_sales as (
select product_id, month, monthly_total, monthly_total AS total_sales, rn
from ordered_sales
where rn = 1
union all
select os.product_id, os.month, os.monthly_total, rs.total_sales + os.monthly_total as total_sales, os.rn
from ordered_sales os
join recursive_sales rs
on os.product_id = rs.product_id
and os.rn = rs.rn + 1
)

select product_id, month,
ROUND(total_sales, 2) as total_sales
from recursive_sales
order by product_id, month




/*
Q7.Write query to first calculate total monthly sales for each payment method, then compute the percentage change from the
previous month. (ordder + payments)
*/


with monthly_sales as (
select p.payment_type, DATE_TRUNC('month', o.order_purchase_timestamp) as sale_month,
sum(p.payment_value) as monthly_total
from amazon_analysis.orders o
join amazon_analysis.payments p
on o.order_id = p.order_id
where extract(year from o.order_purchase_timestamp) = 2018
group by p.payment_type, DATE_TRUNC('month', o.order_purchase_timestamp)
)

select payment_type,
TO_CHAR(sale_month, 'YYYY-MM') as sale_month,
ROUND(monthly_total, 0) as monthly_total,
ROUND(
  (
  (monthly_total - lag(monthly_total) over (
partition by payment_type 
order by sale_month
   ))
   /
nullif(
lag(monthly_total) over (
partition by payment_type 
order by sale_month
    ), 0
   )
  ) * 100, 2
 ) as monthly_change

from monthly_sales
order by payment_type, sale_month;



