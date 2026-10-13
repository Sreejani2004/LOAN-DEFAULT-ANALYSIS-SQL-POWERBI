USE loan_analysis;
SHOW TABLES;
SELECT COUNT(*) AS total_rows
FROM loan_data;
SELECT *
FROM loan_data
LIMIT 10;
SELECT loan_status, COUNT(*) AS total_loans
FROM loan_data
GROUP BY loan_status
ORDER BY total_loans DESC;

SELECT
    COUNT(*) AS total_loans,
    SUM(loan_amnt) AS total_loan_amount,
    ROUND(AVG(loan_amnt), 2) AS average_loan_amount,
    ROUND(AVG(int_rate), 2) AS average_interest_rate,
    ROUND(AVG(annual_inc), 2) AS average_annual_income
FROM loan_data;

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN default_flag = 1 THEN 1 ELSE 0 END)
        AS defaulted_loans,
    SUM(CASE WHEN default_flag = 0 THEN 1 ELSE 0 END)
        AS fully_paid_loans,
    SUM(CASE WHEN default_flag IS NULL THEN 1 ELSE 0 END)
        AS loans_without_final_flag,
    ROUND(
        100.0 * SUM(CASE WHEN default_flag = 1 THEN 1 ELSE 0 END)
        / NULLIF(
            SUM(CASE WHEN default_flag IN (0, 1) THEN 1 ELSE 0 END),
            0
        ),
        2
    ) AS default_rate_pct
FROM loan_data;
SELECT
    SUM(loan_status = 'Charged Off') AS defaults,
    SUM(loan_status IN ('Fully Paid', 'Charged Off')) AS loans_with_known_outcomes,
    ROUND(
        100.0 * SUM(loan_status = 'Charged Off')
        / SUM(loan_status IN ('Fully Paid', 'Charged Off')),
        2
    ) AS default_rate
FROM loan_data;

SELECT
    grade,
    COUNT(*) AS total_loans,
    SUM(loan_status = 'Charged Off') AS defaulted_loans,
    SUM(loan_status = 'Fully Paid') AS fully_paid_loans,
    ROUND(
        100.0 * SUM(loan_status = 'Charged Off')
        / NULLIF(
            SUM(loan_status IN ('Fully Paid', 'Charged Off')),
            0
        ),
        2
    ) AS default_rate_pct
FROM loan_data
GROUP BY grade
ORDER BY grade;

SELECT
    term,
    COUNT(*) AS total_loans,
    SUM(loan_status = 'Charged Off') AS defaulted_loans,
    ROUND(
        100.0 * SUM(loan_status = 'Charged Off')
        / NULLIF(
            SUM(loan_status IN ('Fully Paid', 'Charged Off')),
            0
        ),
        2
    ) AS default_rate_pct
FROM loan_data
GROUP BY term
ORDER BY term;

SELECT
    CASE
        WHEN int_rate < 10 THEN 'Below 10%'
        WHEN int_rate < 15 THEN '10%–14.99%'
        WHEN int_rate < 20 THEN '15%–19.99%'
        ELSE '20% and above'
    END AS interest_rate_band,
    COUNT(*) AS total_loans,
    SUM(loan_status = 'Charged Off') AS defaulted_loans,
    ROUND(
        100.0 * SUM(loan_status = 'Charged Off')
        / NULLIF(
            SUM(loan_status IN ('Fully Paid', 'Charged Off')),
            0
        ),
        2
    ) AS default_rate_pct
FROM loan_data
GROUP BY interest_rate_band
ORDER BY MIN(int_rate);

SELECT
    purpose,
    COUNT(*) AS total_loans,
    SUM(loan_status = 'Charged Off') AS defaulted_loans,
    ROUND(
        100.0 * SUM(loan_status = 'Charged Off')
        / NULLIF(
            SUM(loan_status IN ('Fully Paid', 'Charged Off')),
            0
        ),
        2
    ) AS default_rate_pct
FROM loan_data
GROUP BY purpose
ORDER BY default_rate_pct DESC;

SELECT
    home_ownership,
    COUNT(*) AS total_loans,
    SUM(loan_status = 'Charged Off') AS defaulted_loans,
    ROUND(
        100.0 * SUM(loan_status = 'Charged Off')
        / NULLIF(
            SUM(loan_status IN ('Fully Paid', 'Charged Off')),
            0
        ),
        2
    ) AS default_rate_pct
FROM loan_data
GROUP BY home_ownership
ORDER BY default_rate_pct DESC;

SELECT
    CASE
        WHEN annual_inc < 25000 THEN 'Below $25K'
        WHEN annual_inc < 50000 THEN '$25K–$49,999'
        WHEN annual_inc < 75000 THEN '$50K–$74,999'
        WHEN annual_inc < 100000 THEN '$75K–$99,999'
        ELSE '$100K and above'
    END AS income_band,
    COUNT(*) AS total_loans,
    SUM(loan_status = 'Charged Off') AS defaulted_loans,
    ROUND(
        100.0 * SUM(loan_status = 'Charged Off')
        / NULLIF(
            SUM(loan_status IN ('Fully Paid', 'Charged Off')),
            0
        ),
        2
    ) AS default_rate_pct
FROM loan_data
GROUP BY income_band
ORDER BY MIN(annual_inc);

SELECT
    YEAR(STR_TO_DATE(issue_date, '%d-%m-%Y')) AS issue_year,
    COUNT(*) AS loans_issued,
    SUM(loan_amnt) AS total_amount_issued
FROM loan_data
WHERE STR_TO_DATE(issue_date, '%d-%m-%Y') IS NOT NULL
GROUP BY YEAR(STR_TO_DATE(issue_date, '%d-%m-%Y'))
ORDER BY issue_year;


WITH grade_analysis AS (
    SELECT
        grade,
        SUM(loan_status = 'Charged Off') AS defaults,
        SUM(loan_status IN ('Fully Paid', 'Charged Off'))
            AS known_outcome_loans
    FROM loan_data
    GROUP BY grade
),
grade_rates AS (
    SELECT
        grade,
        ROUND(
            100.0 * defaults / NULLIF(known_outcome_loans, 0),
            2
        ) AS default_rate_pct
    FROM grade_analysis
)
SELECT
    grade,
    default_rate_pct,
    RANK() OVER (
        ORDER BY default_rate_pct DESC
    ) AS risk_rank
FROM grade_rates
ORDER BY risk_rank;
