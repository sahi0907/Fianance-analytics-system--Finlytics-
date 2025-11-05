create database finance;
use finance ;

create table customers (customer_id int,	
                        name varchar(50),	
                        gender char(2),	
                        city varchar(50),
	                    signup_date date ,	
                        annual_income int,	
                        credit_score int);

SHOW VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE 'D:/customers_data.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
select * from customers ;


create table accounts (account_id	int,
                       customer_id	int,
                       account_type	varchar(20),
                       open_date date ,	
                       balance  int );
                       
Load data local infile 'D:/account_data.csv'
into table accounts
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows ;
select * from accounts ;

create table loans (loan_id int ,
                	customer_id	int,
                    loan_type	varchar(30),
                    loan_amount	int,
                    interest_rate float,	
                    start_date	date, 
                    term_months	int,
                    status varchar(20) );
Load data local infile 'D:/loans_data.csv'
into table loans 
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows ;
select * from loans;

create table payments(payment_id int,
					  loan_id	int,
                      payment_date	date ,
					  amount_paid	float,
                      remaining_balance	float,
                      payment_status varchar(20));
Load data local infile 'D:/payments_data.csv'
into table payments 
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows ;
select * from payments ;

create table transictions(transaction_id int ,
                          customer_id	int,
                          date	date,
                          type	varchar(10),
                          amount int	,
                          merchant varchar(50),	
                          city varchar(50));
Load data local infile 'D:/transictions_data.csv'
into table transictions 
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows ;
select * from transictions;

#Data cleaning 

select * from customers ;
select * from loans ;

update loans 
set loan_amount = 0 
where loan_amount = ' ' ;

SELECT 
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id from customers ;
    
select sum( case when loan_amount is null then 1 else 0 end ) as null_loan_amount from loans ;

SELECT 
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN name IS NULL OR name = '' THEN 1 ELSE 0 END) AS null_name,
    SUM(CASE WHEN gender IS NULL OR gender = '' THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN city IS NULL OR city = '' THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN annual_income IS NULL THEN 1 ELSE 0 END) AS null_income,
    SUM(CASE WHEN credit_score IS NULL THEN 1 ELSE 0 END) AS null_credit_score
    
    
    
 FROM customers;
 
 #descriptive analysis 
 #customer overview 
 select count(*) as total_customers ,
 round(avg(annual_income),2)as avg_income ,
 round(avg(credit_score),2)as avg_credit_score from customers ;
 
 #customer distribution by state 
 select city , count(*) as total_customers from customers 
 group by city
 order by total_customers desc
 limit 10;
 
 #Loan performance analysis 
 #total loan amaount distributed 
 select sum(loan_amount) as total_amount ,
 count(*) as total_loan from loans ;
 
 #average loan interest rate by loan type
 select * from loans;
 
 select loan_type , round(avg(interest_rate),2)as avg_interest_rate,
                    round(avg(loan_amount),2) as avg_loan_amount from loans 
                    group by loan_type 
                    order by avg_loan_amount ;
#loan stusts 
 SELECT 
    status,
    COUNT(*) AS total_loans,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM loans), 2) AS percentage
FROM loans
GROUP BY status;


#payment as repayment analysis
#monthly repayment trends 
select * from payments ;

select date_format( payment_date ,'%Y-%m') as month ,
sum(amount_paid) as total_amount,
count(*) as total_count from payments
group by month 
order by month ;

#average payment amount per loan type 
select l.loan_type ,
	   round(avg(p.amount_paid),2) as avg_payment_amount 
       from payments p 
       join loans l on 
       p.loan_id = l.loan_id 
       group by l.loan_type 
       order by avg_payment_amount;
     select * from loans ;  
     
#default_rate loan not fully paid 
select status , count(*) as loan_count ,
                round(count(*) * 100 / (select count(*) from loans),2 ) as percentage 
                from loans 
                where status in ('defaulted','closed_paid','ongoing') 
                group by status ;
  
  select * from transictions;
#customer spend and transiction behaviour 
#total transiction value per customer 
select c.customer_id , c.name ,
       round(sum(t.amount),2) as total_amount,
       count(t.transaction_id ) as total_transactions from customers c
       join transictions t
       on c.customer_id = t.customer_id 
       group by c.customer_id , c.name 
       order by total_transactions desc;
       
# top spending cities 
select city , round(sum(amount),2) as total_amount_spend from transictions 
group by city 
order by total_amount_spend ;

#case studies 
#Q1 . which loan type generates the most revenue (interest)?
select loan_type ,
	   round(sum(loan_amount * interest_rate /100),2) as total_interest
       from loans 
       group by loan_type 
       order by total_interest desc;

#Q2 which customers are likely high_value (top income+ good_credit +big_loans )
select c.customer_id ,
       c.name ,
       c.annual_income,
       c.credit_score,
       sum(l.loan_amount) as total_loans 
       from customers c 
       join loans l on 
       c.customer_id = l.customer_id 
       group by  c.customer_id ,c.name ,c.annual_income,c.credit_score
       having c.annual_income >100000 and c.credit_score >700
       order by total_loans desc 
       limit 10 ;
       
#advanced case studies 
#case study 1 - Loan default risk analysis 
#goal- identify customers most likely to defualt based on income ,credit_score and payment_history 

select c.customer_id , c.name , c.annual_income ,c.credit_score ,
	   l.loan_id , l.loan_amount, l.status ,
       round(sum(p.amount_paid)/l.loan_amount * 100,2) as repayment_ratio,
       case 
       when c.credit_score < 600 or (sum(p.amount_paid) / l.loan_amount) < 0.5 Then  'High risk'
       when c.credit_score between 600 and 700 then 'medium risk'
       else 'low risk'
       end as risk_category 
       from customers c 
       join loans l on c.customer_id = l.customer_id 
       left join payments p on l.loan_id = p.loan_id 
       group by c.customer_id ,c.name , c.annual_income,c.credit_score,
				l.loan_id, l.loan_amount,l.status
                order by repayment_ratio asc
                limit 20;
