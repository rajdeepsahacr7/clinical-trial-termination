SELECT study_type, phase, COUNT(*)
FROM ctgov.studies
GROUP BY 1, 2
ORDER BY 3 DESC;
-- RESULT (all 612,286 registered studies):
-- * Interventional studies: 467,256 (76.3%). Observational: 142,962 (23.4%).
--   Expanded access: 1,076 (0.2%). Missing study type: 992 (0.2%).
-- * Phase "NA" is the largest interventional group: 241,663 (51.7% of
--   interventional). Phase does not apply to these studies (behavioral,
--   device, procedure trials), so they are excluded from this project.
-- * Drug-development phases, interventional: Phase 1: 49,128 | Early Phase 1: 6,547
--   | Phase 1/2: 17,218 | Phase 2: 66,196 | Phase 2/3: 7,664 | Phase 3: 42,583
--   | Phase 4: 36,127.
-- * Focus phases (Phase 2, Phase 2/3, Phase 3) total 116,443 trials, about 19%
--   of the registry. Phase 2 is the largest group.
-- DECISION: Restrict the cohort to interventional Phase 2, Phase 2/3 and Phase 3,
--   where termination decisions follow efficacy/safety testing. Phase 1,
--   Phase 1/2, Phase 4 and non-drug (NA) trials are excluded.
-- DATA QUALITY: 992 studies have no study type (and no sponsor class). They fall
--   outside the cohort filters, so they do not affect the analysis.

SELECT phase, overall_status, COUNT(*)
FROM ctgov.studies
WHERE study_type = 'INTERVENTIONAL'
  AND phase IN ('PHASE2', 'PHASE3', 'PHASE2/PHASE3')
  AND overall_status IN ('COMPLETED', 'TERMINATED')
GROUP BY 1, 2
ORDER BY 1, 2;
-- RESULT (interventional Phase 2, Phase 2/3, Phase 3; completed + terminated only):
-- * Phase 2: 34,416 completed, 7,334 terminated -> 17.6% terminated
-- * Phase 2/3: 3,847 completed, 667 terminated -> 14.8% terminated
-- * Phase 3: 26,336 completed, 3,533 terminated -> 11.8% terminated
-- * Overall: 64,599 completed, 11,534 terminated -> 15.2% terminated
-- INTERPRETATION: Phase 2 trials terminate more often than Phase 3 trials.
--   Descriptive only; statistical testing planned in the Python stage.

SELECT agency_class, COUNT(*)
FROM ctgov.sponsors
WHERE lead_or_collaborator = 'lead'
GROUP BY 1
ORDER BY 2 DESC;
-- RESULT (all 612,286 registered studies, one lead sponsor each):
-- * OTHER: 438,821 (71.7%) | INDUSTRY: 133,800 (21.9%)
-- * Government-related: OTHER_GOV 16,395 + NIH 11,596 + FED 4,959 = 32,950 (5.4%)
-- * NETWORK: 5,071 (0.8%) | INDIV: 561 (0.1%) | UNKNOWN: 88 | AMBIG: 3
-- * Missing sponsor class: 992 (same count as the missing study types).
-- * Sponsor counts sum to exactly 612,286, matching the study total, so each
--   study has one lead sponsor and no studies are lost or duplicated.
-- INTERPRETATION: Most registered trials are led by non-industry sponsors.
--   "OTHER" is a broad bucket (universities, hospitals, non-profits), so it
--   cannot separate academic from other organisations.
-- LIMITATION: These counts cover ALL studies, not my cohort. Termination rates
--   by sponsor type must be recalculated on the Phase 2/3 completed/terminated
--   cohort.
-- PLAN: Group sponsors as Industry / Government / Other (non-industry) for the
--   analysis, and test whether termination rates differ between them.



-- RESULT (interventional Phase 2, Phase 2/3, Phase 3; completed + terminated):
-- * Neoplasms: 20,449 trials, 4,361 terminated (21.3%); India 315 trials, 50 terminated (15.9%)
-- * Diabetes Mellitus: 3,181 trials, 366 terminated (11.5%); India 249 trials, 29 terminated (11.6%)
-- * Communicable Diseases: 2,633 trials, 242 terminated (9.2%); India 52 trials, 5 terminated (9.6%)
-- DECISION: Focus on oncology (Neoplasms): largest sample and highest termination rate.
--   India comparison is secondary/exploratory due to small counts (50 terminated trials).
-- LIMITATION: Communicable Diseases is one MeSH category and may undercount infectious trials.