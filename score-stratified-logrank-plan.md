# Score-Stratified Log-Rank Test — Revised Integration Plan

## Motivation

Oncology trials use stratified log-rank test as the primary analysis for hypothesis testing. Covariate adjustment via Cox PH model is used for estimation (HR + CI) but is secondary/supportive. Ridge-Cal currently addresses only the Cox estimation framework. For Ridge-Cal's efficiency gains to translate to the primary testing framework, we need to adapt the stratified log-rank test.

**Structural distinction (important):** The Cox model uses the score as a *continuous predictor* (1 df, full information). The stratified log-rank uses it as a *stratification factor* (discrete groups, ignores within-stratum risk gradient). These are not interchangeable — discretization loss is inherent and must be quantified.

## Proposal

Add prognostic score quantiles as an additional stratification factor to the log-rank test — alongside conventional factors (ECOG, region).

## Five Testing Methods

| Method | Testing Framework | Score Used | Type I Error Theory |
|--------|------------------|------------|-------------------|
| 1. Standard stratified log-rank | Stratified by ECOG + region | None | Textbook (Fleming & Harrington 1991) |
| 2. External-score stratified log-rank | Stratified by ECOG + region + external score quantiles | External $\hat{S}_{ext}$ | Valid: score depends on $W$ only, $A \perp W$ |
| 3. Ridge-Cal stratified log-rank | Stratified by ECOG + region + calibrated score quantiles | Ridge-Cal $\hat{S}_{cal}$ | Needs simulation validation (post hoc strata) |
| 4. **Ordered trend test** | Log-rank trend across ordered score strata | Score quantile rank | More powerful when score orders risk correctly |
| 5. Oracle stratified log-rank | Stratified by ECOG + region + true score quantiles | True $S_{true}$ | Reference upper bound |

### Method 4: Ordered Trend Test

A log-rank test for trend across ordered score strata (Tarone, 1975) uses the ordinal information in the score quantiles rather than treating them as nominal categories. This is strictly more powerful than the nominal stratified log-rank when the score correctly orders risk, and provides a natural bridge between the discrete log-rank and continuous Cox frameworks.

Implementation: score_stratum coded as an ordered factor, test for trend in treatment effect across ordinal groups.

## Score Discretization

- **Primary:** K = 4 (quartiles) — balances information capture vs. sparse strata risk
- **Sensitivity:** K = 2, 3, 5
- **Pre-specification approach:** External score quantile boundaries are defined from the *external dataset distribution*, not the trial distribution. This makes them pre-specifiable in the SAP. Ridge-Cal calibrated score quantiles use trial data quantiles — these are data-adaptive and must be specified as a *procedure* in the SAP, not as fixed cut-points.

## Simulation Scenarios

### Required scenarios (matching original Ridge-Cal paper):

| Scenario | Shift | N | Key Question |
|----------|-------|---|-------------|
| Null, N=400 | None | 400 | Type I error |
| No shift, N=400 | None | 400 | Power penalty of adding score strata |
| Moderate shift, N=400 | Moderate | 400 | Power gain |
| Severe shift, N=400 | Severe | 400 | Power gain under real conditions |
| Small trial, N=200 | Severe | 200 | Sparse strata stress test |
| Large trial, N=800 | Severe | 800 | Asymptotic behavior |

### Additional scenarios (score-stratified-specific):

| Scenario | Rationale |
|----------|-----------|
| **Weak prognostic score** (C-index ~0.60) | Score barely predicts — does stratification hurt? |
| **Extreme score skew** (90% in one quantile) | Unbalanced strata test |
| **Null + score calibration noise** | Does Ridge-Cal calibrated score produce worse ordering than raw score under null? |
| **Non-PH scenario** | Score stratification may improve within-stratum PH assumption |

## Primary Metrics

1. **Type I error** — $H_0: \beta_{trt} = 0$, target 0.05 one-sided
   - Screening phase: 2,000 reps ($\pm 0.010$ precision)
   - Final tables: 10,000 reps ($\pm 0.004$ precision)
