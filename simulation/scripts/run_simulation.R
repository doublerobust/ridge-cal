# ============================================================
# scripts/run_simulation.R — Main simulation runner
# ============================================================
# Part of: Phase II-Calibrated Prognostic Scores with TMLE
# Author: Yue Shentu
# Usage:
#   Rscript scripts/run_simulation.R --scenario 1 --n_sim 100
#   Rscript scripts/run_simulation.R --all
# ============================================================

# ---- Parse command-line arguments ----
# When sourced from run_all.R, n_sim is already set; don't overwrite it
run_all <- FALSE
if (!exists("n_sim")) {
  args <- commandArgs(trailingOnly = TRUE)
  run_all <- "--all" %in% args
  scenario_id <- NULL

  for (i in seq_along(args)) {
    if (args[i] == "--scenario" && i < length(args))
      scenario_id <- as.integer(args[i + 1])
    if (args[i] == "--n_sim" && i < length(args))
      n_sim <- as.integer(args[i + 1])
  }
}

# ---- Source all R files ----
# Determine simulation directory: when sourced from run_all.R, use the parent's working dir
sim_dir <- if (exists("sim_dir_from_parent") && nzchar(sim_dir_from_parent)) {
  sim_dir_from_parent
} else if (!interactive() && length(grep("--file=", commandArgs(trailingOnly = FALSE))) > 0) {
  script_path <- commandArgs(trailingOnly = FALSE)[grep("--file=", commandArgs(trailingOnly = FALSE))]
  script_dir <- dirname(normalizePath(sub("--file=", "", script_path)))
  normalizePath(file.path(script_dir, ".."))
} else {
  normalizePath(getwd())
}
source(file.path(sim_dir, "R/data_generation.R"))
source(file.path(sim_dir, "R/training.R"))
source(file.path(sim_dir, "R/analysis_methods.R"))
source(file.path(sim_dir, "R/adaptive.R"))

# ---- Run a single replicate ----
run_one_replicate <- function(rep_id, config) {
  set.seed(config$seed_base + rep_id)

  # 1. Determine parameters
  beta_ext <- get_beta_ext(config$shift)
  beta_prog <- get_beta_prog()
  ext_params <- get_weibull_params("external", config$shift)
  trial_params <- get_weibull_params("trial", "none")  # trial always uses trial params

  # 2. Generate external data
  ext_data <- generate_external_data(config$n_ext, beta_ext,
                                      ext_params$shape, ext_params$scale)

  # 3. Generate phase II data
  phaseII <- generate_data(config$n_1, config$beta_trt, beta_prog,
                           trial_params$shape, trial_params$scale)

  # 4. Generate phase III data
  phaseIII <- generate_data(config$n_2, config$beta_trt, beta_prog,
                            trial_params$shape, trial_params$scale)

  # 5. Train external model and compute external score
  ext_model <- train_external_model(ext_data$W, ext_data$T, ext_data$delta)
  S_ext <- ext_model$predict(phaseIII$W)

  # 6. Calibrate
  cal <- calibrate_prognostic(ext_data$W, ext_data$T, ext_data$delta,
                                phaseII$W, phaseII$T, phaseII$delta, phaseII$A)
  S_cal <- cal$predict(phaseIII$W)

  # 7. Run all analysis methods
  # Adaptive: per-coefficient calibration + inverse normal
  adaptive <- tryCatch(
    analyze_adaptive(ext_data$W, ext_data$T, ext_data$delta,
                      phaseII$W, phaseII$A, phaseII$T, phaseII$delta,
                      phaseIII$W, phaseIII$A, phaseIII$T, phaseIII$delta,
                      config$tau),
    error = function(e) {
      list(method = "Adaptive", beta = NA, se = NA, Z1 = NA,
           Z2 = NA, Z_comb = NA, p = 1)
    }
  )

  results <- list(
    cox_std     = analyze_cox_standard(phaseIII$W, phaseIII$A,
                                        phaseIII$T, phaseIII$delta),
    logrank     = analyze_logrank(phaseIII$W, phaseIII$A,
                                   phaseIII$T, phaseIII$delta),
    procova_ext = analyze_cox_with_score(phaseIII$A, phaseIII$T,
                                          phaseIII$delta, S_ext),
    cox_cal     = analyze_cox_with_score(phaseIII$A, phaseIII$T,
                                          phaseIII$delta, S_cal),
    ipcw        = analyze_ipcw(phaseIII$A, phaseIII$T,
                                phaseIII$delta, config$tau),
    aipw_cal    = analyze_aipw(phaseIII$W, phaseIII$A,
                                phaseIII$T, phaseIII$delta, S_cal, config$tau),
    tmle_cal    = analyze_tmle(phaseIII$W, phaseIII$A,
                                phaseIII$T, phaseIII$delta, S_cal, config$tau),
    rmst_cal    = analyze_rmst(phaseIII$A, phaseIII$T, phaseIII$delta, config$tau),
    map_cox     = analyze_map_cox(phaseII$W, phaseII$A,
                                   phaseII$T, phaseII$delta,
                                   phaseIII$W, phaseIII$A,
                                   phaseIII$T, phaseIII$delta,
                                   ext_data$W, ext_data$T, ext_data$delta),
    adaptive    = adaptive
  )

  # 8. Calibration diagnostics
  list(
    results = results,
    diagnostics = list(
      S_ext = S_ext,
      S_cal = S_cal,
      beta_ext = coef(ext_model$fit),
      beta_cal = if (!is.null(cal$beta_mean)) cal$beta_mean else NA
    )
  )
}

