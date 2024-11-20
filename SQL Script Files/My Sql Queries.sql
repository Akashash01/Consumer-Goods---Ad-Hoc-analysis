use gdb023;

-- AD-Hoc Analysis :
-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select distinct market 
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC'
Order by market;

-- What is the percentage of unique product increase in 2021 vs. 2020? 

with cte as (select fiscal_year, count(distinct product_code) as totals
from fact_sales_monthly
group by fiscal_year)
select fiscal_year as years, totals, concat(round(((totals - lag(totals,1,0) over (order by fiscal_year))/ lag(totals,1,0) over (order by fiscal_year)) * 100 , 2), '%') as percentage_increase
from cte
order by years;

-- Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 

select segment , count(distinct product_code) as Total_unique
from dim_product
group by segment
order by Total_unique desc ;

-- Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?

with cte as (select p.segment, count(distinct case when fs.fiscal_year = 2020 then fs.product_code end) as total_2020,
			 count(distinct case when fs.fiscal_year = 2021 then fs.product_code end) as total_2021
from fact_sales_monthly fs
left join dim_product p
on fs.product_code = p.product_code
group by p.segment)
select segment, total_2020, total_2021, concat(round(((total_2021 - total_2020)/ total_2020) * 100, 2), '%') as diff from cte;

-- Get the products that have the highest and lowest manufacturing costs.

select p.product, p.product_code, max(m.manufacturing_cost) as max_value, min(m.manufacturing_cost) as min_value
from fact_manufacturing_cost m
join dim_product p
on m.product_code = p.product_code
group by  m.product_code, p.product;

-- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

select c.customer, c.customer_code , avg(pre_invoice_discount_pct) as high_discount
from fact_pre_invoice_deductions f
join dim_customer c
on f.customer_code = c.customer_code
where f.fiscal_year = 2021
group by c.customer, c.customer_code
order by high_discount desc
limit 5;

-- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.

select month(fm.`date`) as months, year(fm.`date`) as years, concat(sum(fm.sold_quantity * fp.gross_price)/1000000, 'M') as total_gross_price
from fact_sales_monthly fm
join fact_gross_price fp
on fm.product_code = fp.product_code
join dim_customer c
on fm.customer_code = c.customer_code
where c.customer = 'Atliq Exclusive'
group by month(fm.`date`), year(fm.`date`)
order by months;

-- In which quarter of 2020, got the maximum total_sold_quantity? 
-- Note : If fiscal year starts from september, then we have to create seperate quater column using case statement.
 
select quarter(`date`) as qtr, concat(sum(sold_quantity)/ 1000 , 'K') as total_sold
from fact_sales_monthly
where fiscal_year = 2020
group by quarter(`date`)
order by total_sold desc
limit 1;

-- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?

with cte as (
select c.`channel` as channels, concat(round(sum(fm.sold_quantity * fp.gross_price)/1000000, 2), 'M') as total_gross_price
from fact_sales_monthly fm
join fact_gross_price fp
on fm.product_code = fp.product_code
join dim_customer c
on fm.customer_code = c.customer_code
where fm.fiscal_year = 2021
group by c.`channel` ), cte2 as (select sum(total_gross_price) as totals from cte)

select channels, total_gross_price, concat(round((total_gross_price/totals) * 100,2),'%') as percentage
from cte,cte2
order by percentage desc;

-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?

with cte as (
select p.division, p.product_code, sum(fm.sold_quantity) as total_sold
from fact_sales_monthly fm
join dim_product p 
on fm.product_code = p.product_code
where fm.fiscal_year = 2021
group by p.division, p.product_code),

cte2 as (select division, product_code, concat(round(total_sold/1000, 2),'K') as total_qty, rank() over (partition by division order by total_sold desc ) as rnk
		 from cte)

select division, product_code, total_qty
from cte2
where rnk < 4
