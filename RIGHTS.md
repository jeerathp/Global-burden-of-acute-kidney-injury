# Licenses and reference-data terms

## Code

The R scripts, `AKI_GBD.Rproj`, and `.gitignore` are copyright (c) 2026 Jeerath Phannajit and are available under the [MIT license](LICENSE).

## Original data compilation and documentation

The authors' original contributions to `data/studies.csv`, `README.md`, `DATA_DICTIONARY.md`, `RIGHTS.md`, and `CITATION.cff` are offered under [Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/).

You may share and adapt this material for noncommercial purposes under the license terms. Credit the authors identified in CITATION.cff, provide a license link, and identify any modifications. Please cite the archived version used.

This license covers only copyright and database rights held by the authors in their original compilation, annotations, and documentation. It does not create restrictions on underlying facts or public-domain material, override third-party rights, or limit uses permitted by law. The [full license text](https://creativecommons.org/licenses/by-nc/4.0/legalcode) controls.

## Reference inputs

The following files retain their original providers' terms and are not relicensed under MIT or CC BY-NC 4.0 by this package:

| File | Provider and source |
|---|---|
| `data/wpp2024_population_2018_age18plus_thousands.csv` | United Nations, Department of Economic and Social Affairs, Population Division. [World Population Prospects 2024](https://population.un.org/wpp/). |
| `data/who_n17_regional_age_counts.csv` | Derived regional summaries from the [WHO Mortality Database](https://www.who.int/data/data-collection-tools/who-mortality-database). Original WHO database records are not included. |
| `data/gbd2021_standard_life_table.csv` | Global Burden of Disease Collaborative Network. [GBD 2021 Demographics 1950–2021](https://ghdx.healthdata.org/record/ihme-data/global-burden-disease-study-2021-gbd-2021-demographics-1950-2021). Institute for Health Metrics and Evaluation, 2024. |
| `data/gbd2023_stage_proxy_weights.csv` | Selected disability weights from GBD 2023, Institute for Health Metrics and Evaluation. See [IHME data resources](https://ghdx.healthdata.org/). |

Consult the original providers for current access and reuse terms. WHO supplies the source mortality data; the analyses, interpretations, and conclusions are those of the study authors and are not WHO conclusions. The selected disability weights are investigator-assigned proxies and are not validated AKI-stage disability weights.

The package contains aggregate data, not individual participant records.

## License history

The license notices were updated on October 22, 2026, without changing the analysis code or input data. The initial publication of version 1.0.0 at [https://doi.org/10.5281/zenodo.23541304](https://doi.org/10.5281/zenodo.23541304) offered the authors' data compilation and documentation under CC BY 4.0. Those permissions remain valid. This update does not revoke them or restrict reuse already permitted under that earlier license.
