# Simulation Plan: Phase II-Calibrated Prognostic Scores with TMLE

**Author:** Yue Shentu  
**Date:** May 2026  
**Status:** Implementation draft

---

## Overview

This document provides a detailed, self-contained simulation plan for evaluating the proposed method. It covers data generation, analysis pipelines, comparison methods, evaluation metrics, and reporting templates. The plan is designed to be directly implementable in R.

---

## 1. Simulation Parameters

### 1.1 Global Defaults

| Parameter | Default | Description |
|-----------|---------|-------------|
| `n_ext` | 1000 | External dataset size |
| `n_1` | 100 | Phase II sample size |
| `n_2` | 400 | Phase III sample size |
| `n_sim` | 1000 | Number of simulation replicates |
| `alpha` | 0.05 | Two-sided significance level |
| `tau` | 12 | Time horizon for marginal effects (months) |
| `admin_cens` | 24 | Administrative censoring time (months) |
| `dropout_rate` | 0.05 | Annual random dropout rate |
| `K_folds` | 5 | Cross-fitting folds |
| `M_imp` | 100 | Posterior draws for multiple imputation |
| `mcmc_chains` | 4 | MCMC chains for Bayesian calibration |
| `mcmc_iter` | 2000 | MCMC iterations per chain |
| `mcmc_warmup` | 1000 | MCMC warmup iterations |
| `seed_base` | 20260517 | Base random seed (increment by 1 per replicate) |

### 1.2 Covariate Generation

All covariates are drawn independently across patients unless noted.

```r
generate_covariates <- function(n, p_high = 0) {
  # Returns data.frame with n rows
  list(
    # Demographics
    age     = rnorm(n, mean = 60, sd = 10),          # years
    sex     = rbinom(n, 1, 0.5),                     # 0 = female, 1 = male

    # Biomarkers
    pdl1    = rlnorm(n, meanlog = 0, sdlog = 1),     # PD-L1 expression
    tmb     = rpois(n, lambda = 10),                 # tumor mutational burden

    # Imaging
    tumor_vol = rlnorm(n, meanlog = 5, sdlog = 1),   # mm³
    n_met    = rpois(n, lambda = 3),                 # number of metastases

    # Clinical
    ecog    = sample(0:2, n, replace = TRUE, prob = c(0.4, 0.4, 0.2)),
    prior_lines = rpois(n, lambda = 2)               # prior lines of therapy
  )
}
```

For **Scenario 10** (high-dimensional), generate an additional `p = 100` covariates with AR(1) correlation:

```r
generate_highdim_covariates <- function(n, p = 100, rho = 0.3) {
  Sigma <- rho^abs(outer(1:p, 1:p, "-"))
  L <- t(chol(Sigma))
  X <- matrix(rnorm(n * p), n, p) %*% L
  colnames(X) <- paste0("X", 1:p)
  X
}
```

### 1.3 True Coefficient Vectors

For the 8 baseline covariates, the true log-hazard ratios are:

| Covariate | `beta_prog` (trial) | `beta_ext` (no shift) | `beta_ext` (moderate) | `beta_ext` (severe) |
|-----------|--------------------|-----------------------|-----------------------|---------------------|
| age | 0.010 | 0.010 | 0.0085 | 0.006 |
| sex | 0.200 | 0.200 | 0.170 | 0.120 |
| pdl1 | -0.150 | -0.150 | -0.172 | -0.210 |
| tmb | -0.050 | -0.050 | -0.043 | -0.030 |
| tumor_vol | 0.080 | 0.080 | 0.068 | 0.048 |
| n_met | 0.120 | 0.120 | 0.138 | 0.168 |
| ecog=1 | 0.300 | 0.300 | 0.345 | 0.420 |
| ecog=2 | 0.600 | 0.600 | 0.690 | 0.840 |
| prior_lines | 0.050 | 0.050 | 0.058 | 0.070 |

For Scenario 10, the 8 non-zero coefficients among the 100 high-dimensional covariates are randomly selected within each replicate to avoid cherry-picking.

