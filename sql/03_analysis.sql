-- 03_analysis.sql
-- Analysis of the oncology core cohort (Phase 2/2-3/3, start 2010-2017, n = 6,925)
-- Run against: analysis.onc_core (view built from analysis.onc_cohort)
-- Snapshot date: 2026-11-18

--Q1: termination by phase
SELECT phase,
       COUNT(*) AS trials,
       SUM(terminated_flag) AS terminated,
       ROUND(100.0 * AVG(terminated_flag), 1) AS term_rate_pct
FROM analysis.onc_core
GROUP BY phase
ORDER BY phase;

-- RESULT (core window 2010-2017, n = 6,925; 1,592 terminated = 23.0%):
--   Phase 2:   5,191 trials, 1,284 terminated -> 24.7%
--   Phase 2/3:   197 trials,    40 terminated -> 20.3%
--   Phase 3:   1,537 trials,   268 terminated -> 17.4%
-- INTERPRETATION: Termination falls steadily from Phase 2 to Phase 3 (about 7 points
--   lower in Phase 3). Phase 2/3 is a small group (197 trials), so treat it cautiously.
--   Statistical test (chi-square) planned in the Python stage.

--Q2: termination by sponsor group
SELECT sponsor_group,
       COUNT(*) AS trials,
       SUM(terminated_flag) AS terminated,
       ROUND(100.0 * AVG(terminated_flag), 1) AS term_rate_pct
FROM analysis.onc_core
GROUP BY sponsor_group
ORDER BY sponsor_group;

-- RESULT (core window, n = 6,925):
--   Academic/Other: 4,177 trials, 1,039 terminated -> 24.9%
--   Industry:       2,188 trials,   443 terminated -> 20.2%
--   NIH/Network:      490 trials,    99 terminated -> 20.2%
--   Government:        70 trials,    11 terminated -> 15.7%
-- INTERPRETATION: Industry-sponsored trials terminate less often than academic/other
--   trials (20.2% vs 24.9%, about 5 points). NIH/Network matches industry.
--   Government has only 70 trials (11 terminated), too few for firm conclusions.
-- NOTE: Sponsor groups: Industry; NIH/Network (NIH + NETWORK); Government (FED + OTHER_GOV);
--   Academic/Other (OTHER + INDIV + UNKNOWN). Sponsor type may overlap with phase
--   (e.g. more industry trials in Phase 3), so check this in the regression.

--Q3: trend by year, with a rolling 3-year rate (window function)
WITH yearly AS (
    SELECT start_year,
           COUNT(*) AS trials,
           SUM(terminated_flag) AS terminated
    FROM analysis.onc_core
    GROUP BY start_year
)
SELECT start_year, trials, terminated,
       ROUND(100.0 * terminated / trials, 1) AS rate_pct,
       ROUND(100.0 * SUM(terminated) OVER w / SUM(trials) OVER w, 1) AS rolling_3yr_rate_pct
FROM yearly
WINDOW w AS (ORDER BY start_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
ORDER BY start_year;

-- RESULT (yearly termination rate, core window):
--   2010: 23.1% | 2011: 22.5% | 2012: 22.7% | 2013: 21.6%
--   2014: 23.4% | 2015: 23.6% | 2016: 22.6% | 2017: 24.5%
--   Rolling 3-year rate ranges from 22.3% (2013) to 23.6% (2017).
-- INTERPRETATION: The rate is stable across 2010-2017 (about 22-24%), with a slight
--   uptick in 2017. Yearly trial counts are steady (775-991), so this window is
--   not affected by the survivorship problem seen in 2018+ start years.
-- NOTE: The first two rolling values (2010, 2011) use fewer than 3 years of data.

--Q4: India vs. non-India within each phase (checks whether the gap is just phase mix)
SELECT phase, india_flag,
       COUNT(*) AS trials,
       SUM(terminated_flag) AS terminated,
       ROUND(100.0 * AVG(terminated_flag), 1) AS term_rate_pct
FROM analysis.onc_core
GROUP BY phase, india_flag
ORDER BY phase, india_flag;

-- RESULT (core window):
--   Phase 2:   Non-India 5,166 trials, 24.7% | India 25 trials (6 terminated), 24.0%
--   Phase 2/3: Non-India   192 trials, 20.8% | India  5 trials (0 terminated),  0.0%
--   Phase 3:   Non-India 1,470 trials, 17.7% | India 67 trials (8 terminated), 11.9%
-- Overall: India 97 trials, 14 terminated (14.4%) vs non-India 6,828 trials (23.1%).
-- INTERPRETATION: Most India trials are Phase 3 (67 of 97, about 69%, versus about 22%
--   of non-India trials), and Phase 3 trials terminate less often. So the India gap is
--   partly a phase-mix effect: applying non-India phase-specific rates to India's phase mix
--   gives an expected rate of about 19.7%, which explains roughly 40% of the 8.7-point
--   gap (rough calculation). In Phase 2 the gap disappears (24.0% vs 24.7%). The
--   remaining Phase 3 gap (11.9% vs 17.7%) rests on only 8 terminated India trials.
-- CAUTION: Phase 2/3 India row (5 trials) is too small to interpret.
--   Conclusions about India are exploratory; test with Fisher's exact test and
--   adjust for phase, sponsor and year in the regression.


-- Q5: Termination rate by number of countries (core window 2010-2017)
SELECT CASE WHEN n_countries = 0 THEN '0 (no country listed)'
            WHEN n_countries = 1 THEN '1 country'
            WHEN n_countries BETWEEN 2 AND 3 THEN '2-3 countries'
            ELSE '4+ countries' END AS country_bucket,
       COUNT(*) AS trials,
       SUM(terminated_flag) AS terminated,
       ROUND(100.0 * AVG(terminated_flag), 1) AS term_rate_pct
FROM analysis.onc_core
GROUP BY 1
ORDER BY MIN(n_countries);

-- RESULT (core window 2010-2017, n = 6,925):
--   0 (no country listed): 165 trials,    19 terminated -> 11.5%
--   1 country:           5,100 trials, 1,263 terminated -> 24.8%
--   2-3 countries:         509 trials,    96 terminated -> 18.9%
--   4+ countries:        1,151 trials,   214 terminated -> 18.6%
-- Combined multi-country (2+): 1,660 trials, 310 terminated -> 18.7%.
-- INTERPRETATION: Single-country trials terminate more often than multi-country trials
--   (24.8% vs 18.7%, about 6 points). Trials in 2-3 countries and in 4+ countries
--   have almost the same rate, so the main split is single vs. multi-country, not the
--   exact number of countries.
-- CAUTION: Multi-country trials are more often industry-sponsored and later-phase,
--   and both of those are linked to lower termination in Q1 and Q2. So the country
--   effect may partly reflect sponsor and phase mix. Test this in the regression.
-- DATA QUALITY: 165 trials list no country (11.5% terminated). This is probably
--   incomplete location data, not a real group, so exclude them from country analyses
--   or treat them as "unknown".