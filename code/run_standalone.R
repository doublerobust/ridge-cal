library(furrr); library(future); library(glmnet)
source("R/data_generation.R"); source("R/training.R")
source("R/analysis_methods.R"); source("R/map_proper.R")
# Note: run with working directory set to project root
# Or: cd /path/to/simulation && Rscript run_standalone.R
plan(multisession, workers = min(11, future::availableCores() - 1))
n_sim <- 10000

ridge_cal <- function(W, T, d, S_all, cc = c("sex","marker_x","crp","albumin","ldh")) {
  cv <- intersect(cc, names(W))
  x <- as.matrix(cbind(S = as.numeric(S_all), W[, cv, drop = FALSE]))
  cv_fit <- cv.glmnet(x, Surv(T, d), family = "cox", alpha = 0, nfolds = 5)
  list(S = as.numeric(predict(cv_fit, newx = x, s = "lambda.min", type = "link")),
       lam = cv_fit$lambda.min)
}

cat("Full sim: n_sim=", n_sim, " x 7 scenarios x 6 methods\n", sep="")
flush(stdout())

for (s in 1:7) {
  shift <- c("none","moderate","severe","severe","moderate","severe","severe")[s]
  btrt <- if (s == 5) 0 else if (s == 7) log(0.75) else log(0.70)
  inter <- (s == 4)
  nm <- c("No shift","Moderate","Severe","Interaction","Null","Non-PH","Smaller effect")[s]
  seed_b <- 20260517 + s * 100000

  t0 <- Sys.time()
  reps <- future_map(1:n_sim, function(i) {
    set.seed(seed_b + i)
    be <- get_beta_ext(shift); bp <- get_beta_prog()
    ep <- get_weibull_params("external", shift)
    ext <- generate_external_data(2000, be, ep$shape, ep$scale)
    n <- 400; W <- generate_covariates(n); A <- rbinom(n, 1, 0.5)
    lp <- compute_lp(W, bp, btrt, A)
    if (inter) lp <- lp + 0.5 * A * (W$marker_x - mean(W$marker_x))

    if (s == 6) {
      lp_nph <- compute_lp(W, bp, 0)
      Td <- numeric(n)
      for (j in 1:n) {
        hr2 <- if (A[j] == 1) exp(btrt) else 1
        t <- rexp(1, 1/13 * exp(lp_nph[j]))
        if (is.infinite(t)) { Td[j] <- Inf
        } else if (t > 2) { Td[j] <- 2 + rexp(1, 1/13 * hr2 * exp(lp_nph[j]))
        } else { Td[j] <- t }
      }
    } else {
      Td <- rweibull(n, shape = 1.5, scale = 13 * exp(-lp / 1.5))
    }
    C <- pmin(rep(24, n), rexp(n, rate = -log(1 - 0.03) / 12))
    To <- pmin(Td, C); d <- as.numeric(Td <= C)

    cs <- analyze_cox_standard(W, A, To, d)
    lr <- analyze_logrank(W, A, To, d)
    cvars <- names(W)
    ff <- as.formula(paste("Surv(TT,DD)~A+", paste(cvars, collapse = "+")))
    ffit <- coxph(ff, data = cbind(W, A = A, TT = To, DD = d), robust = TRUE)
    em <- train_external_model(ext$W, ext$T, ext$delta); Se <- em$predict(W)
    pr <- analyze_cox_with_score(A, To, d, Se)
    rc <- ridge_cal(W, To, d, Se)
    cc <- analyze_cox_with_score(A, To, d, rc$S)
    mp <- map_proper(ext$W, ext$T, ext$delta, W, A, To, d,
                      calib_covs = c("sex","marker_x","crp","albumin","ldh"))

    c(cs_p = cs$p, lr_p = lr$p, or_p = summary(ffit)$coefficients["A","Pr(>|z|)"],
      pr_p = pr$p, rc_p = cc$p, mp_p = mp$p,
      pr_b = pr$beta, rc_b = cc$beta, or_b = unname(coef(ffit)["A"]), mp_b = mp$beta,
      lam = rc$lam)
  }, .options = furrr_options(seed = TRUE, chunk_size = 200))

  p <- function(n) mean(sapply(reps, `[[`, n) < .05, na.rm = TRUE)
  b <- function(n) mean(sapply(reps, `[[`, n), na.rm = TRUE)

  cat(sprintf("%-12s | Std=%.3f Orac=%.3f PRO=%.3f RCal=%.3f MAP=%.3f LR=%.3f\n",
              nm, p("cs_p"), p("or_p"), p("pr_p"), p("rc_p"), p("mp_p"), p("lr_p")))
  cat(sprintf("  bias: PRO=%.4f RCal=%.4f Orac=%.4f MAP=%.4f lam=%.4f  [%.1f min]\n",
              b("pr_b")-btrt, b("rc_b")-btrt, b("or_b")-btrt, b("mp_b")-btrt,
              mean(sapply(reps,`[[`,"lam")), as.numeric(difftime(Sys.time(), t0, units="mins"))))
  flush(stdout())
}

cat("\nDone.\n")
