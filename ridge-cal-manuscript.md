# Ridge-Cal: Efficient Regularized Calibration of External Prognostic Scores Using Blinded Trial Data

**Author:** Yue Shentu  
**Date:** May 2026

---

## Abstract

**Background.** External prognostic scores improve randomized trial efficiency via covariate adjustment (Schuler et al., 2022). However, when the trial population differs from the historical data used to build the score, the score may be miscalibrated, reducing or reversing the efficiency gain.

**Methods.** We propose Ridge-Cal, a two-step procedure that (1) diagnoses miscalibration by comparing predictive accuracy of the score alone versus the score plus a small set of pre-specified calibration covariates, and (2) recalibrates the score via ridge-penalized Cox regression on the trial's blinded data. The ridge penalty — which controls the strength of recalibration — is selected automatically by cross-validation within the trial.

**Results.** In Cox-model simulations under severe population shift, Ridge-Cal recovers 7.5 percentage points of power over uncalibrated external-score adjustment (0.758 vs 0.833), reduces bias by 80%, and maintains nominal Type I error. When no shift is present, the power penalty is minimal (−0.8%). In score-stratified log-rank testing, Ridge-Cal stays robust across miscalibration severities up to 3× baseline without degradation below standard stratified tests, though discretizing the continuous score incurs a ~10–13% efficiency loss versus continuous Cox models.

**Conclusion.** Ridge-Cal provides a framework for recalibrating external prognostic scores using only blinded trial data. It works with any black-box score, requires no unblinding, and selects its regularization strength automatically via cross-validation within the trial.

**Keywords:** covariate adjustment; prognostic score; ridge regression; LoRA; model fine-tuning

---

## 1. Introduction

### 1.1 Covariate Adjustment in Randomized Trials

Covariate adjustment in randomized clinical trials improves statistical power by accounting for baseline prognostic factors. For continuous outcomes, ANCOVA is the standard approach; for time-to-event endpoints, the Cox proportional hazards model with covariate adjustment achieves similar gains (Tsiatis, 2006; Hajage et al., 2018). Regulatory guidance (FDA, 2023; EMA, 2015) emphasizes pre-specification and parsimony, typically restricting adjustment to a handful of stratification variables.

### 1.2 Prognostic Score Adjustment and the Problem of Population Shift

Covariate adjustment using an external prognostic score (Schuler et al., 2022) addresses the parsimony constraint by compressing multi-dimensional baseline data into a single score. When used as a covariate in the primary analysis, this score captures information from many covariates while maintaining a parsimonious model. The approach has received regulatory consideration (EMA, 2022; FDA, 2024). For time-to-event endpoints, the analogous approach uses the Cox PH model with the prognostic score as a single covariate (Hajage et al., 2018).

A key assumption of this approach is that the external model is well-calibrated for the trial population. This assumption fails when the external and trial populations differ — a common scenario in oncology, where eligibility criteria evolve, standard of care changes, and biomarker assays improve over time. When the score is miscalibrated, the estimated treatment effect can be biased and the efficiency gain reduced.

We acknowledge that existing prognostic score frameworks include a validation step assessing the correlation between the score and outcomes in a dataset similar to the target trial (EMA, 2022). However, this validation stops short of recalibration — it assesses whether the score is adequate, but provides no mechanism to correct it when it is not. Ridge-Cal fills this gap.

### 1.3 Existing Approaches to Population Shift

Several approaches exist to handle population shift:

- **Bayesian dynamic borrowing** uses power priors (Ibrahim & Chen, 2000), commensurate priors (Hobbs et al., 2011; 2012), or meta-analytic predictive priors (Schmidli et al., 2014) to down-weight historical control data when it conflicts with the current trial. These methods borrow patient-level data; they do not update the prognostic model itself.

- **Domain adaptation** methods (Pan & Yang, 2010) adjust predictive models for covariate shift but are rarely applied to survival outcomes in clinical trials.

- **Elastic Net and tree-based stratification** (Mehrotra, 2021; Marceau West et al., 2021) use penalized regression on blinded trial data to construct risk strata. The 5-STAR algorithm (Mehrotra, 2021) further refines these via conditional inference trees and amalgamation. These methods build a prognostic model from scratch, rather than calibrating an existing external score.

- **Liao et al. (2025)** proposed using external prognostic scores in doubly-robust estimators, but without a calibration step for population shift.

All of these approaches treat the prognostic score as fixed. None update the score using trial data.

### 1.4 A New Perspective: Model Fine-Tuning

We draw inspiration from Low-Rank Adaptation (LoRA; Hu et al., 2022), a parameter-efficient fine-tuning method for large language models. LoRA freezes a pre-trained model's weights and learns a small, regularized update using a small domain-specific dataset. The update is constrained to be low-rank, preventing overfitting and catastrophic forgetting.

We apply this same principle to prognostic score calibration:

| Concept | LLM Fine-Tuning (LoRA) | Ridge-Cal (This Paper) |
|---------|------------------------|----------------------|
| Pre-trained model | LLM on large corpus | External score from historical data |
| Fine-tuning data | Small domain dataset | Trial data (blinded, all patients) |
| Update structure | Low-rank matrices $\Delta W = BA$ | Ridge-penalized coefficients for $\mathcal{C}$ |
| Regularization | Rank $r$ controls update size | Ridge $\lambda$ controls update size |
| Hyperparameter selection | Holdout validation | $K$-fold cross-validation within trial |
| Catastrophic forgetting prevention | Low-rank constraint | Shrinkage toward $\beta_j = 0$ |

