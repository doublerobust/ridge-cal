# Simulation Plan: Ridge-Cal — Regularized Calibration of External Prognostic Scores

**Author:** Yue Shentu  
**Date:** May 2026  
**Status:** Complete — 10,000 reps × 7 scenarios, results in `probabilistic-digital-twin-trial.md`

---

## Overview

This document describes the simulation study implemented for the Ridge-Cal paper. The study evaluates a ridge-penalized calibration method for external prognostic scores under population shift. It compares Ridge-Cal against standard PROCOVA, Oracle Cox, stratified log-rank, MAP-Cox borrowing, and standard Cox adjustment.

**Code location:** `simulation/`  
**Entry points:** `run_clean.R` (10K reps, 5 main methods), `run_standalone.R` (interactive, includes MAP-Cox)  
**Results file:** `simulation/results.txt`, `simulation/map_cox_results.txt`

---

## 1. Simulation Parameters

### 1.1 Global Defaults

| Parameter | Value | Description |
|-----------|-------|-------------|
| `N` | 400 | Trial sample size |
| `N_ext` | 2000 | External dataset size |
| `n_sim` | 10,000 | Simulation replicates |
| `alpha` | 0.05 | Two-sided significance level |
| `admin_cens` | 24 | Administrative censoring (months) |
| `dropout_rate` | 0.03 | Annual random dropout rate |
| `shape` | 1.5 | Weibull shape parameter |
| `scale` | 13 | Weibull scale parameter (median ~10 mo) |
| `K_folds` | 5 | CV folds for ridge penalty selection |
| `p` | 20 | Number of baseline covariates |
| `c` | 5 | Number of calibration covariates |
| `seed_base` | 20260517 | Base random seed |

### 1.2 Baseline Covariates

Twenty baseline covariates across four types:

| Type | Covariates | Distribution |
|------|-----------|-------------|
| **Continuous** (10) | age, BMI, CRP, albumin, creatinine, WBC, hemoglobin, neutrophils, platelets, LDH | Standardized normal |
| **Binary** (5) | sex, prior treatment, low eGFR, smoking, marker X | Bernoulli(0.5), except sex=Bernoulli(0.5) |
| **Ordinal** (5) | ECOG (0-2), tumor stage (0-3), comorbidity index (0-5), symptom score (0-3), frailty (1-4) | Independent multinomial/dirichlet |

**Calibration set** $\mathcal{C}$ (5 covariates, pre-specified): sex, marker_x, CRP, albumin, LDH

All covariates are standardized to mean 0, variance 1 after generation.

### 1.3 Coefficient Vectors

**True prognostic coefficients** $\beta_{prog}$ (trial data-generating model): Chosen to yield external C-index ~0.80, LP SD ~1.3.

| Covariate | Coefficient |
|-----------|:----------:|
| age | 0.03 |
| BMI | 0.05 |
| CRP | -0.15 |
| albumin | 0.12 |
| creatinine | 0.04 |
| WBC | 0.06 |
| hemoglobin | -0.10 |
| neutrophils | 0.08 |
| platelets | 0.03 |
| LDH | 0.07 |
| sex | 0.05 |
| prior_tx | 0.10 |
| low_eGFR | 0.08 |
| smoking | 0.06 |
| marker_x | 0.20 |
| ECOG1 | 0.20 |
| ECOG2 | 0.40 |
| tumor_stage | 0.15 |
| comorbidity | 0.08 |
| symptom | 0.10 |
| frailty | 0.12 |

**External coefficients** $\beta_{ext}$ differ from $\beta_{prog}$ depending on the shift scenario:

| Calibration covariate | No shift | Moderate | Severe |
|---------------------|:-------:|:--------:|:------:|
| sex | 0.05 | 0.15 | 0.40 |
| marker_x | 0.20 | 0.08 | -0.30 |
| CRP | -0.15 | -0.25 | -0.50 |
| albumin | 0.12 | 0.22 | 0.45 |
| LDH | 0.07 | 0.15 | 0.35 |

Non-calibration covariates remain at $\beta_{prog}$ values under all scenarios.

### 1.4 Survival Generation

Baseline hazard: Weibull with shape = 1.5, scale = 13.

Linear predictor:
$$\text{LP}_i = A_i \beta_{trt} + \sum_{j=1}^{p} \beta_j W_{ij}$$

Survival time:
$$T_i \sim \text{Weibull}(\text{shape}=1.5, \text{scale}=13 \cdot \exp(-\text{LP}_i / 1.5))$$

Censoring: $C = \min(24, C_{dropout})$ where $C_{dropout} \sim \text{Exp}(\text{rate} = -\log(1-0.03)/12)$.

---

## 2. Scenarios