### 1.4 Weibull Baseline Hazard Parameters

| Scenario | External shape | External scale | Trial shape | Trial scale |
|----------|---------------|---------------|-------------|-------------|
| 1 (no shift) | 1.5 | 0.010 | 1.5 | 0.010 |
| 2 (moderate) | 1.5 | 0.008 | 1.5 | 0.010 |
| 3 (severe) | 1.5 | 0.005 | 1.5 | 0.010 |
| 4-11 | 1.5 | 0.008 | 1.5 | 0.010 |

---

## 2. Data Generation Pipeline

### 2.1 External Data

```r
generate_external_data <- function(n_ext, beta_ext, shape_ext, scale_ext) {
  W <- generate_covariates(n_ext)
  beta_W <- as.matrix(W) %*% beta_ext
  T_death <- rweibull(n_ext, shape = shape_ext,
                      scale = scale_ext * exp(-beta_W / shape_ext))
  # Administrative censoring
  C <- rep(24, n_ext)
  T_obs <- pmin(T_death, C)
  delta <- as.numeric(T_death <= C)

  list(W = W, T = T_obs, delta = delta, beta_W = beta_W)
}
```

### 2.2 Phase II and Phase III Data

```r
generate_trial_data <- function(n, beta_trt, beta_prog, shape, scale,
                                 randomization_ratio = 0.5) {
  W <- generate_covariates(n)
  A <- rbinom(n, 1, randomization_ratio)

  # Linear predictor
  lp <- A * beta_trt + as.matrix(W) %*% beta_prog
  T_death <- rweibull(n, shape = shape,
                      scale = scale * exp(-lp / shape))

  # Censoring: administrative + random dropout
  C_admin <- rep(admin_cens, n)
  C_dropout <- rexp(n, rate = -log(1 - dropout_rate) / 12)  # monthly rate
  C <- pmin(C_admin, C_dropout)

  T_obs <- pmin(T_death, C)
  delta <- as.numeric(T_death <= C)

  list(W = W, A = A, T = T_obs, delta = delta, lp = lp)
}
```

### 2.3 Non-Proportional Hazards (Scenarios 6-7)

For piecewise exponential hazards:

```r
generate_piecewise_exponential <- function(n, beta_trt, beta_prog, W,
                                            breakpoints, hr_by_period,
                                            baseline_hazard = 0.01) {
  A <- rbinom(n, 1, 0.5)
  lp <- A * 0 + as.matrix(W) %*% beta_prog  # prognostic component only

  # Build baseline hazard function
  # For each patient, determine which period they fall into
  # Draw survival time using inverse-CDF method for piecewise exponential
  T_death <- numeric(n)
  for (i in 1:n) {
    t <- 0
    survived <- TRUE
    while (survived) {
      for (k in seq_along(breakpoints)) {
        if (t >= breakpoints[k]) next
        t_end <- if (k < length(breakpoints)) breakpoints[k+1] else Inf
        hr <- if (A[i] == 1) hr_by_period[k] else 1
        rate <- baseline_hazard * hr * exp(lp[i])
        t_candidate <- t + rexp(1, rate)
        if (t_candidate < t_end) {
          T_death[i] <- t_candidate
          survived <- FALSE
          break
        } else {
          t <- t_end
        }
      }
      if (is.infinite(t)) { T_death[i] <- Inf; break }
    }
  }

  C <- rep(admin_cens, n)
  T_obs <- pmin(T_death, C)
  delta <- as.numeric(T_death <= C)

  list(W = W, A = A, T = T_obs, delta = delta)
}

# Scenario 6: delayed effect (HR=1 for 0-4mo, then HR=0.60)
# Scenario 7: diminishing effect (HR=0.50 for 0-6mo, then HR=0.90)
```

### 2.4 Informative Censoring (Scenario 8)

