# ============================================================
# R/analysis_methods.R — All analysis methods
# ============================================================
# Author: Yue Shentu
# ============================================================

library(survival)

# ---- Helpers ----
get_baseline_hazard <- function(cox_fit) {
  bh <- basehaz(cox_fit, centered = FALSE)
  approxfun(bh$time, bh$hazard, rule = 2)
}

cond_survival <- function(H0_fun, tau, lp) {
  exp(-H0_fun(tau) * exp(lp))
}

# ---- Compute true Psi(tau) via IPCW on a reference dataset ----
compute_psi_true <- function(n_ref = 50000, beta_trt, beta_prog,
                              shape, scale, tau = 12) {
  # Generate a large uncensored trial to get the true survival difference
  W <- generate_covariates(n_ref)
  A <- rbinom(n_ref, 1, 0.5)
  lp <- compute_lp(W, beta_prog, beta_trt, A)
  T_death <- generate_survival_time(n_ref, lp, shape, scale)

  psi_true <- mean(T_death[A == 1] > tau) - mean(T_death[A == 0] > tau)
  rmst_true <- mean(pmin(T_death[A == 1], tau)) - mean(pmin(T_death[A == 0], tau))
  c(psi = psi_true, rmst = rmst_true)
}

# ---- 1. Cox-Standard (limited to ECOG + sex) ----
analyze_cox_standard <- function(W, A, T, delta) {
  # Realistic standard covariate adjustment: 8 strong clinically relevant covariates
  # Includes ldh (a C-covariate) since LDH is routinely adjusted for in oncology
  df <- data.frame(T = T, delta = delta, A = A,
    ecog = W$ecog,
    stage = W$tumor_stage,
    prior_tx = W$prior_tx,
    egfr = W$egfr_low,
    ldh = W$ldh,
    hgb = W$hgb,
    wbc = W$wbc,
    age = (W$age - min(W$age)) / diff(range(W$age)))
  fit <- coxph(Surv(T, delta) ~ A + ecog + stage + prior_tx + egfr + ldh + hgb + wbc + age,
               data = df, robust = TRUE)
  list(
    method = "Cox-Standard",
    beta   = unname(coef(fit)["A"]),
    se     = unname(sqrt(vcov(fit)["A", "A"])),
    hr     = unname(exp(coef(fit)["A"])),
    ci_l = unname(exp(coef(fit)["A"] - 1.96 * sqrt(vcov(fit)["A", "A"]))),
    ci_u = unname(exp(coef(fit)["A"] + 1.96 * sqrt(vcov(fit)["A", "A"]))),
    p      = unname(summary(fit)$coefficients["A", "Pr(>|z|)"])
  )
}

# ---- 2. Cox PH with a prognostic score (PROCOVA) ----
analyze_cox_with_score <- function(A, T, delta, S) {
  df <- data.frame(T = T, delta = delta, A = A, S = as.numeric(S))
  fit <- coxph(Surv(T, delta) ~ A + S, data = df, robust = TRUE)
  list(
    method = "PROCOVA",
    beta   = unname(coef(fit)["A"]),
    se     = unname(sqrt(vcov(fit)["A", "A"])),
    hr     = unname(exp(coef(fit)["A"])),
    ci_l = unname(exp(coef(fit)["A"] - 1.96 * sqrt(vcov(fit)["A", "A"]))),
    ci_u = unname(exp(coef(fit)["A"] + 1.96 * sqrt(vcov(fit)["A", "A"]))),
    p      = unname(summary(fit)$coefficients["A", "Pr(>|z|)"])
  )
}

# ---- 3. IPCW estimator (unbiased, model-free) ----
analyze_ipcw <- function(A, T, delta, tau = 12) {
  n <- length(A)
  pi_hat <- mean(A)
  G_fit <- survfit(Surv(T, 1 - delta) ~ 1)
  G_tau <- summary(G_fit, times = tau)$surv
  if (length(G_tau) == 0 || is.na(G_tau)) G_tau <- 1

  w <- A / pi_hat - (1 - A) / (1 - pi_hat)
  Y <- as.numeric(T > tau)
  psi <- mean(w * Y / G_tau)

  IC <- w * Y / G_tau - psi
  se <- sqrt(var(IC) / n)

  list(
    method = "IPCW",
    psi    = psi,
    se     = se,
    ci_l = psi - 1.96 * se,
    ci_u = psi + 1.96 * se,
    p      = 2 * pnorm(-abs(psi / se))
  )
}

