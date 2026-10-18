# 2. Meta-analysis: incidence, associated deaths, and case fatality ----------
# These small functions are shared by the primary and restricted analyses.
fit_model <- function(data, outcome, moderators, extended = FALSE) {
  data <- droplevels(data)
  for (v in c("WHOregion", "country_iso3", "method_dx2", "study_cluster", "study_id"))
    data[[v]] <- factor(data[[v]])
  effects <- if (outcome == "case_fatality") {
    escalc(measure = "PLO", xi = deaths, ni = aki_size, data = data)
  } else {
    escalc(measure = "IRLN", xi = if (outcome == "incidence") aki_size else deaths,
      ti = person.years, data = data)
  }
  # Keep original optimizer settings for the main models. Extended controls
  # reproduce the subgroup/exploratory workflow, including its BFGS fallback.
  control <- if (extended) list(iter.max = 2000, eval.max = 4000) else list()
  fit <- tryCatch(rma.mv(yi, vi, mods = moderators,
    random = ~ 1 | study_cluster/study_id, method = "REML", data = effects,
    control = control), error = function(e) e)
  if (inherits(fit, "error")) {
    if (!extended || !grepl("Optimizer", conditionMessage(fit))) stop(fit)
    warning("Using BFGS because the initial optimizer did not converge.")
    fit <- rma.mv(yi, vi, mods = moderators, random = ~ 1 | study_cluster/study_id,
      method = "REML", data = effects,
      control = list(optimizer = "optim", optmethod = "BFGS", maxit = 10000))
  }
  list(fit = fit, data = data, formula = moderators, outcome = outcome)
}

predict_model <- function(model, geography = NULL, levels_to_predict = NULL) {
  data <- model$data
  n <- if (is.null(geography)) 1 else length(levels_to_predict)
  new <- data[rep(1, n), , drop = FALSE]
  new$year_mid <- 2018
  new$year_centered <- 0
  if (length(unique(data$method_dx2)) > 1)
    new$method_dx2 <- factor("lab-based", levels = levels(data$method_dx2))
  if (!is.null(geography)) new[[geography]] <- factor(levels_to_predict, levels = levels(data[[geography]]))
  X <- model.matrix(model$formula, new)
  colnames(X)[1] <- "intrcpt"
  X <- X[, colnames(model$fit$X), drop = FALSE]
  p <- if (ncol(X) == 1) predict(model$fit) else predict(model$fit, newmods = X[, -1, drop = FALSE])
  transform <- if (model$outcome == "case_fatality") function(x) 100 * plogis(x) else function(x) 1e6 * exp(x)
  list(X = X, table = data.frame(estimate = transform(p$pred), lower = transform(p$ci.lb), upper = transform(p$ci.ub)))
}

# Generalized multilevel I-squared, partitioned by the two random intercepts.
# Centering X here only stabilizes the calculation; it does not refit the model.
heterogeneity <- function(model) {
  f <- model$fit; X <- f$X
  if (ncol(X) > 1) X[, -1] <- scale(X[, -1, drop = FALSE], center = TRUE, scale = FALSE)
  w <- 1/f$vi
  Q <- qr.Q(qr(sqrt(w) * X))
  typical <- (f$k - f$p)/sum(w * (1 - rowSums(Q^2)))
  tau <- sum(f$sigma2)
  c(I2_total = 100*tau/(tau+typical), I2_between = 100*f$sigma2[1]/(tau+typical),
    I2_within = 100*f$sigma2[2]/(tau+typical), tau2_total = tau)
}
regional_formula <- ~ WHOregion + method_dx2 + year_mid
pooled_formula <- ~ method_dx2 + year_mid
fit_scenario <- function(keep) {
  inc <- studies[keep & studies$incidence_include, ]
  mort <- studies[keep & studies$mortality_include, ]
  list(incidence = fit_model(inc, "incidence", regional_formula),
    mortality = fit_model(mort, "mortality", regional_formula),
    regional_cfr = fit_model(mort, "case_fatality", regional_formula),
    pooled_cfr = fit_model(mort, "case_fatality", pooled_formula))
}
primary <- fit_scenario(rep(TRUE, nrow(studies)))