```r
generate_informative_censoring <- function(n, beta_trt, beta_prog, shape, scale) {
  W <- generate_covariates(n)
  A <- rbinom(n, 1, 0.5)

  # Event time (same as before)
  lp <- A * beta_trt + as.matrix(W) %*% beta_prog
  T_death <- rweibull(n, shape = shape,
                      scale = scale * exp(-lp / shape))

  # Censoring depends on tumor volume
  cens_rate <- 0.02 * exp(0.5 * scale(W$tumor_vol))  # standardized tumor vol
  C <- rexp(n, rate = cens_rate)

  T_obs <- pmin(T_death, C)
  delta <- as.numeric(T_death <= C)

  list(W = W, A = A, T = T_obs, delta = delta)
}
```

---

## 3. Analysis Methods — Implementation Details

### 3.1 Training the External Prognostic Model

```r
train_prognostic_model <- function(W_ext, T_ext, delta_ext) {
  # Use SuperLearner with Cox PH loss
  # Candidate learners: Cox with selected covariates, ridge Cox, lasso Cox,
  # random survival forest, gradient boosted Cox
  #
  # Returns: a function S_hat(W) -> predicted log-hazard under control

  library(SuperLearner)
  library(glmnet)
  library(ranger)
  library(xgboost)

  # Cox PH with all covariates (base learner)
  fit_cox <- coxph(Surv(T, delta) ~ ., data = cbind(W_ext, T = T_ext, delta = delta_ext))
  S_ext <- predict(fit_cox, type = "lp")

  # Return both the SuperLearner ensemble and individual predictors
  # For simplicity in simulations, use Cox PH as the working model
  # (SuperLearner used for robustness checks)

  list(
    fit = fit_cox,
    predict = function(W_new) {
      predict(fit_cox, newdata = W_new, type = "lp")
    }
  )
}
```

### 3.2 Bayesian Calibration (Section 3.3 of proposal)

```r
calibrate_prognostic_score <- function(W_ext, T_ext, delta_ext,
                                        W_II, T_II, delta_II, A_II) {
  # We need to be careful: the external model is a Cox PH on W (no A),
  # the phase II model is a Cox PH on W + A.
  #
  # For calibration, we extract beta_W from the external fit,
  # place a Bayesian prior on beta, and update using phase II controls only.
  #
  # In practice, we fit:
  #   Phase II controls: Cox PH on W only
  #   Prior: N(beta_ext, I_prior) where I_prior is the observed Fisher info
  #          from the external fit (scaled by n_ext/n_II for commensurability)

  library(rstan)

  # Stan model code (stored separately)
  stan_model <- "
  data {
    int<lower=0> N_ext;
    int<lower=0> N_II;
    int<lower=0> P;
    matrix[N_ext, P] X_ext;
    vector[N_ext] T_ext;
    array[N_ext] int<lower=0, upper=1> delta_ext;
    matrix[N_II, P] X_II;
    vector[N_II] T_II;
    array[N_II] int<lower=0, upper=1> delta_II;
    vector[P] mu_beta;
    matrix[P, P] Sigma_beta;
  }
  parameters {
    vector[P] beta;
  }
  model {
    // Prior from external data
    target += multi_normal_lpdf(beta | mu_beta, Sigma_beta);

    // Phase II likelihood (controls only)
    target += cox_ph_lpdf(T_II, delta_II, X_II * beta);
  }
  "

  # Fit Stan model
  fit <- sampling(stan_model,
    data = list(
      N_ext = nrow(W_ext),
      N_II = sum(A_II == 0),  # controls only
      P = ncol(W_ext),
      X_ext = as.matrix(W_ext),
      T_ext = T_ext,
      delta_ext = delta_ext,
      X_II = as.matrix(W_II[A_II == 0, ]),
      T_II = T_II[A_II == 0],
      delta_II = delta_II[A_II == 0],
      mu_beta = coef(external_fit),
      Sigma_beta = vcov(external_fit) * nrow(W_ext) / sum(A_II == 0)
    ),
    chains = mcmc_chains,
    iter = mcmc_iter,
    warmup = mcmc_warmup,
    refresh = 0
  )

  # Extract posterior samples of beta
  beta_samples <- extract(fit, "beta")$beta  # (n_samples x P)

  # Calibrated score: posterior mean of beta^T W
  S_cal_III <- function(W_III) {
    beta_mean <- colMeans(beta_samples)
    as.matrix(W_III) %*% beta_mean
  }

  # For multiple imputation, return all samples
  list(
    beta_samples = beta_samples,
    predict = S_cal_III,
    predict_samples = function(W_new, n_samples = 100) {
      idx <- sample(nrow(beta_samples), n_samples)
      sapply(idx, function(i) as.matrix(W_new) %*% beta_samples[i, ])
    }
  )
}
```

