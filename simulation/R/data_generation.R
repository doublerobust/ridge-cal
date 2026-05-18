# ============================================================
# R/data_generation.R — Data generation for simulation study
# ============================================================
# Author: Yue Shentu
#
# Design rationale:
# - External data: 20 baseline covariates, many prognostic.
#   External model is strongly predictive (C-index ~0.80).
# - Trial data: same covariates, but some coefficients shift.
#   Phase II calibration detects the largest shifts.
# - Cox-Standard: only 2 stratification vars (ECOG, sex).
#   Represents limited traditional covariate adjustment.
# - Within-trial ML (TMLE-SL): uses 20 covariates but only n=400,
#   so it cannot match the external model's predictive accuracy.
# ============================================================

library(survival)

# ---- Global defaults ----
default_params <- list(
  n_ext     = 2000,      # External dataset size (large for good external model)
  n_1       = 100,       # Phase II sample size
  n_2       = 400,       # Phase III sample size
  n_sim     = 1000,      # Number of simulation replicates
  alpha     = 0.05,      # Two-sided significance level
  tau       = 12,        # Time horizon for marginal effects (months)
  admin_cens = 24,       # Administrative censoring time (months)
  dropout_rate = 0.03,   # Annual random dropout rate
  seed_base = 20260517,  # Base random seed
  pi        = 0.5        # Randomization probability
)

# ---- 1. Covariate generation ----
generate_covariates <- function(n, n_prog = 20) {
  # Generate n_prog baseline covariates:
  # - 10 continuous (labs, biomarkers, imaging features)
  # - 5 binary (sex, prior treatment, genetic markers)
  # - 5 ordinal (ECOG, tumor stage, smoking, etc.)
  #
  # All covariates are standardized to N(0,1) or centered binary.
  # This makes the linear predictor scale consistent.

  n_cont <- 10
  n_bin <- 5
  n_ord <- 5
  stopifnot(n_prog == n_cont + n_bin + n_ord)

  df <- data.frame(
    # Continuous: mix of normal, lognormal, and Poisson-like
    age    = (rnorm(n, 65, 10) - 65) / 10,                     # standardized age
    bmi    = (rnorm(n, 28, 5) - 28) / 5,                       # standardized BMI
    crp    = (log(rlnorm(n, 0, 0.8)) - 0) / 0.8,               # log CRP, standardized
    albumin = (rnorm(n, 4.0, 0.5) - 4.0) / 0.5,               # standardized albumin
    creatinine = (log(rlnorm(n, 0, 0.4)) - 0) / 0.4,           # log creatinine
    wbc    = (rnorm(n, 7.5, 2) - 7.5) / 2,                     # standardized WBC
    hgb    = (rnorm(n, 13, 1.5) - 13) / 1.5,                   # standardized hemoglobin
    neutro = (rnorm(n, 4.5, 1.5) - 4.5) / 1.5,                 # standardized neutrophils
    platelets = (rnorm(n, 250, 75) - 250) / 75,                # standardized platelets
    ldh    = (log(rlnorm(n, 0, 0.6)) - 0) / 0.6,               # log LDH, standardized

    # Binary
    sex      = rbinom(n, 1, 0.5) - 0.5,                        # centered
    prior_tx = rbinom(n, 1, 0.3) - 0.3,                        # centered
    egfr_low = rbinom(n, 1, 0.15) - 0.15,                      # centered
    smoking  = rbinom(n, 1, 0.4) - 0.4,                        # centered
    marker_x = rbinom(n, 1, 0.25) - 0.25,                      # centered

    # Ordinal
    ecog      = (sample(0:2, n, replace = TRUE, prob = c(0.5, 0.4, 0.1)) - 1),
    tumor_stage = (sample(1:4, n, replace = TRUE, prob = c(0.1, 0.3, 0.4, 0.2)) - 2.5) / 1.5,
    comorbidity = (sample(0:3, n, replace = TRUE, prob = c(0.4, 0.3, 0.2, 0.1)) - 1.5) / 1.5,
    symptom_score = (sample(0:5, n, replace = TRUE, prob = c(0.2, 0.2, 0.2, 0.15, 0.15, 0.1)) - 2.5) / 1.5,
    frailty  = (sample(0:2, n, replace = TRUE, prob = c(0.6, 0.3, 0.1)) - 0.5) / 0.5
  )

  df
}

# ---- 2. True coefficient vectors ----
# External model: all 20 covariates are prognostic.
# Trial model: same covariates but some coefficients shift significantly.
#
# Coefficient magnitudes chosen so the LP SD ≈ 1.2-1.4 (C-index ≈ 0.80).
# This means the worst-vs-best HR is roughly exp(±2.5) ≈ 0.08 to 12.5.

