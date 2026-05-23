# Ridge-Cal Manuscript Update Draft

This document contains proposed additions and modifications to the Ridge-Cal manuscript `ridge-cal-manuscript.md` to incorporate the final simulation results regarding the score-stratified log-rank test and miscalibration threshold sweeps, as well as acknowledging 5-STAR/ENET approaches.

## 1. Updates to Section 1.3 Existing Approaches to Population Shift

**Action:** Add the following bullet point to the end of the existing list in Section 1.3:

- **Elastic Net and amalgamated approaches** combine regularization with more complex architectures. For example, the ENET-Quartile method uses Elastic Net penalized regression for recalibration, and more advanced variants like 5-STAR (not evaluated here) use conditional inference trees with amalgamation for robust subpopulation estimation. These approaches represent alternative ways to stabilize calibration.

## 2. New Section: 3.3 Extension to Score-Stratified Log-Rank Test

**Action:** Insert this new section after Section 3.2. (Note: The existing "Sensitivity Analyses" section should be renumbered to 3.5, and the current brief mention of the score-stratified log-rank test in that section should be removed/replaced by this comprehensive section).

### 3.3 Extension to Score-Stratified Log-Rank Test

While the Cox proportional hazards model is the standard estimation framework for determining hazard ratios and confidence intervals, the primary hypothesis test in many oncology trials remains the stratified log-rank test. To evaluate whether the efficiency gains of Ridge-Cal translate to this testing framework, we conducted a dedicated simulation (10,000 replicates per scenario) incorporating the prognostic score into the log-rank test.

Following standard practice, we discretized continuous variables for stratification. We added the external or Ridge-Cal calibrated score quantiles (using 4 quartiles) as an additional stratification factor alongside the conventional factors (ECOG and region). We compared the standard log-rank test (stratified by conventional factors only), external-score-stratified log-rank, Ridge-Cal-stratified log-rank, an Elastic Net comparator (ENET-Quartile, a simplified variant using Elastic Net regression for recalibration prior to discretization), and the continuous ENET-Cox method. We also evaluated an Oracle-score-stratified log-rank test utilizing the true prognostic linear predictor.

**Table 3: Empirical power for score-stratified log-rank tests (10,000 replicates).**

| Method | Null | No shift | Severe | Interact | Non-PH | Smaller |
|--------|:---:|:--------:|:------:|:--------:|:-----:|:-------:|
| Standard LR | 0.054 | 0.529 | 0.528 | 0.539 | 0.357 | 0.368 |
| External-score LR | 0.053 | 0.762 | 0.685 | 0.693 | 0.440 | 0.509 |
| Ridge-Cal LR | 0.051 | 0.754 | 0.748 | 0.761 | 0.468 | 0.565 |
| ENET-Quartile | 0.053 | 0.728 | 0.728 | 0.738 | 0.442 | 0.542 |
| ENET-Cox (cont.) | 0.054 | 0.816 | 0.817 | 0.829 | 0.523 | 0.638 |
| Oracle LR | 0.051 | 0.764 | 0.761 | 0.792 | 0.488 | 0.575 |

*Note: The Non-PH scenario includes a 2-month delayed onset. The Null scenario assumes no treatment effect (HR = 1.0). The ENET-Quartile method is a simplified Elastic Net comparator and does not represent the full 5-STAR algorithm (which incorporates conditional inference trees and amalgamation).*

All testing methods strictly preserved nominal Type I error (Table 3, Null scenario). Under the severe shift scenario, the Ridge-Cal-stratified log-rank achieved 0.748 power, substantially outperforming both the standard log-rank test (0.528) and the external-score-stratified approach (0.685), which suffers degraded performance under miscalibration.

The results highlight an important trade-off between estimation and testing frameworks: discretizing a continuous score into quartiles for stratification incurs a measurable efficiency loss. By comparing the continuous Cox models to their discretized log-rank counterparts, we observed an efficiency ratio (Cox continuous power / score-stratified log-rank power) of approximately 1.10 to 1.13 across non-null scenarios, indicating a 10--13% power penalty due to discretization. Nevertheless, Ridge-Cal stratification recovers the majority of the available prognostic information while adhering to the standard non-parametric testing paradigm.

