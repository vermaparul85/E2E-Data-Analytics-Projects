--1. for each director count the number of movies and tv shows create by them in separate columns, for directors who have created tv shows and movies both 
--Method 1
with cte as (
select d.director, n.type, count(n.show_id) show_count from netflix_clean n, netflix_directors d
where n.show_id = d.show_id
group by d.director, n.type),
cte1 as (
select director,
sum(case when type = 'Movie' then show_count else 0 end) movies,
sum(case when type = 'TV Show' then show_count else 0 end) tv_shows
from cte
group by director)
select * from cte1
where movies > 0 and tv_shows > 0;

--Method 2
select d.director, 
count(distinct case when n.type = 'Movie' then n.show_id end) movies,
count(distinct case when n.type = 'TV Show' then n.show_id end) tv_shows
from netflix_clean n, netflix_directors d
where n.show_id = d.show_id
group by d.director
having count(distinct n.type) > 1;

--2. which country have highest number of comedy movies
select distinct genre from netflix_genre where lower(genre) like '%comed%';
select distinct genre from netflix_genre order by 1;

--Method 1
select top 1 country, count(1) from netflix_country c, netflix_genre g
where c.show_id = g.show_id
and genre = 'Comedies'
group by country
order by 2 desc;

--Method 2
select top 1 country, count(distinct g.show_id) from netflix_country c, netflix_genre g, netflix_clean n
where c.show_id = g.show_id
and c.show_id = n.show_id
and genre = 'Comedies'
and n.type = 'Movie'
group by country
order by 2 desc;

--3. for each year (as per date added to netflix), which director has maximum number of movies released.
with cte as (
select year(date_added) year, d.director, count(n.show_id) number_of_shows_released,
rank() over(partition by year(date_added) order by count(n.show_id) desc) rn
from netflix_clean n, netflix_directors d
where n.show_id = d.show_id
and n.type = 'Movie'
group by year(date_added), d.director)
select year, director, number_of_shows_released from cte where rn = 1
order by 3 desc;

--4. what is the average duration of movies in each genre
--Method 1
select g.genre, avg(cast(SUBSTRING(duration, 1,len(duration)-4) as int)) as avg_duration from netflix_genre g, netflix_clean n
where n.show_id = g.show_id
and n.type = 'Movie'
group by g.genre
order by 2;

--Method 2
select g.genre, avg(cast(replace(duration, ' min','') as int)) as avg_duration from netflix_genre g, netflix_clean n
where n.show_id = g.show_id
and n.type = 'Movie'
group by g.genre
order by 1;

--5. find the director who have created horror and comedy movies both, also display number of horror and comedy movies directed by them
select distinct genre from netflix_genre order by genre;

select d.director, 
count(case when g.genre = 'Comedies' then n.show_id end) comedy_movie_count,
count(case when g.genre = 'Horror Movies' then n.show_id end) horror_movie_count
from netflix_clean n, netflix_genre g, netflix_directors d
where n.show_id = g.show_id
and n.show_id = d.show_id
and n.type = 'Movie'
and g.genre in ('Comedies','Horror Movies')
group by d.director
having count(distinct g.genre) > 1;
