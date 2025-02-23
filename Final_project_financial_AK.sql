select * from loan;

# History of granted loans
# Write a query that prepares a summary of the granted loans in the following dimensions:
# year, quarter, month,
# year, quarter,
# year,
# total.

SELECT
    -- first we extract what we need from the date column
    extract(YEAR FROM date) as loan_year,
    extract(QUARTER FROM date) as loan_quarter,
    extract(MONTH FROM date) as loan_month
FROM loan
group by extract(YEAR FROM date),
        extract(QUARTER FROM date),
        extract(MONTH FROM date) with rollup ;

# Display the following information as the result of the summary: 
# total amount of loans,
# average loan amount,
# total number of given loans.

SELECT
    extract(YEAR FROM date) as loan_year,
    extract(QUARTER FROM date) as loan_quarter,
    extract(MONTH FROM date) as loan_month,
    sum(amount) as 'total amount of loans',
    avg(amount) as 'average loan amount',
    count(loan_id) as 'total number of given loans'
FROM loan
group by extract(YEAR FROM date),
        extract(QUARTER FROM date),
        extract(MONTH FROM date) with rollup ;

# Loan status
# Write a query to help you answer the question of which statuses represent
# repaid loans (606) and which represent unpaid loans(76).

-- check which groups are repaid loans and which are unpaid loans
select status,
    count(loan_id) as number_loans
from loan
group by status  with rollup;

-- group status by repaid loans and unpaid loans
SELECT
    'Repaid loans' AS status_group,
    count(case when status in ('A', 'C') then loan_id end) AS total_loans
FROM
    loan
UNION ALL
SELECT
    'Unpaid loans' AS status_group,
    count(case when status in ('B', 'D') then loan_id end) AS total_loans
FROM
    loan
UNION ALL
SELECT
    'Total' AS status_group,
    count(loan_id) AS total_loans
FROM loan;

# Analysis of accounts
# Write a query that ranks accounts according to the following criteria:
#
# number of given loans (decreasing),
# amount of given loans (decreasing),
# average loan amount,
# Only fully paid loans are considered.

with cte_accounts as (select account_id,
       count(loan_id) as number_of_loans ,
       sum(amount) as amount_of_loans,
       avg(amount) as average_loan_amount
from loan
where status in ('A', 'C') -- select fully paid loans
group by account_id)
select *,
       row_number() over (order by amount_of_loans desc) as rank_amount,  -- ranking
       row_number() over (order by number_of_loans desc) as rank_account
       from cte_accounts;


# Fully paid loans
# Find out the balance of repaid loans, divided by client gender.
#
# Additionally, use a method of your choice to check whether the query is correct.
select gender,
       sum(l.amount) as total_repaid_loans
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
where status in ('A', 'C') -- select fully paid loans
and type ='OWNER'  -- select only 'owner' customer not disponent
group by gender;

# Client analysis - part 1
# Modifying the queries from the exercise on repaid loans, answer the following questions:
#
# Who has more repaid loans - women or men?
# What is the average age of the borrower divided by gender?

with cte_gender_repaid as ( select   gender,
       amount as repaid_loans,
       2024-year(birth_date) as age -- determine client's age
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
where status in ('A', 'C') -- select fully paid loans
and type ='OWNER'  -- select only 'owner' customer not disponent
)
select gender,
       sum(repaid_loans) as total_repaid_loans,  -- determine total sum of repaid loans
       round(avg(age),0) as average_age,     -- determine average age of client
       count(repaid_loans) as number_loans -- determine how many loans have women and men
from cte_gender_repaid
group by gender ;

# Client analysis - part 2:
# which area has the most clients,
# in which area the highest number of loans was paid,
# in which area the highest amount of loans was paid.
# Select only owners of accounts as clients.

drop table if exists tmp_district;
create temporary table tmp_district as (select
    ds.district_id,
    A3 as place,
    count(distinct c.client_id) as client_amount,
    count( l.amount) as loans_number,  -- aggregate by count
    sum(l.amount) as loans_sum
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
join district ds on c.district_id = ds.district_id
where l.status in ('A', 'C') -- select fully paid loans
and d.type ='OWNER'  -- select only 'owner' customer not 'disponent'
group by ds.district_id );-- grouping according district

