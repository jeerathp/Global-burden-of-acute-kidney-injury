# 4. Mixed-age, coverage, and ascertainment restrictions --------------------
# Restrictions are applied AFTER primary overlap selection; no smaller
# overlapping cohort is substituted when a retained cohort is excluded.
adult_category <- fit_scenario(!studies$mixed)
adult_burden <- calculate_burden(adult_category)

global_summary <- function(models, burden) {
  rates <- rate_table(models, burden$rates)
  rates <- rates[rates$geography == "Global", c("outcome", "estimate", "lower", "upper")]
  names(rates)[1] <- "metric"
  b <- summarize_burden(burden)
  b <- b[b$geography == "Global", c("metric", "mean", "lower", "upper")]
  names(b)[2] <- "estimate"
  rbind(rates, b)
}
compare_global <- function(models, burden, label) {
  base <- global_summary(primary, primary_burden)
  x <- global_summary(models, burden)
  x$change_percent <- 100*(x$estimate/base$estimate-1)
  x$analysis <- label
  rbind(transform(base, change_percent = 0, analysis = "Primary"), x)
}
tableS6 <- compare_global(adult_category, adult_burden, "Mixed-age excluded")
cat("\nTABLE S6: mixed-age exclusion (same six regions)\n"); print(tableS6, row.names = FALSE)
cat("\nMIXED-AGE RESTRICTION COUNTS AND I-SQUARED\n")
print(t(sapply(adult_category, function(m) c(count_evidence(m$data), heterogeneity(m)))))

# Setting/ascertainment comparisons use pooled study models without WHOregion,
# not population-weighted global rates. Each comparator uses the same model.
studies$scale_group <- gsub("single center", "single-center", trimws(studies$scale), fixed = TRUE)
pooled_mods <- function(x) {
  terms <- character()
  if (length(unique(x$method_dx2)) > 1) terms <- c(terms, "method_dx2")
  if (length(unique(x$year_centered)) > 1) terms <- c(terms, "year_centered")
  if (length(terms)) reformulate(terms) else ~ 1
}
restrictions <- list(Primary = rep(TRUE, nrow(studies)),
  Multicenter_nationwide_regionwide = studies$scale_group != "single-center",
  Laboratory_only = studies$method_dx2 == "lab-based")
setting_models <- list(); setting_rows <- list()
for (outcome in c("incidence", "mortality", "case_fatality")) {
  eligible <- if (outcome == "incidence") studies$incidence_include else studies$mortality_include
  for (restriction in names(restrictions)) {
    x <- studies[eligible & restrictions[[restriction]], ]
    model <- fit_model(x, outcome, pooled_mods(x), extended = TRUE)
    setting_models[[paste(outcome, restriction, sep = "|")]] <- model
    setting_rows[[length(setting_rows)+1]] <- data.frame(outcome, analysis = restriction,
      as.list(count_evidence(x)), regions = length(unique(x$WHOregion)),
      predict_model(model)$table, as.list(heterogeneity(model)))
  }
}
tableS7 <- do.call(rbind, setting_rows)
tableS7$change_percent <- NA_real_
for (outcome in unique(tableS7$outcome)) {
  i <- tableS7$outcome == outcome
  base <- tableS7$estimate[i & tableS7$analysis == "Primary"]
  tableS7$change_percent[i] <- 100*(tableS7$estimate[i]/base-1)
}
cat("\nTABLE S7: pooled setting/ascertainment restrictions, not global projections\n")
print(tableS7, row.names = FALSE)
