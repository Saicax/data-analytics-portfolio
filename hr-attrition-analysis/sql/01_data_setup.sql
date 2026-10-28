-- ============================================================
-- Project: HR Employee Attrition Analysis (IBM HR Analytics)
-- File: 01_data_setup.sql
-- Purpose: Create the hr_attrition table and load the dataset
-- Source: WA_Fn-UseC_-HR-Employee-Attrition.csv
--          (classic IBM HR Analytics Employee Attrition dataset)
-- Rows loaded: 1,470 (verified)
-- Database: hr_analytics
-- Encoding: UTF-8 WITH BOM, line endings CRLF (\r\n)
--   - Verified with `file` + byte inspection before writing this
--     script: 1,471 CRLF terminators (header + 1,470 data rows),
--     zero lone LF/CR characters.
--   - The BOM sits on the first field of the HEADER line only, so
--     IGNORE 1 ROWS removes it; no special handling needed.
-- Empty cells: verified ZERO empty cells in the whole file
--   (checked every column), so a direct column load is safe.
--   If a future export contains blanks, wrap numeric columns in
--   @variables and use SET col = NULLIF(@var, '') (see project #3).
-- Columns kept vs dropped (per client brief):
--   KEPT: department, attrition flag, overtime, monthly income,
--         years at company, plus job role, marital status and the
--         satisfaction/tenure columns used by the bonus queries.
--   DROPPED (loaded into throwaway @skip variables):
--     EducationField  - brief says ignore
--     EmployeeNumber  - brief says ignore (row ID, not a factor)
--     EmployeeCount   - constant value 1 in every row
--     Over18          - constant value Y in every row
--     StandardHours   - constant value 80 in every row
-- ============================================================

CREATE DATABASE IF NOT EXISTS hr_analytics;
USE hr_analytics;

CREATE TABLE hr_attrition (
    age INT,
    attrition VARCHAR(3),
    business_travel VARCHAR(30),
    daily_rate INT,
    department VARCHAR(50),
    distance_from_home INT,
    education INT,
    environment_satisfaction INT,
    gender VARCHAR(10),
    hourly_rate INT,
    job_involvement INT,
    job_level INT,
    job_role VARCHAR(50),
    job_satisfaction INT,
    marital_status VARCHAR(20),
    monthly_income INT,
    monthly_rate INT,
    num_companies_worked INT,
    over_time VARCHAR(3),
    percent_salary_hike INT,
    performance_rating INT,
    relationship_satisfaction INT,
    stock_option_level INT,
    total_working_years INT,
    training_times_last_year INT,
    work_life_balance INT,
    years_at_company INT,
    years_in_current_role INT,
    years_since_last_promotion INT,
    years_with_curr_manager INT
);

-- Copy the CSV into the MySQL secure_file_priv folder first
--   C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/WA_Fn-UseC_-HR-Employee-Attrition.csv
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/WA_Fn-UseC_-HR-Employee-Attrition.csv'
INTO TABLE hr_attrition
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(age, attrition, business_travel, daily_rate, department,
 distance_from_home, education, @skip_education_field, @skip_employee_count,
 @skip_employee_number, environment_satisfaction, gender, hourly_rate,
 job_involvement, job_level, job_role, job_satisfaction, marital_status,
 monthly_income, monthly_rate, num_companies_worked, @skip_over18,
 over_time, percent_salary_hike, performance_rating,
 relationship_satisfaction, @skip_standard_hours, stock_option_level,
 total_working_years, training_times_last_year, work_life_balance,
 years_at_company, years_in_current_role, years_since_last_promotion,
 years_with_curr_manager);

-- Verify: should return 1470
SELECT COUNT(*) AS row_count FROM hr_attrition;