# ---- 4. AIPW estimator (IPCW + outcome regression augmentation) ----
analyze_aipw <- function(W, A, T, delta, S_cal, tau = 12) {
  n <- length(A)
  pi_hat <- mean(A)
  G_fit <- survfit(Surv(T, 1 - delta) ~ 1)
  G_tau <- summary(G_fit, times = tau)$surv
  if (length(G_tau) == 0 || is.na(G_tau)) G_tau <- 1

  # Outcome regression: Cox with A + S
  df <- data.frame(T = T, delta = delta, A = A, S = as.numeric(S_cal))
  fit <- coxph(Surv(T, delta) ~ A + S, data = df)
  H0_fn <- get_baseline_hazard(fit)
  bA <- unname(coef(fit)["A"])
  bS <- unname(coef(fit)["S"])

  S1_W <- cond_survival(H0_fn, tau, bA + bS * as.numeric(S_cal))
  S0_W <- cond_survival(H0_fn, tau, 0 + bS * as.numeric(S_cal))

  # AIPW
  w <- A / pi_hat - (1 - A) / (1 - pi_hat)
  Y <- as.numeric(T > tau)
  psi <- mean(w * Y / G_tau - w * (S1_W - S0_W))

  IC <- w * Y / G_tau - w * (S1_W - S0_W) - psi
  se <- sqrt(var(IC) / n)

  list(
    method = "AIPW",
    psi    = psi,
    se     = se,
    ci_l = psi - 1.96 * se,
    ci_u = psi + 1.96 * se,
    p      = 2 * pnorm(-abs(psi / se))
  )
}

# ---- 5. TMLE for marginal survival difference ----
analyze_tmle <- function(W, A, T, delta, S_cal, tau = 12) {
  n <- length(A)
  df <- data.frame(T = T, delta = delta, A = A, S = as.numeric(S_cal))

  # Initial Cox
  init_fit <- coxph(Surv(T, delta) ~ A + S, data = df)
  bA <- unname(coef(init_fit)["A"])
  bS <- unname(coef(init_fit)["S"])
  H0_fn <- get_baseline_hazard(init_fit)

  mo <- bS * as.numeric(S_cal)
  S1_init <- cond_survival(H0_fn, tau, bA + mo)
  S0_init <- cond_survival(H0_fn, tau, 0 + mo)

  # Clever covariate (includes IPCW for censoring)
  pi_hat <- mean(A)
  G_fit <- survfit(Surv(T, 1 - delta) ~ 1)
  G_tau <- summary(G_fit, times = tau)$surv
  if (length(G_tau) == 0 || is.na(G_tau)) G_tau <- 1

  H <- (A / pi_hat - (1 - A) / (1 - pi_hat)) / G_tau

  # Fluctuation: add H to Cox model
  offset_term <- bA * A + bS * as.numeric(S_cal)
  fluct_fit <- coxph(Surv(T, delta) ~ offset(offset_term) + H, data = df)
  eps <- unname(coef(fluct_fit))

  # Updated survival
  lp1_up <- bA + mo + eps * (1 / pi_hat - 0 / (1 - pi_hat)) / G_tau
  lp0_up <- 0 + mo + eps * (0 / pi_hat - 1 / (1 - pi_hat)) / G_tau

  psi <- mean(cond_survival(H0_fn, tau, lp1_up) - cond_survival(H0_fn, tau, lp0_up))

  # Variance via influence function
  IC <- H * (as.numeric(T > tau) - (S1_init - S0_init)) - psi
  se <- sqrt(var(IC) / n)

  list(
    method = "TMLE",
    psi    = psi,
    se     = se,
    ci_l = psi - 1.96 * se,
    ci_u = psi + 1.96 * se,
    p      = 2 * pnorm(-abs(psi / se))
  )
}