2. **Power** — across shift scenarios
3. **Cox-to-log-rank efficiency ratio** — `Power(log-rank) / Power(Cox continuous score)` to quantify discretization loss
4. **Within-stratum diagnostics:**
   - Number of non-empty strata per replicate
   - Proportion of events in smallest stratum
   - Events per arm within each stratum (flag if < 5 in any arm)

## SAP Integration (operational reality)

The reviewer flagged an important issue: **score quantile boundaries cannot be pre-specified in the SAP if they depend on trial outcomes.** Solution:

- **Primary analysis:** Pre-specify external score quantiles *from the external dataset distribution*. The cut-points (e.g., external data quartiles) are fixed before the trial starts. This is clean and preserves the log-rank's validity.
- **Sensitivity analysis:** Pre-specify the *procedure* for calibrated score strata: (1) apply Ridge-Cal to blinded data, (2) cut at trial data quantiles, (3) include as additional stratum in log-rank. The cut-points are data-adaptive but the *method* is pre-specified.
- **Sparse strata fallback:** If any score stratum has < 5 events per arm, collapse adjacent quantiles (K → max(2, K-1)). Specify this rule in the simulation protocol, not determined post hoc.

## Expected Challenges — Acknowledged

| Challenge | Mitigation |
|-----------|-----------|
| **Data-adaptive strata boundaries** | External score strata avoid this. Calibrated strata need simulation evidence for Type I error |
| **Discretization loss** | Quantify via Cox-to-log-rank efficiency ratio |
| **Sparse strata** | Pre-specified fallback: collapse adjacent quantiles |
| **Structural mismatch** | Cox continuous vs. log-rank discrete — present log-rank as sensitivity, not primary lens for Ridge-Cal |
| **Non-PH** | Score stratification may help; test explicitly |

## Recommended Paper Presentation

- **Primary manuscript focus:** Cox-based results (where Ridge-Cal operates)
- **Log-rank results as Section 3.x sensitivity analysis:** Tables showing all 5 methods across scenarios
- **Key message:** The efficiency gains are preserved when translated to the stratified log-rank framework, though attenuated by discretization. This addresses the practical question: "How does this work in a real oncology trial?"

## Implementation Sketch (R)

```r
library(survival)

# Pre-specified external score quantiles (from external data distribution)
ext_quantiles <- c(0, 0.25, 0.5, 0.75, 1)  # fixed before trial

# Method 1: Standard stratified log-rank
survdiff(Surv(time, event) ~ treatment + strata(ecog, region))

# Method 2: External-score stratified log-rank
score_strata <- cut(ext_score, breaks = quantile(ext_score, ext_quantiles),
                    include.lowest = TRUE)
survdiff(Surv(time, event) ~ treatment + strata(ecog, region, score_strata))

# Method 3: Ridge-Cal calibrated score stratified log-rank
# (calibrated score estimated from blinded data, trial-distribution quantiles)
cal_score_strata <- cut(cal_score, breaks = quantile(cal_score, 0:4/4),
                        include.lowest = TRUE)
survdiff(Surv(time, event) ~ treatment + strata(ecog, region, cal_score_strata))

# Method 4: Ordered trend test
survdiff(Surv(time, event) ~ treatment + strata(ecog, region) +
           tt(score_rank), data = d)
# Uses score_rank as ordinal covariate within strata

# Method 5: Oracle (true score quantiles)
survdiff(Surv(time, event) ~ treatment + strata(ecog, region, true_score_strata))
```

## Rep Count Strategy

| Phase | Reps | Purpose |
|-------|------|--------|
| Screening | 500 | Check Type I error (detect >0.06) |
| Small test | 2,000 | Reliable Type I error + power patterns |
| Final | 10,000 | Publication-ready tables |

## References to Add
- Fleming & Harrington (1991) — stratified log-rank theory
- Tarone (1975) — log-rank trend test for ordered alternatives
- Lausen & Schumacher (1992) — maximally selected log-rank (post hoc stratification)
- Altman et al. (1994) — cutpoint optimization bias
- Schuler et al. (2022, Theorem 1) — score validity depends on $W$ only

## Next Steps
1. ✅ Plan drafted + reviewed (Major Revision → revised)
2. Code the simulation
3. Run screening (500 reps)
4. Review → expand or adjust
5. Final run (10,000 reps)
6. Write results section
