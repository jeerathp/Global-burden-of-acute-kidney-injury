# 5. Exploratory subgroup estimates and moderator tests --------------------
# These pooled study estimates are not population-weighted global projections.
# Sparse/non-identifiable subgroups are reported as not estimable, not zero.
studies$setting <- ifelse(studies$scale_group == "single-center", "Single-center", "Multicenter/national/regional")
studies$ascertainment <- ifelse(studies$method_dx2 == "ICD", "ICD", "Laboratory")
studies$framework <- trimws(studies$staging_system)
studies$framework[is.na(studies$framework) | studies$framework == ""] <- "Unspecified laboratory framework"
studies$framework[studies$ascertainment == "ICD"] <- studies$method_dx[studies$ascertainment == "ICD"]
income_labels <- c(H = "High income", UM = "Upper-middle income", LM = "Lower-middle income", L = "Low income")
studies$income <- unname(income_labels[studies$incomegroup])
subgroup_rows <- test_rows <- list()

for (scenario in c("Primary", "Mixed-age excluded")) {
  scenario_keep <- if (scenario == "Primary") rep(TRUE, nrow(studies)) else !studies$mixed
  for (outcome in c("incidence", "mortality", "case_fatality")) {
    keep <- if (outcome == "incidence") studies$incidence_include else studies$mortality_include
    data <- studies[scenario_keep & keep, ]
    for (axis in c("setting", "scale_group", "ascertainment", "framework", "income")) {
      groups <- if (axis == "income") unname(income_labels) else unique(data[[axis]])
      for (group in groups) {
        x <- data[data[[axis]] == group, ]
        formula <- pooled_mods(x)
        fit <- tryCatch({
          # Prevent automatic dropping of aliased coefficients or fitting a
          # subgroup with no independent residual evidence.
          if (length(unique(x$study_cluster)) < 2) stop("Fewer than two studies")
          X <- model.matrix(formula, x)
          if (nrow(X) <= ncol(X) || qr(X)$rank < ncol(X)) stop("Insufficient or non-identifiable model")
          fit_model(x, outcome, formula, extended = TRUE)
        }, error = function(e) e)
        row <- data.frame(scenario, outcome, axis, group, as.list(count_evidence(x)),
          estimate = NA_real_, lower = NA_real_, upper = NA_real_, I2 = NA_real_,
          reference_year = if (length(unique(x$year_mid)) == 1) unique(x$year_mid) else 2018,
          reference_method = if (length(unique(x$method_dx2)) > 1) "lab-based" else paste(unique(x$method_dx2), collapse = ";"),
          status = "Estimated")
        if (inherits(fit, "error")) row$status <- conditionMessage(fit) else {
          row[c("estimate", "lower", "upper")] <- predict_model(fit)$table
          row$I2 <- heterogeneity(fit)["I2_total"]
          if (row$studies < 5) row$status <- "Estimated; fewer than five studies"
        }
        subgroup_rows[[length(subgroup_rows)+1]] <- row
      }
    }
    # Wald tests compare groups jointly; overlapping subgroup CIs are not tests.
    for (axis in c("setting", "ascertainment", "framework", "income")) {
      for (region_adjusted in if (axis == "income") c(FALSE, TRUE) else FALSE) {
        x <- data; x$group <- factor(x[[axis]])
        terms <- "group"
        if (!axis %in% c("ascertainment", "framework") && length(unique(x$method_dx2)) > 1)
          terms <- c(terms, "method_dx2")
        if (region_adjusted) terms <- c(terms, "WHOregion")
        formula <- reformulate(c(terms, "year_centered"))
        result <- tryCatch({
          X <- model.matrix(formula, x)
          if (qr(X)$rank < ncol(X)) stop("Non-identifiable moderator combination")
          model <- fit_model(x, outcome, formula, extended = TRUE)
          ids <- grep("^group", names(coef(model$fit)))
          test <- anova(model$fit, btt = ids)
          data.frame(QM = test$QM, df = length(ids), p = test$QMp, status = "Estimated")
        }, error = function(e) data.frame(QM = NA_real_, df = NA_real_, p = NA_real_, status = conditionMessage(e)))
        test_rows[[length(test_rows)+1]] <- data.frame(scenario, outcome, axis, region_adjusted, result)
      }
    }
  }
}
subgroup_estimates <- do.call(rbind, subgroup_rows)
moderator_tests <- do.call(rbind, test_rows)
cat("\nEXPLORATORY SUBGROUPS: setting, ascertainment, framework, recorded income\n")
print(subgroup_estimates, row.names = FALSE)
cat("\nEXPLORATORY JOINT TESTS (no multiple-testing correction)\n")
print(moderator_tests, row.names = FALSE)
