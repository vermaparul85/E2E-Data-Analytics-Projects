use mysqldb;
drop table yelp_review_data;

CREATE TABLE [dbo].[yelp_review_data](
	[review_id] [varchar](25) NULL,
	[business_id] [varchar](25) NULL,
	[user_id] [varchar](25) NULL,
	[date] [datetime] NULL,
	[stars] [int] NULL,
	[text] [varchar](8000) NULL,
	[sentiment_analysis] [varchar](10) NULL
);

drop table yelp_business_data;

CREATE TABLE [dbo].yelp_business_data(
	[business_id] [varchar](25) NULL,
	[name] [varchar](100) NULL,
	[city] [varchar](100) NULL,
	[state] [varchar](10) NULL,
	[review_count] [int] NULL,
	[stars] [int] NULL,
	[categories] [varchar](1000) NULL
);

select count(*) from yelp_review_data;
select * from yelp_review_data;

select count(*) from yelp_business_data;
select * from yelp_business_data;

--Data Analysis
--1. find the number of businesses in each category
select trim(value) as category, count(business_id) from yelp_business_data
cross apply string_split(categories, ',')
group by trim(value)
order by 2 desc;

--2. find the top 10 users who have reviewed the most businesses in the restaurant category
select top 10 r.user_id, count(distinct b.business_id) from yelp_business_data b
inner join yelp_review_data r on (b.business_id = r.business_id)
where lower(categories) like '%restaurants%'
group by r.user_id
order by 2 desc;

--3. Find the most popular categories of businesses (based on the number of reviews)
--Method 1
with cte as (
select trim(value) as category, business_id from yelp_business_data
cross apply string_split(categories, ',')
)
select category, count(*) no_of_reviews from yelp_review_data r 
inner join cte b
on (b.business_id = r.business_id)
group by category
order by 2 desc;

--Method 2
select trim(value) as category, count(*) from yelp_business_data b
cross apply string_split(categories, ',')
inner join yelp_review_data r on (b.business_id = r.business_id)
group by trim(value)
order by 2 desc;

--4. find the top 3 most recent reviews for each business
with cte as (
select r.business_id, b.name, r.date, .text, 
ROW_NUMBER() over(partition by r.business_id order by r.date desc) rn
from yelp_review_data r
inner join yelp_business_data b on (b.business_id = r.business_id))
select * from cte where rn <= 3
order by business_id;

--5. find the month with the highest number of reviews
select top 1 format(date,'MMMM') as month, count(*) from yelp_review_data
group by format(date,'MMMM')
order by 2 desc;

--6. find the percentage of 5-star reviews for each business
select r.business_id, b.name, count(*) total_reviews,
count(case when r.stars = 5 then 1 else null end) star_5_reviews_total,
round(100 * count(case when r.stars = 5 then 1 else null end)/count(*),2) star_5_reviews_percentage
from yelp_review_data r
inner join yelp_business_data b on (b.business_id = r.business_id)
group by r.business_id, b.name;

--7. find the top 5 most reviewed businesses in each city
select * from (
select r.business_id, b.name, b.city, count(*) total_reviews,
ROW_NUMBER() over(partition by b.city order by count(*) desc) rn
from yelp_review_data r
inner join yelp_business_data b on (b.business_id = r.business_id)
group by r.business_id, b.name, b.city) a
where rn <= 5
order by city, rn;

--8. find the average rating of businesses that have at least 100 reviews
select r.business_id, b.name, AVG(r.stars) average_rating
from yelp_review_data r
inner join yelp_business_data b on (b.business_id = r.business_id)
group by r.business_id, b.name
having count(*) > 100;

--9. List the top 10 users who have written the most reviews, along with the businesses they reviewed
with cte as (
select top 10 r.user_id, count(*) total_reviews
from yelp_review_data r
group by r.user_id
order by 2 desc)
select r.user_id, r.business_id, b.name
from yelp_review_data r
inner join yelp_business_data b on (b.business_id = r.business_id)
where user_id in (select user_id from cte)
order by user_id;

--10. find top 10 businesses with highest positive sentiment reviews
select top 10 r.business_id, b.name, count(*) total_positive_reviews
from yelp_review_data r
inner join yelp_business_data b on (b.business_id = r.business_id)
where sentiment_analysis = 'Positive'
group by r.business_id, b.name
order by 3 desc;