### 3.3 Cox PH Model with Calibrated Score (Primary Analysis)

```r
analyze_cox_calibrated <- function(W_III, A_III, T_III, delta_III, S_cal) {
  df <- data.frame(
    T = T_III, delta = delta_III, A = A_III, S = as.numeric(S_cal)
  )
  fit <- coxph(Surv(T, delta) ~ A + S, data = df, robust = TRUE)

  list(
    beta_trt = coef(fit)["A"],
    se_beta = sqrt(vcov(fit)["A", "A"]),
    hr = exp(coef(fit)["A"]),
    ci_lower = exp(coef(fit)["A"] - 1.96 * sqrt(vcov(fit)["A", "A"])),
    ci_upper = exp(coef(fit)["A"] + 1.96 * sqrt(vcov(fit)["A", "A"])),
    p_value = summary(fit)$coefficients["A", "Pr(>|z|)"]
  )
}
```

### 3.4 TMLE for Marginal Survival Difference (Efficient Analysis)

```r
analyze_tmle_calibrated <- function(W_III, A_III, T_III, delta_III,
                                     S_cal, tau = 12) {
  # Step 1: Initial Cox model
  df <- data.frame(T = T_III, delta = delta_III, A = A_III, S = as.numeric(S_cal))
  init_fit <- coxph(Surv(T, delta) ~ A + S, data = df)
  beta_init <- coef(init_fit)["A"]
  beta_S <- coef(init_fit)["S"]

  # Breslow baseline hazard estimate
  bh <- basehaz(init_fit, centered = FALSE)

  # Step 2: Conditional survival at tau under each treatment
  get_S_a <- function(a_val) {
    # For each patient, S(tau | A=a, S_cal)
    H0_tau <- bh$hazard[which.min(abs(bh$time - tau))]
    exp(-H0_tau * exp(a_val * beta_init + as.numeric(S_cal) * beta_S))
  }
  S1_initial <- sapply(A_III, function(a) get_S_a(1))
  S0_initial <- sapply(A_III, function(a) get_S_a(0))

  # Step 3: Clever covariate
  pi_hat <- mean(A_III)
  H <- A_III / pi_hat - (1 - A_III) / (1 - pi_hat)

  # Step 4: Fluctuation — fit epsilon via Cox with offset
  # Keep beta_A and beta_S fixed, estimate epsilon
  offset_term <- beta_init * A_III + beta_S * as.numeric(S_cal)

  # Use standard Cox with offset
  fluctuated_fit <- coxph(
    Surv(T_III, delta_III) ~ offset(offset_term) + H,
    data = df
  )
  epsilon_hat <- coef(fluctuated_fit)

  # Step 5: Update survival curves
  get_S_a_updated <- function(a_val) {
    H_val <- a_val / pi_hat - (1 - a_val) / (1 - pi_hat)
    exp(-H0_tau * exp(a_val * beta_init + as.numeric(S_cal) * beta_S +
                      epsilon_hat * H_val))
  }
  S1_tmle <- mean(sapply(A_III, function(a) get_S_a_updated(1)))
  S0_tmle <- mean(sapply(A_III, function(a) get_S_a_updated(0)))

  psi_tmle <- S1_tmle - S0_tmle

  # Step 6: Variance via influence function
  # (Simplified: use bootstrap for variance in simulations;
  #  analytical IF variance used in the paper)
  G_hat <- survfit(Surv(T_III, 1 - delta_III) ~ 1)  # KM for censoring
  G_tau <- summary(G_hat, times = tau)$surv

  IC <- H * (as.numeric(T_III > tau & delta_III == 1) / G_tau -
             (S1_tmle - S0_tmle)) - psi_tmle
  var_psi <- var(IC) / length(A_III)

  list(
    psi = psi_tmle,
    se = sqrt(var_psi),
    ci_lower = psi_tmle - 1.96 * sqrt(var_psi),
    ci_upper = psi_tmle + 1.96 * sqrt(var_psi),
    epsilon = epsilon_hat,
    S1 = S1_tmle,
    S0 = S0_tmle
  )
}
```

