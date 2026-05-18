# ============================================================
# run_all.R — Master script: run all 11 scenarios in parallel
# ============================================================
# Part of: Phase II-Calibrated Prognostic Scores with TMLE
# Author: Yue Shentu
# Usage:
#   cd simulation
#   Rscript run_all.R                    # all 11 scenarios, 1000 reps
#   Rscript run_all.R --quick            # 100 reps each (test)
#   Rscript run_all.R --scenarios 1,2,3  # specific scenarios
# ============================================================

args <- commandArgs(trailingOnly = TRUE)
quick_mode <- "--quick" %in% args
scenarios_arg <- grep("--scenarios", args, value = TRUE)

if (quick_mode) {
  n_sim <- 100
  cat("⚡ Quick mode: 100 replicates each\n")
} else {
  n_sim <- 1000
}

if (length(scenarios_arg) > 0) {
  scenarios <- as.integer(strsplit(gsub("--scenarios=", "", scenarios_arg), ",")[[1]])
} else {
  scenarios <- 1:11
}

cat(sprintf("📊 Running scenarios %s with %d reps each\n",
            paste(scenarios, collapse = ", "), n_sim))

# Source runners
sim_dir_from_parent <- normalizePath(getwd())
source("R/data_generation.R")
source("R/training.R")
source("R/analysis_methods.R")
source("R/adaptive.R")
source("scripts/run_simulation.R")

# Parallel setup
library(furrr)
library(future)

n_cores <- future::availableCores() - 1
cat(sprintf("🖥️  Using %d cores\n", n_cores))
plan(multisession, workers = n_cores)

for (sc in scenarios) {
  config <- get_scenario_config(sc)
  config$n_sim <- n_sim
  config$seed_base <- default_params$seed_base

  cat(sprintf("\n========== Scenario %d: %s ==========\n", sc, config$name))

  t_start <- Sys.time()

  # Parallel across replicates
  reps <- future_map(1:n_sim, function(rep_id) {
    if (rep_id %% 200 == 0) cat(sprintf("  rep %d/%d\n", rep_id, n_sim))
    run_one_replicate(rep_id, config)
  }, .options = furrr_options(seed = TRUE, chunk_size = 50))

  agg <- aggregate_results(reps, config)
  saveRDS(agg, file.path("output", sprintf("scenario_%02d.rds", sc)))

  elapsed <- difftime(Sys.time(), t_start, units = "mins")
  cat(sprintf("  ✅ Scenario %d complete in %.1f min\n", sc, elapsed))
}

cat("\n✅ All done!\n")