get_beta_prog <- function() {
  # Trial population coefficients.
  # LP SD ≈ 1.35 → C-index ≈ 0.82, strongly prognostic.
  # Worst-vs-best HR ≈ exp(±2.5) ≈ 0.08 to 12.
  c(
    # Continuous (10)
    age        =  0.20,
    bmi        = -0.10,
    crp        =  0.35,
    albumin    = -0.40,
    creatinine =  0.15,
    wbc        =  0.25,
    hgb        = -0.28,
    neutro     =  0.20,
    platelets  =  0.14,
    ldh        =  0.45,

    # Binary (5)
    sex        =  0.00,    # not prognostic in trial
    prior_tx   =  0.28,
    egfr_low   =  0.35,
    smoking    =  0.20,
    marker_x   = -0.55,    # strongly protective

    # Ordinal (5)
    ecog         =  0.40,
    tumor_stage  =  0.35,
    comorbidity  =  0.20,
    symptom_score =  0.28,
    frailty      =  0.28
  )
}

get_beta_ext <- function(shift = "none") {
  bp <- get_beta_prog()

  # Key shifts (change in coefficient from trial to external):
  #   sex: 0 → 0.30      (not prognostic → strongly prognostic)
  #   marker_x: -0.55 → 0.20  (strongly protective → harmful)
  #   crp: 0.35 → 0.55   (stronger externallly)
  #   albumin: -0.40 → -0.15 (weaker externally)
  #   ldh: 0.45 → 0.65   (stronger externally)

  delta_mod <- c(
    0, 0, 0.08, 0.10, 0, 0, 0, 0, 0, 0.08,  # continuous
    0.15, 0, 0, 0, 0.30,                      # binary: sex +0.15, marker_x +0.30
    0.05, 0.05, 0, 0, 0                      # ordinal
  )

  delta_sev <- c(
    0, 0, 0.20, 0.25, 0, 0, 0, 0, 0, 0.20,  # continuous
    0.30, 0, 0, 0, 0.75,                      # binary: sex +0.30, marker_x +0.75 (flip!)
    0.10, 0.10, 0, 0.08, 0                   # ordinal
  )

  switch(shift,
    none     = bp,
    moderate = bp + delta_mod,
    severe   = bp + delta_sev,
    bp)
}

# ---- 3. Weibull baseline hazard ----
# Median survival ~10 months for an average patient (lp=0).
# With admin censoring at 24 months, ~60-70% events by month 12.
# Weibull: S(t) = exp(-(t/scale)^shape), median = scale * log(2)^(1/shape)
# shape=1.5 → log(2)^(2/3) ≈ 0.77, scale = 10 / 0.77 ≈ 13
get_weibull_params <- function(population = "trial", shift = "none") {
  base <- list(shape = 1.5, scale = 13)
  if (population == "external") {
    switch(shift,
      none     = list(shape = 1.5, scale = 13),
      moderate = list(shape = 1.5, scale = 11),
      severe   = list(shape = 1.5, scale =  9),
      base)
  } else {
    base
  }
}

# ---- 4. Linear predictor ----
# Covariates are already standardized/centered in generate_covariates().
# LP = sum(beta_i * X_i)
compute_lp <- function(W, beta, beta_trt = NULL, A = NULL) {
  # Match covariate names in W to names in beta
  common <- intersect(names(W), names(beta))
  lp <- as.matrix(W[, common, drop = FALSE]) %*% beta[common]

  if (!is.null(beta_trt) && !is.null(A))
    lp <- lp + A * beta_trt

  as.numeric(lp)
}

# ---- 5. Survival and censoring ---
generate_survival_time <- function(n, lp, shape, scale) {
  rweibull(n, shape = shape, scale = scale * exp(-lp / shape))
}

generate_censoring <- function(n, tau_max = 24, dropout_rate = 0.03) {
  C_admin <- rep(tau_max, n)
  C_dropout <- rexp(n, rate = -log(1 - dropout_rate) / 12)
  pmin(C_admin, C_dropout)
}

# ---- 6. Main data generation ----
generate_data <- function(n, beta_trt, beta_prog, shape, scale,
                           pi = 0.5, tau_max = 24, dropout_rate = 0.03) {
  W <- generate_covariates(n)
  A <- rbinom(n, 1, pi)
  lp <- compute_lp(W, beta_prog, beta_trt, A)

  T_death <- generate_survival_time(n, lp, shape, scale)
  C <- generate_censoring(n, tau_max, dropout_rate)
  T_obs <- pmin(T_death, C)
  delta <- as.numeric(T_death <= C)

  list(W = W, A = A, T = T_obs, delta = delta, lp = lp)
}

# ---- 7. External data generation ----
generate_external_data <- function(n_ext, beta_ext, shape, scale) {
  W <- generate_covariates(n_ext)
  lp_W <- compute_lp(W, beta_ext)
  T_death <- rweibull(n_ext, shape = shape, scale = scale * exp(-lp_W / shape))
  C <- rep(24, n_ext)
  T_obs <- pmin(T_death, C)
  delta <- as.numeric(T_death <= C)
  list(W = W, T = T_obs, delta = delta)
}

# ---- 8. (removed: get_scenario_config — superseded by per-runner scenario definitions)
# The simulation runners (run_clean.R, run_standalone.R) hardcode their
# 7 scenarios directly, with scenario IDs mapping to:
#   1 = No shift, 2 = Moderate, 3 = Severe, 4 = Interaction,
#   5 = Null, 6 = Non-PH, 7 = Small HR
