# 3. YLL, acute YLD, DALY, and uncertainty ----------------------------------
# Simulation size: n_draws <- 10000 in R/01_inputs_and_selection.R.
# The 10,000 simulations are matrix rows, computed together without a loop.
# WHO N17 records supply an age-distribution proxy, not projected death totals.
# These derived reference counts are supplied for offline reproduction.
age_distribution <- read_input("who_n17_regional_age_counts.csv")
life <- read_input("gbd2021_standard_life_table.csv")
age_labels <- c("18-19", paste(seq(20, 90, 5), seq(24, 94, 5), sep = "-"), "95+")
age_midpoints <- c(18.5, seq(22, 92, 5), 95)
remaining_le <- approx(life$age, life$remaining_life_expectancy, xout = age_midpoints, rule = 2)$y
age_distribution$proportion <- ave(age_distribution$estimated_N17_deaths,
  age_distribution$WHOregion, FUN = function(x) x/sum(x))
age_distribution$remaining_le <- remaining_le[match(age_distribution$age_band, age_labels)]
yll_per_death <- sapply(regions, function(r) {
  x <- age_distribution[age_distribution$WHOregion == r, ]
  sum(x$proportion*x$remaining_le)
})
cat("\nAGE-WEIGHTED STANDARD REMAINING LIFE EXPECTANCY\n"); print(yll_per_death)

# Primary proxy: acute glomerulonephritis, rounded reference 0.051 (0.032-0.074).
# Fit the two interval limits. The resulting beta mean is approximately 0.050966.
beta_for_alpha <- function(log_alpha) {
  exp(uniroot(function(log_beta) pbeta(.032, exp(log_alpha), exp(log_beta)) - .025,
    interval = c(-20, 20), tol = 1e-14)$root)
}
log_alpha <- uniroot(function(a) qbeta(.975, exp(a), beta_for_alpha(a)) - .074,
  interval = c(log(.1), log(1000)), tol = 1e-13)$root
dw_alpha <- exp(log_alpha)
dw_beta <- beta_for_alpha(log_alpha)
cat("\nPRIMARY DISABILITY-WEIGHT BETA PARAMETERS\n")
print(c(alpha = dw_alpha, beta = dw_beta, mean = dw_alpha/(dw_alpha+dw_beta)))

# DALY UIs include coefficient and DW uncertainty only. Population, death-age
# proportions, life expectancy and duration are fixed. No study random effect
# is drawn: these are fitted-mean UIs, not prediction intervals for new studies.
calculate_burden <- function(models) {
  rate_draws <- draw_rates(models) # Reset seed; draw incidence then mortality.
  dw <- rbeta(n_draws, dw_alpha, dw_beta) # Third draw operation, as reported.
  # Every row combines one incidence, mortality, and disability-weight draw.
  # The same disability-weight draw is applied across all six regions.
  cases <- sweep(rate_draws$incidence, 2, population, "*")
  deaths <- sweep(rate_draws$mortality, 2, population, "*")
  yll <- sweep(deaths, 2, yll_per_death, "*")
  yld <- cases * dw * 30/365.25
  list(rates = rate_draws, cases = cases, deaths = deaths, dw = dw,
    YLL = yll, YLD = yld, DALY = yll+yld)
}
summarize_burden <- function(burden) {
  do.call(rbind, lapply(c("DALY", "YLL", "YLD"), function(metric) {
    # Sum regions within each draw BEFORE taking the global percentiles.
    x <- cbind(Global = rowSums(burden[[metric]]), burden[[metric]])
    z <- t(apply(x, 2, interval))
    data.frame(geography = c("Global", regions), metric, z, row.names = NULL)
  }))
}
primary_burden <- calculate_burden(primary)
table2 <- summarize_burden(primary_burden)
table2$rate_per_100000 <- table2$mean / c(sum(population), population)[match(table2$geography, c("Global", regions))] * 1e5
table2$rate_lower <- table2$lower / c(sum(population), population)[match(table2$geography, c("Global", regions))] * 1e5
table2$rate_upper <- table2$upper / c(sum(population), population)[match(table2$geography, c("Global", regions))] * 1e5
cat("\nTABLE 2: annual associated burden in years; rates per 100,000 adults\n")
print(table2, row.names = FALSE)

# Country burden uses the same country models fitted above. All eligible
# incidence countries inform that model, including those without mortality.
# Only countries with both outcomes receive a DALY estimate; do not sum them.
countries <- sort(intersect(levels(country_models$incidence$data$country_iso3),
  levels(country_models$mortality$data$country_iso3)))
ip <- predict_model(country_models$incidence, "country_iso3", countries)
mp <- predict_model(country_models$mortality, "country_iso3", countries)
set.seed(seed)
ci <- exp(mvrnorm(n_draws, as.numeric(country_models$incidence$fit$b), country_models$incidence$fit$vb) %*% t(ip$X))
cm <- exp(mvrnorm(n_draws, as.numeric(country_models$mortality$fit$b), country_models$mortality$fit$vb) %*% t(mp$X))
cdw <- rbeta(n_draws, dw_alpha, dw_beta)
cpop <- wpp$population[match(countries, wpp$iso3c)]
cregion <- wpp$WHOregion[match(countries, wpp$iso3c)]
cyll <- sweep(cm, 2, cpop*yll_per_death[cregion], "*")
cyld <- sweep(ci, 2, cpop, "*") * cdw * 30/365.25
tableS5 <- do.call(rbind, lapply(c("DALY", "YLL", "YLD"), function(metric) {
  x <- switch(metric, DALY = cyll+cyld, YLL = cyll, YLD = cyld)
  data.frame(iso3c = countries, metric, t(apply(x, 2, interval)), row.names = NULL)
}))
tableS5$country <- tableS4$country[match(tableS5$iso3c, tableS4$iso3c)]
tableS5 <- tableS5[order(tableS5$country, tableS5$metric), ]
cat("\nTABLE S5: country-associated burden in years (95% UI)\n")
print(tableS5, row.names = FALSE)
