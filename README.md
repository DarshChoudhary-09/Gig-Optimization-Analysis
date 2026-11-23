# Gig Earning Optimizer: Freelancer Pay & Platform Earnings Analysis

An end-to-end analytics project that asks what drives freelancer pay and whether the platform a freelancer works on changes their earnings. It combines Excel (Power Query), MySQL, Python and a three-page Power BI dashboard.

**Tools:** Excel / Power Query, MySQL , Python (pandas, SciPy, scikit-learn, Matplotlib, seaborn), Power BI (DAX)

## Dashboard preview
**Overview**
![Overview](docs/images/overview.png)

**Worker pay**
![Worker pay](docs/images/worker_pay.png)

**Platforms and earnings**
![Platforms and earnings](docs/images/platforms_earnings.png)

## Business questions
1. What drives a freelancer's hourly rate?
2. Do platform or job category change earnings, or is the difference just noise?
3. How sensitive are net-earnings rankings to the platform-fee assumption?

## The dashboard (Power BI)
| Page | What it shows |
|---|---|
| **Overview** | KPI cards (workers, average hourly rate, total earnings, job postings); slicers for region, experience level and platform; average hourly rate by region; average earnings per freelancer by platform |
| **Worker pay** | Average hourly rate by experience level and by category; scatter of years of experience against hourly rate; a Key influencers visual ranking what lifts hourly rate |
| **Platforms and earnings** | A what-if slider for the platform fee; a heat-map matrix of average net earnings by category and platform; gross earnings against net earnings by platform; the share of freelancers with negative net earnings |

**Model:** a shared `dim_platform` lookup table links the worker and transaction data, and DAX measures (including a what-if fee parameter) drive the cards and charts.

## Key findings
- **Region is the strongest driver of hourly rate.** It explains about 47% of the variation. The average rate is about $152 in Western Europe and about $51 in Africa, and the Key influencers visual ranks region first.
- **Pay rises with experience.** Average hourly rate is about $45.5 for Junior, $82.4 for Mid and $114.9 for Senior workers (only 46 Junior workers, so treat that group with care).
- **Platform does not significantly change earnings.** Average earnings per freelancer are almost the same on all five platforms (about $4,900 to $5,100). A one-way ANOVA gives p = 0.97, and bootstrap 95% confidence intervals overlap heavily, so no platform winner is claimed. Job category also shows no significant effect (p = 0.53).
- **Net earnings depend on the fee assumption.** With one flat fee on every platform, the average net earning is about $4,267 at 10% and about $3,766 at 20%. With each platform's assumed fee, Fiverr ranks lowest (about $3,819) only because its assumed fee is 20%, not because of performance.
- **About 3.1% of freelancers (61 of 1,950) end up with negative net earnings** once platform fees and marketing spend are subtracted.
- **A regression and a random forest predict hourly rate with a cross-validated R² of about 0.68**, against about 0 for a baseline that guesses the average. Region and years of experience matter most. `[Keep this line only if you ran the Python models.]`

## Data
| Dataset | Rows | Description | Used for |
|---|---|---|---|
| workers | 500 | Freelancer profiles: category, skills, region, experience, hourly rate | Worker pay analysis |
| transaction_clean | 1,950 | Freelancer earnings by platform, with costs | Platform and net-earnings analysis |
| gigs_clean | 52,977 | Upwork job postings, Dec 2023 to Feb 2024 | Job postings card; SQL and Python analysis |
| gigs_skills | 263,240 | One row per job and skill | SQL and Python analysis |
| time_tracking_clean | 10,000 | Salaried employee records | Benchmark in SQL and Python only |

Sources: `[add where each dataset came from and its license]`.

## Methods
1. **Cleaning (Excel / Power Query):** removed duplicate postings, converted text to numbers and dates, extracted category and skills, flagged outliers (kept, not deleted), and created order and band columns for sorting.
2. **SQL (MySQL 8):** data-quality checks, then analytical queries using CTEs, window functions and confidence intervals, plus views, indexes and a stored procedure. `[Remove what you did not build.]`
3. **Python:** exploratory analysis, ANOVA and Kruskal-Wallis with effect sizes, bootstrap confidence intervals, regression and random forest with cross-validation, and fee sensitivity analysis. `[Remove what you did not run.]`
4. **Power BI:** the three-page dashboard described above.

## Repository structure
```
GigEarningOptimizer/
  data/       cleaned CSV files
  excel/      GigEarningOptimizer_Excel.xlsx
  sql/        SQL scripts
  python/     analysis notebook and requirements.txt
  powerbi/    GigEarningOptimizer.pbix
  docs/       screenshots
```
Adjust the folder names to match your repository.

## How to run
1. **SQL:** create the database, run the table-creation script, import the CSVs from `data/`, then run the scripts in `sql/`.
2. **Python:** `pip install -r python/requirements.txt`, set the data folder path at the top of the notebook, then run it from top to bottom.
3. **Power BI:** open `powerbi/GigEarningOptimizer.pbix` and point the data sources to the `data/` folder.

## Limitations
- The transactions data shows almost no structure and looks synthetic, so no claim is made about which platform earns more.
- Platform fees are assumptions. `[State which fees you verified; PeoplePerHour and Toptal are unverified placeholders unless you checked them.]`
- Workers and transactions cannot be joined (different IDs), so they are compared only by platform.
- Real job-posting volume covers about 11 days (12 to 23 Feb 2024), so no trends over time are claimed.
- Results show association, not cause.

## Skills demonstrated
Power BI (data modeling, DAX measures, what-if parameters, heat maps, Key influencers), Excel (Power Query, pivot tables), SQL (CTEs, window functions, views), Python (pandas, statistics, scikit-learn), data-quality checks and honest reporting of limitations.

## Author
Darsh Choudhary · [LinkedIn](https://linkedin.com/in/darsh-choudhary-4a7563238) · [GitHub](https://github.com/DarshChoudhary-09)
