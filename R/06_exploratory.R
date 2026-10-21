# 6. COVID-19, mortality endpoints, and acute disability assumptions --------
# Calendar overlap does not identify individual infection or causal effects.
non_covid_keep <- studies$year_stop < 2020 | studies$year_start > 2023
non_covid <- fit_scenario(non_covid_keep)
non_covid_burden <- calculate_burden(non_covid)
tableS8 <- compare_global(non_covid, non_covid_burden, "Exclude overlap with 2020-2023")
cat("\nTABLE S8: COVID-19 calendar restriction (same six regions)\n")
print(tableS8, row.names = FALSE)

studies$period <- factor(ifelse(studies$year_stop < 2020, "Pre2020",
  ifelse(studies$year_start >= 2020, "From2020", "Spanning2020")),
  levels = c("Pre2020", "Spanning2020", "From2020"))
studies$endpoint <- NA_character_
studies$endpoint[studies$mort_st_label %in% "All-cause in-hospital mortality"] <- "InHospital"
studies$endpoint[studies$mort_st_label %in% c("1-week mortality", "14-day mortality", "30-day mortality")] <- "FixedLE30"
studies$endpoint[studies$mort_st_label %in% c("60-day mortality", "90-day mortality")] <- "Fixed60to90"
studies$endpoint <- factor(studies$endpoint, levels = c("InHospital", "FixedLE30", "Fixed60to90"))
cat("\nMORTALITY ENDPOINT DISTRIBUTION (records)\n")
print(table(studies$mort_st_label[studies$mortality_include]))

period_endpoint_tests <- period_endpoint_coefficients <- list()
for (variable in c("period", "endpoint")) {
  for (outcome in c("incidence", "mortality", "case_fatality")) {
    if (variable == "endpoint" && outcome == "incidence") next
    keep <- if (outcome == "incidence") studies$incidence_include else studies$mortality_include
    keep <- keep & !is.na(studies[[variable]])
    model <- fit_model(studies[keep, ], outcome,
      reformulate(c("WHOregion", "method_dx2", "year_centered", variable)), extended = TRUE)
    f <- model$fit
    ids <- grep(paste0("^", variable), names(coef(f)))
    test <- anova(f, btt = ids)
    period_endpoint_tests[[length(period_endpoint_tests)+1]] <- data.frame(variable, outcome,
      as.list(count_evidence(model$data)), QM = test$QM, df = length(ids), p = test$QMp)
    period_endpoint_coefficients[[length(period_endpoint_coefficients)+1]] <- data.frame(variable, outcome,
      term = names(coef(f))[ids], ratio = exp(coef(f)[ids]), lower = exp(f$ci.lb[ids]), upper = exp(f$ci.ub[ids]))
  }
}
period_endpoint_tests <- do.call(rbind, period_endpoint_tests)
period_endpoint_coefficients <- do.call(rbind, period_endpoint_coefficients)
cat("\nPOST HOC PERIOD/ENDPOINT MODERATOR TESTS\n"); print(period_endpoint_tests, row.names = FALSE)
cat("\nRATE RATIOS (incidence/deaths) OR ODDS RATIOS (case fatality)\n")
print(period_endpoint_coefficients, row.names = FALSE)

