use mysqldb;
drop table orders;

CREATE TABLE [dbo].[orders](
	[order_id] int primary key,
	[order_date] date,
	[ship_mode] varchar(20),
	[segment] varchar(20),
	[country] varchar(20),
	[city] varchar(20),
	[state] varchar(20),
	[postal_code] varchar(20),
	[region] varchar(20),
	[category] varchar(20),
	[sub_category] varchar(20),
	[product_id] varchar(50),
	[quantity] int,
	[discount] decimal(7,2),
	[sale_price] decimal(7,2),
	[profit] decimal(7,2)
);

select * from orders;

--find top 10 highest revenue generating products
select top 10 product_id, sum(sale_price) product_sales from orders
group by product_id
order by product_sales desc;

--find top 5 highest selling products in each region
--Method 1
with region_sales as (
select region, product_id, sum(sale_price) product_sales,
ROW_NUMBER() over(partition by region order by sum(sale_price) desc) rn
from orders
group by region, product_id)
select * from region_sales
where rn <= 5;

--Method 2
with region_sales as (
select region, product_id, sum(sale_price) product_sales
from orders
group by region, product_id),
region_rank as (
select *,
ROW_NUMBER() over(partition by region order by product_sales desc) rn
from region_sales)
select * from region_rank
where rn <= 5;

--find month over month growth comparison for 2022 and 2023 sales. eg: jan 2022 vs jan 2023
with month_year_sales as (
select YEAR(order_date) year, MONTH(order_date) month, sum(sale_price) monthly_sales
from orders
group by YEAR(order_date), MONTH(order_date))
select month, 
sum(case when year = 2022 then monthly_sales else 0 end) year_2022_sales,
sum(case when year = 2023 then monthly_sales else 0 end) year_2023_sales
from month_year_sales
group by month
order by month;

--for each category which month had highest sales
--Method 1
with category_wise_sales as (
select category, YEAR(order_date) year, month(order_date) month, sum(sale_price) sales,
ROW_NUMBER() over(partition by category order by sum(sale_price) desc) rn
from orders
group by category, YEAR(order_date), month(order_date))
select * from category_wise_sales
where rn = 1;

--Method 2
with category_wise_sales as (
select category, format(order_date,'yyyyMM') year_month, sum(sale_price) sales,
ROW_NUMBER() over(partition by category order by sum(sale_price) desc) rn
from orders
group by category, format(order_date,'yyyyMM'))
select * from category_wise_sales
where rn = 1;

--which sub category had the highest growth by profit in 2023 compare to 2022
with yearly_sales as (
select year(order_date) year, sub_category, sum(sale_price) sales
from orders
group by year(order_date), sub_category),
sub_category_sales as (
select sub_category, 
max(case when year = 2022 then sales else 0 end) year_2022_sales,
max(case when year = 2023 then sales else 0 end) year_2023_sales
from yearly_sales
group by sub_category)
select top 1 sub_category, (year_2023_sales - year_2022_sales)*100/year_2022_sales growth_percent from sub_category_sales
order by 2 desc;