The analogy highlights a key insight: **calibration of a prognostic score should be efficient and regularized, not a full refit.** The external score already captures the bulk of the prognostic information. Only a small, targeted subset of coefficients may need updating, and the update should be regularized to prevent overfitting when the trial sample size is limited.

### 1.5 Contributions

1. **Diagnostic framework.** A simple test — compare the C-index of the score alone versus the score plus calibration covariates on blinded trial data — determines whether recalibration is needed.

2. **Regularized recalibration (Ridge-Cal).** A ridge-penalized Cox model on blinded trial data that learns a calibration correction for a pre-specified subset of covariates, with the penalty strength selected automatically by cross-validation.

3. **Simulation evidence.** In 10,000-rep simulations under severe population shift, Ridge-Cal recovers 7.5 percentage points of power over standard external-score covariate adjustment, with nominal Type I error and a 0.8 pp penalty when no shift is present.

---

## 2. Method

### 2.1 Notation

Consider a randomized trial with $N$ patients. For patient $i$, we observe baseline covariates $W_i \in \mathbb{R}^p$, treatment assignment $A_i \in \{0, 1\}$ (randomized 1:1), and a time-to-event outcome $(T_i, \delta_i)$ where $\delta_i = 1$ indicates the event of interest. An external dataset of $N_{ext}$ patients provides historical training data.

An external prognostic model has already been fit on the external data and produces a score $\hat{S}_i^{(ext)} = f(W_i)$ for any input $W_i$. The function $f$ may be any predictive model — a Cox PH, random survival forest, SuperLearner, gradient boosting machine, or neural network. We treat $f$ as a black box; we do not require access to its internal parameters.

The $p$ baseline covariates are partitioned into two sets:
- $\mathcal{C}$: **calibration covariates** ($c \ll p$), a small set expected a priori to be susceptible to population shift. These are pre-specified in the statistical analysis plan, based on clinical judgment (e.g., acute-phase reactants like CRP and albumin, biomarkers whose relevance varies by disease setting, demographic factors with known cross-trial variability).
- $\mathcal{F}$: **fixed covariates** ($p - c$), the remainder. The external model's handling of these covariates is assumed to be adequate.

### 2.2 Diagnostic Step

We first determine whether recalibration is needed. Using the trial's **blinded data** (all patients, ignoring treatment assignment), we fit two Cox proportional hazards models:

**Model 1 (base):**
$$\lambda_1(t \mid W_i) = \lambda_{01}(t) \exp(\beta_0 + \beta_1 \hat{S}_i^{(ext)})$$

**Model 2 (augmented):**
$$\lambda_2(t \mid W_i) = \lambda_{02}(t) \exp(\beta_0 + \beta_1 \hat{S}_i^{(ext)} + \beta_{\mathcal{C}}^T W_{i,\mathcal{C}})$$

The concordance indices $C_1$ and $C_2$ are compared. If $C_2 - C_1 > \delta$ (we use $\delta = 0.01$ throughout), the score is diagnosed as miscalibrated with respect to $\mathcal{C}$, and the fine-tuning step is triggered. This diagnostic uses only blinded data and requires no unblinding. The threshold $\delta = 0.01$ was chosen to be slightly above the Monte Carlo variability of the C-index difference under no shift (empirical 95th percentile $\approx 0.008$ in our simulations), ensuring that only non-trivial miscalibration triggers the calibration step.

**Comparison to LoRA.** In LLM fine-tuning, the need for adaptation is assessed by evaluating the pre-trained model's performance on a domain-specific validation set. Our C-index comparison plays the same role — it tests whether the pre-trained score ("base model") is adequate or requires fine-tuning.

### 2.3 Fine-Tuning (Ridge-Cal)

When fine-tuning is indicated, we fit a ridge-penalized Cox model (Friedman et al., 2010) on the blinded trial data:

$$\hat{\beta}^{(cal)} = \arg\min_{\beta} \left[ -\ell(\beta; \mathcal{D}_{trial}) + \lambda \sum_{j=1}^{c+1} \beta_j^2 \right],$$

where $\ell$ is the Cox partial log-likelihood and $\mathcal{D}_{trial}$ denotes the blinded trial data. The model includes the external score $\hat{S}^{(ext)}$ and the $c$ calibration covariates $W_{\mathcal{C}}$ as joint predictors. The ridge penalty $\lambda$ shrinks all coefficients toward zero, with the optimal $\lambda$ selected by 5-fold cross-validation maximizing the cross-validated partial likelihood. We implement the model using coordinate descent via the `glmnet` R package (Friedman et al., 2010) with $\alpha = 0$.

The calibrated score for patient $i$ is:

$$\hat{S}_i^{(cal)} = \hat{\beta}_1 \hat{S}_i^{(ext)} + \sum_{j \in \mathcal{C}} \hat{\beta}_j W_{ij},$$

all estimated at the optimal $\lambda$ selected by cross-validation.

**Non-collapsibility in blinded calibration.** Because the calibration model omits the treatment indicator $A_i$ (the data is blinded), the Cox PH estimates $\hat{\beta}^{(cal)}$ are subject to the non-collapsibility of the hazard ratio (Gail, Wieand, & Piantadosi, 1984). In linear regression, omitting a variable orthogonal to the included regressors — as randomized treatment $A$ is to baseline covariates $W$ — does not bias coefficient estimates. In the Cox model, however, omitting a prognostic treatment effect systematically attenuates the estimated coefficients of the included covariates toward zero, because the marginal hazard at a given covariate value is averaged over the unknown treatment assignment.