# ---- Aggregate results across replicates ----
aggregate_results <- function(results_list, config) {
  methods <- names(results_list[[1]]$results)
  n_rep <- length(results_list)
  beta_true <- if (isTRUE(config$beta_trt == 0)) 0 else config$beta_trt
  psi_true  <- config$psi_true

  out <- list()
  for (method in methods) {
    est <- lapply(results_list, function(r) r$results[[method]])

    if (!is.null(est[[1]]$beta)) {
      # Log-HR scale
      v <- sapply(est, `[[`, "beta")
      se_v <- sapply(est, `[[`, "se")
      p <- sapply(est, `[[`, "p")
      out[[method]] <- list(
        method = est[[1]]$method, n_rep = n_rep,
        bias = mean(v) - beta_true,
        emp_se = sd(v),
        avg_se = mean(se_v),
        mse = mean((v - beta_true)^2),
        power = mean(p < 0.05),
        coverage = mean(v - 1.96 * se_v <= beta_true &
                         v + 1.96 * se_v >= beta_true)
      )
    } else if (!is.null(est[[1]]$psi)) {
      # Survival difference or RMST scale
      v <- sapply(est, `[[`, "psi")
      se_v <- sapply(est, `[[`, "se")
      p <- sapply(est, `[[`, "p")
      is_rmst <- grepl("RMST", method, ignore.case = TRUE) ||
                 grepl("rmst", names(est[[1]])[1], ignore.case = TRUE)
      truth <- if (is_rmst) config$rmst_true else psi_true
      out[[method]] <- list(
        method = est[[1]]$method, n_rep = n_rep,
        bias = mean(v) - truth,
        emp_se = sd(v),
        avg_se = mean(se_v),
        mse = mean((v - truth)^2),
        power = mean(p < 0.05),
        coverage = mean(v - 1.96 * se_v <= truth &
                         v + 1.96 * se_v >= truth)
      )
    }
  }
  list(config = config, results = out)
}

# ---- Main ----
if (!interactive()) {
  if (run_all) {
    for (sc in 1:11) {
      cat(sprintf("\n========== Scenario %d ==========\n", sc))
      config <- get_scenario_config(sc)
      config$seed_base <- default_params$seed_base

      cat(sprintf("Running %d replicates of %s...\n",
                  config$n_sim, config$name))

      # Sequential for now (parallel added in run_all.R)
      reps <- lapply(1:config$n_sim, function(rep_id) {
        if (rep_id %% 100 == 0)
          cat(sprintf("  rep %d/%d\n", rep_id, config$n_sim))
        run_one_replicate(rep_id, config)
      })

      agg <- aggregate_results(reps, config)
      saveRDS(agg, file.path(sim_dir, "output",
                             sprintf("scenario_%02d.rds", sc)))
      cat(sprintf("  ✅ Saved to output/scenario_%02d.rds\n", sc))
    }
    cat("\n✅ All scenarios complete!\n")
  } else if (!is.null(scenario_id)) {
    config <- get_scenario_config(scenario_id)
    if (!is.null(n_sim)) config$n_sim <- n_sim
    config$seed_base <- default_params$seed_base

    # Compute true psi for this scenario
    trial_params <- get_weibull_params("trial")
    true_vals <- compute_psi_true(
      n_ref = 50000,
      beta_trt = config$beta_trt,
      beta_prog = get_beta_prog(),
      shape = trial_params$shape,
      scale = trial_params$scale,
      tau = config$tau
    )
    config$psi_true <- unname(true_vals["psi"])
    config$rmst_true <- unname(true_vals["rmst"])

    cat(sprintf("Running %s (scenario %d)\n", config$name, scenario_id))
    cat(sprintf("  %d reps, psi_true=%.4f, rmst_true=%.2f\n",
                config$n_sim, config$psi_true, config$rmst_true))

    reps <- lapply(1:config$n_sim, function(rep_id) {
      if (rep_id %% 100 == 0)
        cat(sprintf("  rep %d/%d\n", rep_id, config$n_sim))
      run_one_replicate(rep_id, config)
    })

    agg <- aggregate_results(reps, config)
    saveRDS(agg, file.path(sim_dir, "output",
                           sprintf("scenario_%02d.rds", scenario_id)))
    cat(sprintf("✅ Saved to output/scenario_%02d.rds\n", scenario_id))
  } else {
    cat("Usage:\n")
    cat("  Rscript scripts/run_simulation.R --scenario <id> [--n_sim <n>]\n")
    cat("  Rscript scripts/run_simulation.R --all\n")
  }
}
