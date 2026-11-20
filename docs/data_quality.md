## Data quality notes
- Cohort: 10,134 oncology Phase 2/2-3/3 trials (completed or terminated, start 2010-2024); 2,621 terminated.
- Smaller than the unrestricted oncology count (20,449) because of the start-date filter.
- Survivorship bias: trials still running are excluded, so termination rates for 2018+ starts are inflated.
  Primary analysis window: 2010-2017. Later years shown only as sensitivity analysis.
- why_stopped available for 2,453 of 2,621 terminated trials (93.6%): used for AI classification.
- Missing: enrollment 5, enrollment_type 6, completion_date 48, primary_completion_date 2. Excluded where needed.
- Enrollment for terminated trials is usually actual enrollment at stop, so it is not used as a predictor (leakage).
- Small sponsor groups (FED, INDIV, UNKNOWN, OTHER_GOV) merged into broader categories.
- India: 139 trials, 27 terminated; too few for strong conclusions. Reported with confidence intervals.