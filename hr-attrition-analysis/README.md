# HR Employee Attrition Analysis

## The Question

**Client brief:** "I want to know which factors — department, overtime, salary band, tenure — are most linked to employees quitting, so HR can act before people leave."

In other words: who is most likely to leave, and what can HR do about it *before* they hand in their notice?

## The Data

- **Source:** IBM HR Analytics Employee Attrition dataset (`WA_Fn-UseC_-HR-Employee-Attrition.csv`) — the classic HR attrition dataset.
- **Size:** 1,470 employees, 35 columns in the raw file.
- **Fields used:** Department, Attrition (Yes/No), OverTime, MonthlyIncome, YearsAtCompany, plus JobRole and MaritalStatus for bonus analysis.
- **Fields deliberately ignored (per brief):** EmployeeNumber (row ID, not a factor), EducationField, and the constant columns EmployeeCount (always 1), Over18 (always Y), StandardHours (always 80).

## The Process

1. **Inspect before loading.** Verified with `file` and byte inspection: UTF-8 **with BOM**, CRLF (`\r\n`) line endings, 1,471 lines (header + 1,470 rows). The BOM sits on the header line only, so `IGNORE 1 ROWS` removes it — no special handling needed.
2. **Load** (`sql/01_data_setup.sql`): `CREATE TABLE` + `LOAD DATA INFILE` with `CHARACTER SET utf8mb4` and `LINES TERMINATED BY '\r\n'`. Dropped columns were loaded into throwaway `@skip` variables. Row count verified: **1,470**.
3. **Analyse** (`sql/02_attrition_analysis.sql`): 8 queries, each saved as a numbered section with its own export file and Finding line.

**Attrition-rate formula (used in every query):**

```
attrition_rate = (employees with Attrition = 'Yes' in the group)
                 / (all employees in the group) × 100
```

In SQL: `ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2)`.

**Data-quality notes:**
- Zero empty cells anywhere in the file (verified across all 35 columns), so no NULL-handling was needed at load time.
- Three columns are constants (EmployeeCount = 1, Over18 = Y, StandardHours = 80) and carry no analytical signal — they were dropped.
- `Attrition` is a clean Yes/No flag; no standardization was required.

## Findings

**Baseline: 237 of 1,470 employees left = 16.12%.** Every rate below is judged against this line.

### 1. Overtime is the strongest binary signal

| OverTime | n | Leavers | Attrition rate |
|---|---|---|---|
| Yes | 416 | 127 | **30.53%** |
| No | 1,054 | 110 | 10.44% |

Employees working overtime leave at **nearly 3× the rate** of those who don't. The gap (20.1 points) is the largest of any two-group split in the project.

### 2. The first year is the danger window

| Tenure band | n | Leavers | Attrition rate |
|---|---|---|---|
| 0–1 years | 215 | 75 | **34.88%** |
| 2–5 years | 561 | 87 | 15.51% |
| 6–10 years | 448 | 55 | 12.28% |
| 10+ years | 246 | 20 | 8.13% |

Attrition falls **monotonically** with tenure. More than a third of employees in their first year leave — the highest rate of any band in this project.

### 3. Low pay is a clear risk zone

| Salary band (monthly) | n | Leavers | Attrition rate |
|---|---|---|---|
| < $3,000 | 395 | 113 | **28.61%** |
| $3,000–$8,000 | 694 | 84 | 12.10% |
| > $8,000 | 381 | 40 | 10.50% |

The sub-$3,000 band leaves at nearly triple the rate of the top band. Pay alone doesn't explain everything (overtime and tenure matter too), but the gradient is unambiguous.

### 4. Department: Sales highest, R&D lowest

| Department | n | Leavers | Attrition rate |
|---|---|---|---|
| Sales | 446 | 92 | **20.63%** |
| Human Resources | 63 | 12 | 19.05% |
| Research & Development | 961 | 133 | 13.84% |

### 5. Highest-risk groups (RANK() over department × overtime)