| ID | Name | Shift | $\beta_{trt}$ | Special |
|:--:|:-----|:-----|:-------------:|:--------|
| 1 | No shift | None | $\log 0.70$ | Baseline — score is well-calibrated |
| 2 | Moderate | Moderate | $\log 0.70$ | Small coefficient differences |
| 3 | Severe | Severe | $\log 0.70$ | Marker_X sign flips, CRP albumin/LDH shift |
| 4 | Interaction | Severe | $\log 0.70$ | Marker_X × treatment interaction ($\gamma = 0.5$) |
| 5 | Null | Moderate | 0 | Type I error assessment |
| 6 | Non-PH | Severe | $\log 0.70$ | Delayed effect: HR=1 for 0–2 mo, then HR=0.70 |
| 7 | Smaller effect | Severe | $\log 0.75$ | Weaker treatment effect |

### 2.1 Non-PH Generation (Scenario 6)

Piecewise exponential with 2-month delay:

$$h(t \mid A, W) = \begin{cases} h_0(t) \exp(\text{LP}_W) & \text{if } t \leq 2 \\ h_0(t) \exp(\text{LP}_W + \beta_{trt} A) & \text{if } t > 2 \end{cases}$$

where $\text{LP}_W = \sum \beta_j W_j$ (prognostic component only).

### 2.2 Interaction Generation (Scenario 4)

Same as severe shift, with additional term in the linear predictor:
$$\text{LP}_i = A_i \beta_{trt} + \text{LP}_W + \gamma \cdot A_i \cdot (W_{marker\_x} - \bar{W}_{marker\_x})$$
where $\gamma = 0.5$.

---

## 3. Methods Compared

### 3.1 Main Methods (5)

| ID | Method | Description |
|:---|:-------|:-----------|
| **Std** | Cox-2 | Standard Cox PH with 2 stratification variables (ECOG, sex). Conventional limited adjustment. |
| **Orac** | Oracle Cox | Cox PH with all 20 covariates. Theoretical upper bound — not achievable in practice due to EPP limits and regulatory parsimony requirements. |
| **LR** | Stratified Log-Rank | Non-parametric log-rank test stratified by ECOG and sex. |
| **PRO** | PROCOVA | Cox PH with the external prognostic score $\hat{S}^{(ext)}$ as sole covariate. Standard PROCOVA without calibration. |
| **RCal** | Ridge-Cal | Cox PH with ridge-calibrated score $\hat{S}^{(cal)}$ from blinded trial data. |

### 3.2 Sensitivity Analysis

| ID | Method | Description |
|:---|:-------|:-----------|
| **MAP** | MAP-Cox | Bayesian prior borrowing (Schmidli et al., 2014) via precision-weighted updating. Uses unblinded trial data and all 20 covariates + treatment (21 parameters). Not recommended for primary analysis — included as a sensitivity benchmark. |

### 3.3 Ridge-Cal Implementation

**Step 1 — Diagnostic (Section 2.2):** Fit two Cox models on blinded trial data:

1. Base: $\lambda(t \mid W) = \lambda_0(t) \exp(\beta_0 + \beta_1 \hat{S}^{(ext)})$
2. Augmented: $\lambda(t \mid W) = \lambda_0(t) \exp(\beta_0 + \beta_1 \hat{S}^{(ext)} + \beta_\mathcal{C}^T W_\mathcal{C})$

If $C_2 - C_1 > 0.01$, recalibration is triggered.

**Step 2 — Ridge-Cal (Section 2.3):** Fit ridge-penalized Cox on blinded data:

$$\hat{\beta}^{(cal)} = \arg\min_\beta \left[ -\ell(\beta; \mathcal{D}_{trial}) + \lambda \sum_{j=1}^{c+1} \beta_j^2 \right]$$

Includes $\hat{S}^{(ext)}$ and the $c$ calibration covariates. $\lambda$ selected by 5-fold CV using `glmnet` with $\alpha = 0$. The calibrated score is:
$$\hat{S}_i^{(cal)} = \hat{\beta}_1 \hat{S}_i^{(ext)} + \sum_{j \in \mathcal{C}} \hat{\beta}_j W_{ij}$$

**Primary analysis (Section 2.4):** Standard Cox PH with $\hat{S}^{(cal)}$ as covariate, robust sandwich variance.

### 3.4 MAP-Cox Implementation

The proper MAP prior uses precision-weighting (code in `R/map_proper.R`):

$$\hat{\beta} = \frac{k \cdot \beta_{ext} \cdot \tau_{ext} + \beta_{trial} \cdot \tau_{trial}}{k \cdot \tau_{ext} + \tau_{trial}}$$

where $k > 1$ discounts the external prior (default $k = 5$ by AIC), and $\tau_{ext}, \tau_{trial}$ are Fisher information-based precisions. This implements a Schmidli et al. (2014)-style robust MAP prior as a precision-weighted approximation.

---

## 4. Evaluation Metrics

### 4.1 Primary Metric: Power

Empirical power at $\alpha = 0.05$ (two-sided Wald test):

$$\text{Power} = \frac{1}{n_{sim}} \sum_{i=1}^{n_{sim}} I(p_i < 0.05)$$

### 4.2 Bias

Bias of the treatment effect estimator on the log-HR scale:

$$\text{Bias} = \frac{1}{n_{sim}} \sum_{i=1}^{n_{sim}} (\hat{\beta}_{trt,i} - \beta_{trt})$$

### 4.3 Type I Error