### 3.5 AIPW Estimator

```r
analyze_aipw <- function(W_III, A_III, T_III, delta_III, S_cal, tau = 12) {
  # Fit propensity score (known, but estimate for finite-sample adjustment)
  pi_hat <- mean(A_III)

  # Fit outcome models
  df <- data.frame(T = T_III, delta = delta_III, A = A_III, S = as.numeric(S_cal))
  fit <- coxph(Surv(T, delta) ~ A + S, data = df)
  beta_trt <- coef(fit)["A"]
  beta_S <- coef(fit)["S"]
  bh <- basehaz(fit, centered = FALSE)
  H0_tau <- bh$hazard[which.min(abs(bh$time - tau))]

  # Conditional survival
  S_1_given_W <- exp(-H0_tau * exp(beta_trt + as.numeric(S_cal) * beta_S))
  S_0_given_W <- exp(-H0_tau * exp(0 + as.numeric(S_cal) * beta_S))

  # IPCW for censoring
  G_hat <- survfit(Surv(T_III, 1 - delta_III) ~ 1)
  G_tau <- summary(G_hat, times = tau)$surv

  # AIPW estimator
  ipcw_part <- (A_III / pi_hat) * as.numeric(T_III > tau) / G_tau -
               ((1 - A_III) / (1 - pi_hat)) * as.numeric(T_III > tau) / G_tau

  augmentation <- ((A_III / pi_hat) - ((1 - A_III) / (1 - pi_hat))) *
                   (S_1_given_W - S_0_given_W)

  psi <- mean(ipcw_part - augmentation)

  # Variance via influence function
  IC <- ipcw_part - augmentation - psi
  var_psi <- var(IC) / length(A_III)

  list(
    psi = psi,
    se = sqrt(var_psi),
    ci_lower = psi - 1.96 * sqrt(var_psi),
    ci_upper = psi + 1.96 * sqrt(var_psi)
  )
}
```

### 3.6 MAP Prior Borrowing (Bayesian Competitor)

```r
analyze_map_cox <- function(W_II, A_II, T_II, delta_II,
                             W_III, A_III, T_III, delta_III) {
  # Robust MAP prior on the treatment effect
  # Following Schmidli et al. (2014):
  #   Prior = w * N(mu_II, sigma_II^2) + (1-w) * N(0, sigma_vague^2)
  #
  # mu_II, sigma_II from phase II Cox model
  # w controls borrowing strength (estimated via commensurability)

  # Step 1: Fit phase II Cox model
  df_II <- data.frame(T = T_II, delta = delta_II, A = A_II)
  fit_II <- coxph(Surv(T, delta) ~ A, data = df_II)
  mu_II <- coef(fit_II)["A"]
  sigma_II <- sqrt(vcov(fit_II)["A", "A"])

  # Step 2: Robust MAP prior with vague component
  # w = I^2 / (I^2 + tau^2) where tau^2 is heterogeneity
  # For simplicity, use w = 0.5 (fixed robust mixture)
  w <- 0.5
  sigma_vague <- 2.0  # very vague

  # Step 3: Combine with phase III data
  # Posterior is mixture of two normals (not conjugate with Cox)
  # Approximate using MCMC or INLA
  #
  # For simulation purposes, use a simple approximation:
  # Fit phase III Cox model and combine with prior via normal approximation
  df_III <- data.frame(T = T_III, delta = delta_III, A = A_III)
  fit_III <- coxph(Surv(T, delta) ~ A, data = df_III)
  mu_III <- coef(fit_III)["A"]
  sigma_III <- sqrt(vcov(fit_III)["A", "A"])

  # Posterior mean (mixture approximation)
  post_prec_III <- 1 / sigma_III^2
  post_prec_prior <- w / sigma_II^2 + (1 - w) / sigma_vague^2
  post_mu <- (mu_III * post_prec_III + mu_II * post_prec_prior) /
             (post_prec_III + post_prec_prior)
  post_sigma <- sqrt(1 / (post_prec_III + post_prec_prior))

  list(
    beta_trt = post_mu,
    se = post_sigma,
    ci_lower = post_mu - 1.96 * post_sigma,
    ci_upper = post_mu + 1.96 * post_sigma,
    hr = exp(post_mu)
  )
}
```

