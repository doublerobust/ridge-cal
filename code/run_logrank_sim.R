#!/usr/bin/env Rscript
# run_logrank_sim.R — Score-stratified log-rank simulation
#
# Implements 7 testing methods:
#   1. Standard stratified log-rank (ECOG + region)
#   2. External-score stratified (+ external score quartiles)
#   3. Ridge-Cal calibrated score stratified (+ calibrated score quartiles)
#   4. ENET-Quartile (elastic net from blinded trial data → score quartiles)
#   5. ENET-Cox (elastic net from blinded trial data → continuous Cox p-value)
#   6. Oracle stratified (+ true score quartiles)
#   7. Trend test (Tarone 1975, across external-score quartiles)
#
# Two phases:
#   Phase 1 (Core):  10K reps x 7 scenarios (∼30 min with 11 workers)
#   Phase 2 (Sweep): 2K reps x 8 severity multipliers (∼7 min)
#
# Usage:
#   Rscript run_logrank_sim.R                # full run
#   Rscript run_logrank_sim.R 500            # screening (small test)
#   Rscript run_logrank_sim.R 10000 0        # core only
#   Rscript run_logrank_sim.R 0 2000         # threshold sweep only (2K reps per multiplier)
#
# Output:
#   ../output/logrank-sim-results.txt       (core summary)
#   ../output/logrank-sim-results.rds       (full core data)
#   ../output/logrank-threshold-results.txt (threshold sweep summary)
#
# Dependencies: survival, glmnet, furrr, future

# ---- Setup ----
library(survival)
library(glmnet)
library(furrr)
library(future)

script_dir <- tryCatch(normalizePath(dirname(commandArgs(trailingOnly = FALSE)[
  grep("--file=", commandArgs(trailingOnly = FALSE))
])), error = function(e) getwd())
if (!grepl("code$", script_dir)) {
  script_dir <- file.path(script_dir, "code")
}
setwd(script_dir)
source("R/data_generation.R")
source("R/training.R")
source("R/analysis_methods.R")

# ---- Seed base ----
SEED_BASE <- 20260517

# ---- ridge_cal (from run_clean.R) ----
ridge_cal <- function(W, T, d, S_all,
                       cc = c("sex", "marker_x", "crp", "albumin", "ldh")) {
  cv <- intersect(cc, names(W))
  x <- as.matrix(cbind(S = as.numeric(S_all), W[, cv, drop = FALSE]))
  cf <- cv.glmnet(x, Surv(T, d), family = "cox", alpha = 0, nfolds = 5)
  list(S = as.numeric(predict(cf, newx = x, s = "lambda.min", type = "link")),
       lam = cf$lambda.min)
}

# ============================================================
# Score discretization helper
# ============================================================
make_score_strata <- function(score, breaks = NULL, K = 4) {
  if (is.null(breaks)) {
    breaks <- quantile(score, probs = seq(0, 1, length.out = K + 1), na.rm = TRUE)
  }
  breaks <- sort(unique(breaks))
  if (length(breaks) <= 1) return(rep(1, length(score)))
  strata <- cut(score, breaks = breaks, include.lowest = TRUE, labels = FALSE)
  strata
}

# ============================================================
# Log-rank method implementations
# ============================================================

# Method 1: Standard (ECOG + region)
logrank_standard <- function(T, d, A, ecog, region) {
  strata_var <- interaction(ecog >= 0, region, drop = TRUE)
  fit <- survdiff(Surv(T, d) ~ A + strata(strata_var))
  chisq <- fit$chisq
  p <- 1 - pchisq(chisq, df = 1)
  list(method = "Standard", p = p, chisq = chisq,
       n_strata = length(unique(strata_var)))
}

# Method 2: External-score stratified
logrank_extscore <- function(T, d, A, ecog, region, score_ext, ext_quantile_breaks) {
  score_s <- make_score_strata(score_ext, breaks = ext_quantile_breaks)
  strata_var <- interaction(ecog >= 0, region, score_s, drop = TRUE)
  fit <- survdiff(Surv(T, d) ~ A + strata(strata_var))
  chisq <- fit$chisq
  p <- 1 - pchisq(chisq, df = 1)
  list(method = "ExtScore", p = p, chisq = chisq,
       n_strata = length(unique(strata_var)))
}

# Method 3: Ridge-Cal calibrated score stratified
logrank_rcscore <- function(T, d, A, ecog, region, score_cal) {
  score_s <- make_score_strata(score_cal)
  strata_var <- interaction(ecog >= 0, region, score_s, drop = TRUE)
  fit <- survdiff(Surv(T, d) ~ A + strata(strata_var))
  chisq <- fit$chisq
  p <- 1 - pchisq(chisq, df = 1)
  list(method = "RCCal", p = p, chisq = chisq,
       n_strata = length(unique(strata_var)))
}

