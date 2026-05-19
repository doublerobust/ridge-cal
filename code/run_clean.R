#!/usr/bin/env Rscript
# run_clean.R — Ridge-Cal 10K x 7 scenarios, no MAP-Cox
# Run: Rscript run_clean.R
library(furrr); library(future); library(glmnet)
source("R/data_generation.R"); source("R/training.R"); source("R/analysis_methods.R")
plan(multisession, workers = min(11, future::availableCores() - 1))
n <- 10000  # Number of simulation replicates

ridge_cal <- function(W, T, d, S_all, cc = c("sex","marker_x","crp","albumin","ldh")) {
  cv <- intersect(cc, names(W))
  x <- as.matrix(cbind(S = as.numeric(S_all), W[, cv, drop = FALSE]))
  cf <- cv.glmnet(x, Surv(T, d), family = "cox", alpha = 0, nfolds = 5)
  list(S = as.numeric(predict(cf, newx = x, s = "lambda.min", type = "link")), lam = cf$lambda.min)
}

cat("=== 10K x 7 scenarios x 5 methods ===\n", file = "results.txt")
for (s in 1:7) {
  shift <- c("none","moderate","severe","severe","moderate","severe","severe")[s]
  btrt <- if (s == 5) 0 else if (s == 7) log(0.75) else log(0.70)
  inter <- (s == 4)
  nm <- c("No shift","Moderate","Severe","Interaction","Null","Non-PH","Smaller effect")[s]
  t0 <- Sys.time()

  reps <- future_map(1:n, function(i, s_val=s, shift_val=shift, btrt_val=btrt, inter_val=inter) {
    set.seed(20260517 + s_val*100000 + i)
    be <- get_beta_ext(shift_val); bp <- get_beta_prog()
    ep <- get_weibull_params("external", shift_val)
    ext <- generate_external_data(2000, be, ep$shape, ep$scale)
    n_t <- 400; W <- generate_covariates(n_t); A <- rbinom(n_t, 1, 0.5)
    lp <- compute_lp(W, bp, btrt_val, A)
    if (inter_val) lp <- lp + 0.5*A*(W$marker_x - mean(W$marker_x))
    if (s_val == 6) {
      lp_nph <- compute_lp(W, bp, 0); Td <- numeric(n_t)
      for (j in 1:n_t) {
        hr2 <- if (A[j]==1) exp(btrt_val) else 1
        t <- rexp(1, 1/13*exp(lp_nph[j]))
        if (is.infinite(t)) Td[j] <- Inf
        else if (t > 2) Td[j] <- 2 + rexp(1, 1/13*hr2*exp(lp_nph[j]))
        else Td[j] <- t
      }
    } else Td <- rweibull(n_t, shape=1.5, scale=13*exp(-lp/1.5))
    C <- pmin(rep(24,n_t), rexp(n_t, rate=-log(1-0.03)/12))
    To <- pmin(Td,C); d <- as.numeric(Td<=C)
    cs <- analyze_cox_standard(W, A, To, d)
    lr <- analyze_logrank(W, A, To, d)
    ff <- as.formula(paste("Surv(TT,DD)~A+",paste(names(W),collapse="+")))
    ffit <- coxph(ff, data=cbind(W,A=A,TT=To,DD=d),robust=T)
    em <- train_external_model(ext$W,ext$T,ext$delta); Se <- em$predict(W)
    pr <- analyze_cox_with_score(A,To,d,Se)
    rc <- ridge_cal(W,To,d,Se)
    cc <- analyze_cox_with_score(A,To,d,rc$S)
    c(cs_p=cs$p, lr_p=lr$p, or_p=summary(ffit)$coefficients["A","Pr(>|z|)"],
      pr_p=pr$p, rc_p=cc$p,
      pr_b=pr$beta, rc_b=cc$beta, or_b=unname(coef(ffit)["A"]), lam=rc$lam)
  }, .options=furrr_options(seed=TRUE, chunk_size=200))

  p <- function(x) mean(sapply(reps, `[[`, x) < .05, na.rm=TRUE)
  b <- function(x) mean(sapply(reps, `[[`, x), na.rm=TRUE)
  cat(sprintf("%s | Std=%.3f Orac=%.3f LR=%.3f PRO=%.3f RCal=%.3f [%.1f min]\n",
              nm, p("cs_p"), p("or_p"), p("lr_p"), p("pr_p"), p("rc_p"),
              as.numeric(difftime(Sys.time(),t0,units="mins"))), file="results.txt", append=TRUE)
  cat(sprintf("  bias: PRO=%.4f RCal=%.4f Orac=%.4f lam=%.4f\n",
              b("pr_b")-btrt, b("rc_b")-btrt, b("or_b")-btrt,
              mean(sapply(reps,`[[`,"lam"))), file="results.txt", append=TRUE)
}
cat("Done.\n", file="results.txt", append=TRUE)