#case study 2 
#profitability by loan type 
#goal - identify which loan type generates the most interest revenue per customer 
create view  loanORintersetsummary as(
select l.loan_type ,
       count(distinct l.customer_id ) as total_customers ,
       round(sum(l.loan_amount * (l.interest_rate/100)),2)as toatl_interest_revenue,
       round(avg(l.loan_amount),2) as avg_loan_amount,
       round(sum(l.loan_amount * (l.interest_rate /100)) / count(distinct l.customer_id) ,2) as profit_per_customer
       from loans l 
       group by l.loan_type 
       order by profit_per_customer desc);
select * from loanORintersetsummary ;

#case study 3 
#customers retention and churn 
#goal -identify inactive or lost customers based on transiction and payment history 

delimiter $$ 
create procedure retentionORchurne()
begin 
    select c.customer_id , c.name ,
	   max(t.date )as late_transaction,
       max(p.payment_date) as last_payment,
       datediff(curdate(), greatest(max(t.date),max(p.payment_date))) as days_since_activity,
       case 
           when datediff(curdate(),greatest(max(t.date),max(p.payment_date)))>180 then 'churned'
           when datediff(curdate(), greatest(max(t.date),max(p.payment_date))) between 90 and 180 then 'At risk'
           else 'active'
           end as customer_status
           from customers c 
          left join transictions t on c.customer_id = t.customer_id 
          left join loans l on c.customer_id = l.customer_id 
          left join payments p on l.loan_id = p.loan_id 
          group by c.customer_id , c.name 
          order by days_since_activity desc;
	end$$
    delimiter ;
    call retentionORchurne();
    
    #case study-4 
    #state level financial performance 
    #rank states by total distributed repayment rate and default ratio
    
    delimiter $$ 
    create procedure citylaonsummary()
    begin
    SELECT 
    c.city,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    ROUND(SUM(l.loan_amount), 2) AS total_loan_disbursed,
    ROUND(SUM(p.amount_paid), 2) AS total_repaid,
    ROUND(SUM(p.amount_paid) / SUM(l.loan_amount) * 100, 2) AS repayment_rate,
    SUM(CASE WHEN l.status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(SUM(CASE WHEN l.status = 'Defaulted' THEN 1 ELSE 0 END) * 100.0 / COUNT(l.loan_id), 2) AS default_rate
FROM customers c
JOIN loans l ON c.customer_id = l.customer_id
LEFT JOIN payments p ON l.loan_id = p.loan_id
GROUP BY c.city
ORDER BY repayment_rate DESC;
end $$ 
delimiter ;

call citylaonsummary();

#Average repayment ratio by loan type using CTE

WITH loan_summary AS (
    SELECT 
        l.loan_id,
        l.loan_type,
        l.loan_amount,
        SUM(p.amount_paid) AS total_paid,
        ROUND(SUM(p.amount_paid) / l.loan_amount * 100, 2) AS repayment_ratio
    FROM loans l
    LEFT JOIN payments p ON l.loan_id = p.loan_id
    GROUP BY l.loan_id, l.loan_type, l.loan_amount
)
SELECT 
    loan_type,
    ROUND(AVG(repayment_ratio), 2) AS avg_repayment_ratio
FROM loan_summary
GROUP BY loan_type
ORDER BY avg_repayment_ratio DESC;


# Rank customers by loan amount (per state) 

select c.city, c.customer_id , c.name ,
       sum(l.loan_amount) as total_loan,
       rank() over (partition by c.city order by sum(l.loan_amount)) as city_rank
       from customers c
       join loans l on c.customer_id = l.customer_id 
       group by c.city ,c.customer_id , c.name 
       order by c.city , city_rank;
       
       
#interest earning percentile per loan type 
select loan_type ,loan_id ,
       round(loan_amount * (interest_rate /100),2) as interest_earning,
       percent_rank() over (partition by loan_type order by (loan_amount * interest_rate/100)) as percentile_rank
       from loans 
       order by loan_type ,percentile_rank desc;
       
       
CREATE TABLE date_to_date AS
SELECT DISTINCT signup_date AS date_value
FROM customers
WHERE signup_date IS NOT NULL
UNION
SELECT DISTINCT start_date
FROM loans
WHERE start_date IS NOT NULL
UNION
SELECT DISTINCT payment_date
FROM payments
WHERE payment_date IS NOT NULL
union
select Distinct date 
from transictions 
where date is not null
union
select distinct open_date 
from accounts 
where open_date is not null ;

select * from date_to_date order by date_value;

ALTER TABLE date_to_date
ADD COLUMN year INT,
ADD COLUMN month INT,
ADD COLUMN month_name VARCHAR(15),
ADD COLUMN quarter VARCHAR(5),
ADD COLUMN day_of_week VARCHAR(15),
ADD COLUMN week_of_year INT;

UPDATE date_to_date
SET 
    year = YEAR(date_value),
    month = MONTH(date_value),
    month_name = MONTHNAME(date_value),
    quarter = CONCAT('Q', QUARTER(date_value)),
    day_of_week = DAYNAME(date_value),
    week_of_year = WEEK(date_value);
       
       
   DELETE FROM date_to_date
WHERE date_value < '2016-01-01'
   OR date_value > '2025-12-31';   
       
       
 SELECT MIN(date_value) AS start_date,
       MAX(date_value) AS end_date,
       COUNT(*) AS total_days
FROM date_to_date;


#THANK YOU 