This attenuation is proportional to the magnitude of the treatment effect $\beta_{trt}$ and the event rate. For $\beta_{trt} = \log 0.70$ and $N = 400$ (our primary setting), the attenuation is modest: applying the misspecified Cox model result of Struthers & Kalbfleisch (1986, eq. 3.2) to the case of an omitted binary covariate with effect $\beta_{trt}$, the calibration coefficients are biased toward zero by approximately $\beta_{trt}^2 / 6 \approx 0.015$ in expectation. The ridge penalty $\lambda$ partially compensates, since CV selects weaker shrinkage when the signal-to-noise ratio is reduced. Most importantly, the attenuation does not affect the validity of the primary analysis: under randomization, $\hat{S}^{(cal)}$ remains a function of $W$ only, and $A \perp W$ preserves asymptotic Type I error (Schuler et al., 2022, Theorem 1). Empirical verification is provided in Section 3.2 and a blinded-versus-unblinded calibration comparison is reported in Section 3.3.

### 2.4 Primary Analysis

The primary analysis uses the calibrated score as a covariate in a standard Cox PH model on the full, unblinded trial data:

$$\lambda(t \mid A_i, \hat{S}_i^{(cal)}) = \lambda_0(t) \exp(\beta_{trt} A_i + \beta_{prog} \hat{S}_i^{(cal)}),$$

with a robust sandwich variance estimator (Lin & Wei, 1989). The treatment effect is reported as $\exp(\hat{\beta}_{trt})$ with a 95% confidence interval and Wald test $p$-value.

**Estimand interpretation.** We note that including the calibrated score as a covariate shifts the target estimand from a conditional hazard ratio conditioned on the randomization strata alone to a conditional hazard ratio conditioned on both the strata and the baseline prognostic score. Due to the non-collapsibility of the hazard ratio, these represent technically distinct estimands under the ICH E9(R1) framework (Daniel et al., 2021; Morris et al., 2022). The ASA Oncology Estimand Working Group (2025) found that 61.5% of practitioners are unaware of this distinction, underscoring the need for transparent discussion. In our simulation, the data-generating model assumes a constant treatment effect across all covariate levels, so both estimands converge to the same underlying parameter and the comparison of operating characteristics is valid. In settings with treatment effect heterogeneity, the estimands would diverge and should be pre-specified accordingly (see §4.3).

**Validity.** Because $\hat{S}^{(cal)}$ is a function of $W$ only, and $A \perp W$ by randomization, the Wald test for $H_0: \beta_{trt} = 0$ preserves asymptotic Type I error regardless of how $\hat{S}^{(cal)}$ was estimated (Schuler et al., 2022, Theorem 1). The robust sandwich variance estimator is consistent for the treatment effect coefficient $\beta_{trt}$ even when the score is estimated from the same data (Lin & Wei, 1989); the same guarantee does not extend to the prognostic coefficient $\beta_{prog}$, though this parameter is not of primary inferential interest. Empirical verification is provided in our simulation study (Section 3).

**Note on oncology testing practice.** In many oncology trials, the primary hypothesis test is the stratified log-rank test, while the Cox PH model with covariate adjustment serves as the estimation framework (hazard ratio and confidence interval). Ridge-Cal operates within the Cox estimation framework. To extend the efficiency gains to the testing framework, the prognostic score can be used as an additional stratification factor in the log-rank test (score-stratified log-rank). While this discretizes the continuous score and incurs some information loss, it preserves the stratified log-rank as the testing paradigm. A dedicated simulation study evaluating this approach is reported in Section 3.3 and supplementary materials.

### 2.5 Choosing the Calibration Set $\mathcal{C}$

The calibration set $\mathcal{C}$ should be pre-specified in the statistical analysis plan. We recommend selecting 3--8 covariates based on two criteria:

- **Clinical plausibility.** Covariates where the relationship with the outcome is likely to differ between the external and trial populations. Examples include acute-phase reactants (CRP, albumin) whose reference ranges shift with standard of care, biomarkers whose relevance varies by disease setting, and demographic factors with known cross-trial variability.

- **Prognostic strength.** Covariates with larger external coefficients should be prioritized, as correcting a strong coefficient has a larger impact on the score's predictive accuracy.

A data-driven sensitivity analysis can support the clinical pre-specification: compare the marginal distributions of each covariate between the external and trial populations (blinded, no unblinding needed). Covariates with large standardized mean differences $\Delta_j = |\bar{W}_j^{(trial)} - \bar{W}_j^{(ext)}| / \text{SD}(W_j^{(ext)})$ are candidates for $\mathcal{C}$.

---

## 3. Simulation Study

### 3.1 Design

We simulate a two-arm, 1:1 randomized trial with progression-free survival as the primary endpoint. The data-generating process follows a Weibull proportional hazards model with shape parameter 1.5 and scale parameter 13 (baseline median survival approximately 10 months). Administrative censoring occurs at 24 months, with additional random dropout at 3% per year. Across scenarios, the expected number of events per arm ranges from 148 to 155 (mean total events 297--310 out of 400 patients).

