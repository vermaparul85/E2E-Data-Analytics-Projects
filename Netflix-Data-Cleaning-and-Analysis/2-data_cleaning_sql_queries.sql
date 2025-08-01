use mysqldb;
DROP TABLE [dbo].[netflix_raw];

CREATE TABLE [dbo].[netflix_raw](
	[show_id] [varchar](10) primary key,
	[type] [varchar](10) NULL,
	[title] [nvarchar](200) NULL,
	[director] [varchar](250) NULL,
	[cast] [varchar](800) NULL,
	[country] [varchar](150) NULL,
	[date_added] [varchar](20) NULL,
	[release_year] [bigint] NULL,
	[rating] [varchar](10) NULL,
	[duration] [varchar](10) NULL,
	[listed_in] [varchar](100) NULL,
	[description] [varchar](500) NULL
);

select * from netflix_raw;

--Check dupilcate show_id, title
select count(show_id), count(distinct show_id) from netflix_raw; -- no duplicate, so define it as primary key, again drop and create table
select count(title), count(distinct title) from netflix_raw; -- 7 duplicates

--Fetch the duplicate title records
select title, count(*) from netflix_raw
group by title
having count(*) > 1;

select * from netflix_raw where upper(title) in (
select upper(title) from netflix_raw
group by upper(title)
having count(*) > 1)
order by title;

--Fetch the duplicate records for title and type combination
--Method 1
select * from netflix_raw where concat(upper(title),type) in (
select concat(upper(title), type) from netflix_raw
group by upper(title), type
having count(*) > 1)
order by title;

--Method 2 Fetch duplicate records eligible for delete, will be removed while creating clean table
with cte as (
select *,
ROW_NUMBER() over(partition by title, type order by show_id) rn
from netflix_raw)
select *  from netflix_raw where show_id in (select show_id from cte where rn <> 1);

--Create new table for director
drop table netflix_directors;

select show_id, trim(value) as director
into netflix_directors
from netflix_raw
cross apply string_split(director, ',');

select * from netflix_directors;

--Create new table for cast
drop table netflix_cast;

select show_id, trim(value) as cast
into netflix_cast
from netflix_raw
cross apply string_split(cast, ',');

select * from netflix_cast;

--Create new table for country
drop table netflix_country;

select show_id, trim(value) as country
into netflix_country
from netflix_raw
cross apply string_split(country, ',');

select * from netflix_country;

--Create new table for listed_in
drop table netflix_genre;

select show_id, trim(value) as genre
into netflix_genre
from netflix_raw
cross apply string_split(listed_in, ',');

select * from netflix_genre;

--populate missing values in country
select count(*) from netflix_raw where country is null; --831

insert into netflix_country 
select show_id, dc.country from netflix_raw r
inner join
(select distinct director, country from netflix_directors d join netflix_country c
on d.show_id = c.show_id) dc
on r.director = dc.director
and r.country is null;

select * from netflix_raw where show_id not in (select show_id from netflix_country); --681

--Check missing values in duration column, will be removed while creating clean table
select * from netflix_raw where duration is null; --duration information is present in rating column

--create netflix_clean table 
--1. remove duplicate records for same title and type
--2. data type conversion for date_added column, 
--3. drop columns director, cast, country, listed_in
--4. update null values for duration column
with cte as (
select *,
ROW_NUMBER() over(partition by title, type order by show_id) rn
from netflix_raw)
select show_id, type, title, cast(date_added as date) date_added, release_year,
rating, case when duration is null then rating else duration end duration, description
into netflix_clean
from netflix_raw where show_id in (select show_id from cte where rn = 1);

--populate rest of nulls as not_available for duration column
select * from netflix_clean where duration is null;
