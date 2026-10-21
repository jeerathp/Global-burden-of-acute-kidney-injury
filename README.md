# Global burden of acute kidney injury

R code and input data for estimating acute kidney injury (AKI) incidence, associated mortality, and health loss. Projections target adults aged 18 years or older in 2018. Estimates describe AKI-associated burden, not burden causally attributable to AKI.

## How to run

1. Extract the ZIP and open **`AKI_GBD.Rproj`** in RStudio. Keep the folder structure unchanged.
2. Install the required packages once:

```r
install.packages(c("metafor", "MASS"))
```

3. Run the complete analysis:

```r
source("run_analysis.R")
```

The scripts run in order. Results print in the console and remain in the RStudio Environment. No result files are automatically exported. Once the packages are installed, the analysis runs offline using the included inputs.

4. Inspect the main results or display the disability-weight plot:

```r
# Global and regional incidence, associated death rates, and case fatality
View(rate_table(primary, primary_rates))

# Global and regional DALYs, YLLs, and YLDs
View(summarize_burden(primary_burden))

# Exploratory subgroup results
View(subgroup_estimates)

# Disability-weight plot, displayed in the Plots pane
plot_disability_weights()
```

Run the complete analysis before using these commands. Individual scripts depend on earlier steps.

## Analyses and results

| Script | Analysis and results produced |
|---|---|
| [01_inputs_and_selection.R](R/01_inputs_and_selection.R) | Loads the study data and finalized inclusion flags; summarizes study counts and adult population totals. |
| [02_meta_analysis.R](R/02_meta_analysis.R) | Estimates global, regional, and country incidence, AKI-associated death rates, and case fatality, with 95% intervals and model heterogeneity (I²). |
| [03_daly.R](R/03_daly.R) | Calculates years of life lost (YLLs), years lived with disability (YLDs), and disability-adjusted life-years (DALYs), with 95% uncertainty intervals. |
| [04_sensitivity.R](R/04_sensitivity.R) | Compares the primary analysis with exclusion of mixed-age studies and restrictions by study coverage or laboratory ascertainment. |
| [05_subgroups.R](R/05_subgroups.R) | Compares study settings, coverage, AKI ascertainment, diagnostic frameworks, and income categories; reports subgroup estimates, I², and moderator tests. |
| [06_exploratory.R](R/06_exploratory.R) | Examines COVID-19 observation periods, mortality endpoints, alternative AKI durations, fixed disability weights, and stage-specific proxy weights; provides burden comparisons and the disability-weight plot. |

Rates are reported per million person-years and case fatality as a percentage. DALYs, YLLs, and YLDs are reported in years; regional and global burden rates are also calculated per 100,000 adults.

## Input data

The `data/` folder contains five files:

- `studies.csv`: combined extraction data, study identification, geography, and finalized inclusion flags.
- `wpp2024_population_2018_age18plus_thousands.csv`: adult population estimates and WHO regions.
- `who_n17_regional_age_counts.csv`: derived WHO death-age counts.
- `gbd2021_standard_life_table.csv`: standard remaining life expectancy.
- `gbd2023_stage_proxy_weights.csv`: stage-specific proxy disability weights.

The analysis uses the finalized outcome-specific inclusion flags in `studies.csv`.

## Software and documentation

Tested with **R 4.5.3**, **metafor 5.2-1**, **MASS 7.3-65**, and **Matrix 1.7-4**. Uncertainty calculations use 10,000 draws and seed 20250725. The packaged analysis reproduced the finalized results; minor numerical differences may occur with other software versions.

The simulation size is set by `n_draws <- 10000` in `R/01_inputs_and_selection.R`. Script `02` samples model coefficients; script `03` combines the resulting rates with disability-weight draws to calculate YLLs, YLDs, and DALYs. Each matrix row is one simulation. The 95% uncertainty limits are the 2.5th and 97.5th percentiles; global burdens are summed across regions within each draw first. After running the analysis, you can check:

```r
nrow(primary_burden$DALY)                         # 10000 draws
quantile(rowSums(primary_burden$DALY), c(.025, .975))
```

- [Data dictionary](DATA_DICTIONARY.md): variable definitions and units.

## Licenses

- **R code and project configuration:** [MIT license](LICENSE); copyright (c) 2026 Jeerath Phannajit.
- **Original data compilation and documentation:** [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/), allowing noncommercial sharing and adaptation with appropriate attribution.
- **UN, WHO, and IHME reference inputs:** original provider terms.

See [RIGHTS.md](RIGHTS.md) for file-specific coverage and exceptions. Material previously released under CC BY 4.0 remains usable under that license; this update does not revoke those permissions.

## Citation

Phannajit J, Tran PNT, Harnpramukkul P, Kaewdoungtien P, Suttiruk P, Kusirisin P, Tangchitthavorngul S, Kellum JA, Srisawat N. Global burden of acute kidney injury: analysis data and R code. Version 1.0.0. Zenodo; 2026. [https://doi.org/10.5281/zenodo.23541304](https://doi.org/10.5281/zenodo.23541304).

Code copyright: Jeerath Phannajit. The archive credits all study authors in manuscript order.