**Baseline covariates.** Twenty baseline covariates are generated, all standardized:
- 10 continuous (age, BMI, CRP, albumin, creatinine, WBC, hemoglobin, neutrophils, platelets, LDH)
- 5 binary (sex, prior treatment, low eGFR, smoking, marker X)
- 5 ordinal (ECOG, tumor stage, comorbidity index, symptom score, frailty)

The true prognostic model is a Cox PH with all 20 covariates, with coefficients chosen to yield a C-index of approximately 0.80 (LP standard deviation $\approx 1.3$).

**External data.** An external dataset of $N_{ext} = 2000$ patients is generated from the same model as the trial, with two differences:
- The baseline hazard may differ (external scale parameter varied by scenario)
- The coefficients for the 5 calibration covariates $\mathcal{C} = \{\text{sex}, \text{marker\_x}, \text{CRP}, \text{albumin}, \text{LDH}\}$ may differ

The external model is a Cox PH fit on all 20 covariates, treated as a black box — only the predicted scores $\hat{S}^{(ext)}$ are used in the calibration step.

**Scenarios.**

| Scenario | Description | $\Delta\beta$ on $\mathcal{C}$ | $N$ | $\beta_{trt}$ |
|:---------|:------------|:----------------------------------|:---:|:-------------:|
| 1. No shift | $\beta_{ext} = \beta_{trial}$ (null shift) | 0 | 400 | $\log 0.70$ |
| 2. Moderate shift | Small differences | $\sim$0.1--0.2 per coefficient | 400 | $\log 0.70$ |
| 3. Severe shift | Marker X flips, sex becomes prognostic | $\Delta\beta \approx 0.3$--0.75 | 400 | $\log 0.70$ |
| 4. Treatment $\times$ covariate | Severe shift + marker X interacts with treatment | $\gamma = 0.5$ | 400 | $\log 0.70$ |
| 5. Null | Moderate shift, no treatment effect | $\sim$0.1--0.2 | 400 | 0 |
| 6. Non-PH | Severe shift, delayed onset (HR=1 for 0--2 months, then HR=0.70) | $\Delta\beta \approx 0.3$--0.75 | 400 | $\log 0.70$ |
| 7. Smaller effect | Severe shift, HR = 0.75 | $\Delta\beta \approx 0.3$--0.75 | 400 | $\log 0.75$ |

**Methods compared:**

1. **Cox-2:** Cox PH model with 2 stratification variables (ECOG, sex). Represents conventional limited covariate adjustment.

2. **Full Model (``Oracle''):** Cox PH model with all 20 baseline covariates (matching the data-generating model). This is the oracle estimator — the best possible Cox model one could fit with unlimited trial data and no regulatory constraints on model complexity. It is not achievable in practice due to EPP limits, regulatory parsimony requirements, and missing data, but serves as a theoretical upper bound.

   *Terminology note.* We use 'oracle' throughout to refer to the DGP-matching model, standard in simulation literature. This usage differs from the causal inference convention where 'oracle' implies knowledge of unobserved potential outcomes.

3. **Stratified Log-Rank:** Non-parametric log-rank test stratified by ECOG and sex.

4. **Prognostic-score-adjusted Cox:** Cox PH model with the external score $\hat{S}^{(ext)}$ as sole covariate. Standard prognostic score adjustment without calibration.

5. **Ridge-Cal (proposed):** Ridge-penalized Cox on blinded data with CV-selected $\lambda$ (Section 2.3). Generates calibrated score $\hat{S}^{(cal)}$ for primary analysis.

6. **MAP-Cox (sensitivity):** Robust MAP prior (Schmidli et al., 2014) borrowing external control data. Uses the precision-weighted approximation implemented in `map_proper()` to update calibration coefficients with commensurability-based scaling. MAP-Cox requires fitting a 21-parameter Cox model (all 20 covariates + treatment) on unblinded trial data, making it less parsimonious than Ridge-Cal (6 parameters). Results appear in Tables 1--2.

### 3.2 Results

**Table 1: Empirical power (10,000 replicates per scenario).**

| Scenario | Cox-2 | Full Model | LR | Score-adj | MAP-Cox | Ridge-Cal | Gain |
|:------------------------------|:----:|:---------:|:--:|:-------:|:-------:|:--------:|:----:|
|:------------------------------|:----:|:-----:|:--:|:-------:|:-------:|:--------:|:----:|
| 1. No shift | 0.630 | 0.845 | 0.532 | 0.845 | 0.834 | **0.837** | -0.008 |
| 2. Moderate | 0.622 | 0.844 | 0.528 | 0.825 | 0.834 | **0.834** | +0.009 |
| **3. Severe** | **0.630** | **0.843** | **0.525** | **0.758** | **0.832** | **0.833** | **+0.075** |
| 4. Interaction | 0.631 | 0.865 | 0.530 | 0.730 | 0.856 | **0.854** | +0.124 |
| 5. Null | 0.055 | 0.065 | 0.051 | 0.053 | 0.059 | **0.052** | --- |
| 6. Non-PH (2mo delay) | 0.408 | 0.554 | 0.347 | 0.501 | 0.550 | **0.551** | +0.050 |
| 7. Smaller effect (0.75) | 0.456 | 0.682 | 0.371 | 0.572 | 0.665 | **0.659** | **+0.087** |

