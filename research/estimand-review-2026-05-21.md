# Methodological Review: Conditional vs Marginal Estimands in Ridge-Cal

## 1. Are the Comparisons "Apples to Apples"?

Strictly speaking, **no, they are not "apples to apples" when evaluating point estimation (bias and coverage).** However, **they are comparable for hypothesis testing (Type I error and power).**

Because the HR is a non-collapsible effect measure, the true value of the estimand changes when you add a prognostic covariate, even in a perfectly randomized trial with no confounding.

- **Stratified Cox** targets HR_{|strata}
- **Ridge-cal** targets HR_{|strata, score}

When a true treatment effect exists (HR ≠ 1), adjusting for a prognostic score will typically drive the estimated HR further away from 1. If simulations evaluate "bias" by comparing both models against a single true marginal HR, the ridge-cal method will appear mathematically biased — not because the estimator is flawed, but because it is estimating a structurally different (and more extreme) conditional HR.

Under the strong null hypothesis (HR = 1), the HR is collapsible. Therefore, comparing Type I error rates is valid. Power comparisons are acceptable provided readers understand that the efficiency gain comes partly from testing a different, more localized estimand.

## 2. What to Acknowledge in the Paper

- **Estimand Distinction:** Ridge-cal shifts the target from strata-conditional to strata-and-score-conditional estimand
- **Non-collapsibility:** Cite Daniel et al., Morris et al. — observed divergence in point estimates when HR ≠ 1 is a known consequence
- **Clinical Interpretability:** Conditional estimands represent "effect for two patients with the exact same strata and prognostic score" rather than a population-averaged measure

## 3. Recommended Sensitivity Analyses

- **Standardization / G-computation:** Apply marginalization (e.g., `stdReg`) to recover the marginal HR — showing ridge-cal after marginalization still yields tighter CI would be a strong selling point
- **PH Assumption Diagnostics:** Check if PH assumption holds better in ridge-cal vs stratified Cox
- **Treatment-by-Score Interaction:** Verify efficiency gains hold without interaction term

## 4. Regulatory Context

- **FDA 2023 Guidance:** Allows covariate adjustment for TTE outcomes, acknowledges non-collapsibility but accepts conditional HRs if pre-specified
- **ASA EWG (2025):** Highlights tension between marginal causal estimands and legacy conditional Cox models — ridge-cal bridges this gap