For Scenario 5 (Null, $\beta_{trt} = 0$):

$$\text{Type I Error} = \frac{1}{n_{sim}} \sum_{i=1}^{n_{sim}} I(p_i < 0.05)$$

### 4.4 Ridge Penalty

Distribution of CV-selected $\lambda$ values across replicates.

---

## 5. Results Summary

Full results in `probabilistic-digital-twin-trial.md`, Tables 1–2.

### 5.1 Key Findings

1. **RCal preserves power under shift** — PROCOVA drops 9pp under severe shift (84.5→75.8%), RCal drops only 0.4pp (83.7→83.3%)
2. **Interaction advantage** — RCal captures A×marker_x interaction (85.4%), PROCOVA misses it (73.0%). Bias near-zero for RCal (0.0006 vs PRO's 0.0455)
3. **Non-PH robustness** — RCal (54.4%) recovers nearly all oracle (56.1%), PROCOVA (48.3%) and log-rank (35.0%) lag
4. **Type I error control** — RCal at 5.2%, essentially nominal
5. **Lowest bias** — RCal bias <0.01 under all active scenarios except non-PH (where all methods show non-collapsibility bias)
6. **Minimal no-shift penalty** — RCal (83.7%) vs PROCOVA (84.5%) = −0.8pp
7. **MAP-Cox comparison** — MAP-Cox achieves comparable power using 21 parameters on unblinded data vs. RCal's 6 on blinded data. RCal remains superior on parsimony and blinding.

### 5.2 Final Results (10,000 reps)

| Scenario | Std | Oracle | LR | PROCOVA | MAP-Cox | Ridge-Cal |
|:---------|:---:|:-----:|:--:|:-------:|:-------:|:--------:|
| **No shift** | 0.630 | 0.845 | 0.532 | 0.845 | 0.834 | **0.837** |
| **Moderate** | 0.622 | 0.844 | 0.528 | 0.825 | 0.834 | **0.834** |
| **Severe** | 0.630 | 0.843 | 0.525 | 0.758 | 0.832 | **0.833** |
| **Interaction** | 0.631 | 0.865 | 0.530 | 0.730 | 0.856 | **0.854** |
| **Null** | 0.055 | 0.065 | 0.051 | 0.053 | 0.059 | **0.052** |
| **Non-PH** | 0.408 | 0.554 | 0.347 | 0.501 | 0.550 | **0.551** |
| **Smaller effect** | 0.456 | 0.682 | 0.371 | 0.572 | 0.665 | **0.659** |

---

## 6. R Implementation

### File Structure

```
simulation/
├── run_clean.R              # 10K × 7 scenarios (5 methods: Std, Orac, LR, PRO, RCal)
├── run_standalone.R         # Interactive version (6 methods, includes MAP-Cox)
├── R/
│   ├── data_generation.R    # Covariate generation, survival generation
│   ├── training.R           # External model training
│   ├── analysis_methods.R   # All analysis functions (cox_standard, logrank, etc.)
│   └── map_proper.R         # Proper MAP prior precision-weighted implementation
├── scripts/
│   └── report.R             # Report generation
├── launch_now.sh            # Quick launch script
└── launch_sim.sh            # Cron-ready launch script
```

### Key Functions

| Function | File | Purpose |
|----------|------|---------|
| `generate_covariates()` | `data_generation.R` | Generate 20 baseline covariates |
| `generate_external_data()` | `data_generation.R` | Generate external dataset |
| `compute_lp()` | `data_generation.R` | Compute linear predictor |
| `train_external_model()` | `training.R` | Fit external Cox PH (all 20 covariates) |
| `analyze_cox_standard()` | `analysis_methods.R` | Cox with 2 stratification vars |
| `analyze_logrank()` | `analysis_methods.R` | Stratified log-rank test |
| `analyze_cox_with_score()` | `analysis_methods.R` | PROCOVA / score-based Cox |
| `ridge_cal()` | `run_clean.R` / `run_standalone.R` | Ridge-Cal with cv.glmnet |
| `analyze_map_cox()` | `analysis_methods.R` | MAP prior borrowing |
| `map_proper()` | `map_proper.R` | Precision-weighted MAP prior |

### Dependencies

- R ≥ 4.0
- `survival` (base Cox models, log-rank)
- `glmnet` (ridge-penalized Cox, cv.glmnet)
- `furrr` + `future` (parallel simulation)
- `rlang` (tidy evaluation)

### Running the Simulation

```bash
# Full 10K × 7 (5 methods, ~27 min on 12 cores)
cd /path/to/simulation
export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH
Rscript run_clean.R

# Interactive with MAP-Cox (6 methods, ~35 min)
Rscript run_standalone.R
```

---

## 7. Reproducibility

- Seed-based reproducibility: `set.seed(20260517 + scenario_id * 100000 + replicate_id)`
- All code in `github.com/doublerobust/ridge-cal`
- Results can be reproduced via `run_clean.R` (10K reps) or `run_standalone.R` (fewer reps for testing)
- Cross-validation within `glmnet` uses internal seed management

---

*End of simulation plan.*
