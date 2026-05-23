# Statistical Review: Score-Stratified Log-Rank Integration Plan

**Reviewer:** Natasha (subagent methodology reviewer)  
**Date:** 2026-05-22  
**Document reviewed:** `score-stratified-logrank-plan.md`  
**Context:** Ridge-Cal manuscript (JBS submission-ready, post-reviewer-2 revisions)

---

## Executive Summary

The plan proposes extending Ridge-Cal's evaluation framework from Cox-based estimation to the
stratified log-rank testing framework — motivated by the fact that oncology trials use the stratified
log-rank as the primary analysis for the formal hypothesis test while Cox PH with covariate
adjustment provides the estimation (HR + CI). This is a reasonable practical extension with
operational relevance. **However, the plan as written has several unaddressed statistical gaps
that could — if implemented naively — produce misleading results or fail to convince reviewers.**
The proposal is sound in concept but needs substantial methodological refinement and
transparency about its limitations.

**Verdict: Major Revision** (of the plan, not the paper — the plan needs significant rework before
implementation proceeds to full-scale simulation)

---

## 1. Statistical Validity: Does Score-Stratified Log-Rank Preserve Type I Error?

### 1.1 The surface-level argument works, but…

For the **external score** $\hat{S}_{ext}$: stratifying the log-rank by quantiles of an *external* score
is clearly valid. The score is a function of baseline covariates $W$ only, and $A \perp W$ by
randomization. The stratified log-rank test conditions on the strata (which are fixed under the null),
so the permutation distribution within each stratum is preserved. This is textbook:
Fleming & Harrington (1991), Klein & Moeschberger (2003).

For the **Ridge-Cal calibrated score** $\hat{S}_{cal}$: the argument becomes more subtle. The
calibrated score uses *blinded trial outcome data* to estimate the coefficients $\hat{\beta}^{(cal)}$,
and then the score quantiles are computed from the **trial sample distribution** of
$\hat{S}_{cal}$. This means:

1. The strata boundaries are **estimated from the trial data**, not pre-specified.
2. The calibrated score values depend on the trial outcomes (through the Ridge-Cal Cox fit on
   blinded data).
3. The quantile cut-points are therefore data-adaptive, not fixed.

**Critically, the log-rank null distribution conditions on the strata as if they were known a
priori. When the strata boundaries are estimated from the same data used for testing, standard
asymptotic theory for the stratified log-rank may not hold.** This is a well-documented issue
for post hoc stratification (e.g., Lausen & Schumacher 1992 for the maximally selected log-rank
statistic; Altman et al. 1994 for cutpoint optimization bias).

### 1.2 Why this might still be OK — but needs justification

Three arguments could rescue validity:

**(a) The score is a function of $W$ only.** The calibrated score $\hat{S}_{cal}$ is estimated
from a Cox model that does not include treatment $A$. Under $H_0: \beta_{trt} = 0$, the outcome
is independent of $A$, and the blinded data provides a consistent estimate of the prognostic
structure regardless of $A$. The strata boundaries are then functions of $W$ only (estimated
with noise from the outcome data, but the noise vanishes as $N \to \infty$). This justifies
asymptotic validity but the **finite-sample behavior** needs the simulation to demonstrate.

**(b) This is the same issue as PROCOVA.** PROCOVA itself uses the estimated score $\hat{S}_{ext}$
as a covariate, and Schuler et al. (2022, Theorem 1) established validity because the score
is a function of $W$ only. The stratified log-rank version faces an identical situation — the
strata are functions of $W$ — but with the added wrinkle of discretization and in-sample
quantile estimation. The argument needs to be made explicitly.

**(c) The discretization adds robustness.** If the score ordering is even moderately
well-calibrated, small estimation errors in the Ridge-Cal coefficients will not change the
quantile membership of most patients. This "smoothing" effect of discretization may make the
test more robust to calibration noise than the continuous Cox model.

### 1.3 Required additions to the plan

- Add explicit citation and discussion of post hoc stratification literature.
- Add a theoretical justification (or at minimum an asymptotic argument) for why
  data-adaptive strata boundaries preserve Type I error.
