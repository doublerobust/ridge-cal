# ============================================================
# R/adaptive.R — Adaptive Seamless Phase II/III Design
# ============================================================
# Author: Yue Shentu
#
# Targeted calibration: update only the K pre-specified
# "calibration covariates" using phase II data. All other
# coefficients stay at their well-estimated external values.
# ============================================================
#
# Depends on: training.R (for train_external_model)
#              data_generation.R (for compute_lp)
# ============================================================

library(survival)

# ---- Pre-specified calibration covariates ----
# These are the 5 covariates expected to shift between populations.
# In a real trial, this list would be pre-specified in the SAP.
CALIBRATION_COVS <- c("sex", "marker_x", "crp", "albumin", "ldh")

# ---- 1. Targeted calibration ----
# Uses train_external_model() from training.R
calibrate_targeted <- function(W_ext, T_ext, delta_ext,
                                W_II, A_II, T_II, delta_II,
                                calib_covars = CALIBRATION_COVS) {
  # --- External: full model ---
  ext_model <- train_external_model(W_ext, T_ext, delta_ext)
  beta_ext <- coef(ext_model$fit)
  names(beta_ext) <- gsub("_std$", "", names(beta_ext))
  se_ext <- sqrt(diag(vcov(ext_model$fit)))
  names(se_ext) <- gsub("_std$", "", names(se_ext))

  # --- Phase II: reduced model (only calib covariates + treatment) ---
  avail_covars <- intersect(calib_covars, names(W_II))
  if (length(avail_covars) < 1) {
    return(list(
      beta_cal = beta_ext,
      beta_trt_II = NA, se_trt_II = NA,
      n_calibrated = 0,
      predict = ext_model$predict
    ))
  }

  form_II <- as.formula(paste("Surv(T, delta) ~ A +",
                               paste(avail_covars, collapse = " + ")))
  df_II <- cbind(W_II[, avail_covars, drop = FALSE],
                 A = A_II, T = T_II, delta = delta_II)
  fit_II <- tryCatch(coxph(form_II, data = df_II),
                     error = function(e) NULL)

  if (is.null(fit_II)) {
    return(list(
      beta_cal = beta_ext,
      beta_trt_II = NA, se_trt_II = NA,
      n_calibrated = 0,
      predict = ext_model$predict
    ))
  }

  # --- Phase II treatment effect ---
  coef_names <- names(coef(fit_II))
  beta_trt_II <- if ("A" %in% coef_names) unname(coef(fit_II)["A"]) else NA
  se_trt_II <- if ("A" %in% coef_names) unname(sqrt(vcov(fit_II)["A", "A"])) else NA

  # --- Build calibrated coefficient vector ---
  # For calibration covariates: weaken the external prior so phase II
  # data dominates. Factor K=5 means prior SE is 5x wider → phase II
  # gets ~25x more weight in the precision-weighted average.
  PRIOR_WEAKEN <- 5

  beta_cal <- beta_ext  # start with external
  for (cv in avail_covars) {
    if (cv %in% coef_names && cv %in% names(beta_ext)) {
      # Bayesian precision-weighted update with weakened prior
      prec_ext_w <- 1 / (se_ext[cv]^2 * PRIOR_WEAKEN^2)
      prec_II <- 1 / (sqrt(diag(vcov(fit_II)))[cv]^2)
      beta_cal[cv] <- (beta_ext[cv] * prec_ext_w +
                        unname(coef(fit_II)[cv]) * prec_II) /
                       (prec_ext_w + prec_II)
    }
  }

  list(
    beta_cal = beta_cal,
    beta_trt_II = beta_trt_II,
    se_trt_II = se_trt_II,
    n_calibrated = length(avail_covars),
    predict = function(new_W) {
      common <- intersect(names(beta_cal), names(new_W))
      as.numeric(as.matrix(new_W[, common, drop = FALSE]) %*% beta_cal[common])
    }
  )
}

# ---- 2. Full adaptive pipeline ----
run_adaptive <- function(W_ext, T_ext, delta_ext,
                          W_II, A_II, T_II, delta_II,
                          W_III, A_III, T_III, delta_III,
                          tau = 12, weight_fixed = NULL) {

  # Targeted calibration using phase II
  cal <- calibrate_targeted(W_ext, T_ext, delta_ext,
                             W_II, A_II, T_II, delta_II)

  # Z₁ from phase II
  Z1 <- if (!is.null(cal$beta_trt_II) && !is.na(cal$beta_trt_II) &&
            !is.null(cal$se_trt_II) && !is.na(cal$se_trt_II) &&
            cal$se_trt_II > 0)
    cal$beta_trt_II / cal$se_trt_II else 0

  # Calibrated score for phase III
  S_cal <- cal$predict(W_III)

  # Phase III Cox with calibrated score
  df_III <- data.frame(T = T_III, delta = delta_III,
                        A = A_III, S = as.numeric(S_cal))
  fit_III <- coxph(Surv(T, delta) ~ A + S, data = df_III, robust = TRUE)
  beta_III <- unname(coef(fit_III)["A"])
  se_III <- unname(sqrt(vcov(fit_III)["A", "A"]))
  Z2 <- beta_III / se_III

  # Inverse normal combination
  n1 <- sum(A_II)
  n2 <- sum(A_III)
  w <- if (is.null(weight_fixed)) sqrt(n1 / (n1 + n2)) else weight_fixed
  Zc <- w * Z1 + sqrt(1 - w^2) * Z2
  p_comb <- 2 * pnorm(-abs(Zc))

  list(
    method = "Adaptive",
    beta = beta_III,
    se = se_III,
    Z1 = Z1,
    Z2 = Z2,
    Z_comb = Zc,
    p = p_comb,
    n_cal = cal$n_calibrated,
    n1 = n1, n2 = n2, w = w
  )
}

# ---- 3. Simulation wrapper ----
analyze_adaptive <- function(W_ext, T_ext, delta_ext,
                              W_II, A_II, T_II, delta_II,
                              W_III, A_III, T_III, delta_III,
                              tau = 12) {
  run_adaptive(W_ext, T_ext, delta_ext,
               W_II, A_II, T_II, delta_II,
               W_III, A_III, T_III, delta_III, tau)
}