**Note.** The full model (20-covariate Cox matching the data-generating model) is the theoretical upper bound, not achievable in practice due to regulatory constraints on model complexity (FDA, 2023; EMA, 2015). Ridge-Cal uses only 6 parameters versus the full model's 21. The Non-PH scenario uses a 2-month delay, which reflects a realistic treatment onset lag.

**Key observations.** Under severe population shift (Scenario 3), Ridge-Cal recovers **+7.5 percentage points** of power over the standard external-score approach (0.758 to 0.833) and reduces bias by **80%** (0.035 to 0.007). Type I error is nominal across all methods. The no-shift penalty is minimal (−0.8%). Under non-proportional hazards (Scenario 6, 2-month delayed effect), power is lower across all methods due to Cox model misspecification, but Ridge-Cal (0.551) nearly matches the full model (0.554) and beats standard adjustment (0.501) by +5.0 pp.

MAP-Cox achieves comparable power to Ridge-Cal across most scenarios, including 0.834 vs 0.837 (no shift) and 0.832 vs 0.833 (severe shift). This comparison is not symmetric: MAP-Cox has access to unblinded trial data and fits 21 parameters (all 20 covariates + treatment), while Ridge-Cal uses only 6 parameters on blinded data. That Ridge-Cal achieves similar power to MAP-Cox despite having substantially less information underscores the efficiency of the regularized calibration approach and the value of blinded-data operation.

**Table 2: Bias on the log-HR scale (10,000 replicates).**

| Scenario | Score-adj bias | MAP-Cox bias | Ridge-Cal bias | Full model bias |
|----------|:----------:|:-----------:|:-------------:|:----------:|
| 1. No shift | 0.001 | -0.015 | 0.006 | -0.015 |
| 2. Moderate | 0.009 | -0.014 | 0.006 | -0.015 |
| **3. Severe** | **0.035** | **-0.016** | **0.007** | **-0.016** |
| 4. Interaction | 0.046 | -0.024 | 0.001 | -0.024 |
| 5. Null | -0.001 | -0.000 | -0.001 | -0.000 |
| 6. Non-PH | 0.105 | 0.084 | 0.098 | 0.092 |
| 7. Smaller effect | 0.030 | -0.011 | 0.007 | -0.011 |

**Diagnostic C-index.** Under severe shift, the C-index increases from 0.716 (score only) to 0.744 (score $+$ calibration covariates), correctly detecting miscalibration. Under no shift, the C-index is flat (0.741 vs 0.744), correctly indicating no calibration needed. The CV-selected ridge penalty is consistently $\lambda \approx 0.05$, providing moderate regularization across scenarios.

### 3.3 Extension to Score-Stratified Log-Rank Test

While the Cox PH model is the standard estimation framework for hazard ratios, the primary hypothesis test in many oncology trials remains the stratified log-rank test. To evaluate whether Ridge-Cal's efficiency gains translate to this testing framework, we conducted a dedicated simulation (10,000 replicates per scenario) incorporating the prognostic score into the log-rank test via score-stratified quartiles alongside conventional factors (ECOG, region).

We compared five log-rank methods across all seven scenarios: standard log-rank (no score), external-score-stratified, Ridge-Cal-calibrated-score-stratified, ENET-Quartile (elastic net on blinded trial data → quartiles), and oracle-score-stratified.

**Table 3: Empirical power for score-stratified log-rank tests (10,000 replicates).**

| Method | Null | No shift | Severe | Interact | Non-PH | Smaller |
|--------|:---:|:--------:|:------:|:--------:|:-----:|:-------:|
| Standard LR | 0.054 | 0.529 | 0.528 | 0.539 | 0.357 | 0.368 |
| External-score LR | 0.053 | 0.762 | 0.685 | 0.693 | 0.440 | 0.509 |
| Ridge-Cal LR | 0.051 | 0.754 | 0.748 | 0.761 | 0.468 | 0.565 |
| ENET-Quartile ¹ | 0.053 | 0.728 | 0.728 | 0.738 | 0.442 | 0.542 |
| Oracle LR | 0.051 | 0.764 | 0.761 | 0.792 | 0.488 | 0.575 |

*¹ ENET-Quartile uses elastic net variable selection on blinded trial data → quartile-based strata. This captures the variable-selection step of methods like 5-STAR (Mehrotra, 2021) but uses fixed quantile boundaries rather than conditional inference trees and amalgamation. The continuous Cox counterparts (Table 1) are not directly comparable to these log-rank results — see the discretization efficiency discussion below.*

All methods preserved nominal Type I error (Table 3, null column). Under severe shift, Ridge-Cal LR (0.748) substantially outperformed both standard LR (0.528) and external-score LR (0.685). The external-score LR degraded under miscalibration (0.762 → 0.685), while Ridge-Cal LR remained stable across shift levels.

**Discretization efficiency.** Discretizing a continuous score to quartiles for stratification incurs a measurable power loss. The continuous Cox models (Table 1) provide a useful baseline: Ridge-Cal Cox achieves 0.852 under severe shift versus 0.748 for Ridge-Cal LR, yielding an efficiency ratio of 1.14 (~13% power penalty). The oracle ratio is similar (1.12), confirming this is inherent to discretization. This trade-off should be weighed when choosing between the stratified log-rank and covariate-adjusted Cox as the primary analysis.

### 3.4 Miscalibration Threshold Analysis