# Method 4: ENET-Quartile — elastic net on blinded trial data → score quartiles
logrank_enet_quartile <- function(T, d, A, ecog, region, W) {
  # Elastic net on blinded trial data (all 20 covariates)
  x_all <- as.matrix(W[, intersect(names(W), names(get_beta_prog())), drop = FALSE])
  # Suppress cv.glmnet convergence warnings
  suppressWarnings({
    cv_enet <- cv.glmnet(x_all, Surv(T, d), family = "cox",
                          alpha = 0.5, nfolds = 5)
  })
  enet_score <- as.numeric(predict(cv_enet, newx = x_all, s = "lambda.min", type = "link"))

  score_s <- make_score_strata(enet_score)
  strata_var <- interaction(ecog >= 0, region, score_s, drop = TRUE)
  fit <- survdiff(Surv(T, d) ~ A + strata(strata_var))
  chisq <- fit$chisq
  p <- 1 - pchisq(chisq, df = 1)
  list(method = "ENETQ", p = p, chisq = chisq,
       n_strata = length(unique(strata_var)), score = enet_score)
}

# Method 5: ENET-Cox — elastic net score as continuous Cox covariate
enet_cox <- function(A, T, d, W) {
  x_all <- as.matrix(W[, intersect(names(W), names(get_beta_prog())), drop = FALSE])
  suppressWarnings({
    cv_enet <- cv.glmnet(x_all, Surv(T, d), family = "cox",
                          alpha = 0.5, nfolds = 5)
  })
  enet_score <- as.numeric(predict(cv_enet, newx = x_all, s = "lambda.min", type = "link"))

  df <- data.frame(T = T, d = d, A = A, S = enet_score)
  fit <- tryCatch(
    coxph(Surv(T, d) ~ A + S, data = df, robust = TRUE),
    error = function(e) NULL
  )
  if (is.null(fit)) return(list(p = NA_real_, beta = NA_real_))
  list(p = unname(summary(fit)$coefficients["A", "Pr(>|z|)"]),
       beta = unname(coef(fit)["A"]))
}

# Method 6: Oracle stratified (true prognostic LP quartiles)
logrank_oracle <- function(T, d, A, ecog, region, true_lp) {
  score_s <- make_score_strata(true_lp)
  strata_var <- interaction(ecog >= 0, region, score_s, drop = TRUE)
  fit <- survdiff(Surv(T, d) ~ A + strata(strata_var))
  chisq <- fit$chisq
  p <- 1 - pchisq(chisq, df = 1)
  list(method = "Oracle", p = p, chisq = chisq,
       n_strata = length(unique(strata_var)))
}

# Method 7: Trend test (Tarone 1975) across external-score quartiles
logrank_trend <- function(T, d, A, ecog, region, score) {
  score_q <- make_score_strata(score)
  k_levels <- sort(unique(score_q))
  K <- length(k_levels)

  o_e <- numeric(K)
  var_o_e <- numeric(K)
  n_events <- numeric(K)

  for (qi in seq_along(k_levels)) {
    q <- k_levels[qi]
    idx <- which(score_q == q)
    if (length(idx) < 4 || sum(d[idx]) < 2) {
      o_e[qi] <- NA
      var_o_e[qi] <- NA
      n_events[qi] <- sum(d[idx])
      next
    }
    fit_q <- survdiff(Surv(T[idx], d[idx]) ~ A[idx] +
                        strata(ecog[idx] >= 0, region[idx]))
    o_e[qi] <- fit_q$obs[1] - fit_q$exp[1]
    var_o_e[qi] <- fit_q$var[1, 1]
    n_events[qi] <- sum(d[idx])
  }

  valid <- !is.na(o_e) & !is.na(var_o_e) & var_o_e > 0
  if (sum(valid) < 2) {
    return(list(method = "Trend", p = NA_real_, chisq = NA_real_,
                n_valid_strata = sum(valid)))
  }

  doses <- seq_len(K)[valid]
  num <- sum(doses * o_e[valid], na.rm = TRUE)^2
  den <- sum(doses^2 * var_o_e[valid], na.rm = TRUE)

  if (den > 0) {
    chisq <- num / den
    p <- 1 - pchisq(chisq, df = 1)
  } else {
    chisq <- NA_real_
    p <- NA_real_
  }

  list(method = "Trend", p = p, chisq = chisq,
       n_valid_strata = sum(valid))
}

# ---- Cox continuous-score reference ----
cox_with_score <- function(A, T, d, score) {
  df <- data.frame(T = T, d = d, A = A, S = as.numeric(score))
  fit <- tryCatch(
    coxph(Surv(T, d) ~ A + S, data = df, robust = TRUE),
    error = function(e) NULL
  )
  if (is.null(fit)) return(list(p = NA_real_, beta = NA_real_))
  list(p = unname(summary(fit)$coefficients["A", "Pr(>|z|)"]),
       beta = unname(coef(fit)["A"]))
}

