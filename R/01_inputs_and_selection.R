# 1. Study inputs with finalized outcome-specific inclusion flags -----------
read_input <- function(name) read.csv(file.path("data", name),
  check.names = FALSE, na.strings = c("", "NA"), fileEncoding = "UTF-8")
studies <- read_input("studies.csv")
regions <- c("AFRO", "AMRO", "EMRO", "EURO", "SEARO", "WPRO")
n_draws <- 10000 # Number of Monte Carlo draws for rates and DALY uncertainty.
seed <- 20250725

# Preserve the verified, study-specific person-time denominators.
# Death counts may be fractional; missing mortality is never replaced by zero.
studies$deaths <- studies$aki_size * studies$mort_st
studies$method_dx2 <- ifelse(studies$method_dx %in% c("ICD-9", "ICD-10"), "ICD", "lab-based")
studies$mixed <- studies$mixed_age
# In selected studies, mixed means threshold 0. The source retains an unresolved
# historical flag for aki512 (not selected); do not invent its missing threshold.
studies$year_centered <- studies$year_mid - 2018
# incidence_include and mortality_include already apply the observation window
# and reviewed overlap decisions.
count_evidence <- function(x) c(studies = length(unique(x$study_cluster)), records = nrow(x))
cat("\nPRIMARY EVIDENCE COUNTS\n")
print(rbind(either = count_evidence(studies[studies$incidence_include | studies$mortality_include, ]),
  incidence = count_evidence(studies[studies$incidence_include, ]),
  mortality = count_evidence(studies[studies$mortality_include, ])))
cat("\nAGE THRESHOLDS IN PRIMARY RECORDS\n")
print(table(studies$age.threshold[studies$incidence_include | studies$mortality_include]))

# 2018 adult population from UN WPP 2024. Source cells are in thousands.
wpp <- read_input("wpp2024_population_2018_age18plus_thousands.csv")
age_columns <- c(as.character(18:99), "100+")
wpp$population <- rowSums(wpp[, age_columns]) * 1000
population <- tapply(wpp$population, wpp$WHOregion, sum)[regions]
cat("\n2018 POPULATION AGED 18+\n"); print(population)