| Rank | Department | OverTime | n | Leavers | Attrition rate |
|---|---|---|---|---|---|
| 1 | Sales | Yes | 128 | 48 | **37.50%** |
| 2 | Human Resources | Yes | 17 | 5 | 29.41% |
| 3 | Research & Development | Yes | 271 | 74 | 27.31% |
| 4 | Human Resources | No | 46 | 7 | 15.22% |
| 5 | Sales | No | 318 | 44 | 13.84% |
| 6 | Research & Development | No | 690 | 59 | 8.55% |

The pattern is decisive: **overtime lifts attrition in every single department**, and every no-overtime group sits below the 16.12% baseline. Rank 1 (Sales + overtime, 37.50%, n = 128) is more than double the baseline on a solid sample. Rank 2 (HR + overtime, 29.41%) comes with a small-sample warning — only 17 people — so treat it as a flag, not a verdict.

### 6. Bonus: job role and marital status

- **Sales Representative is the worst single role: 39.76% (33 of 83)** — the highest rate of any group in the project. Laboratory Technician (23.94%, 62 of 259) and Human Resources (23.08%, 12 of 52) follow. Safest: Research Director (2.50%, 2 of 80) and Manager (4.90%, 5 of 102).
- **Single employees leave at 25.53% (120 of 470)**, roughly double Married (12.48%, 84 of 673) and Divorced (10.09%, 33 of 327). Caveat: this likely overlaps with the tenure effect (newer, younger hires skew single) — a correlated signal, not proof of cause.

## HR Actions — acting BEFORE people leave

Each finding maps to a concrete preventive move:

1. **Cap and rotate overtime (targets Finding 1 + 5).** Overtime is the one lever HR controls directly. Set a monthly overtime cap, rotate coverage in Sales and R&D, and trigger a manager check-in when anyone's overtime crosses the cap for two consecutive months. Goal: move the 416 overtime employees toward the 10.44% no-overtime rate.
2. **First-year retention program (targets Finding 2).** With 34.88% of 0–1-year employees leaving, assign every new hire a buddy/mentor, run structured 30/60/90-day check-ins, and review first-year pay and workload at the 6-month mark — before the decision to leave hardens.
3. **Review sub-$3,000 pay bands (targets Finding 3).** 395 employees sit below $3,000/month and leave at 28.61%. Audit these roles for market competitiveness and build a transparent path to the next band; even a small band adjustment is cheaper than replacing 113 people.
4. **Sales-team intervention first (targets Findings 4 + 5 + 6).** Sales + overtime (37.50%) and Sales Representatives (39.76%) are the two hottest spots. Start with workload reviews and territory/commission conversations for Sales Reps on overtime — this one group covers the top of every ranking.
5. **Watchlist, not witch-hunt (targets Finding 5).** Use the ranked groups as an early-warning list for supportive check-ins, never as a penalty list. Small-n groups (e.g. HR + overtime, n = 17) get a conversation, not a policy.

## Files

```
04-hr-attrition/
├── README.md
├── hr-attrition.xlsx              # workbook: one sheet per result + native charts
├── sql/
│   ├── 01_data_setup.sql          # CREATE TABLE + LOAD DATA (1,470 rows)
│   └── 02_attrition_analysis.sql  # 8 numbered queries with Findings
├── data/                          # clean result CSVs (data only, no notes)
│   ├── overall_attrition.csv
│   ├── attrition_by_department.csv
│   ├── attrition_by_overtime.csv
│   ├── attrition_by_salary_band.csv
│   ├── attrition_by_tenure_band.csv
│   ├── highest_risk_groups.csv
│   ├── attrition_by_job_role.csv
│   └── attrition_by_marital_status.csv
└── images/                        # chart PNGs
    ├── attrition_by_department.png
    ├── attrition_by_overtime.png
    ├── attrition_by_salary_band.png
    └── attrition_by_tenure_band.png
```

## Tools

MySQL 8 · Python (csv verification) · matplotlib · openpyxl