### 3.7 RMST with Calibrated Score

```r
analyze_rmst_calibrated <- function(W_III, A_III, T_III, delta_III,
                                     S_cal, tau = 12) {
  library(riskRegression)

  # Pseudo-observation approach for RMST
  df <- data.frame(
    T = T_III, delta = delta_III, A = A_III,
    S = as.numeric(S_cal)
  )

  # RMST by pseudo-observations (Andersen et al., 2004)
  fit <- glm(Surv(T, delta) ~ A + S, data = df,
             family = "pseudo", time = tau)

  list(
    rmst_diff = coef(fit)["A"],
    se = sqrt(vcov(fit)["A", "A"]),
    ci_lower = coef(fit)["A"] - 1.96 * sqrt(vcov(fit)["A", "A"]),
    ci_upper = coef(fit)["A"] + 1.96 * sqrt(vcov(fit)["A", "A"])
  )
}
```

---

## 4. Master Simulation Loop

```r
run_scenario <- function(scenario_id, n_sim = 1000, seed_base = 20260517) {
  results <- list()

  for (s in 1:n_sim) {
    set.seed(seed_base + s)

    # 1. Resolve scenario parameters
    params <- get_scenario_params(scenario_id)

    # 2. Generate data
    ext_data <- generate_external_data(params$n_ext,
                                       params$beta_ext,
                                       params$shape_ext,
                                       params$scale_ext)

    trial_data <- switch(scenario_id,
      `6` = generate_piecewise_exponential(params$n_2, params$beta_trt,
               params$beta_prog, W, breakpoints = c(4, Inf),
               hr_by_period = c(1.0, 0.6)),
      `7` = generate_piecewise_exponential(params$n_2, params$beta_trt,
               params$beta_prog, W, breakpoints = c(6, Inf),
               hr_by_period = c(0.5, 0.9)),
      `8` = generate_informative_censoring(params$n_2, params$beta_trt,
               params$beta_prog, params$shape_trial, params$scale_trial),
      # Default: standard Cox PH generation
      generate_trial_data(params$n_2, params$beta_trt, params$beta_prog,
                          params$shape_trial, params$scale_trial)
    )

    # Phase II data (separate generation)
    phaseII <- generate_trial_data(params$n_1, params$beta_trt,
                                   params$beta_prog,
                                   params$shape_trial, params$scale_trial)

    # 3. Train external model
    ext_model <- train_prognostic_model(ext_data$W, ext_data$T, ext_data$delta)

    # 4. Calibrate
    cal <- calibrate_prognostic_score(ext_data$W, ext_data$T, ext_data$delta,
                                       phaseII$W, phaseII$T, phaseII$delta,
                                       phaseII$A)

    # 5. Generate scores for phase III
    S_ext <- ext_model$predict(trial_data$W)
    S_cal <- cal$predict(trial_data$W)

    # 6. Run all analysis methods
    results[[s]] <- list(
      # Baseline
      cox_std    = analyze_cox_standard(trial_data$W, trial_data$A,
                       trial_data$T, trial_data$delta),
      logrank    = analyze_logrank_stratified(trial_data$W, trial_data$A,
                       trial_data$T, trial_data$delta),

      # PROCOVA family
      procova_ext = analyze_cox_with_score(trial_data$A, trial_data$T,
                       trial_data$delta, S_ext),
      procova_sl  = analyze_cox_with_sl_score(trial_data$W, trial_data$A,
                       trial_data$T, trial_data$delta),
      cox_cal     = analyze_cox_calibrated(trial_data$W, trial_data$A,
                       trial_data$T, trial_data$delta, S_cal),

      # Efficient estimators
      aipw_ext  = analyze_aipw(trial_data$W, trial_data$A,
                       trial_data$T, trial_data$delta, S_ext),
      aipw_cal  = analyze_aipw(trial_data$W, trial_data$A,
                       trial_data$T, trial_data$delta, S_cal),
      tmle_sl   = analyze_tmle_superlearner(trial_data$W, trial_data$A,
                       trial_data$T, trial_data$delta),
      tmle_cal  = analyze_tmle_calibrated(trial_data$W, trial_data$A,
                       trial_data$T, trial_data$delta, S_cal),

      # Bayesian borrowing
      map_cox   = analyze_map_cox(phaseII$W, phaseII$A,
                       phaseII$T, phaseII$delta,
                       trial_data$W, trial_data$A,
                       trial_data$T, trial_data$delta),

      # RMST
      rmst_cal  = analyze_rmst_calibrated(trial_data$W, trial_data$A,
                       trial_data$T, trial_data$delta, S_cal),

      # Calibration diagnostics
      cal_diag  = list(
        ext_score = S_ext,
        cal_score = S_cal,
        beta_ext  = coef(ext_model$fit),
        beta_cal  = colMeans(cal$beta_samples)
      )
    )
  }

  # Aggregate results
  aggregate_results(results, scenario_id)
}
```