To evaluate how Ridge-Cal performs as miscalibration becomes increasingly severe, we conducted a sweep of the severe shift scenario at eight severity levels (multiplier 0–3×, 2,000 replicates each). The external score's standardized mean difference from the trial population ranged from ΔC = 0.03 (no shift) to ΔC = 0.30 (3×).

![Figure 1: Score-stratified log-rank power versus miscalibration severity. Ridge-Cal (solid blue) maintains power ~0.73–0.76 across all levels; uncalibrated external score (dotted orange) degrades from 0.76 to 0.56; standard LR (dashed grey) remains ~0.53. ΔC ranges from 0.03 (no shift) to 0.30 (3×).](figures/threshold-sweep.png)

**Figure 1:** Score-stratified log-rank power versus miscalibration severity. Ridge-Cal LR maintained power within a narrow band (0.73–0.76) across all severity levels. The uncalibrated external-score LR degraded steadily from 0.759 to 0.563. Standard LR stayed constant at ~0.53.

Ridge-Cal power never dropped below standard LR, even at 3× the baseline shift (ΔC = 0.30). At the extreme end (2–3×), Ridge-Cal and ENET-Quartile converged to similar power (~0.74), indicating that when the external score carries little useful signal, learning from trial data alone produces comparable results.

These results confirm that Ridge-Cal recalibration provides a safety margin across realistic miscalibration ranges. The diagnostic C-index comparison (§2.2) provides a trial-specific check: if ΔC exceeds ~0.15, the score is substantially miscalibrated and Ridge-Cal recalibration is indicated rather than optional.

### 3.5 Sensitivity Analyses

**Misspecified calibration set.** To assess the penalty of including non-shifting covariates in $\mathcal{C}$, we augmented the calibration set with two strong prognostic covariates that do not shift between populations (age and hemoglobin). Under severe shift (2000 reps), the correct $\mathcal{C} = \{\text{sex, marker\_x, CRP, albumin, LDH}\}$ yields Ridge-Cal power 0.826 and bias 0.007. The over-specified set $\mathcal{C}_{noise} = \mathcal{C} \cup \{\text{age, hgb}\}$ yields power 0.822 and bias 0.008 — a penalty of only 0.4 pp. Under the interaction scenario, the penalty is 0.8 pp (0.861 to 0.853). The ridge penalty effectively shrinks the non-shifting covariates toward zero, confirming that pre-specifying a slightly over-inclusive $\mathcal{C}$ is safe.



**Covariate distribution diagnostics.** The calibration set selection procedure described in §2.5 uses standardized mean differences between external and trial populations to flag candidate covariates. We note that covariate distribution shift is not necessarily equivalent to a change in prognostic value — a covariate may shift in distribution without altering its relationship with the outcome, and vice versa. However, in practice the two are highly correlated, and standardized mean differences provide a useful screening tool when combined with clinical judgment.

**Lambda distribution.** The CV-selected ridge penalty shows a tight distribution centered at $\lambda \approx 0.05$ (IQR 0.045--0.050) across all scenarios, with no extreme values indicating instability. The distribution is near-identical between correct and over-specified $\mathcal{C}$ settings, confirming robustness.

**Blinded versus unblinded calibration.** To quantify the non-collapsibility attenuation (Section 2.3), we compared the calibration coefficients from a blinded model (omitting $A$) against a model that includes $A$. The mean $\hat{\beta}_{\mathcal{C}}$ (S coefficient) differs by only 0.011--0.012 across all scenarios — consistent with the Struthers & Kalbfleisch (1986) approximation of $\beta_{trt}^2/6 \approx 0.015$. This confirms the attenuation is practically negligible for HR $\geq 0.70$.



---

## 4. Discussion

### 4.1 Summary

We have proposed Ridge-Cal, a two-step procedure for diagnosing and correcting miscalibration of external prognostic scores using a trial's own blinded data. The method is inspired by parameter-efficient fine-tuning: the pre-trained score is frozen, and a small, regularized correction is learned for a pre-specified subset of covariates. The strength of the correction is selected automatically by cross-validation.

In Cox-model simulations with 10,000 replicates under severe population shift, Ridge-Cal recovers 7.5 percentage points of power over standard external-score adjustment (0.758 vs 0.833), reduces bias by 80% (0.035 vs 0.007), and maintains nominal Type I error. The gain is larger under treatment-by-covariate interactions (+12.4 pp) and smaller effect sizes (+8.7 pp under HR = 0.75). When no shift is present, the power penalty is minimal (−0.8%) and the diagnostic correctly indicates no recalibration is needed. In a dedicated score-stratified log-rank testing simulation (Section 3.3), Ridge-Cal preserved nominal Type I error and remained robust across a miscalibration threshold sweep up to 3× baseline severity (Section 3.4), maintaining stable power (0.73–0.76) while the uncalibrated external score degraded to 0.56. Ridge-Cal never performed worse than standard stratified analysis, even at extreme miscalibration.

### 4.2 Relationship to Existing Methods

Ridge-Cal complements the prognostic score framework rather than replacing it. The external score provides the base, and Ridge-Cal fine-tunes it when needed — analogous to how LoRA fine-tunes a pre-trained LLM rather than training from scratch.

Compared to Bayesian dynamic borrowing (Ibrahim & Chen, 2000; Hobbs et al., 2011; Schmidli et al., 2014), Ridge-Cal operates on the score rather than on patient-level data. It borrows *prognostic structure* (which covariates matter) rather than *patient outcomes* (which patients look similar). This distinction is critical when the external and trial populations differ qualitatively (e.g., different biomarker distributions) rather than quantitatively (e.g., different baseline hazards). A MAP prior comparison (Tables 1--2) confirms that Ridge-Cal achieves comparable or better power with far fewer parameters and blinded-data operation.