# ---- Sparse strata diagnostics ----
check_strata <- function(T, d, A, ecog, region, score) {
  score_s <- make_score_strata(score)
  strata_var <- interaction(ecog >= 0, region, score_s, drop = TRUE)
  tbl <- table(strata_var, A)
  n_strata <- nrow(tbl)
  min_events <- if (n_strata > 0) min(tbl) else 0
  sparse_arms <- sum(tbl[, 1] < 2 | tbl[, 2] < 2)
  list(n_strata = n_strata, min_events_stratum = min_events,
       sparse_arms = sparse_arms)
}

# ============================================================
# One simulation replicate (returns named vector)
# ============================================================
sim_one_rep <- function(i, s_val, shift_val, btrt_val, inter_val,
                         em, ext_quantile_breaks) {
  set.seed(SEED_BASE + s_val * 100000 + i)

  be <- get_beta_ext(shift_val)
  bp <- get_beta_prog()
  ep <- get_weibull_params("external", shift_val)

  n_t <- 400
  W <- generate_covariates(n_t)
  W$region <- rbinom(n_t, 1, 0.5)

  A <- rbinom(n_t, 1, 0.5)
  lp <- compute_lp(W, bp, btrt_val, A)

  if (inter_val) {
    lp <- lp + 0.5 * A * (W$marker_x - mean(W$marker_x))
  }

  if (s_val == 6) {
    lp_nph <- compute_lp(W, bp, 0)
    Td <- numeric(n_t)
    for (j in 1:n_t) {
      hr2 <- if (A[j] == 1) exp(btrt_val) else 1
      t <- rexp(1, 1/13 * exp(lp_nph[j]))
      if (is.infinite(t)) {
        Td[j] <- Inf
      } else if (t > 2) {
        Td[j] <- 2 + rexp(1, 1/13 * hr2 * exp(lp_nph[j]))
      } else {
        Td[j] <- t
      }
    }
  } else {
    Td <- rweibull(n_t, shape = 1.5, scale = 13 * exp(-lp / 1.5))
  }

  C <- pmin(rep(24, n_t), rexp(n_t, rate = -log(1 - 0.03) / 12))
  To <- pmin(Td, C)
  d <- as.numeric(Td <= C)

  # True prognostic LP (without treatment effect — for oracle)
  true_prog_lp <- compute_lp(W, bp, 0, NULL)

  # External score
  Se <- em$predict(W)

  # Ridge-Cal calibrated score
  rc <- ridge_cal(W, To, d, Se)
  S_cal <- rc$S

  # --- 7 log-rank / testing methods ---
  m1 <- logrank_standard(To, d, A, W$ecog, W$region)
  m2 <- logrank_extscore(To, d, A, W$ecog, W$region, Se, ext_quantile_breaks)
  m3 <- logrank_rcscore(To, d, A, W$ecog, W$region, S_cal)
  m4 <- logrank_enet_quartile(To, d, A, W$ecog, W$region, W)
  m5_enet <- enet_cox(A, To, d, W)       # ENET-Cox
  m6 <- logrank_oracle(To, d, A, W$ecog, W$region, true_prog_lp)
  m7 <- logrank_trend(To, d, A, W$ecog, W$region, Se)  # Trend test (external score)

  # --- Supplementary trend tests (for diagnostics) ---
  m7_cal <- logrank_trend(To, d, A, W$ecog, W$region, S_cal)
  m7_prog <- logrank_trend(To, d, A, W$ecog, W$region, true_prog_lp)

  # --- Cox continuous-score references ---
  cx_std <- analyze_cox_standard(W, A, To, d)
  cx_ext <- cox_with_score(A, To, d, Se)
  cx_cal <- cox_with_score(A, To, d, S_cal)
  cx_orc <- cox_with_score(A, To, d, true_prog_lp)

  # --- Sparse strata diagnostics ---
  chk_ext <- check_strata(To, d, A, W$ecog, W$region, Se)
  chk_cal <- check_strata(To, d, A, W$ecog, W$region, S_cal)
  chk_orc <- check_strata(To, d, A, W$ecog, W$region, true_prog_lp)
  chk_enet <- check_strata(To, d, A, W$ecog, W$region, m4$score)

  c(
    # p-values for 7 methods
    m1_p = m1$p, m2_p = m2$p, m3_p = m3$p,
    m4_p = m4$p, m5_p = m5_enet$p, m6_p = m6$p, m7_p = m7$p,
    # Non-empty strata counts
    m1_ns = m1$n_strata, m2_ns = m2$n_strata, m3_ns = m3$n_strata,
    m4_ns = m4$n_strata, m6_ns = m6$n_strata,
    # ENET-Cox beta estimate
    m5_beta = m5_enet$beta,
    # Supplementary trend tests
    m7_cal_p = m7_cal$p, m7_prog_p = m7_prog$p,
    # Cox continuous p-values
    cx_std_p = cx_std$p, cx_ext_p = cx_ext$p,
    cx_cal_p = cx_cal$p, cx_orc_p = cx_orc$p,
    # Sparse strata diagnostics — external
    ext_ns = chk_ext$n_strata, ext_min = chk_ext$min_events_stratum,
    ext_sparse = chk_ext$sparse_arms,
    # Sparse — calibrated
    cal_ns = chk_cal$n_strata, cal_min = chk_cal$min_events_stratum,
    cal_sparse = chk_cal$sparse_arms,
    # Sparse — oracle
    orc_ns = chk_orc$n_strata, orc_min = chk_orc$min_events_stratum,
    orc_sparse = chk_orc$sparse_arms,
    # Sparse — ENET
    enet_ns = chk_enet$n_strata, enet_min = chk_enet$min_events_stratum,
    enet_sparse = chk_enet$sparse_arms,
    # Events
    events = sum(d)
  )
}

