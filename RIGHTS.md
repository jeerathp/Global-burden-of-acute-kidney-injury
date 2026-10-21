# Licenses and reference-data terms

## Code

The R scripts, `AKI_GBD.Rproj`, and `.gitignore` are copyright (c) 2026 Jeerath Phannajit and are available under the [MIT license](LICENSE).

## Original data compilation and documentation

The authors' original contributions to `data/studies.csv`, `README.md`, `DATA_DICTIONARY.md`, `RIGHTS.md`, and `CITATION.cff` are offered under [Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/).

You may share and adapt this material for noncommercial purposes under the license terms. Credit the authors identified in CITATION.cff, provide a license link, and identify any modifications. Please cite the archived version used.

This license covers only copyright and database rights held by the authors in their original compilation, annotations, and documentation. It does not create restrictions on underlying facts or public-domain material, override third-party rights, or limit uses permitted by law. The [full license text](https://creativecommons.org/licenses/by-nc/4.0/legalcode) controls.

## Included reference inputs

The following files retain their original providers' terms and are not relicensed under MIT or CC BY-NC 4.0 by this package:

| File | Provider and source |
|---|---|
| `data/wpp2024_population_2018_age18plus_thousands.csv` | United Nations, Department of Economic and Social Affairs, Population Division. [World Population Prospects 2024](https://population.un.org/wpp/). |
| `data/who_n17_regional_age_counts.csv` | Derived regional summaries from the [WHO Mortality Database](https://www.who.int/data/data-collection-tools/who-mortality-database). Original WHO database records are not included. |

Consult the original providers for current access and reuse terms. WHO supplies the source mortality data; the analyses, interpretations, and conclusions are those of the study authors and are not WHO conclusions.

## IHME inputs obtained separately

IHME source files and the prepared life-table and stage-weight CSVs are not redistributed in this repository or its ZIP archive. Obtain the [GBD 2021 theoretical minimum risk life table](https://ghdx.healthdata.org/record/ihme-data/global-burden-disease-study-2021-gbd-2021-demographics-1950-2021) and [GBD 2023 disability weights](https://ghdx.healthdata.org/record/ihme-data/gbd-2023-disability-weights) directly from IHME, following [README.md](README.md).

These separately obtained data remain subject to the [IHME free-of-charge noncommercial user agreement](https://www.healthdata.org/Data-tools-practices/data-practices/ihme-free-charge-non-commercial-user-agreement) and any dataset-specific terms. Section 2 requires UW's written permission before providing third-party downloads of IHME datasets from user-hosted facilities. Keep downloaded and prepared files in the ignored `local_inputs/` folder and exclude them from shared archives. The repository's MIT and CC BY-NC 4.0 licenses do not grant rights to redistribute IHME data.

The selected disability weights are investigator-assigned proxies, not validated AKI-stage disability weights. The input preparation code is MIT-licensed; the underlying data are not.

The package contains aggregate data, not individual participant records.

## License history

The initial publication of version 1.0.0 at [https://doi.org/10.5281/zenodo.23541304](https://doi.org/10.5281/zenodo.23541304) offered the authors' data compilation and documentation under CC BY 4.0. Those permissions remain valid. The subsequent CC BY-NC 4.0 notice does not revoke them. Neither license notice grants rights in third-party data.

On October 22, 2026, bundled IHME inputs were replaced with official download instructions and local preparation code. The analysis methods, numerical input values, and reported results are unchanged.