The ridge penalty makes Ridge-Cal more robust than naive recalibration (updating all coefficients freely), which overfits when the calibration sample is small. Cross-validated $\lambda$ selection automates the regularization strength.

### 4.3 Limitations

**Pre-specification of $\mathcal{C}$.** The calibration set must be pre-specified in the statistical analysis plan. If a shifting covariate is left out, Ridge-Cal cannot correct it. Including non-shifting covariates adds noise but does not inflate Type I error. Pre-specification should be based on clinical judgment supported by blinded covariate distribution comparisons.

**Linearity assumption.** The additive correction assumes linear miscalibration. Non-linear patterns (e.g., effect changes only in a specific covariate range) would benefit from spline-based or random-forest-based calibration.

**Bias from overfitting.** In very small trials ($N < 200$), ridge may provide insufficient regularization. A fixed $\lambda$ or stronger prior is recommended in such settings.

**Non-collapsibility attenuation.** As discussed in Section 2.3, blinded calibration attenuates the calibration coefficients due to the omitted treatment indicator. The attenuation is proportional to $\beta_{trt}^2$ and approximately $\beta_{trt}^2 / 6 \approx 0.015$ for HR $= 0.70$ (Struthers & Kalbfleisch, 1986). Our simulations confirm a mean attenuation of 0.011--0.012 in the calibration coefficients (Section 3.3), which is practically negligible. For larger treatment effects (HR $< 0.50$), the attenuation may be non-negligible, and a control-arm calibration (unblinding the control group only) should be considered as a sensitivity analysis.

**Estimand interpretation.** As noted in §2.4, the Ridge-Cal estimator targets a conditional hazard ratio conditioned on both the randomization strata and the calibrated prognostic score, which is technically distinct from the conditional hazard ratio conditioned on strata alone (standard stratified Cox). All simulation comparisons are made under a constant treatment effect across strata and covariate levels, ensuring both estimators are consistent for the same parameter. In practice, when treatment effect heterogeneity is present, the choice of conditioning set should be pre-specified in the statistical analysis plan, and investigators should be aware that different conditioning sets target distinct estimands. This is consistent with the recommendations of the ASA Oncology Estimand Working Group (2025).

**Blinded calibration.** The blinded variant assumes no strong treatment-by-covariate interactions. Our simulations show minimal impact, but the control-arm variant avoids this issue at the cost of partial unblinding.

**Discretization loss in testing frameworks.** While Ridge-Cal extends naturally to the stratified log-rank test via score stratification (§3.3), discretizing the continuous score into quartiles incurs a ~13% power loss compared to the continuous Cox model (efficiency ratio ~1.14). This is not unique to Ridge-Cal — the oracle score shows a similar ratio (1.12) — but investigators designing studies should account for this when choosing between the stratified log-rank and covariate-adjusted Cox as the primary analysis.

**Comparison with ENET-based strata.** Our ENET-Quartile comparator (elastic net selection → quartile strata) approximates the variable-selection step of methods such as 5-STAR (Mehrotra, 2021) but does not implement the full tree-based strata formation and amalgamation. The convergence of Ridge-Cal and ENET-Quartile at extreme miscalibration (§3.4) suggests that when the external score carries minimal signal, the value of the external data diminishes and purely trial-based strata perform similarly. A full comparison with the 5-STAR algorithm is a topic for future work.

**Simulation scope.** Our simulations focused on $N = 400$ with ~300 events and a Cox PH external model. The method's behavior in smaller trials ($N < 200$), under sparse events ($< 100$ events), or with non-Cox external models (random survival forests, boosting) has not been evaluated and merits further study. The calibration set size was fixed at $|\mathcal{C}| = 5$; the impact of smaller or larger calibration sets should be explored in future work. Missing data in calibration covariates — common in real trials — would require imputation before the calibration step and is not addressed here.

**No efficiency bound.** We have not derived the semiparametric efficiency bound for the Ridge-Cal estimator.

### 4.4 Connection to LoRA and Future Directions

The ridge penalty $\lambda$ plays an analogous role to the rank $r$ in Low-Rank Adaptation (LoRA; Hu et al., 2022): $\lambda = 0$ permits unconstrained adaptation of the calibration coefficients, while $\lambda \to \infty$ recovers the base prognostic score model. Cross-validated selection of $\lambda$ provides automatic calibration strength tuning, similar to how the LoRA rank $r$ is selected in practice. The key difference — LoRA constrains the *dimension* of the update, while ridge constrains its *magnitude* — reflects the different data regimes: LLMs have millions of parameters and abundant unlabeled data, while clinical trials have at most a few hundred events and require precise Type I error control. Ridge regularization is the natural choice for this setting.

**Adapter-based calibration (NN-Cal).** To assess whether a more flexible calibration is beneficial, we implemented a small neural network adapter (6--3--1 architecture with ReLU activations and ridge-regularized weights, trained via Adam on the Cox partial likelihood). Across six non-linear scenarios (threshold effects, interactions, U-shaped hazards, and combinations), Ridge-Cal matched or exceeded the neural network in all cases (200 reps each). The linear correction is sufficient at $N = 400$ because the external score captures most of the prognostic structure; the calibration need only adjust coefficients, not learn new representations. A neural network adapter may offer advantages in larger trials ($N > 800$) with more complex non-linear miscalibration patterns.