---

## 5. Output Tables

### 5.1 Main Results Table (one per scenario)

| Method | Bias | Emp. SE | Avg. SE | SE Ratio | MSE | RE | Power | Coverage | Conv. % |
|--------|------|---------|---------|----------|-----|-----|-------|----------|---------|
| Cox-Standard | | | | | | 1.00 | | | |
| Stratified LR | | | | | | | | | |
| PROCOVA (Ext) | | | | | | | | | |
| PROCOVA (SL) | | | | | | | | | |
| Cox-Calibrated | | | | | | | | | |
| AIPW (Ext) | | | | | | | | | |
| AIPW (Cal) | | | | | | | | | |
| TMLE (SL) | | | | | | | | | |
| TMLE-Calibrated | | | | | | | | | |
| MAP-Cox | | | | | | | | | |
| RMST-Calibrated | | | | | | | | | |

### 5.2 Type I Error Table (Scenario 11)

| Method | Type I Error (α=0.05) | 95% CI |
|--------|----------------------|--------|
| ... | ... | ... |

### 5.3 Multiple Imputation Diagnostics (all scenarios)

| Scenario | Avg. Within Var | Between Var | Var Ratio | FMI |
|----------|----------------|-------------|-----------|-----|
| 1 | | | | |
| 2 | | | | |
| ... | | | | |

### 5.4 Calibration Diagnostics

| Scenario | Ext Score Slope | Cal Score Slope | β Ext L2 Error | β Cal L2 Error |
|----------|----------------|----------------|----------------|----------------|
| ... | ... | ... | ... | ... |

---

## 6. Scenario Specification Quick Reference

