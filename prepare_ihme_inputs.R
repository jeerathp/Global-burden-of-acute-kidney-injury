# Prepare privately downloaded IHME inputs. See the download links in README.md.
# Run from the project folder. This script does not download or redistribute data.
prepare_ihme_inputs <- function(
  life_file = "local_inputs/IHME_GBD_2021_DEMOG_1950_2021_TMLRT_Y2024M02D14.CSV",
  weights_file = "local_inputs/IHME_GBD_2023_DISABILITY_WEIGHTS_Y2025M10D12.XLSX",
  weights_sheet = 1,
  output_dir = "local_inputs") {

  if (!all(file.exists(c(life_file, weights_file))))
    stop("Download the two official IHME files first; see README.md. You can also supply their local paths.")

  # GBD 2021 theoretical minimum risk life table: keep all source ages.
  life <- read.csv(life_file, check.names = FALSE)
  life <- life[c("Age", "Life Expectancy")]
  names(life) <- c("age", "remaining_life_expectancy")

  # Read the original full GBD 2023 health-state worksheet, not a study output.
  # openxlsx requires a lowercase extension; IHME's filename ends in .XLSX.
  weights_copy <- tempfile(fileext = ".xlsx")
  on.exit(unlink(weights_copy), add = TRUE)
  if (!file.copy(weights_file, weights_copy)) stop("Could not copy the disability-weight workbook for reading.")
  weights <- openxlsx::read.xlsx(weights_copy, sheet = weights_sheet)
  selected_sequelae <- c(
    "Acute glomerulonephritis",
    "Stage 5 chronic kidney disease untreated due to other and unspecified causes, with mild heart failure",
    "End-stage renal disease on dialysis due to other and unspecified causes, without anemia"
  )
  source_names <- trimws(weights$sequela_name)
  if (!all(vapply(selected_sequelae, function(x) sum(source_names == x), integer(1)) == 1L))
    stop("The worksheet must contain each selected sequela exactly once. Check the source version and sheet.")
  selected <- weights[match(selected_sequelae, source_names), c("mean", "lower", "upper")]
  # The finalized stage analysis used source means and limits rounded to 6 decimals.
  stage_proxy <- data.frame(stage = 1:3, round(selected, 6))

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(life, file.path(output_dir, "gbd2021_standard_life_table.csv"), row.names = FALSE)
  write.csv(stage_proxy, file.path(output_dir, "gbd2023_stage_proxy_weights.csv"), row.names = FALSE)
  message("Prepared local IHME inputs. Keep this folder private; now run source('run_analysis.R').")
  invisible(list(life = life, stage_proxy = stage_proxy))
}