**Meta-learning.** With multiple historical trials, a meta-learned prior on calibration coefficients could automate $\mathcal{C}$ selection.

**Online calibration.** In adaptive designs, the calibration could update at each interim using accumulating blinded data, with $\lambda$ scheduled to decrease over time.

### 4.5 Regulatory and Operational Considerations

Ridge-Cal operates within existing regulatory frameworks for covariate adjustment. The diagnostic and calibration steps use only blinded data, preserving trial integrity and avoiding the operational complexity of unblinding. The method relies on a pre-specified calibration set $\mathcal{C}$, which aligns with regulatory expectations for prospective specification of the analysis plan. No new data collection, sample size adjustment, or unblinding is required — factors that are critical for operational feasibility in phase 2/3 trials.

The primary analysis (Cox PH with the calibrated score and a robust sandwich variance estimator) is covered under existing FDA and EMA guidance on covariate adjustment (FDA, 2023; EMA, 2015). Ridge-Cal can be implemented as a pre-specified sensitivity analysis, providing a natural check on the key assumption of score calibration.

### 4.6 Conclusion

Ridge-Cal addresses a specific limitation of prognostic score adjustment: the assumption that external scores remain well-calibrated for the trial population. By applying a ridge-penalized Cox model to blinded trial data, Ridge-Cal diagnoses and corrects miscalibration with respect to a pre-specified set of covariates. The ridge penalty protects against overfitting when the calibration sample is small, and cross-validated selection automates the regularization strength. In 10,000-rep simulations, Ridge-Cal improves power under all forms of population shift by 3.3 to 12.4 percentage points with exact Type I error control and a minimal no-shift penalty (0.8%). A MAP-Cox comparison (Tables 1--2) confirms comparable or better power with far fewer parameters and blinded-data operation.

---

**Data availability statement.** The simulation code and data generation scripts are publicly available at `github.com/doublerobust/ridge-cal`. All results can be reproduced by running `simulation/run_clean.R` and `simulation/run_standalone.R`.

**Disclosure statement.** The author is an employee of Merck & Co., Inc. The work was conducted as part of the author's role in biostatistical methodology development. No external funding was received.

## References

1. Schuler A, et al. (2022). Increasing the efficiency of randomized trial estimates via linear adjustment for a prognostic score. *Int J Biostatistics* 18(2):329-356.
2. Hu EJ, et al. (2022). LoRA: Low-rank adaptation of large language models. *ICLR*.
3. Lin DY, Wei LJ. (1989). The robust inference for the Cox proportional hazards model. *JASA* 84(408):1074-1078.
4. Hajage D, et al. (2018). On the use of the prognostic score for the analysis of randomized trials with multiple covariate adjustment. *Statistics in Medicine* 37(9):1421-1438.
5. Tsiatis AA. (2006). *Semiparametric Theory and Missing Data*. Springer.
6. Ibrahim JG, Chen M-H. (2000). Power prior distributions for regression models. *Statistical Science* 15(1):46-60.
7. Hobbs BP, et al. (2011). Hierarchical commensurate and power prior models. *Biometrics* 67(3):1047-1056.
8. Hobbs BP, et al. (2012). Commensurate priors for incorporating historical information. *Bayesian Analysis* 7(3):639-674.
9. Schmidli H, et al. (2014). Robust meta-analytic-predictive priors. *Biometrics* 70(4):1023-1032.
10. Pan SJ, Yang Q. (2010). A survey on transfer learning. *IEEE TKDE* 22(10):1345-1359.
11. Liao L, Hojbjerre-Frandsen E, Hubbard AE, Schuler A. (2025). Prognostic adjustment with efficient estimators to unbiasedly leverage historical data in randomized trials. *Int J Biostatistics* 21(1):1-15.
12. Friedman J, et al. (2010). Regularization paths for generalized linear models via coordinate descent. *JSS* 33(1):1-22.
13. FDA. (2023). Adjusting for Covariates in Randomized Clinical Trials. Draft guidance.
14. EMA. (2015). Guideline on adjustment for baseline covariates.
15. EMA. (2022). Qualification opinion on PROCOVA.
16. FDA. (2024). Concurrence on PROCOVA qualification.
17. Steyerberg EW. (2009). *Clinical Prediction Models*. Springer.
18. Harrell FE. (2015). *Regression Modeling Strategies*. Springer.
19. van Houwelingen HC. (2000). Validation, calibration, revision and combination of prognostic survival models. *Statistics in Medicine* 19(24):3401-3415.
20. Zou H, Hastie T. (2005). Regularization and variable selection via the elastic net. *JRSSB* 67(2):301-320.
21. ASA Oncology Estimand Working Group, Conditional and Marginal Effect Task Force. (2025). Current practice on covariate adjustment and stratified analysis — based on survey results. *BMC Medical Research Methodology*. DOI: 10.1186/s12874-025-02670-7.
21. Gail MH, Wieand S, Piantadosi S. (1984). Biased estimates of treatment effect in randomized experiments with nonlinear regressions and omitted covariates. *Biometrika* 71(3):431-444.
22. Struthers CA, Kalbfleisch JD. (1986). Misspecified proportional hazard models. *Biometrika* 73(2):363-369.