| ID | Name | n_ext | n_1 | n_2 | β_trt | Shift | PH | Censoring | p | Special |
|----|------|-------|-----|-----|-------|-------|----|-----------|-----|---------|
| 1 | No shift | 1000 | 100 | 400 | -0.357 | None | Yes | Independent | 8 | — |
| 2 | Mod shift | 1000 | 100 | 400 | -0.357 | 1.25x λ, 15% β | Yes | Independent | 8 | — |
| 3 | Severe shift | 1000 | 100 | 400 | -0.357 | 2x λ, 40% β | Yes | Independent | 8 | — |
| 4 | Small Phase II | 1000 | 50 | 450 | -0.357 | Moderate | Yes | Independent | 8 | — |
| 5 | Large Phase II | 1000 | 200 | 300 | -0.357 | Moderate | Yes | Independent | 8 | — |
| 6 | Delayed effect | 1000 | 100 | 400 | — | Moderate | **No**ⁱ | Independent | 8 | PW exp |
| 7 | Diminishing | 1000 | 100 | 400 | — | Moderate | **No**ⁱ | Independent | 8 | PW exp |
| 8 | Inform. cens. | 1000 | 100 | 400 | -0.357 | Moderate | Yes | **Depends on W** | 8 | — |
| 9 | Small ext | 200 | 100 | 400 | -0.357 | Moderate | Yes | Independent | 8 | — |
| 10 | High-dim | 1000 | 100 | 400 | -0.357 | Moderate | Yes | Independent | 100 | 8/100 sparse |
| 11 | Null | 1000 | 100 | 400 | **0** | Moderate | Yes | Independent | 8 | Type I focus |

ⁱ Scenarios 6-7: non-proportional hazards (piecewise exponential, see Section 2.3).

---

## 7. Multiple Imputation Procedure (for Section 3.4.4 of the proposal)

For each simulation replicate:

```r
run_with_multiple_imputation <- function(M = 100) {
  # Draw M posterior samples of beta from the calibration
  # For each m:
  #   1. Compute S_cal_m = beta_m^T W_III
  #   2. Run Cox and TMLE analyses
  #   3. Store psi_m and var_m
  #
  # Combine via Rubin's rules:
  psi_bar <- mean(psi_m)
  W <- mean(var_m)                          # within-imputation variance
  B <- var(psi_m)                           # between-imputation variance
  V_total <- W + (1 + 1/M) * B             # total variance
  fmi <- (1 + 1/M) * B / V_total            # fraction of missing information
}
```

Report `fmi` for each scenario. If `fmi < 0.05`, the calibration contributes negligible variance and single-imputation (using the posterior mean) is adequate.

---

## 8. Memory and Runtime Considerations

- 11 scenarios × 1000 replicates × 11 methods = ~121,000 analysis runs
- Estimated runtime per replicate (single core): ~30 seconds (MCMC is the bottleneck)
- Estimated total runtime: 11 × 1000 × 30 = 330,000 seconds ≈ 92 hours (single core)
- **Solution:** Parallelize across scenarios (11 cores), then across replicates within each scenario
- Approximate wall time with 11 cores: ~8–10 hours
- Memory: ~500 MB per scenario (results stored as list of lists)

```r
library(furrr)
plan(multisession, workers = parallel::detectCores() - 2)

# Parallel across replicates within each scenario
results <- future_map(1:n_sim, ~run_replicate(.x, scenario_params),
                      .options = furrr_options(seed = TRUE))
```

---

## 9. Reproducibility Checklist

- [ ] Set global seed via `set.seed()` at the start of each replicate
- [ ] Use `withr::with_seed()` for any nested randomization (MCMC sampling)
- [ ] Record R sessionInfo() for each run
- [ ] Store all parameter values in a YAML config file
- [ ] Version-control all analysis scripts
- [ ] Use `targets` R package for pipeline orchestration with caching
- [ ] Docker image with pinned R version and package versions

---

## 10. Sensitivity Analyses (Post-Hoc)

If time permits:

- **SA1: Different SuperLearner libraries** — compare SL.glmnet + SL.ranger + SL.xgboost vs. just SL.glm
- **SA2: Different MCMC settings** — 500 vs. 2000 vs. 5000 iterations per chain
- **SA3: τ = {6, 12, 18, 24} months** — does the choice of time horizon matter?
- **SA4: Different effect sizes** — HR = {0.50, 0.60, 0.70, 0.80}
- **SA5: Different phase II/III allocation** — n_1/n_2 = {25/475, 50/450, 100/400, 200/300, 300/200}
- **SA6: Alternative calibration** — compare Bayesian updating with simple recalibration (update intercept only) vs. full recalibration

---

*End of simulation plan.*