select *
from tmp_district
order by client_amount desc  -- sorted by number of clients
limit 1;

select *
from tmp_district
order by loans_number desc  -- sorted by higest number of paid loans
limit 1;

select *
from tmp_district
order by loans_sum desc  -- sorted by highest amount of paid loans
limit 1;

# Client analysis - part 3
# Use the query created in the previous task and modify it
#     to determine the percentage of each district in the total amount of loans granted.

with cte_district as (select
    ds.district_id,
    A3 as place,
    count(distinct c.client_id) as client_amount,
    count( l.amount) as loans_number,  -- aggregate by count
    sum(l.amount) as loans_sum        -- aggregate by sum
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
join district ds on c.district_id = ds.district_id
where l.status in ('A', 'C') -- select fully paid loans
and d.type ='OWNER'  -- select only 'owner' customer not 'disponent'
group by ds.district_id, A3 )-- grouping according district
select *,
       (loans_sum*100)/sum(loans_sum) over () as percentage
from cte_district
order by percentage desc;


# Client selection
# Check the database for the clients who meet the following results:
#
# their account balance is above 1000,
# they have more than 5 loans,
# they were born after 1990.
# And we assume that the account balance is loan amount - payments.


select  c.client_id,
       count(amount)  as loan_number,
       sum(amount-payments) as account_balance
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
where l.status in ('A', 'C') -- select fully paid loans
  and d.type ='OWNER'  -- select only 'owner' customer not 'disponent'
  and year(birth_date)>1945      -- show only clients born after 1990
group by c.client_id
having  account_balance >1000  -- show only clients with account balance above 1000
        and loan_number > 5 ;       -- write out clients who have more than 5 credits

# Selection part 2
# From the previous exercise you probably already know that there are no customers who meet the requirements.
# Make an analysis to determine which condition caused the empty results.

select  c.client_id,
       count(amount)  as loan_number,
       sum(amount-payments) as account_balance,
       year(birth_date) as year_of_birth       -- checking the client's year of birth
from loan l
join account a on l.account_id = a.account_id
join disp d on a.account_id = d.account_id
join client c on d.client_id = c.client_id
where l.status in ('A', 'C') -- select fully paid loans
  and d.type ='OWNER'  -- select only 'owner' customer not 'disponent'
  -- and year(birth_date)>1945      -- show only clients born after 1990
group by c.client_id
having  account_balance >1000  -- show only clients with account balance above 1000
order by loan_number desc;       -- check how many maximum loans clients have

# Expiring cards
# Write a procedure to refresh the table you created (you can call it e.g. cards_at_expiration)
# containing the following columns:
#
# client_id,
# card_id,
# expiration_date - assume that the card can be active for 3 years after issue date,
# client_address (column A3 is enough).
# Note: The card table has cards that were issued until the end of 1998.
# Determine the card's expiration (7 days before inactivation)

-- write procedure 
delimiter $$
create procedure getCardsExpiration_a (in set_date date)
begin
    with cte_cardexpiration as (select c.client_id as client_id,
           ca.card_id as card_id,
           issued as card_issued,
           ds.A3 as client_address,
           date_add(issued, interval 3 year ) as card_expiration_date
    from client c
    join disp d on c.client_id = d.client_id
    join card ca on d.disp_id = ca.disp_id
    join district ds on c.district_id = ds.district_id)
    select *,
           case  -- determine card expiration
               when  set_date < date_sub(card_expiration_date, interval 7 day) then 'active card'
                when set_date >= card_expiration_date then 'inactive card'
                else 'expired soon'
                  end as card_activity
    from cte_cardexpiration;
end $$
delimiter ;

-- call procedure
call getCardsExpiration_a ('2001-10-15'); -- write out activity of the cards to date '2001-10-15'
call getCardsExpiration_a (curdate());  -- write out activity of the cards to actual date
drop procedure getCardsExpiration_a;