# ---- 6. RMST via IPCW (no bootstrap needed) ----
analyze_rmst <- function(A, T, delta, tau = 12) {
  # IPCW-based RMST: E[w · min(T*, tau)] where T* is the death time
  # and w = I(A=1)/π - I(A=0)/(1-π) is the treatment weight.
  #
  # For censored patients with T < tau, we don't know their full survival.
  # IPCW corrects: RMST_i = min(T_i, tau) if delta_i = 1 or T_i > tau,
  # else RMST_i is unknown and we use IPCW weighting.
  #
  # Simple robust approach: RMST = area between KM curves.
  # Use IPCW-weighted RMST difference:
  #   RMST = E[w · ∫₀ᵗ I(T>u)/G(u) du]
  # where G is the censoring survival function.

  n <- length(A)
  pi_hat <- mean(A)
  w <- A / pi_hat - (1 - A) / (1 - pi_hat)

  # Censoring KM
  G_fit <- survfit(Surv(T, 1 - delta) ~ 1)
  G_fn <- stepfun(G_fit$time, c(1, G_fit$surv))

  # RMST for each patient: integral_0^{min(T,tau)} 1/G(u) du
  # When T > tau: = integral_0^tau 1/G(u) du
  # When T <= tau and delta=1 (death observed): = integral_0^T 1/G(u) du
  # When T <= tau and delta=0 (censored): IPCW handles this

  u_grid <- seq(0, tau, length.out = 200)
  du <- u_grid[2] - u_grid[1]

  rmst_i <- numeric(n)
  for (i in 1:n) {
    t_max <- min(T[i], tau)
    u_sub <- u_grid[u_grid <= t_max]
    if (length(u_sub) > 0) {
      G_u <- G_fn(u_sub)
      rmst_i[i] <- sum(1 / pmax(G_u, 0.01)) * du
    }
  }

  psi <- mean(w * rmst_i)
  IC <- w * rmst_i - psi
  se <- sqrt(var(IC) / n)

  list(
    method = "RMST",
    psi    = psi,
    se     = se,
    ci_l = psi - 1.96 * se,
    ci_u = psi + 1.96 * se,
    p      = 2 * pnorm(-abs(psi / se))
  )
}

# ---- 7. MAP prior borrowing (Bayesian competitor) ----
analyze_map_cox <- function(W_II, A_II, T_II, delta_II,
                             W_III, A_III, T_III, delta_III,
                             W_ext = NULL, T_ext = NULL, delta_ext = NULL) {
  # Robust MAP prior with data-adaptive mixture weight.
  # w is estimated from the discrepancy between phase II and external
  # treatment effect estimates (if external data provided) or defaults
  # to a weakly informative prior.

  df_II <- data.frame(T = T_II, delta = delta_II, A = A_II)
  fit_II <- coxph(Surv(T, delta) ~ A, data = df_II)
  mu_II <- unname(coef(fit_II)["A"])
  sig_II <- unname(sqrt(vcov(fit_II)["A", "A"]))

  # If external data provided, use empirical Bayes to estimate w
  if (!is.null(W_ext) && !is.null(T_ext) && !is.null(delta_ext)) {
    fit_ext <- coxph(Surv(T, delta) ~ A,
                     data = data.frame(T = T_ext, delta = delta_ext,
                                       A = rep(0.5, length(T_ext))))
    mu_ext <- 0  # external data has no treatment effect info about current drug
    # w based on how well external and phase II agree
    z <- (mu_II - mu_ext) / sqrt(sig_II^2 + 0.01)
    w <- exp(-0.5 * z^2) / (1 + exp(-0.5 * z^2))
    w <- max(0.1, min(0.9, w))
  } else {
    w <- 0.5
  }

  sig_v <- 2.0
  df_III <- data.frame(T = T_III, delta = delta_III, A = A_III)
  fit_III <- coxph(Surv(T, delta) ~ A, data = df_III)
  mu_III <- unname(coef(fit_III)["A"])
  sig_III <- unname(sqrt(vcov(fit_III)["A", "A"]))

  prec_III <- 1 / sig_III^2
  prec_pr <- w / sig_II^2 + (1 - w) / sig_v^2
  post_mu <- (mu_III * prec_III + mu_II * prec_pr) / (prec_III + prec_pr)
  post_sig <- sqrt(1 / (prec_III + prec_pr))

  list(
    method = "MAP-Cox",
    beta   = post_mu,
    se     = post_sig,
    hr     = exp(post_mu),
    ci_l = exp(post_mu - 1.96 * post_sig),
    ci_u = exp(post_mu + 1.96 * post_sig),
    p    = 2 * pnorm(-abs(post_mu / post_sig)),
    w    = w
  )
}

# ---- 8. Stratified Log-Rank ----
analyze_logrank <- function(W, A, T, delta) {
  strata <- interaction(W$ecog >= 0, W$sex >= 0.5)
  fit <- survdiff(Surv(T, delta) ~ A + strata(strata))
  p <- 1 - pchisq(fit$chisq, df = 1)
  list(method = "Log-Rank", p = p, chisq = fit$chisq)
}
