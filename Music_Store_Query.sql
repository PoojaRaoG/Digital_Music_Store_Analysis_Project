-- 1. Who is the senior most employee based on their job title?

select *
from employee
order by levels desc
limit 1

 -- 2. Which countries have the most Invoices?
 
select billing_country, count(total) as t
from invoice
group by billing_country
order by t desc
-- or
select count(*) as c, billing_country
from invoice
group by billing_country
order by c desc

-- 3. What are the top 3 values of total invoice?

select total from invoice
order by total desc
limit 3

-- 4. Which city has the best customers?

select billing_city, sum(total) as t
from invoice
group by billing_city
order by t desc
limit 1

-- 5. Who is the best customer?  

select c.customer_id, c.first_name, c.last_name, sum(i.total) as t
from customer as c
inner join invoice as i
on c.customer_id = i.customer_id
group by c.customer_id
order by t desc
limit 1

--6. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A\*

select distinct c.email, c.first_name, c.last_name 
from customer as c
join invoice as i on c.customer_id = i.customer_id
join invoice_line as il on i.invoice_id = il.invoice_id
join track as t on il.track_id = t.track_id
join genre as g on t.genre_id = g.genre_id
where g.genre_id = '1'
order by c.email asc

-- 7. Let's invite the artists who have written the most rock music in our dataset.Write a query that returns the Artist name and total track count of the top 10 rock bands.

select a.name, a.artist_id, count(t.track_id) as total_track
from artist as a
join album as al on a.artist_id = al.artist_id
join track as t on al.album_id = t.album_id
where t.genre_id = '1'
group by a.name, a.artist_id
order by total_track desc
limit 10

-- 8. Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.

select name, milliseconds
from track
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds desc

-- 9. Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent.

select c.customer_id, c.first_name, c.last_name, a.name, sum(il.unit_price * il.quantity) as total_spent
from customer as c
join invoice as i on c.customer_id = i.customer_id
join invoice_line as il on i.invoice_id = il.invoice_id
join track as t on il.track_id = t.track_id
join album as al on t.album_id = al.album_id
join artist as a on al.artist_id = a.artist_id
group by c.customer_id, c.first_name, c.last_name, a.name
order by total_spent desc

-- 10. Find the top artist and write a query to return customer name, artist name and total amount spent on the top artist.

with best_Selling_artist as(
    select a.artist_id, a.name, sum(il.unit_price * il.quantity)  as total_earned
    from artist as a 
    join album as al on a.artist_id = al.artist_id
    join track as t on al.album_id = t.album_id
    join invoice_line as il on t.track_id = il.track_id
    group by 1,2
    order by 3 desc
    limit 1
)
select c.customer_id, c.first_name, c.last_name, bsa.name, sum(il.unit_price * il.quantity) as total_spent
from customer as c
join invoice as i on c.customer_id = i.customer_id
join invoice_line as il on i.invoice_id = il.invoice_id
join track as t on il.track_id  = t.track_id
join album as al on t.album_id = al.album_id
join best_Selling_artist as bsa on al.artist_id = bsa.artist_id
group by 1,2,3,4
order by total_spent desc;

-- 11. We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.

-- Method a:
with top_genre as (
   select c.country as country, g.name as top_genre, g.genre_id, count(il.quantity) as purchase,
   rank() over (partition by c.country order by count(il.quantity) desc) as row_no
   from customer as c
   join invoice as i on c.customer_id = i.customer_id
   join invoice_line as il on i.invoice_id = il.invoice_id
   join track as t on il.track_id = t.track_id
   join genre as g on t.genre_id = g.genre_id
   group by 1,2,3
   order by 1 asc,4 desc
)
select * 
from top_genre
where row_no =1

-- Method b:
with recursive sales as (
   select c.country, g.name, g.genre_id, count(*) as purchase
   from customer as c
   join invoice as i on c.customer_id = i.customer_id
   join invoice_line as il on i.invoice_id = il.invoice_id
   join track as t on il.track_id = t.track_id
   join genre as g on t.genre_id = g.genre_id
   group by 1,2,3
   order by 1 asc, 4 desc
),
   most_saled as (select max(sales.purchase) as max_purchased, sales.country as country
   from sales
   group by 2
   order by 2)
select sales.*
from sales
join most_saled 
on sales.country = most_saled.country
where sales.purchase = most_saled.max_purchased;

-- 12. Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent.For countries where the top amount spent is shared, provide all customers who spent this amount.

-- Method a:
with total_time_spent as(
  select c.customer_id, c.first_name, c.last_name, i.billing_country, sum(i.total) as total_spending,
  rank() over (partition by i.billing_country order by sum(i.total)desc) as rank_no
  from customer as c
  join invoice as i on c.customer_id = i.customer_id
  group by 1,2,3,4
  order by 4 asc, 5 desc
)
select * from total_time_spent
where rank_no =1

-- Method b:
with recursive spent_most_on_music as (
   select c.customer_id, c.first_name, c.last_name, i.billing_country as country, sum(i.total) as total_spending
   from customer as c
   join invoice as i on c.customer_id = i.customer_id
   group by 1,2,3,4
   order by 4 asc,5 desc
),
   most_spent as (Select max(spent_most_on_music.total_spending) as max_spending, spent_most_on_music.country as country
   from spent_most_on_music
   group by 2)
select spent_most_on_music.*
from spent_most_on_music
join most_spent
on spent_most_on_music.country = most_spent.country

where spent_most_on_music.total_spending = most_spent.max_spending;
