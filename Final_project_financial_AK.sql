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
group by EXTRACT(YEAR FROM date),
        EXTRACT(QUARTER FROM date),
        EXTRACT(MONTH FROM date) with rollup ;

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
select*
from client;
