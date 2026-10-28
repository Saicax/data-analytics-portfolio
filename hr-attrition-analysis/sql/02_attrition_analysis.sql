-- ============================================================
-- Project: HR Employee Attrition Analysis (IBM HR Analytics)
-- File: 02_attrition_analysis.sql
-- Purpose: Answer the client question — which factors are most
--          linked to employees quitting, so HR can act early?
-- Depends on: 01_data_setup.sql (table: hr_attrition, 1,470 rows)
--
-- FORMULA (used in every query below):
--   attrition_rate = (employees with Attrition = 'Yes' in group)
--                    / (all employees in group) * 100
--   Written in SQL as:
--     ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END)
--           / COUNT(*), 2)
--   'Yes' counts are the leavers; the rate is a percentage.
-- ============================================================

USE hr_analytics;

-- ------------------------------------------------------------
-- Q1: Overall attrition rate (the baseline every group is
--     compared against)
-- Export: data/overall_attrition.csv
-- Finding: 237 of 1,470 employees left = 16.12% baseline.
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS total_employees,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
    ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS attrition_rate_pct
FROM hr_attrition;

-- ------------------------------------------------------------
-- Q2: Attrition rate by department
-- Export: data/attrition_by_department.csv
-- Finding: Sales is highest at 20.63% (92 of 446), then
--   Human Resources 19.05% (12 of 63), then Research &
--   Development 13.84% (133 of 961). Sales runs ~4.5 points
--   above the 16.12% baseline; R&D runs ~2.3 points below.
-- ------------------------------------------------------------
SELECT
    department,
    COUNT(*) AS n,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
    ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY department
ORDER BY attrition_rate_pct DESC;

-- ------------------------------------------------------------
-- Q3: Attrition rate by overtime (Yes / No)
-- Export: data/attrition_by_overtime.csv
-- Finding: Overtime = Yes: 30.53% (127 of 416) vs Overtime = No:
--   10.44% (110 of 1,054). Employees working overtime leave at
--   nearly 3x the rate of those who don't — the single strongest
--   binary signal in this dataset.
-- ------------------------------------------------------------
SELECT
    over_time,
    COUNT(*) AS n,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
    ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY over_time
ORDER BY attrition_rate_pct DESC;

-- ------------------------------------------------------------
-- Q4: Attrition rate by salary band (CASE on MonthlyIncome)
-- Bands: <3000 | 3000-8000 | >8000 (monthly USD)
-- Export: data/attrition_by_salary_band.csv
-- Finding: <3000: 28.61% (113 of 395) — by far the worst band.
--   3000-8000: 12.10% (84 of 694). >8000: 10.50% (40 of 381).
--   Attrition falls as pay rises; the sub-3000 band is the
--   clear pay-risk zone.
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN monthly_income < 3000 THEN '<3000'
        WHEN monthly_income <= 8000 THEN '3000-8000'
        ELSE '>8000'
    END AS salary_band,
    COUNT(*) AS n,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
    ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY salary_band
ORDER BY attrition_rate_pct DESC;

-- ------------------------------------------------------------
-- Q5: Attrition rate by tenure band (CASE on YearsAtCompany)
-- Bands: 0-1 | 2-5 | 6-10 | 10+ years
-- Export: data/attrition_by_tenure_band.csv
-- Finding: Attrition falls monotonically with tenure.
--   0-1 years: 34.88% (75 of 215) — the highest rate of any band
--   in the project. 2-5: 15.51% (87 of 561). 6-10: 12.28%
--   (55 of 448). 10+: 8.13% (20 of 246). The first year is the
--   danger window.
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN years_at_company <= 1 THEN '0-1'
        WHEN years_at_company <= 5 THEN '2-5'
        WHEN years_at_company <= 10 THEN '6-10'
        ELSE '10+'
    END AS tenure_band,
    COUNT(*) AS n,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
    ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY tenure_band
ORDER BY attrition_rate_pct DESC;

-- ------------------------------------------------------------
-- Q6: Highest-risk groups — RANK() over department x overtime
-- Export: data/highest_risk_groups.csv
-- Finding: Rank 1 = Sales + overtime at 37.50% (48 of 128) —
--   more than double the 16.12% baseline, on a solid sample.
--   Rank 2 = Human Resources + overtime at 29.41%, but note the
--   small sample (5 of 17) — treat as a flag, not a verdict.
--   Rank 3 = R&D + overtime at 27.31% (74 of 271). The pattern:
--   overtime lifts attrition in EVERY department; the no-overtime
--   groups all sit below baseline (best: R&D + no overtime,
--   8.55%, rank 6).
-- ------------------------------------------------------------
WITH group_stats AS (
    SELECT
        department,
        over_time,
        COUNT(*) AS n,
        SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
        ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END)
              / COUNT(*), 2) AS attrition_rate_pct
    FROM hr_attrition
    GROUP BY department, over_time
)
SELECT
    department,
    over_time,
    n,
    leavers,
    attrition_rate_pct,
    RANK() OVER (ORDER BY attrition_rate_pct DESC) AS risk_rank
FROM group_stats
ORDER BY risk_rank;

-- ------------------------------------------------------------
-- Q7 (bonus): Attrition rate by job role
-- Export: data/attrition_by_job_role.csv
-- Finding: Sales Representative is the worst role at 39.76%
--   (33 of 83) — the highest rate of any single group in the
--   project. Laboratory Technician 23.94% (62 of 259) and
--   Human Resources 23.08% (12 of 52) follow. Safest roles:
--   Research Director 2.50% (2 of 80) and Manager 4.90% (5 of 102).
-- ------------------------------------------------------------
SELECT
    job_role,
    COUNT(*) AS n,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
    ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY job_role
ORDER BY attrition_rate_pct DESC;

-- ------------------------------------------------------------
-- Q8 (bonus): Attrition rate by marital status
-- Export: data/attrition_by_marital_status.csv
-- Finding: Single employees leave at 25.53% (120 of 470) —
--   roughly double Married (12.48%, 84 of 673) and Divorced
--   (10.09%, 33 of 327). Note: this likely overlaps with the
--   tenure effect (younger, newer hires skew single), so treat
--   it as a correlated signal, not a cause.
-- ------------------------------------------------------------
SELECT
    marital_status,
    COUNT(*) AS n,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
    ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS attrition_rate_pct
FROM hr_attrition
GROUP BY marital_status
ORDER BY attrition_rate_pct DESC;
