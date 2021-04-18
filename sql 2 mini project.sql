create database mini2;
use mini2;
show tables;
select * from cust_dimen;
select * from market_fact;
select * from orders_dimen;
select * from prod_dimen;
select * from shipping_dimen;
drop table orders_dimen;

#1. Join all the tables and create a new table called combined_table.
#(market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
create table combined_table as
select customer_name,province,region,customer_segment,mf.cust_id,mf.ord_id,mf.prod_id,mf.ship_id,sales,discount,order_quantity,profit,shipping_cost,
product_base_margin,od.order_ID,order_date,order_priority,product_category,product_sub_category,ship_mode,ship_date 
from
cust_dimen cd join market_fact mf
on cd.cust_id=mf.cust_id
join orders_dimen od
on od.ord_id=mf.ord_id
join prod_dimen pd
on pd.prod_id=mf.prod_id
join shipping_dimen sd
on sd.ship_id=mf.ship_id;

#2. Find the top 3 customers who have the maximum number of orders
select * from cust_dimen 
where cust_id in 
(select cust_id from
(select cust_id,count(cust_id)total_orders from
(select distinct cust_id,ord_id from market_fact
order by ord_id)t1
group by cust_id
order by 2 desc limit 3)t2);

#3. Create a new column DaysTakenForDelivery that contains the date difference
#of Order_Date and Ship_Date.
alter table combined_table
add column dateddifference int;
update combined_table
set dateddifference= datediff(str_to_date(ship_date,'%d-%m-%Y'),str_to_date(order_date,'%d-%m-%Y'));
select * from combined_table;

#4. Find the customer whose order took the maximum time to get delivered.
select * from combined_table order by dateddifference desc limit 1;

#5. Retrieve total sales made by each product from the data (use Windows
#function)
select distinct p.Product_Sub_Category,m.prod_id,
sum(sales) over(partition by prod_id) from market_fact m 
join prod_dimen p on m.Prod_id=p.Prod_id order by m.prod_id desc ;

select *,sum(sales) from market_fact group by prod_id;-- checking

## solution-2
select prod_id,round(sum_sales,2)Total_Sales from
(select distinct prod_id,sum(sales) over(partition by prod_id) as sum_Sales from combined_table)t1;

#6. Retrieve total profit made from each product from the data (use windows
#function)
select distinct p.Product_Sub_Category,m.Prod_id, sum(profit) 
over(partition by prod_id) from market_fact m 
join prod_dimen p on m.Prod_id=p.Prod_id order by m.prod_id;

select prod_id,sum(profit) from market_fact group by prod_id;-- checking


#7. Count the total number of unique customers in January and how many of them
#came back every month over the entire year in 2011
select year(str_to_date(order_date,'%d-%m-%Y'))yr,month(str_to_date(order_date,'%d-%m-%Y'))mnth,count(distinct cust_id)Total from
combined_table where 
year(str_to_date(order_date,'%d-%m-%Y'))=2011 and
 cust_id in
(select distinct cust_id from
(select distinct cust_id,ord_id,order_date from combined_table
where month(str_to_date(order_date,'%d-%m-%Y'))=01
and year(str_to_date(order_date,'%d-%m-%Y'))=2011)t)
group by 1,2;


#8. Retrieve month-by-month customer retention rate since the start of the
#business.(using views)
select cust_id,order_date,case
when month_diff>=0 then 'retained'
when month_diff>1 then 'Irregular'
when month_diff is null then 'Churned'
end Status from
(select *,round(datediff(str_to_date(first_order,'%d-%m-%Y'),str_to_date(order_date,'%d-%m-%Y'))/30,0) month_diff from
(select *,lead(order_date) over(partition by cust_id order by str_to_date(order_date,'%d-%m-%Y'))first_order from
(select distinct cust_id,ord_id,order_date from combined_table
order by order_date)t)t1)t2;


-- rough work
/*select * from shipping_dimen;
select * from orders_dimen;
alter table shipping_dimen ship_dat
e date_format(ship_date,'%y-%m-%d') ;
desc shipping_dimen;
select * from orders_dimen;
drop database mini2;
select month(ship_date) from shipping_dimen;
select str_to_date(ship_date,'%y-%m-%d')  from shipping_dimen;
select datediff('2020-12-05','2020-12-04');
select str_to_date(order_Date,'%d-%m-%y') from orders_dimen;
select str_to_date(order_Date,'%y-%m-%d') from orders_dimen;
alter table orders_dimen modify order_date date ;*/