- The plan should specify that Type I error evaluation under Scenario 5 (null) must use
  **10,000+ reps** for precision (0.05 ± 0.004), not 100. The plan's mention of "100 reps"
  for initial testing is adequate for power exploration but dangerously misleading for Type I
  error — use at least 2,000 for Type I error screening, 10,000 for the final table.

---

## 2. Simulation Design: What's Missing?

### 2.1 The comparison table is good but incomplete

The four-method comparison (standard LR, score-stratified LR, Ridge-Cal-stratified LR, oracle
LR) is sensible. However, the plan misses several critical simulation arms:

| Missing Comparison | Why It Matters |
|-------------------|----------------|
| **Ridge-Cal Cox (continuous score)** | This is the baseline from the main paper. The log-rank results must be compared against it directly to quantify the discretization loss. |
| **Score-stratified log-rank with TRUE score quantiles** | The plan includes "oracle" stratified log-rank (true $S_{true}$ quantiles). This separates the *stratification benefit* from the *calibration benefit* — valuable for understanding mechanism. |
| **Continuous score log-rank trend test** | See Section 2.3 below. |
| **Nested comparison: K=1 (no score strata)** | This is just standard stratified log-rank (Method 1). Not needed separately but worth noting. |

### 2.2 Missing scenarios

The plan reuses the original paper's 7 scenarios, which is appropriate for consistency. But
additional scenarios are needed to stress-test the **score-stratified** approach specifically:

| Missing Scenario | Rationale |
|-----------------|-----------|
| **Weak prognostic score** (C-index ~0.60–0.65) | If the external score barely predicts, stratification by its quantiles adds little. The log-rank test may not benefit. Need to show the method doesn't *hurt*. |
| **Sparse strata** ($N=200$, K=5, 3 stratification factors) | With 5×2×2 = 20 strata and 200 patients = 10 per stratum, ~3–4 events each. This is the regime where stratified log-rank degrades. |
| **Extreme score skew** (e.g., 90% of patients in one quantile) | If the external score concentrates patients (e.g., all predicted near-median survival), quantile-based strata will be unbalanced and uninformative. |
| **Score-calibration harms ordering** (calibration adds noise under no shift) | The Ridge-Cal calibrated score could, in small samples, produce *worse* ordering than the raw external score. The log-rank would then lose power relative to external-score stratification. |

### 2.3 Omission: Trend test (ordered strata)

The stratified log-rank treats the score strata as **nominal categories** — it ignores the natural
ordering of the score. This is a significant missed opportunity. A **log-rank test for trend**
across ordered score strata (Tarone 1975; the `survival::survdiff` function can handle this with
score strata coded as ordered factor + appropriate contrasts) would:

1. Use the ordinal information in the score quantiles rather than discarding it
2. Be more powerful when the score genuinely orders risk (as it should)
3. Provide a natural bridge between the discrete stratified test and the continuous Cox model

The plan should add, as Method 5 or a sensitivity arm: **Ordered score-stratified log-rank
trend test** — which tests whether the treatment effect varies across ordered score strata in
a monotonic pattern.

### 2.4 Metric gap: Should report stratum-level event distribution

The plan lists "Type I error" and "Power" as primary metrics. An additional essential diagnostic:

- **Number of non-empty strata per replicate** (especially under small N)
- **Proportion of events in smallest stratum** (detects sparse-strata degradation)
- **Within-stratum event balance** (expected 50:50 by randomization, but sparse strata can
  produce 0 events in one arm within a stratum, making that stratum non-informative)

---

## 3. Practical Concerns

### 3.1 Sparse strata — deeper analysis needed

The plan correctly identifies sparse strata as a risk. Let's quantify it:

- **Worst case:** 3 stratification factors (ECOG 0/1, region US/ex-US, score K=4 quantiles) =  
  $2 \times 2 \times 4 = 16$ strata.
- With $N=400$, $\approx 25$ patients/stratum, $\approx 19$ events/stratum, $\approx 9$ per arm.
- With $N=200$, $\approx 12$ patients/stratum, $\approx 9$ events/stratum, $\approx 5$ per arm.

The stratified log-rank test loses efficiency when many strata have < 5 events per arm.
At $N=200$, about half the strata will have < 5 events in at least one arm.

**The plan should pre-specify a fallback** for when strata become too sparse: pool adjacent
score strata (e.g., collapse K=4 → K=2), or drop the score strata and fall back to standard
stratification. This decision rule should be specified in the simulation protocol, not
determined post hoc.

