# Open AKI_GBD.Rproj, then run source("run_analysis.R").
# Install once if needed: install.packages(c("metafor", "MASS"))
# Results are printed and retained as R objects; no result files are imported.
ihme_inputs <- file.path("local_inputs", c("gbd2021_standard_life_table.csv", "gbd2023_stage_proxy_weights.csv"))
if (!all(file.exists(ihme_inputs)))
  stop("IHME inputs are not bundled. Follow README.md, then source('prepare_ihme_inputs.R') and run prepare_ihme_inputs().")
if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.utf8")
Sys.setlocale("LC_COLLATE", "C") # Stable factor ordering across computers.
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
library(metafor)
library(MASS)
options(width = 140, digits = 7, contrasts = c("contr.treatment", "contr.poly"))
source("R/01_inputs_and_selection.R")
source("R/02_meta_analysis.R")
source("R/03_daly.R")
source("R/04_sensitivity.R")
source("R/05_subgroups.R")
source("R/06_exploratory.R")
print(sessionInfo())