# Acute disability scenarios reuse identical primary cases and YLL draws.
# Recreate the original RNG sequence before sampling stage weights.
primary_for_stage <- calculate_burden(primary)
stage_proxy <- read_local_input("gbd2023_stage_proxy_weights.csv")
fit_stage_beta <- function(mean, lower, upper) {
  objective <- function(log_k) {
    q <- qbeta(c(.025, .975), mean*exp(log_k), (1-mean)*exp(log_k))
    sum((qlogis(q)-qlogis(c(lower, upper)))^2)
  }
  k <- exp(optimize(objective, interval = log(c(.1, 1e7)), tol = 1e-12)$minimum)
  c(alpha = mean*k, beta = (1-mean)*k)
}
stage_parameters <- t(sapply(1:3, function(i) fit_stage_beta(stage_proxy$mean[i], stage_proxy$lower[i], stage_proxy$upper[i])))
stage_dw_draws <- sapply(1:3, function(i) rbeta(n_draws, stage_parameters[i, 1], stage_parameters[i, 2]))
stage_columns <- c("AKI_stage1_pct", "AKI_stage2_pct", "AKI_stage3_pct")
stage_data <- studies[studies$incidence_include & complete.cases(studies[stage_columns]), ]
stage_proportions <- t(sapply(regions, function(r) {
  x <- stage_data[stage_data$WHOregion == r, ]
  counts <- colSums(x[stage_columns]*x$aki_size)
  counts/sum(counts)
}))
cat("\nSTAGE EVIDENCE AND FIXED REGIONAL PROPORTIONS\n")
print(count_evidence(stage_data)); print(stage_proportions)
cat("\nSTAGE-WEIGHT BETA PARAMETERS\n"); print(stage_parameters)

global_cases <- rowSums(primary_burden$cases)
global_yll <- rowSums(primary_burden$YLL)
base_yld <- mean(rowSums(primary_burden$YLD))
base_daly <- mean(rowSums(primary_burden$DALY))
scenario_summary <- function(name, yld) {
  ys <- interval(yld); ds <- interval(global_yll+yld)
  data.frame(scenario = name, YLD_mean = ys[1], YLD_lower = ys[2], YLD_upper = ys[3],
    DALY_mean = ds[1], DALY_lower = ds[2], DALY_upper = ds[3],
    YLD_change_percent = 100*(ys[1]/base_yld-1), DALY_change_percent = 100*(ds[1]/base_daly-1), row.names = NULL)
}
tableS9 <- do.call(rbind, lapply(c(7, 14, 30, 45, 90), function(days)
  scenario_summary(paste(days, "days"), global_cases*primary_burden$dw*days/365.25)))
fixed_dw <- c(.032, .051, .074, seq(.10, .50, .05))
figureS3_values <- do.call(rbind, lapply(fixed_dw, function(dw)
  scenario_summary(paste("Fixed DW", dw), global_cases*dw*30/365.25)))
regional_stage_dw <- stage_dw_draws %*% t(stage_proportions)
stage_yld <- rowSums(primary_for_stage$cases * regional_stage_dw) * 30/365.25
tableS10 <- rbind(scenario_summary("Equal fixed proxy 0.051", global_cases*.051*30/365.25),
  scenario_summary("GBD 2023 stage-specific proxies", stage_yld))
cat("\nTABLE S9: duration in days; burden in years\n"); print(tableS9, row.names = FALSE)
cat("\nFIGURE S3: fixed disability-weight scenarios\n"); print(figureS3_values, row.names = FALSE)
cat("\nTABLE S10: investigator-selected stage proxies at 30 days\n"); print(tableS10, row.names = FALSE)

# Optional interactive plot (no files exported): run after sourcing this file.
plot_disability_weights <- function() {
  old <- par(mfrow = c(2, 1), mar = c(4, 5, 2, 1)); on.exit(par(old))
  for (metric in c("YLD", "DALY")) {
    divisor <- if (metric == "YLD") 1000 else 1e6
    x <- figureS3_values
    plot(fixed_dw, x[[paste0(metric, "_mean")]]/divisor, type = "n",
      ylim = range(x[c(paste0(metric,"_lower"),paste0(metric,"_upper"))]/divisor),
      xlab = "Fixed disability weight", ylab = paste(metric, if (metric == "YLD") "(thousands)" else "(millions)"))
    polygon(c(fixed_dw, rev(fixed_dw)), c(x[[paste0(metric,"_lower")]], rev(x[[paste0(metric,"_upper")]]))/divisor,
      col = "#D7E6F0", border = NA)
    lines(fixed_dw, x[[paste0(metric,"_mean")]]/divisor, col = "#25678B", lwd = 2)
    abline(v = .051, lty = 2)
  }
}