### 3.2 Discretization loss quantification

The plan says "binning a continuous score loses information vs. using it as a continuous covariate
in Cox." This is understated. Let me be precise:

- **At K=4**, the stratified log-rank discards 3 degrees of freedom of score variation per
  stratum. The within-stratum risk heterogeneity is completely ignored.
- **At K=5**, the loss is slightly smaller but still substantial.
- **The loss can be quantified:** the relative efficiency of the discretized score log-rank
  vs. the continuous-score Cox Wald test under $H_1$ can be computed. This ratio is likely
  in the range 0.80–0.95 depending on K and the true score-risk relationship.

**Critical implication:** If the score-stratified log-rank shows a power gain over the standard
log-rank, that's the *net* effect of (a) risk stratification benefit minus (b) discretization loss.
The plan should attempt to decouple these.

### 3.3 SAP integration

The plan says "the score strata are pre-specified in the SAP, just like any stratification factor."
This is operationally more complex than stated:

- In a real trial, the SAP stratification factors are locked before database lock and
  unblinding.
- The external score $\hat{S}_{ext}$ quantiles **can** be pre-specified if the external model is
  fixed and the cut-points are defined relative to the external distribution (e.g., external
  data quartiles).
- The **Ridge-Cal calibrated** score quantiles **cannot** be pre-specified because:
  - The calibration occurs during the trial (on blinded data)
  - The calibrated score values depend on the trial outcomes
  - The quantile boundaries are trial-distribution-dependent
  
**This is a fundamental operational issue.** The SAP cannot specify the Ridge-Cal score
strata boundaries a priori because they depend on data yet to be collected. The SAP can
specify the *procedure* (calibrate via Ridge-Cal, cut at trial quantiles), but not the
cut-points. The plan should:

1. Propose forward: pre-specify external score quantiles (from external data) in the SAP for
   the primary log-rank, and include Ridge-Cal strata as a sensitivity analysis.
2. Or: pre-specify the *method* for determining strata boundaries from trial data, analogous
   to how adaptive stratification rules are specified.

### 3.4 Treatment-arm-stratified log-rank syntax issue

The R code snippet in the plan:
```r
survdiff(Surv(time, event) ~ treatment + strata(ecog, region, score_stratum))
```
is correct for a two-arm test with stratification. However, the score_stratum must be a factor
variable, not the raw quantile integer. The `survdiff` function expects `strata()` to contain
factor variables; integer codes work but may produce confusing output labels. Minor but worth
noting for the implementation.

---

## 4. Presentation Strategy

### 4.1 Primary vs. Sensitivity Analysis

The plan recommends presenting stratified log-rank as **sensitivity analysis / practical
extension**. I agree with this placement, with the following reasoning:

**Why NOT primary:**
- Ridge-Cal is fundamentally a Cox-based method — the calibration itself uses the Cox partial
  likelihood. The "natural" evaluator of Ridge-Cal is the Cox Wald test with the calibrated
  score as a continuous covariate. This is internally consistent.
- The stratified log-rank loses information through discretization. If Ridge-Cal shows a gain
  in the Cox framework but fails to show a gain in the log-rank framework, that says more
  about the inefficiency of discretization than about the method.
- The regulatory trajectory for PROCOVA is Cox-based (EMA qualification). Log-rank analysis
  is a separate track.

**Why it should still be included:**
- Reviewer 2 (or other reviewers) may well ask: "In oncology, the primary analysis is the
  stratified log-rank test. How does Ridge-Cal help *testing*?" The plan correctly anticipates
  this concern.
- If the log-rank results mirror the Cox results (efficiency gain + nominal Type I error),
  it significantly strengthens the manuscript's claim that Ridge-Cal is a general-purpose
  improvement, not a Cox-specific artifact.
- It bridges the gap between methodology papers (which focus on estimation) and clinical
  trial practice (which focuses on testing).

