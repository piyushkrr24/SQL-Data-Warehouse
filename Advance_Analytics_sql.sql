--  ADVANCE ANALYTICS  --

------------------------------------------------------------------------------------------------------------

-- 1. Change over time

-- Analysed sales performance over time
select extract(year from order_date) order_year, sum(sales_amount) sales
from gold.fact_sales
where order_date is not null
group by order_year
order by order_year;

-- Analysed no. of customers over time
select extract(year from order_date) order_year, count(distinct customer_key) customers
from gold.fact_sales
where order_date is not null
group by order_year
order by order_year;

-- Analysed quantity sold over time
select extract(year from order_date) order_year, sum(quantity) total_quantity
from gold.fact_sales
where order_date is not null
group by order_year
order by order_year;

-- Analysed (sales performance, no. of customers, quantity sold) over time(month)
select extract(month from order_date) order_month, sum(sales_amount) sales, count(distinct customer_key) customers, sum(quantity) total_quantity
from gold.fact_sales
where order_date is not null
group by order_month
order by order_month;

------------------------------------------------------------------------------------------------------------


-- 2. Cumulative Analysis

-- total sales per month
-- running total of sales over time
select 
	t.order_year,
	t.order_month,
	t.sales,
	sum(t.sales) over(order by order_month) running_total_sales
from(
	select 
		extract(year from order_date) order_year,
		date_trunc('month', order_date) order_month,
		sum(sales_amount) sales
	from gold.fact_sales
	where order_date is not null
	group by order_year, order_month
	order by order_year, order_month
) t;

-- moving AVERAGE of sales overtime
select
	t.order_year,
	t.order_month,
	t.average_sales,
	avg(t.average_sales) over(order by order_month) running_average_sales
from (
	select 
		extract(year from order_date) order_year,
		date_trunc('month', order_date) order_month,
		avg(sales_amount) average_sales
	from gold.fact_sales
	group by order_year, order_month
	order by order_year, order_month
) t;

------------------------------------------------------------------------------------------------------------


-- 3. Performance Analysis

-- yearly performance vs average sales performation and last years performance
with yearly_product_sales as(
	select 
		dp.product_name product,
		extract(year from fs.order_date) order_year,
		sum(fs.sales_amount) current_year_sales
	from gold.fact_sales fs
	left join gold.dim_products dp
		on fs.product_key = dp.product_key
	where fs.order_date is not null
	group by dp.product_name, order_year
)

select 
	y.product,
	y.order_year,
	y.current_year_sales,
	avg(y.current_year_sales) over(partition by y.product) avg_sales,
	y.current_year_sales - avg(y.current_year_sales) over(partition by y.product) diff_in_sales_from_avg,
	case
		when y.current_year_sales - avg(y.current_year_sales) over(partition by y.product) > 0 then 'Good'
		when y.current_year_sales - avg(y.current_year_sales) over(partition by y.product) = 0 then 'Okay'
		else 'Bad'
	end sales_rating,
	lag(y.current_year_sales) over(partition by y.product order by y.order_year) prev_yr_sales,
	y.current_year_sales - lag(y.current_year_sales) over(partition by y.product order by y.order_year) diff_curr_prev_yr_sales,
	case 
		when y.current_year_sales - lag(y.current_year_sales) over(partition by y.product order by y.order_year) >0 then 'More sales than prev yr'
		when y.current_year_sales - lag(y.current_year_sales) over(partition by y.product order by y.order_year) =0 then 'Same sales than prev yr'
		when y.current_year_sales - lag(y.current_year_sales) over(partition by y.product order by y.order_year) <0 then 'Less sales than prev yr'
		else 'Launch yr of prod'
	end sales_comparison_from_prev_yr
from yearly_product_sales y
order by y.product, y.order_year
;


------------------------------------------------------------------------------------------------------------


-- 4. Part To Whole Analysis

-- Which Category Contribute to most of the Sales
with t as(
	select 
		dp.category category,
		sum(fs.sales_amount) category_sales
	from gold.fact_sales fs
	left join gold.dim_products dp
		on fs.product_key = dp.product_key 
	group by category
	order by category_sales desc
)

select 
	t.category,
	t.category_sales,
	sum(t.category_sales) over() total_sales,
	concat(round((t.category_sales/sum(t.category_sales) over()) *100, 2), '%') pct_sales
from t
-- limit 1
;


------------------------------------------------------------------------------------------------------------


-- 5. Data Segmentation

-- segment product into cost range and 
-- count how many products fall into each segment

with prod_segment as(
	select 
		product_name,
		cost,
		case
			when cost<200 then 'Below 200'
			when cost<500 then '200-500'
			when cost<1000 then '500-1000'
			when cost<2000 then '1000-2000'
			else 'Above 2000'
		end cost_range
	from gold.dim_products
)

select 
	-- product_name,
	cost_range,
	-- cost,
	count(cost_range) quantity_of_prod
from prod_segment p
group by cost_range
order by quantity_of_prod desc