# ============================================================
# Scenario definitions (matching run_clean.R)
# ============================================================
scenarios <- list(
  list(id = 1, name = "No shift",          shift = "none",     btrt = log(0.70), inter = FALSE),
  list(id = 2, name = "Moderate",          shift = "moderate", btrt = log(0.70), inter = FALSE),
  list(id = 3, name = "Severe",            shift = "severe",   btrt = log(0.70), inter = FALSE),
  list(id = 4, name = "Interaction",       shift = "severe",   btrt = log(0.70), inter = TRUE),
  list(id = 5, name = "Null",              shift = "none",     btrt = 0,         inter = FALSE),
  list(id = 6, name = "Non-PH",            shift = "severe",   btrt = log(0.70), inter = FALSE),
  list(id = 7, name = "Smaller effect",    shift = "severe",   btrt = log(0.75), inter = FALSE)
)

method_labels <- c("Standard", "ExtScore", "RCCal", "ENETQ", "ENETCox", "Oracle", "Trend")
n_methods <- length(method_labels)

# ============================================================
# Run one scenario
# ============================================================
run_scenario <- function(s, n_reps, seed_offset = 0) {
  sc <- scenarios[[s]]
  cat(sprintf("\n=== Scenario %d: %s (%d reps) ===\n", s, sc$name, n_reps))
  t0 <- Sys.time()

  # Generate external data once per scenario
  ep <- get_weibull_params("external", sc$shift)
  be <- get_beta_ext(sc$shift)
  ext <- generate_external_data(2000, be, ep$shape, ep$scale)
  em <- train_external_model(ext$W, ext$T, ext$delta)
  Se_ext <- em$predict(ext$W)

  # Pre-specified external score quartile boundaries
  ext_quantile_breaks <- quantile(Se_ext, probs = seq(0, 1, 0.25), na.rm = TRUE)
  ext_quantile_breaks <- sort(unique(ext_quantile_breaks))

  reps <- future_map(seq_len(n_reps), function(i) {
    sim_one_rep(i + seed_offset, s, sc$shift, sc$btrt, sc$inter,
                em, ext_quantile_breaks)
  }, .options = furrr_options(seed = TRUE, chunk_size = 200))

  res_mat <- do.call(rbind, reps)

  cat(sprintf("  Time: %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  list(res_mat = res_mat)
}

# ============================================================
# Compute summary statistics from result matrix
# ============================================================
summarize_results <- function(res_mat) {
  p_vals <- function(prefix) {
    cols <- grep(paste0("^", prefix, "$"), colnames(res_mat))
    if (length(cols) == 0) return(NA_real_)
    mean(res_mat[, cols] < 0.05, na.rm = TRUE)
  }

  list(
    p_std   = mean(res_mat[, "m1_p"] < 0.05, na.rm = TRUE),
    p_ext   = mean(res_mat[, "m2_p"] < 0.05, na.rm = TRUE),
    p_rccal = mean(res_mat[, "m3_p"] < 0.05, na.rm = TRUE),
    p_enetq = mean(res_mat[, "m4_p"] < 0.05, na.rm = TRUE),
    p_enetcox = mean(res_mat[, "m5_p"] < 0.05, na.rm = TRUE),
    p_orc   = mean(res_mat[, "m6_p"] < 0.05, na.rm = TRUE),
    p_trend = mean(res_mat[, "m7_p"] < 0.05, na.rm = TRUE),
    cx_std  = mean(res_mat[, "cx_std_p"] < 0.05, na.rm = TRUE),
    cx_ext  = mean(res_mat[, "cx_ext_p"] < 0.05, na.rm = TRUE),
    cx_cal  = mean(res_mat[, "cx_cal_p"] < 0.05, na.rm = TRUE),
    cx_orc  = mean(res_mat[, "cx_orc_p"] < 0.05, na.rm = TRUE),
    trend_cal = mean(res_mat[, "m7_cal_p"] < 0.05, na.rm = TRUE),
    trend_prog = mean(res_mat[, "m7_prog_p"] < 0.05, na.rm = TRUE),
    ext_ns_mean  = mean(res_mat[, "ext_ns"], na.rm = TRUE),
    cal_ns_mean  = mean(res_mat[, "cal_ns"], na.rm = TRUE),
    orc_ns_mean  = mean(res_mat[, "orc_ns"], na.rm = TRUE),
    enet_ns_mean = mean(res_mat[, "enet_ns"], na.rm = TRUE),
    ext_min_mean  = mean(res_mat[, "ext_min"], na.rm = TRUE),
    cal_min_mean  = mean(res_mat[, "cal_min"], na.rm = TRUE),
    orc_min_mean  = mean(res_mat[, "orc_min"], na.rm = TRUE),
    enet_min_mean = mean(res_mat[, "enet_min"], na.rm = TRUE),
    ext_sparse_pct  = mean(res_mat[, "ext_sparse"] > 0, na.rm = TRUE) * 100,
    cal_sparse_pct  = mean(res_mat[, "cal_sparse"] > 0, na.rm = TRUE) * 100,
    orc_sparse_pct  = mean(res_mat[, "orc_sparse"] > 0, na.rm = TRUE) * 100,
    enet_sparse_pct = mean(res_mat[, "enet_sparse"] > 0, na.rm = TRUE) * 100,
    mean_events = mean(res_mat[, "events"], na.rm = TRUE)
  )
}

# ============================================================
# Phase 2: Miscalibration threshold sweep (severe shift only)
# ============================================================
run_threshold_sweep <- function(n_reps = 2000) {
  severity_multipliers <- c(0.0, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0)

  cat("\n\n========================================\n")
  cat("Phase 2: Miscalibration Threshold Sweep\n")
  cat("========================================\n")

  bp <- get_beta_prog()
  baseline_delta <- c(
    0, 0, 0.20, 0.25, 0, 0, 0, 0, 0, 0.20,
    0.30, 0, 0, 0, 0.75,
    0.10, 0.10, 0, 0.08, 0
  )
  names(baseline_delta) <- names(bp)

  # Pre-generate external data for each multiplier
  sweeps <- list()

  for (m_idx in seq_along(severity_multipliers)) {
    sv <- severity_multipliers[m_idx]
    cat(sprintf("\n--- Severity multiplier: %.2f ---\n", sv))

    s_val <- 3  # severe shift scenario
    btrt_val <- log(0.70)
    t0 <- Sys.time()

    # Build shifted betas
    be <- bp + sv * baseline_delta

    # External data
    ep_ext <- get_weibull_params("external", "severe")
    # For multiplier < 1, the survival distribution gets less shifted too
    # We scale the weibull scale: more shift = worse survival
    ep_ext$scale <- 13 - sv * (13 - 9)  # linear from 13 (no shift) to 9 (full severe)

    ext <- generate_external_data(2000, be, ep_ext$shape, ep_ext$scale)
    em <- train_external_model(ext$W, ext$T, ext$delta)
    Se_ext <- em$predict(ext$W)
    ext_quantile_breaks <- quantile(Se_ext, probs = seq(0, 1, 0.25), na.rm = TRUE)
    ext_quantile_breaks <- sort(unique(ext_quantile_breaks))

    # C-index estimation for external model on trial-like data
    # Generate a large trial-like dataset to compute ΔC
    n_ref <- 2000
    W_ref <- generate_covariates(n_ref)
    lp_true <- compute_lp(W_ref, bp)
    lp_ext <- em$predict(W_ref)
    c_ext <- tryCatch(
      Hmisc::rcorr.cens(lp_ext, lp_true)[1],
      error = function(e) NA_real_
    )
    # C-index of true model on itself
    c_true <- tryCatch(
      Hmisc::rcorr.cens(lp_true, lp_true)[1],
      error = function(e) NA_real_
    )

    reps <- future_map(seq_len(n_reps), function(i) {
      set.seed(SEED_BASE + 1000000 + m_idx * 100000 + i)
      n_t <- 400
      W <- generate_covariates(n_t)
      W$region <- rbinom(n_t, 1, 0.5)
      A <- rbinom(n_t, 1, 0.5)
      lp <- compute_lp(W, bp, btrt_val, A)

      Td <- rweibull(n_t, shape = 1.5, scale = 13 * exp(-lp / 1.5))
      C <- pmin(rep(24, n_t), rexp(n_t, rate = -log(1 - 0.03) / 12))
      To <- pmin(Td, C)
      d <- as.numeric(Td <= C)

      Se <- em$predict(W)
      rc <- ridge_cal(W, To, d, Se)
      S_cal <- rc$S

      m1 <- logrank_standard(To, d, A, W$ecog, W$region)
      m2 <- logrank_extscore(To, d, A, W$ecog, W$region, Se, ext_quantile_breaks)
      m3 <- logrank_rcscore(To, d, A, W$ecog, W$region, S_cal)

      # ENET methods
      m4_res <- logrank_enet_quartile(To, d, A, W$ecog, W$region, W)
      m5_res <- enet_cox(A, To, d, W)

      c(m1_p = m1$p, m2_p = m2$p, m3_p = m3$p,
        m4_p = m4_res$p, m5_p = m5_res$p)
    }, .options = furrr_options(seed = TRUE, chunk_size = 200))

    res_mat <- do.call(rbind, reps)

    sweeps[[m_idx]] <- list(
      multiplier = sv,
      power_std   = mean(res_mat[, "m1_p"] < 0.05, na.rm = TRUE),
      power_ext   = mean(res_mat[, "m2_p"] < 0.05, na.rm = TRUE),
      power_rccal = mean(res_mat[, "m3_p"] < 0.05, na.rm = TRUE),
      power_enetq = mean(res_mat[, "m4_p"] < 0.05, na.rm = TRUE),
      power_enetcox = mean(res_mat[, "m5_p"] < 0.05, na.rm = TRUE),
      c_ext = c_ext,
      c_true = c_true,
      delta_c = c_true - c_ext,
      n_reps = n_reps
    )

    cat(sprintf("  Std=%.3f Ext=%.3f RCal=%.3f ENETQ=%.3f ENETCox=%.3f  ΔC=%.3f  [%.1f min]\n",
                sweeps[[m_idx]]$power_std, sweeps[[m_idx]]$power_ext,
                sweeps[[m_idx]]$power_rccal, sweeps[[m_idx]]$power_enetq,
                sweeps[[m_idx]]$power_enetcox,
                sweeps[[m_idx]]$delta_c,
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  }

  # Find crossover point
  cat("\n\n--- Crossover Analysis ---\n")
  mc_se <- sqrt(0.5 * 0.5 / n_reps) * 2  # 2x MC SE at worst-case 50% power
  crossover_idx <- NA
  for (m_idx in seq_along(severity_multipliers)) {
    sw <- sweeps[[m_idx]]
    if (sw$power_rccal <= sw$power_std + 2 * mc_se) {
      crossover_idx <- m_idx
      cat(sprintf("  Crossover at multiplier %.2f: RCal=%.3f ≤ Std=%.3f + 2×SE(%.4f)\n",
                  sw$multiplier, sw$power_rccal, sw$power_std, 2 * mc_se))
      break
    }
  }
  if (is.na(crossover_idx)) {
    cat(sprintf("  No crossover observed across tested multipliers. RCal always > Std + 2×SE.\n"))
  }

  list(sweeps = sweeps, crossover_idx = crossover_idx, mc_se = mc_se)
}

# ============================================================
# Write text results
# ============================================================
write_core_results <- function(summaries, results_list, n_reps, filepath) {
  con <- file(filepath, "w")
  writeLines("=== Score-Stratified Log-Rank Simulation Results (Core) ===\n", con)
  writeLines(sprintf("Replicates: %d\n", n_reps), con)
  writeLines(paste("Date:", Sys.time()), con)
  writeLines("\n", con)

  # Power table
  writeLines("--- Power (p < 0.05) ---\n", con)
  header <- sprintf("%-20s", "Scenario")
  for (m in method_labels) header <- paste0(header, sprintf(" %10s", m))
  header <- paste0(header, sprintf(" %10s", "CoxExt"))
  header <- paste0(header, sprintf(" %10s", "CoxCal"))
  writeLines(header, con)
  writeLines(strrep("-", 20 + 11 * (n_methods + 2)), con)

  for (s in 1:7) {
    su <- summaries[[s]]
    sc <- scenarios[[s]]
    line <- sprintf("%-20s", sc$name)
    line <- paste0(line, sprintf(" %10.4f", su$p_std))
    line <- paste0(line, sprintf(" %10.4f", su$p_ext))
    line <- paste0(line, sprintf(" %10.4f", su$p_rccal))
    line <- paste0(line, sprintf(" %10.4f", su$p_enetq))
    line <- paste0(line, sprintf(" %10.4f", su$p_enetcox))
    line <- paste0(line, sprintf(" %10.4f", su$p_orc))
    line <- paste0(line, sprintf(" %10.4f", su$p_trend))
    line <- paste0(line, sprintf(" %10.4f", su$cx_ext))
    line <- paste0(line, sprintf(" %10.4f", su$cx_cal))
    writeLines(line, con)
  }

  # Efficiency ratio table
  writeLines("\n\n--- Cox-to-Log-Rank Efficiency Ratios ---\n", con)
  writeLines(sprintf("%-20s %12s %12s %12s %12s %12s %12s",
                     "Scenario", "Std", "Ext", "Cal", "ENET", "Orc", "Trend"), con)
  writeLines(strrep("-", 92), con)
  for (s in 1:7) {
    su <- summaries[[s]]
    sc <- scenarios[[s]]
    eff_std <- su$cx_std / max(su$p_std, 0.001)
    eff_ext <- su$cx_ext / max(su$p_ext, 0.001)
    eff_cal <- su$cx_cal / max(su$p_rccal, 0.001)
    eff_enet <- su$cx_ext / max(su$p_enetq, 0.001)
    eff_orc <- su$cx_orc / max(su$p_orc, 0.001)
    eff_trend <- su$cx_ext / max(su$p_trend, 0.001)
    writeLines(sprintf("%-20s %12.3f %12.3f %12.3f %12.3f %12.3f %12.3f",
                       sc$name, eff_std, eff_ext, eff_cal, eff_enet, eff_orc, eff_trend), con)
  }

  # Type I error
  writeLines("\n\n--- Type I Error (Scenario 5: Null) ---\n", con)
  writeLines(sprintf("Target: 0.05\tn = %d\tnull scenario precision: ±%.4f\n",
                     n_reps, 1.96 * sqrt(0.05 * 0.95 / n_reps)), con)
  su5 <- summaries[[5]]
  t1 <- c(su5$p_std, su5$p_ext, su5$p_rccal, su5$p_enetq,
          su5$p_enetcox, su5$p_orc, su5$p_trend)
  for (m in 1:7) {
    writeLines(sprintf("  %-12s %8.4f", method_labels[m], t1[m]), con)
  }
  writeLines(sprintf("  %-12s %8.4f", "Cox-Std", su5$cx_std), con)
  writeLines(sprintf("  %-12s %8.4f", "Cox-Ext", su5$cx_ext), con)
  writeLines(sprintf("  %-12s %8.4f", "Cox-Cal", su5$cx_cal), con)
  writeLines(sprintf("  %-12s %8.4f", "Cox-Orc", su5$cx_orc), con)

  # Sparse strata
  writeLines("\n\n--- Sparse Strata Diagnostics ---\n", con)
  writeLines(sprintf("%-20s %30s %25s %15s",
                     "Scenario", "Ext score", "Cal score", "ENET score"), con)
  writeLines(sprintf("%-20s %10s %9s %8s %9s %8s %9s",
                     "", "N_strata", "min_ev", "N_strata", "min_ev", "N_strata", "min_ev"), con)
  writeLines(strrep("-", 80), con)
  for (s in 1:7) {
    su <- summaries[[s]]
    sc <- scenarios[[s]]
    writeLines(sprintf("%-20s %10.1f %9.1f %8.1f %9.1f %8.1f %9.1f",
                       sc$name,
                       su$ext_ns_mean, su$ext_min_mean,
                       su$cal_ns_mean, su$cal_min_mean,
                       su$enet_ns_mean, su$enet_min_mean), con)
  }

  writeLines("\n\n--- Sparsity Rate (>0 arms with <2 events, % of reps) ---\n", con)
  writeLines(sprintf("%-20s %10s %10s %10s %10s",
                     "Scenario", "Ext %", "Cal %", "Ora %", "ENET %"), con)
  for (s in 1:7) {
    su <- summaries[[s]]
    sc <- scenarios[[s]]
    writeLines(sprintf("%-20s %10.1f %10.1f %10.1f %10.1f",
                       sc$name,
                       su$ext_sparse_pct, su$cal_sparse_pct,
                       su$orc_sparse_pct, su$enet_sparse_pct), con)
  }

  # Mean events
  writeLines("\n\n--- Mean Events per Scenario ---\n", con)
  for (s in 1:7) {
    sc <- scenarios[[s]]
    writeLines(sprintf("  %-20s %.0f", sc$name, summaries[[s]]$mean_events), con)
  }

  close(con)
  cat(sprintf("\nCore results written to %s\n", filepath))
}

write_threshold_results <- function(sweep_result, n_reps, filepath) {
  con <- file(filepath, "w")
  writeLines("=== Miscalibration Threshold Sweep ===\n", con)
  writeLines(sprintf("Replicates per multiplier: %d\n", n_reps), con)
  writeLines(paste("Date:", Sys.time()), con)
  writeLines("\nSeverity multipliers tested: ", con)
  writeLines(paste(sapply(sweep_result$sweeps, `[[`, "multiplier"), collapse = ", "), con)
  writeLines("\n", con)

  # Table
  writeLines(sprintf("%-10s %10s %10s %10s %10s %10s %10s %8s",
                     "Multiplier", "Std", "Ext", "RCal", "ENETQ", "ENETCox", "Delta-C", "C_ext"), con)
  writeLines(strrep("-", 76), con)
  for (sw in sweep_result$sweeps) {
    writeLines(sprintf("%-10.2f %10.4f %10.4f %10.4f %10.4f %10.4f %8.3f %8.3f",
                       sw$multiplier, sw$power_std, sw$power_ext,
                       sw$power_rccal, sw$power_enetq, sw$power_enetcox,
                       sw$delta_c, sw$c_ext), con)
  }

  # Crossover
  writeLines("\n\n--- Crossover Analysis ---\n", con)
  writeLines(sprintf("MC SE (2x) threshold: %.4f\n", 2 * sweep_result$mc_se), con)
  if (!is.na(sweep_result$crossover_idx)) {
    sw <- sweep_result$sweeps[[sweep_result$crossover_idx]]
    writeLines(sprintf("Crossover at multiplier %.2f:\n", sw$multiplier), con)
    writeLines(sprintf("  Power(Standard)=%.4f\n", sw$power_std), con)
    writeLines(sprintf("  Power(External)=%.4f\n", sw$power_ext), con)
    writeLines(sprintf("  Power(Ridge-Cal)=%.4f\n", sw$power_rccal), con)
    writeLines(sprintf("  Power(ENET-Quartile)=%.4f\n", sw$power_enetq), con)
    writeLines(sprintf("  ΔC at crossover=%.3f\n", sw$delta_c), con)
  } else {
    writeLines("No crossover observed: Ridge-Cal power exceeded Standard + 2*MC_SE at all tested levels.\n", con)
  }

  close(con)
  cat(sprintf("Threshold sweep results written to %s\n", filepath))
}

# ============================================================
# Main
# ============================================================
args <- commandArgs(trailingOnly = TRUE)
n_reps_core <- if (length(args) >= 1) as.integer(args[1]) else 10000
n_reps_sweep <- if (length(args) >= 2) as.integer(args[2]) else 2000

cat("=== Score-Stratified Log-Rank Simulation (Final) ===\n")
cat(sprintf("Core reps: %d  |  Sweep reps: %d\n", n_reps_core, n_reps_sweep))
cat(sprintf("Available cores: %d\n\n", future::availableCores()))

n_workers <- min(11, future::availableCores() - 1)
plan(multisession, workers = n_workers)
cat(sprintf("Using %d workers\n\n", n_workers))

output_dir <- normalizePath(file.path(script_dir, "..", "output"), mustWork = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# ---- Phase 1: Core simulation ----
if (n_reps_core > 0) {
  cat("========================================\n")
  cat("Phase 1: Core Simulation (7 scens)\n")
  cat("========================================\n")

  all_results <- list()
  summaries <- list()

  for (s in 1:7) {
    res <- run_scenario(s, n_reps_core)
    all_results[[s]] <- res$res_mat
    summaries[[s]] <- summarize_results(res$res_mat)

    su <- summaries[[s]]
    sc <- scenarios[[s]]
    cat(sprintf("  Power: Std=%.3f Ext=%.3f RCal=%.3f ENETQ=%.3f ENETCox=%.3f Orac=%.3f Trend=%.3f\n",
                su$p_std, su$p_ext, su$p_rccal, su$p_enetq, su$p_enetcox,
                su$p_orc, su$p_trend))
    cat(sprintf("  Cox: Std=%.3f Ext=%.3f Cal=%.3f Orac=%.3f\n",
                su$cx_std, su$cx_ext, su$cx_cal, su$cx_orc))
    cat(sprintf("  Events=%.0f Sparse: Ext=%.1f%% Cal=%.1f%% ENET=%.1f%%\n",
                su$mean_events, su$ext_sparse_pct, su$cal_sparse_pct, su$enet_sparse_pct))
    flush(stdout())
  }

  # Save full RDS
  rds_path <- file.path(output_dir, "logrank-sim-results.rds")
  saveRDS(all_results, file = rds_path)
  cat(sprintf("\nFull results saved to %s\n", rds_path))

  # Write text summary
  write_core_results(summaries, all_results, n_reps_core,
                     file.path(output_dir, "logrank-sim-results.txt"))
}

# ---- Phase 2: Threshold sweep ----
if (n_reps_sweep > 0) {
  sweep_result <- run_threshold_sweep(n_reps_sweep)
  write_threshold_results(sweep_result, n_reps_sweep,
                          file.path(output_dir, "logrank-threshold-results.txt"))
}

cat("\n=== Done. ===\n")