**Recommendation:** Present as Section 3.4 in Results ("Extension to the Log-Rank Testing
Framework") with 1–2 tables in the supplement, 1 key figure in the main text. Do **not**
relegate entirely to "additional simulation" — give it enough prominence that reviewers can
see it was a serious consideration, but not so much that it distracts from the core Cox-based
evaluation.

### 4.2 Narrative framing

The paper should frame this as:
> "While Ridge-Cal is designed for the Cox estimation framework — which aligns with PROCOVA's
> operational and regulatory context — we recognize that oncology trials often pre-specify
> the stratified log-rank as the primary hypothesis test. We therefore evaluated whether
> Ridge-Cal's efficiency gains translate from the continuous-score Cox model to the
> discrete-strata log-rank framework."

This frames the log-rank analysis as a **robustness check** rather than a competing analysis.

### 4.3 Recommended supplement structure

- **Table S1:** Full 4×7 results (4 methods × 7 scenarios) for power and Type I error.
- **Table S2:** K sensitivity (K=3,4,5) × selected scenarios (null, severe, interaction).
- **Figure S1:** Power vs. number of score strata (K=2 to K=6).
- **Figure S2:** % non-informative strata across N=200/400/800 (diagnostic of sparse-strata
  degradation).

---

## 5. Blind Spots — What the Author Is Missing

### 5.1 The gap between K=∞ (continuous score) and K=4

The plan presents the stratified log-rank as the natural discretized analog of the continuous
Cox model. But the comparison is asymmetric:

- **Cox model with $\hat{S}_{cal}$:** Uses the continuous score as a single covariate (1 df).
  The full prognostic information is preserved.
- **Stratified log-rank with $\hat{S}_{cal}$ quantiles:** Uses the score to **stratify** the
  baseline hazard by risk group. The score's *within-stratum* predictive power is unused.

These are structurally different approaches to using the score. The Cox model uses the score
to **model the hazard directly** (as a linear predictor). The stratified log-rank uses the
score to **create risk-homogeneous subgroups** (a non-parametric approach). The plan treats
them as if the log-rank is just a "discretized version" of the Cox test. **It is not.** The
stratified log-rank is fundamentally different — it avoids any proportionality assumption
across strata but loses the continuous risk gradient within strata.

This distinction has practical implications:
- If the score-risk relationship is non-linear, discretization may actually *help* (the
  stratified log-rank is robust to within-stratum misspecification).
- If the relationship is linear (as the Cox model assumes), discretization hurts.

The plan should consider this tradeoff explicitly.

### 5.2 Blinded calibration → unblinded log-rank: sequential estimation risk

The procedure is:
1. Fit Ridge-Cal on blinded data → get $\hat{S}_{cal}$
2. Compute trial quantiles of $\hat{S}_{cal}$ → define strata
3. Fit stratified log-rank with unblinded $A$ + strata

Steps 1–2 use outcome data (blinded). Step 3 uses the same outcome data (unblinded). The
strata definition is therefore **outcome-informed**, even if blinded. Under $H_0$, the strata
boundaries are just functions of $W$ plus outcome noise (under the null, outcome is independent
of $A$). This is asymptotically fine but the finite-sample dependence structure needs
evaluation.

**Concrete risk:** In a finite sample, the Ridge-Cal fit on blinded data may produce
calibrated scores that over-sort patients by *random* outcome fluctuations. The resulting
quantile strata may be outcome-stratified, creating spurious "risk groups" that the
subsequent unblinded log-rank then conditions on. This could inflate Type I error or create
artifactual power gains.

**Mitigation:** The simulation should compare:
1. Score strata from calibrated score (using trial outcome data)
2. Score strata from external score only (no outcome data used)
3. Fixed strata boundaries (external data quantiles, applied to trial patients)

If methods 1 and 2 give similar Type I error, the concern is empirically resolved.

### 5.3 Cox non-collapsibility → log-rank: different mechanism

The main paper devotes significant attention to non-collapsibility in the blinded Cox
calibration. The log-rank test is **not** susceptible to non-collapsibility in the same way
because it is a permutation test, not a model-based estimator. The log-rank test statistic
is asymptotically equivalent to the score test from the Cox model (with no covariate), and
under $H_0$, it is distribution-free.

**However**, the stratified log-rank test statistic's asymptotic variance is affected by the
stratum-specific event distributions. If the calibrated score strata create strata with
systematically different censoring patterns or event rates (which they will — that's the
point), the log-rank test's power depends on the *within-stratum* treatment-event
association, not the *between-stratum* risk gradient. This is qualitatively different from
the Cox model, where the score enters as a *between-patient* predictor.

**Implication:** Ridge-Cal could improve the score's ordering of patient risk without
improving the log-rank test's ability to detect a treatment effect, because the log-rank
test only uses the ordering for stratification, not for risk adjustment. The plan does not
acknowledge this.

### 5.4 No discussion of the non-PH scenario for log-rank

The original manuscript includes a non-PH scenario (2-month delayed effect) where the
stratified log-rank had power 0.347 vs. Cox-2 at 0.408. If the score-stratified log-rank
struggles similarly (or worse) under non-PH, the comparison needs careful framing.

The plan reuses the 7 scenarios, including non-PH. Good. But the discussion should
specifically address: **Does adding score strata improve the log-rank test's robustness to
non-PH?** Intuitively yes — finer strata by risk group might better enforce the
within-stratum PH assumption. But this needs simulation evidence.

### 5.5 Missing: familywise error rate

If the paper reports **both** the Cox-based primary analysis **and** the log-rank test as
co-primary or as both "primary analyses," the multiplicity across testing frameworks needs
addressing. Real oncology SAPs often specify the log-rank as the primary analysis and the
Cox HR as estimation, but both are reported without correction. If Ridge-Cal intends to
support both, the paper should note that:
- The two tests are not independent (they use the same data)
- Familywise error inflation is minimal under the null (since both are tests of the same
  $H_0$, they are positively correlated)
- But in principle, if both are pre-specified, Bonferroni or a closed testing procedure
  should be considered

### 5.6 Log-rank is not the only testing framework in oncology

The plan focuses on the stratified log-rank, but modern oncology trials increasingly use:

- **MaxCombo test** (combination of log-rank and weighted Kaplan-Meier tests) for
  non-proportional hazards scenarios
- **Restricted mean survival time (RMST)** as a alternative to the log-rank
- **Cox score test** with covariate adjustment

Score stratification could theoretically be applied to any of these. The plan's narrow focus
on the log-rank is understandable as a starting point, but the Discussion should acknowledge
that the same stratification approach generalizes.

---

## 6. Recommended Implementation Changes

Before proceeding to full-scale simulation:

1. **Add the trend test** (ordered log-rank across score strata) as a comparison method.
2. **Add weak-score scenario** (external C-index ~0.60).
3. **Specify sparse-strata fallback rule** explicitly in the simulation protocol.
4. **Separate external-score strata from calibrated-score strata** in the simulation analysis
   — don't conflate them.
5. **Increase initial test to at least 500 reps** (not 100) for meaningful Type I error
   screening. Reserve 10,000 for the final run.
6. **Pre-compute external-data quantiles before simulation** so that the "pre-specified strata"
   approach is cleanly implemented and comparable to data-adaptive strata boundaries.
7. **Document the Cox-to-log-rank efficiency ratio** — for each scenario, compute
   `Power(log-rank) / Power(Cox continuous score)` to quantify discretization loss.

---

## 7. Verdict

**Major Revision** (of the plan)

The concept is sound and operationally relevant. However, the plan has significant gaps:

- **Statistical theory:** The validity of data-adaptive score strata boundaries for the
  stratified log-rank is asserted without justification. Post hoc stratification literature
  needs to be addressed.
- **Simulation scope:** Missing key scenarios (weak score, extreme sparsity, trend test) that
  would stress-test the approach. The initial 100-rep plan is inadequate.
- **Operational realism:** The SAP integration issue — pre-specifying strata boundaries for
  a data-adaptive calibrated score — is more complex than presented.
- **Fundamental framing:** The Cox-based analysis and the stratified log-rank use the score
  in structurally different ways (continuous predictor vs. stratification factor). The plan
  treats them as interchangeable, which they are not.
- **Mechanism clarity:** The plan never asks: "If the score-stratified log-rank shows a power
  gain, *why* did it work?" Without this, the analysis risks being a "look, a number!"
  result that doesn't advance understanding.

These gaps are fixable. The plan should be revised before implementation begins, and the
revisions should engage with the statistical theory (not just the simulation mechanics). Once
addressed, the analysis has clear value as a sensitivity analysis in the Ridge-Cal paper.
