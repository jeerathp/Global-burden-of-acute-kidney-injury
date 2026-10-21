# Data dictionary

Blank numeric cells are missing values. Proportions are on a **0–1 scale**, even where historical variable names contain `pct`. Do not convert these again to percentages before fitting.

## Main extracted dataset: `data/studies.csv`

| Column | Meaning and use |
|---|---|
| `study_id` | Unique extraction-record identifier; nested random intercept and overlap matching |
| `study_cluster` | Publication/study cluster identifier; study random intercept and study counts |
| `author` | Extracted author label, merged from the study index |
| `year_pub` | Publication year; identifies the report, not observation eligibility |
| `source_family` | Reviewed underlying registry/database/source-family label |
| `is.unique.pts` | Original patient-versus-episode descriptor, preserved as extracted |
| `country` | Original extracted country/geographic label |
| `country_iso3` | Final three-letter country code used in country models |
| `country_name` | Country display name from the geographic lookup; Taiwan retained as labeled |
| `WHOregion` | Extracted WHO region; regional moderator and stage aggregation |
| `incidence_include` | Final TRUE/FALSE inclusion in primary incidence after observation-window and overlap selection |
| `mortality_include` | Final TRUE/FALSE inclusion in primary mortality/case fatality after observation-window, outcome availability, and overlap selection |
| `year_start` | Reviewed first observation year; eligibility and COVID classification |
| `year_stop` | Reviewed last observation year; eligibility and COVID classification |
| `year_mid` | Reviewed calendar midpoint used by the models; not recalculated from rounded year endpoints |
| `age.threshold` | Extracted threshold text, including ranges such as `16-99`; printed to document age coverage |
| `mixed_age` | Reviewed TRUE/FALSE policy flag. Selected mixed cohorts have threshold 0; nonselected aki512 retains its historical flag with missing threshold |
| `aki_size` | Extracted AKI cases, patients or episodes as reported; numerator and overlap-size criterion |
| `person.years` | Verified population-time for the same extraction record, in person-years |
| `mort_st` | Selected reported short-term mortality proportion; missing remains missing |
| `mort_st_label` | Extracted mortality endpoint; descriptive counts and exploratory endpoint models |
| `method_dx` | Extracted ascertainment label; ICD-9/ICD-10 versus laboratory grouping |
| `scale` | Single-center, multi-center, nationwide or regionwide coverage; source spellings are normalized in code |
| `staging_system` | Recorded framework, e.g. KDIGO, AKIN or RIFLE; missing stays unspecified; coding records use ICD version |
| `incomegroup` | Recorded H/UM/LM/L income category; no updated classification is substituted |
| `AKI_stage1_pct` | Stage 1 proportion (0–1); used with the case count |
| `AKI_stage2_pct` | Stage 2 proportion (0–1) |
| `AKI_stage3_pct` | Stage 3 proportion (0–1) |

Derived in R rather than included as redundant source columns: deaths, ascertainment grouping, mixed restriction, COVID period, centered year, incidence/death rates, effect sizes, variances, stage counts, and burden outputs. Country identifiers and inclusion flags are already finalized in this input; no separate lookup is needed.

## Included reference inputs in `data/`

`wpp2024_population_2018_age18plus_thousands.csv`: `iso3c`, final `WHOregion`, and age columns `18`, `19`, …, `99`, `100+`; both sexes, 2018, populations in **thousands**. Each of 237 countries/areas appears once. Region assignments include countries without study data; only age columns are summed.

`who_n17_regional_age_counts.csv`: `WHOregion`, `age_band`, and `estimated_N17_deaths`. These are derived regional sums of WHO N17 deaths in 2015–2019, with ages 18–19 allocated as two-fifths of the source 15–19 band. They are **reference age-profile inputs**, not modeled deaths or previously exported meta-analysis results. The analysis recalculates proportions within region; missing-data and registration-coverage uncertainty are not propagated.

## IHME inputs prepared locally in `local_inputs/`

These files are not distributed. Download the specified official releases and run `prepare_ihme_inputs.R` as described in [README.md](README.md).

`gbd2021_standard_life_table.csv`: `age` in years and `remaining_life_expectancy` in years. Prepared from the GBD 2021 theoretical minimum risk life table without numerical rounding. This is **remaining** life expectancy at a given age, not life expectancy at birth minus age.

`gbd2023_stage_proxy_weights.csv`: `stage` number, source `mean`, and `lower`/`upper` reference uncertainty limits, rounded to six decimal places to match the finalized analysis. Beta parameters are refitted in R; they are not imported from previous results. The investigator-selected proxies are acute glomerulonephritis for stage 1, untreated stage 5 chronic kidney disease with mild heart failure for stage 2, and end-stage renal disease on dialysis without anemia for stage 3. These are clinical analogues, not validated AKI-stage disability weights.

Reference inputs are derived from United Nations World Population Prospects 2024, the WHO Mortality Database, and IHME GBD 2021/2023 data. The analysis and interpretations are those of the study authors; reference data retain their providers' terms.

## Output units

`table1`, `tableS4`, `tableS6`, `tableS7`, `tableS8`, and subgroup estimates: incidence/associated death rates per **million person-years**, case fatality in **percent**. DALY/YLL/YLD entries in the global sensitivity comparisons are in **years**, not millions.

`table2` and `tableS5`: burden means and uncertainty limits in **years**; `table2` also has rates per **100,000 adults**. `tableS9`, `tableS10`, and `figureS3_values`: burden in **years** and relative changes in percent. Display scaling in the optional figure is labeled separately.

`I2_total`, `I2_between`, `I2_within`, and `I2`: percentages. `tau2_total`: total fitted random-effect variance on the log/logit scale. Period/endpoint exponentiated coefficients are rate ratios for incidence/mortality and odds ratios for case fatality.
