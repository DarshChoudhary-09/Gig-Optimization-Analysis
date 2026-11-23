create database gig_optimizer;
use gig_optimizer;

describe workers_data;
select * from workers_data;
select * from transaction_clean;


-- 1. Average hourly rate by category 
select category, count(*) as workers, 
round(avg(hourly_rate_usd),2) as avg_rate
from workers_data 
group by category
order by avg_rate desc;


select * from gigs_clean;


DROP TABLE IF EXISTS workers_skills;

CREATE TABLE workers_skills AS
SELECT w.freelancer_id,
       (TRIM(jt.skill) COLLATE utf8mb4_unicode_ci) AS skill
FROM workers_data w,
     JSON_TABLE(
       CONCAT('["', REPLACE(REPLACE(w.primary_skills, '"', ''), ',', '","'), '"]'),
       '$[*]' COLUMNS (skill VARCHAR(100) PATH '$')
     ) AS jt
WHERE w.primary_skills IS NOT NULL
  AND w.primary_skills <> '';

SELECT * FROM workers_skills LIMIT 10;


ALTER TABLE workers_skills
  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SET GLOBAL local_infile = 1;

SHOW VARIABLES LIKE 'secure_file_priv';




DROP TABLE IF EXISTS gigs_clean;

CREATE TABLE gigs_clean (
    title VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    is_hourly BOOLEAN,
    hourly_low DECIMAL(10, 2),
    budget DECIMAL(10, 2),
    job_id VARCHAR(50)  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci primary key,
    category VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    skills TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    location_requirement TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    pay_type VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    hourly_high DECIMAL(10, 2),
    hourly_mid DECIMAL(10, 2),
    country_clean VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    outlier_flag INT,
    posted_at DATETIME,
    posted_hour_utc INT,
    posted_weekday VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    weekday_num INT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;



LOAD DATA LOCAL INFILE 'C:/Users/HP/Desktop/Darsh/Gig Earning Optimizer/clean data/gigs_clean_fixed.csv'
INTO TABLE gigs_clean
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(title, is_hourly, hourly_low, budget, job_id, category, skills, location_requirement, pay_type, hourly_high, hourly_mid, country_clean, outlier_flag, posted_at, posted_hour_utc, posted_weekday, weekday_num);



LOAD DATA LOCAL INFILE 'C:\Users\HP\Desktop\Darsh\Gig Earning Optimizer\clean data'
INTO TABLE gigs_clean
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(title, is_hourly, hourly_low, budget, job_id, category, skills, location_requirement, pay_type, hourly_high, hourly_mid, country_clean, outlier_flag, posted_at, posted_hour_utc, posted_weekday, weekday_num);


USE gig_optimizer;

DROP TABLE IF EXISTS gigs_skills;

CREATE TABLE gigs_skills (
    job_id VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    skill VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    PRIMARY KEY (job_id, skill),
    FOREIGN KEY (job_id) REFERENCES gigs_clean(job_id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


LOAD DATA LOCAL INFILE 'C:/Users/HP/Desktop/Darsh/Gig Earning Optimizer/clean data/gigs_skills_fixed.csv'
INTO TABLE gigs_skills
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(job_id, skill);

-- 1. Count Null Values.
select count(*) from gigs_clean 
where hourly_low is null;

-- 2. if in place of null count 0 comes then correct blank space into null.

set sql_safe_updates = 0;
update gigs_clean set hourly_low = null, hourly_high = null, hourly_mid = null where hourly_low = 0;
update gigs_clean set budget = null where budget = 0;

-- 3. Data check 
-- Row Counts - 
select 'workers_data' as t, count(*) as n from workers_data
union all select 'transaction_clean' , count(*) from transaction_clean
union all select 'time_tracking_clean', count(*) from time_tracking_clean
union all select 'gigs_clean', count(*) from gigs_clean
union all select 'gigs_skills', count(*) from gigs_skills;

-- duplicates keys. 
select job_id,
count(*) from gigs_clean
group by job_id
having count(*) > 1;

-- orphan child rows (skills with no parents)
select count(*) from gigs_skills s
left join gigs_clean c 
on c.job_id = s.job_id
where c.job_id is null;

-- the net earning formula still holds 
select freelancer_id from transaction_clean
where abs(est_net_earnings_usd - (earnings_usd - est_platform_fee_usd - marketing_spend_usd)) > 0.05;

-- how much does seniority add inside eacg field?
WITH cat_avg AS (
  SELECT category, AVG(hourly_rate_usd) AS cat_avg_rate FROM workers_data GROUP BY category
),
lvl AS (
  SELECT category, experience_level, years_experience, COUNT(*) AS workers, AVG(hourly_rate_usd) AS avg_rate
  FROM workers_data GROUP BY category, experience_level, years_experience
)
SELECT l.category, l.experience_level, l.workers, ROUND(l.avg_rate,2) AS avg_rate,
       ROUND(100*(l.avg_rate/c.cat_avg_rate-1),1) AS pct_vs_category_avg
FROM lvl l JOIN cat_avg c ON c.category = l.category
ORDER BY l.category, l.years_experience;


-- Median rate per category
with ranked as (
	select category, hourly_rate_usd,
		row_number() over(partition by category order by hourly_rate_usd) as rn,
        count(*) over (partition by category) as cnt
	from workers_data
)
select category, round(avg(hourly_rate_usd),2) as median_rate
from ranked
where rn >= cnt/2.0 and rn <= cnt/2.0 + 1 
group by category order by median_rate desc;

-- who is in the top pay quartile
WITH ranked AS (
  SELECT w.*, NTILE(4) OVER (ORDER BY hourly_rate_usd) AS pay_quartile FROM workers_data w
)
SELECT pay_quartile, COUNT(*) AS workers, MIN(hourly_rate_usd) AS min_rate, MAX(hourly_rate_usd) AS max_rate,
       ROUND(AVG(years_experience),1) AS avg_years,
       ROUND(100*AVG(CASE WHEN experience_level='Senior' THEN 1 ELSE 0 END),1) AS pct_senior
FROM ranked GROUP BY pay_quartile ORDER BY pay_quartile;

-- Daily postings with day-over-day change and a 3-day average
WITH daily AS (
  SELECT posted_at, COUNT(*) AS postings FROM gigs_clean
  WHERE posted_at >= '2024-02-13' GROUP BY posted_at
)
SELECT posted_at, postings,
       ROUND(100.0*(postings - LAG(postings) OVER (ORDER BY posted_at))
             / LAG(postings) OVER (ORDER BY posted_at),1) AS dod_pct,
       ROUND(AVG(postings) OVER (ORDER BY posted_at ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),0) AS moving_avg_3d
FROM daily ORDER BY posted_at;

-- do platforms really differ in earning 
WITH stats AS (
  SELECT platform, COUNT(*) AS n, AVG(earnings_usd) AS m, AVG(earnings_usd*earnings_usd) AS msq
  FROM transaction_clean GROUP BY platform
),
sd AS (SELECT platform, n, m, SQRT((msq - m*m) * n/(n-1)) AS s FROM stats)
SELECT platform, n, ROUND(m) AS mean_earnings,
       ROUND(m - 1.96*s/SQRT(n)) AS ci_low, ROUND(m + 1.96*s/SQRT(n)) AS ci_high
FROM sd ORDER BY m DESC;

CREATE OR REPLACE VIEW v_category_skill_opportunity AS
WITH sp AS (
  SELECT w.category, s.skill, COUNT(*) AS workers, AVG(w.hourly_rate_usd) AS avg_rate
  FROM workers_skills s
  JOIN workers_data w ON w.freelancer_id = s.freelancer_id
  GROUP BY w.category, s.skill
),
demand AS (
  SELECT skill, COUNT(*) AS postings
  FROM gigs_skills
  GROUP BY skill
),
j AS (
  SELECT sp.category, sp.skill, sp.workers, sp.avg_rate, d.postings
  FROM sp
  JOIN demand d ON d.skill = sp.skill
),
scored AS (
  SELECT j.*,
         PERCENT_RANK() OVER (PARTITION BY category ORDER BY avg_rate) AS pay_pct,
         PERCENT_RANK() OVER (PARTITION BY category ORDER BY postings) AS demand_pct
  FROM j
)
SELECT category, skill, workers, ROUND(avg_rate, 2) AS avg_rate, postings,
       ROUND(100 * (0.5 * pay_pct + 0.5 * demand_pct), 1) AS opportunity_score
FROM scored;

DROP PROCEDURE IF EXISTS recommend_skills;

DELIMITER //

DROP PROCEDURE IF EXISTS recommend_skills;

DELIMITER //
CREATE PROCEDURE recommend_skills(IN p_category VARCHAR(40), IN p_limit INT)
BEGIN
  SELECT skill, workers, avg_rate, postings, opportunity_score
  FROM v_category_skill_opportunity
  WHERE category = p_category
  ORDER BY opportunity_score DESC
  LIMIT p_limit;
END //
DELIMITER ;

SELECT DISTINCT category FROM workers_data;
CALL recommend_skills('Data Engineering', 5);

SELECT COUNT(DISTINCT ws.skill) AS matching_skills
FROM workers_skills ws
JOIN gigs_skills gs ON gs.skill = ws.skill;

(SELECT 'worker_skill' AS src, skill COLLATE utf8mb4_unicode_ci AS val
 FROM workers_skills LIMIT 10)
UNION ALL
(SELECT 'gig_skill', skill COLLATE utf8mb4_unicode_ci
 FROM gigs_skills GROUP BY skill LIMIT 10)
UNION ALL
(SELECT 'category', category COLLATE utf8mb4_unicode_ci
 FROM workers_data GROUP BY category LIMIT 10);