# ============================================================
# scripts/report.R — Generate results tables from .rds output
# ============================================================
# Part of: Phase II-Calibrated Prognostic Scores with TMLE
# Author: Yue Shentu
# Usage:
#   cd simulation
#   Rscript scripts/report.R                    # all scenarios
#   Rscript scripts/report.R --scenario 3       # single scenario
#   Rscript scripts/report.R --latex            # LaTeX output
# ============================================================

args <- commandArgs(trailingOnly = TRUE)
scenario_filter <- NULL
use_latex <- "--latex" %in% args

for (i in seq_along(args)) {
  if (args[i] == "--scenario" && i < length(args))
    scenario_filter <- as.integer(args[i + 1])
}

output_dir <- "output"
rds_files <- list.files(output_dir, pattern = "^scenario_.*\\.rds$")

if (length(rds_files) == 0) {
  cat("❌ No result files found in output/\n")
  cat("   Run the simulation first:\n")
  cat("   Rscript run_all.R --quick\n")
  quit(status = 1)
}

# Sort by scenario number
scenario_ids <- as.integer(gsub("scenario_(\\d+)\\.rds", "\\1", rds_files))
rds_files <- rds_files[order(scenario_ids)]

if (!is.null(scenario_filter)) {
  rds_files <- rds_files[scenario_ids == scenario_filter]
}

cat("\n========================================\n")
cat("        SIMULATION RESULTS\n")
cat("========================================\n\n")

for (rds_file in rds_files) {
  sc_id <- as.integer(gsub("scenario_(\\d+)\\.rds", "\\1", rds_file))
  agg <- readRDS(file.path(output_dir, rds_file))

  cat(sprintf("===== Scenario %d: %s =====\n", sc_id, agg$config$name))

  # Method name mapping
  method_labels <- list(
    cox_std    = "Cox-Standard",
    logrank    = "Strat. Log-Rank",
    procova_ext = "PROCOVA-Ext",
    cox_cal    = "Cox-Calibrated",
    aipw_cal   = "AIPW-Calibrated",
    tmle_cal   = "TMLE-Calibrated",
    rmst_cal   = "RMST-Calibrated",
    map_cox    = "MAP-Cox"
  )

  if (use_latex) {
    cat("\n\\begin{table}[h]\n")
    cat("\\centering\n")
    cat(sprintf("\\caption{Scenario %d: %s}\n", sc_id, agg$config$name))
    cat("\\begin{tabular}{lrrrrrrr}\n")
    cat("\\hline\n")
    cat("Method & Bias & Emp.SE & Avg.SE & MSE & RE & Power & Cov. \\\\\n")
    cat("\\hline\n")
  } else {
    # Column headers
    cat(sprintf("\n%-20s %8s %8s %8s %8s %8s %7s %7s\n",
                "Method", "Bias", "Emp.SE", "Avg.SE", "MSE", "RE", "Power", "Cov."))
    cat(strrep("-", 75), "\n", sep = "")
  }

  # Find reference variance for RE
  std_var <- if (!is.null(agg$results$cox_std$emp_se))
    agg$results$cox_std$emp_se^2 else NA

  for (method in names(method_labels)) {
    if (is.null(agg$results[[method]])) next
    r <- agg$results[[method]]
    label <- method_labels[[method]]

    re <- if (!is.na(std_var) && !is.null(r$emp_se) && r$emp_se > 0)
      r$emp_se^2 / std_var else NA

    if (use_latex) {
      cat(sprintf("%-20s & %.4f & %.4f & %.4f & %.4f & %.2f & %.3f & %.3f \\\\\n",
                  label, r$bias, r$emp_se, r$avg_se, r$mse, re, r$power, r$coverage))
    } else {
      cat(sprintf("%-20s %8.4f %8.4f %8.4f %8.4f %8.2f %7.3f %7.3f\n",
                  label, r$bias, r$emp_se, r$avg_se, r$mse, re, r$power, r$coverage))
    }
  }

  if (use_latex) {
    cat("\\hline\n")
    cat("\\end{tabular}\n")
    cat("\\end{table}\n")
  }
  cat("\n")
}

# Type I error summary (Scenario 11)
if (is.null(scenario_filter) || scenario_filter == 11) {
  sc11_file <- file.path(output_dir, "scenario_11.rds")
  if (file.exists(sc11_file)) {
    agg11 <- readRDS(sc11_file)
    cat("\n===== Type I Error Summary (Scenario 11) =====\n")

    method_labels <- list(
      cox_std    = "Cox-Standard",
      procova_ext = "PROCOVA-Ext",
      cox_cal    = "Cox-Calibrated",
      aipw_cal   = "AIPW-Calibrated",
      tmle_cal   = "TMLE-Calibrated",
      rmst_cal   = "RMST-Calibrated",
      map_cox    = "MAP-Cox"
    )

    cat(sprintf("\n%-20s %10s %12s\n", "Method", "Type I Error", "95% CI"))
    cat(strrep("-", 45), "\n", sep = "")
    for (method in names(method_labels)) {
      if (is.null(agg11$results[[method]])) next
      r <- agg11$results[[method]]
      ci <- 1.96 * sqrt(r$power * (1 - r$power) / r$n_rep)
      cat(sprintf("%-20s %10.4f [%.4f, %.4f]\n",
                  method_labels[[method]], r$power,
                  max(0, r$power - ci), min(1, r$power + ci)))
    }
  }
}

cat("\nDone.\n")