# Coefficient draws preserve covariance within each outcome; incidence and
# mortality are drawn independently. The seed and draw order match reporting.
# mvrnorm(n_draws, ...) generates all 10,000 coefficient draws at once.
# Each returned matrix has 10,000 rows (draws) and six columns (WHO regions).
draw_rates <- function(models) {
  ip <- predict_model(models$incidence, "WHOregion", regions)
  mp <- predict_model(models$mortality, "WHOregion", regions)
  set.seed(seed)
  incidence <- exp(mvrnorm(n_draws, as.numeric(models$incidence$fit$b), models$incidence$fit$vb) %*% t(ip$X))
  mortality <- exp(mvrnorm(n_draws, as.numeric(models$mortality$fit$b), models$mortality$fit$vb) %*% t(mp$X))
  list(incidence = incidence, mortality = mortality)
}
primary_rates <- draw_rates(primary)
# Summarize the draw distribution: mean and 2.5th/97.5th percentiles.
interval <- function(x) c(mean = mean(x), lower = unname(quantile(x, .025)), upper = unname(quantile(x, .975)))
rate_table <- function(models, draws) {
  output <- list()
  for (outcome in c("incidence", "mortality")) {
    p <- predict_model(models[[outcome]], "WHOregion", regions)$table
    global <- data.frame(estimate = sum(p$estimate*population)/sum(population),
      lower = quantile(as.numeric(draws[[outcome]] %*% population)/sum(population)*1e6, .025),
      upper = quantile(as.numeric(draws[[outcome]] %*% population)/sum(population)*1e6, .975))
    x <- models[[outcome]]$data
    counts <- rbind(count_evidence(x), t(sapply(regions, function(r) count_evidence(x[x$WHOregion == r, ]))))
    output[[outcome]] <- data.frame(geography = c("Global", regions), outcome,
      counts, rbind(global, p), row.names = NULL)
  }
  p <- rbind(predict_model(models$pooled_cfr)$table,
    predict_model(models$regional_cfr, "WHOregion", regions)$table)
  x <- output$mortality
  output$case_fatality <- data.frame(x[c("geography", "studies", "records")], outcome = "case_fatality", p)
  do.call(rbind, lapply(output, function(x) x[c("geography", "outcome", "studies", "records", "estimate", "lower", "upper")]))
}
table1 <- rate_table(primary, primary_rates)
cat("\nTABLE 1: rates per million person-years; case fatality in percent\n")
print(table1, row.names = FALSE)
cat("\nTABLE 1 MODEL HETEROGENEITY (not a separate model for each region)\n")
print(t(sapply(primary, heterogeneity)))

# Country estimates use ISO-code factor order, matching the reported models.
country_models <- list()
country_rates <- list()
for (outcome in c("incidence", "mortality", "case_fatality")) {
  keep <- if (outcome == "incidence") studies$incidence_include else studies$mortality_include
  model <- fit_model(studies[keep, ], outcome, ~ country_iso3 + method_dx2 + year_mid)
  ids <- levels(model$data$country_iso3)
  country_models[[outcome]] <- model
  country_rates[[outcome]] <- data.frame(iso3c = ids, outcome,
    t(sapply(ids, function(id) count_evidence(model$data[model$data$country_iso3 == id, ]))),
    predict_model(model, "country_iso3", ids)$table)
}
tableS4 <- do.call(rbind, country_rates)
tableS4$country <- studies$country_name[match(tableS4$iso3c, studies$country_iso3)]
tableS4 <- tableS4[order(tableS4$country, tableS4$outcome), ]
cat("\nTABLE S4: country rates (unavailable mortality is omitted, not zero)\n")
print(tableS4, row.names = FALSE)