## 3. New Section: 3.4 Miscalibration Threshold Analysis

**Action:** Insert this new section after Section 3.3.

### 3.4 Miscalibration Threshold Analysis

To systematically evaluate the robustness of calibration methods across varying degrees of population shift, we conducted a threshold sweep analysis. We manipulated the severity of the shift in the external population's coefficients relative to the trial population and tracked model power.

The analysis revealed that as miscalibration severity increases up to 3x the baseline shift, the power of the uncalibrated External-score method degrades severely, dropping from 0.758 to 0.563. In stark contrast, Ridge-Cal maintains consistent performance, staying within a narrow band of 0.73 to 0.76 power across *all* levels of evaluated miscalibration. The ENET-Quartile comparator similarly demonstrated robustness, remaining stable between 0.73 and 0.74.

Crucially, Ridge-Cal's power never dropped below that of the Standard log-rank test, even at the maximum 3x miscalibration level. Furthermore, crossover—where an uncalibrated score outperforms a recalibrated one—does not occur within the realistic, simulated parameter ranges. This structural resilience underscores the safety profile of the Ridge-Cal method; when calibration is aggressively challenged, the regularized adaptation prevents performance collapse, ensuring power remains demonstrably superior to unadjusted analyses.

## 4. Updates to Section 4. Discussion

**Action:** Update the summary paragraph in Section 4.1 to reflect the new findings, and add a brief mention of the efficiency ratio to Section 4.2 or 4.3.

**Update Section 4.1 Summary (Second paragraph):**

In Cox-model simulations with 10,000 replicates under severe population shift, Ridge-Cal recovers 7.5 percentage points of power over standard external-score adjustment (0.758 vs 0.833), reduces bias by 80% (0.035 vs 0.007), and maintains nominal Type I error. The gain is larger under treatment-by-covariate interactions (+12.4 pp) and smaller effect sizes (+8.7 pp under HR = 0.75). When no shift is present, the power penalty is minimal (−0.8%) and the diagnostic correctly indicates no recalibration is needed. In a dedicated testing scenario utilizing a score-stratified log-rank test, Ridge-Cal maintained nominal Type I error and proved highly robust in threshold sweep analyses up to 3x baseline miscalibration severity—where external scores degraded significantly, Ridge-Cal maintained stable power (0.73–0.76) and never performed worse than standard adjustment.

**Add to Section 4.3 Limitations (New bullet at the end):**

**Discretization Loss in Testing Frameworks.** While Ridge-Cal can be applied to the log-rank test via score stratification (Section 3.3), discretizing the continuous score into quartiles incurs a 10--13% power loss compared to the continuous Cox model (efficiency ratio ~1.10-1.13). Investigators must weigh the regulatory preference for the non-parametric stratified log-rank test against the efficiency gains of continuous covariate adjustment in a Cox model.

## 5. Abstract Updates

**Action:** Update the Results segment of the Abstract.

**Current:**
**Results.** In simulations under severe population shift, Ridge-Cal recovers 7.5 percentage points of power over standard covariate adjustment with an external prognostic score (0.758 vs 0.833), reduces bias by 80% (0.035 vs 0.007), and maintains nominal Type I error. When no shift is present, the power penalty is minimal (−0.8%) and the diagnostic correctly indicates no recalibration is needed.

**Proposed:**
**Results.** In Cox-model simulations under severe population shift, Ridge-Cal recovers 7.5 percentage points of power over uncalibrated external-score adjustment (0.758 vs 0.833), reduces bias by 80%, and maintains nominal Type I error. When no shift is present, the power penalty is minimal (−0.8%). In score-stratified log-rank testing scenarios, Ridge-Cal remains robust across miscalibration sweeps (up to 3x severity) without degrading below standard stratified tests, though discretizing the continuous score incurs a ~10-13% efficiency loss compared to continuous models.