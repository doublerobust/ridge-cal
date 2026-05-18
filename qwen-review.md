# Peer Review: Ridge-Cal — Efficient Regularized Calibration of External Prognostic Scores Using Blinded Trial Data

**Journal:** Journal of Biopharmaceutical Statistics (JBS)  
**Manuscript Title:** Ridge-Cal: Efficient Regularized Calibration of External Prognostic Scores Using Blinded Trial Data  
**Author:** Yue Shentu  
**Reviewer:** Qwen (subagent peer review)  
**Date:** May 18, 2026  

---

## 1. Summary of Contributions

The manuscript proposes **Ridge-Cal**, a two-step procedure for diagnosing and correcting miscalibration of external prognostic scores in randomized trials. The method: (1) compares the concordance index of the external score alone versus the score plus a small set of pre-specified calibration covariates on blinded trial data to detect miscalibration; and (2) when miscalibration is detected, fits a ridge-penalized Cox model on the blinded data to learn a regularized calibration correction, with the penalty strength selected by cross-validation. The calibrated score is then used in the primary Cox PH analysis with a robust sandwich variance estimator. The method is motivated by an analogy to Low-Rank Adaptation (LoRA) from deep learning. Simulation results (10,000 replicates) under seven scenarios demonstrate that Ridge-Cal recovers power under population shift while incurring minimal penalty when no shift is present.

---

## 2. Assessment by Dimension

### 2.1 Mathematical Rigor

**Strengths:**
- The formulation is clear and well-defined. The ridge-penalized Cox model (Section 2.3) is standard, and the use of `glmnet` with $\alpha=0$ is appropriate.
- The validity argument for Type I error preservation under randomization (Section 2.4, citing Schuler et al. 2022, Theorem 1 and Lin & Wei 1989) is correct in principle: because $\hat{S}^{(cal)}$ is a function of $W$ only and $A \perp W$, the Wald test for the treatment effect preserves asymptotic Type I error.
- The discussion of non-collapsibility attenuation in blinded calibration (Section 2.3) is a genuine and important insight. Citing Struthers & Kalbfleisch (1986) and Gail et al. (1984) is appropriate. The quantitative approximation $\beta_{trt}^2/6$ is a useful practical guide.
- The distinction between $\mathcal{C}$ (calibration covariates) and $\mathcal{F}$ (fixed covariates) is well-motivated and clearly formalized.

**Concerns:**
- **Section 2.3: The attenuation approximation $\beta_{trt}^2/6$ is stated without derivation or citation of a specific theorem.** Struthers & Kalbfleisch (1986) do discuss misspecified Cox models, but the formula $\beta_{trt}^2/6$ is not a universally cited result from that paper. The reviewer should be asked to either provide a derivation or cite the specific result more precisely. This is a minor issue but affects reproducibility of the claim.
- **The claim that the robust sandwich variance estimator is "consistent even when the score is estimated from the same data" (Section 2.4)** is true for the treatment effect coefficient under randomization (Lin & Wei 1989), but the manuscript does not fully address the impact of estimating the score from the *same* data on the variance of the prognostic coefficient $\beta_{prog}$. This is a known issue in PROCOVA literature (Hajage et al. 2018 discuss this); the sandwich estimator is valid for the treatment effect but may be anti-conservative for the prognostic coefficient's standard error. The authors should clarify this distinction.
- **The C-index threshold $\delta = 0.01$ (Section 2.2)** is chosen without justification. A threshold of 0.01 in C-index difference is extremely small and may trigger unnecessary recalibration in many scenarios due to sampling variability. The manuscript should either justify this choice (e.g., via a power analysis or simulation-based calibration of the threshold) or provide guidance on how to choose $\delta$ based on sample size and event rate.
- **The claim that the CV-selected $\lambda$ is "consistently $\approx 0.05$" (Section 3.2)** across all scenarios is concerning. If the optimal penalty is essentially the same regardless of the magnitude of population shift, this suggests the CV criterion may not be adaptive enough. The authors should investigate whether the CV criterion (maximizing cross-validated partial likelihood) is the optimal choice for calibration, or whether an information-criterion-based criterion (e.g., AIC/BIC on the partial likelihood) or a different validation strategy might be more appropriate.

### 2.2 Statistical Innovativeness

**Strengths:**
- The LoRA analogy is creative and helps communicate the method's philosophy. The core idea — regularized, parameter-efficient fine-tuning of a prognostic score — is novel in the biostatistics literature.
- The diagnostic step (comparing C-index with and without calibration covariates on blinded data) is a simple but useful addition to the PROCOVA toolkit.
- The explicit treatment of the non-collapsibility issue in blinded calibration is a genuine contribution that many applied researchers might overlook.

**Concerns:**
- **The method is essentially ridge regression applied to a specific problem.** While the application is novel, the statistical core is well-established. JBS readers familiar with PROCOVA and regularized regression may find the innovation less substantial than presented. The manuscript should more clearly position Ridge-Cal relative to other PROCOVA extensions (e.g., Hajage et al. 2018's discussion of score estimation uncertainty, or Schuler et al. 2022's own extensions).
- **The LoRA analogy, while illustrative, may overstate the novelty.** The idea of regularized coefficient adjustment for prognostic scores is not entirely new; penalized regression for score calibration has been explored in various forms (e.g., in the clinical prediction model literature by Steyerberg and others). The manuscript should more carefully distinguish Ridge-Cal from these prior approaches.
- **The neural network adapter comparison (Section 5.4) is underpowered.** Only 200 replicates per scenario is insufficient to draw conclusions about the linear vs. non-linear calibration comparison. This should either be expanded to more replicates or removed as a definitive claim.

### 2.3 Simulation Completeness

**Strengths:**
- 10,000 replicates per scenario provides good precision for power and Type I error estimates (standard error of a proportion with $p \approx 0.8$ and $n = 10,000$ is approximately 0.004).
- The seven scenarios cover a reasonable range of conditions: no shift, moderate shift, severe shift, treatment-by-covariate interaction, null treatment effect, non-proportional hazards, and smaller treatment effect.
- The inclusion of MAP-Cox as a sensitivity comparison is valuable.
- The misspecified calibration set sensitivity analysis (over-inclusive $\mathcal{C}$) is well-designed and reassuring.

**Concerns:**
- **Missing scenarios that JBS reviewers will likely expect:**
  - **Small sample sizes.** The manuscript focuses on $N = 400$. Trials with $N = 100-200$ are common in phase II oncology and would be important to test, especially given the acknowledged limitation about small trials.
  - **Varying event rates.** All scenarios appear to use the same data-generating process with similar event counts (~300 events). The method's behavior under sparse events (e.g., 50-100 events) should be assessed.
  - **Different external model types.** The manuscript treats the external score as a black box, which is a strength, but the simulation should verify that Ridge-Cal works well when the external model is a Cox PH (as simulated) versus a non-Cox model (e.g., random survival forest, SuperLearner). The current DGP matches the external model type, which may overstate performance.
  - **Varying the number of calibration covariates.** The method is claimed to work with 3-8 covariates, but only one calibration set ($|\mathcal{C}| = 5$) is used. Performance with $|\mathcal{C}| = 3$ and $|\mathcal{C}| = 8$ should be reported.
  - **Extreme population shift.** The "severe shift" scenario ($\Delta\beta \approx 0.3$--0.75) is moderate by clinical standards. A scenario with $\Delta\beta > 1.0$ (e.g., a biomarker whose effect direction reverses) would be more informative about the method's limits.
  - **Missing data.** Real trials have missing covariate data. The manuscript does not address how Ridge-Cal handles this. If covariates in $\mathcal{C}$ have missing data, the calibration step cannot proceed without imputation, which introduces additional uncertainty.
- **The oracle/full model comparison (Section 3.1) is conceptually problematic.** The manuscript acknowledges that the full model is "not achievable in practice," yet presents it prominently as a benchmark. This is acceptable as a theoretical upper bound, but the gap between Ridge-Cal (0.833) and the full model (0.843) in the severe shift scenario (1.0 pp) should be discussed more carefully: is this gap due to the ridge penalty, the limited calibration set, or the fact that the external score cannot perfectly replicate the full model?
- **The MAP-Cox comparison is not a fair comparison.** MAP-Cox uses unblinded data and 21 parameters while Ridge-Cal uses blinded data and 6 parameters. The fact that Ridge-Cal matches MAP-Cox is impressive, but the comparison should be framed more carefully. A fairer comparison would include a "full PROCOVA with unblinded refit" (refitting all coefficients on unblinded data) to show what Ridge-Cal achieves with fewer parameters and no unblinding.

### 2.4 Prose and Formatting

**Strengths:**
- The writing is generally clear and well-organized. The introduction builds a logical case for the method.
- The LoRA analogy table (Section 1.4) is an effective visual aid.
- The notation is consistent and well-defined.
- The manuscript is well-structured with clear section headings.

**Concerns:**
- **Section 4 ("Results") is redundant with Section 3.2.** The simulation results are presented in Section 3.2 and then repeated in Section 4 with essentially the same content. This is a structural issue that should be resolved: either move all results to Section 4 and renumber, or remove Section 4 and integrate its content into the Discussion.
- **Some formatting inconsistencies:** The manuscript uses both "PROCOVA" and "PROCOVA" inconsistently in table headers (e.g., Table 1 has "Std" which is ambiguous — does it mean "Standard PROCOVA" or "Standard deviation"?). The table formatting could be improved for JBS style.
- **The terminology note in Section 3.1 about "oracle" is helpful but the explanation is overly long for a footnote.** Consider moving this to the main text or a shorter note.
- **The pre-submission checklist (top of manuscript) should be removed before submission.** This is a minor housekeeping item.
- **Reference formatting is inconsistent.** Some references use "et al." and some do not; journal names are abbreviated inconsistently. JBS has specific reference style requirements.
- **The "Disclosure statement" mentions the author is a Merck employee.** This is appropriate for transparency but should be checked against JBS conflict-of-interest requirements.

### 2.5 Regulatory and Operational Fit

**Strengths:**
- The method's use of blinded data is a significant operational advantage. The manuscript correctly emphasizes this throughout.
- The pre-specified calibration set $\mathcal{C}$ aligns well with regulatory expectations for prospective specification.
- The discussion of regulatory frameworks (FDA 2023, EMA 2015/2022) is appropriate and well-placed.
- The method's parsimony (6 parameters vs. 21 for MAP-Cox) is a genuine advantage for regulatory acceptance.

**Concerns:**
- **The manuscript does not address how Ridge-Cal would be presented in a clinical trial report.** Regulators will want to know: how was $\mathcal{C}$ chosen? What was the diagnostic result? What was the selected $\lambda$? What were the recalibrated coefficients? The manuscript should include a worked example or a template for reporting Ridge-Cal in a trial report.
- **The claim that "no new data collection, sample size adjustment, or unblinding is required" needs qualification.** While Ridge-Cal itself does not require these, the diagnostic step adds a pre-specified analysis that should be powered appropriately. The manuscript does not discuss whether the sample size should account for the possibility that Ridge-Cal might be triggered (and the associated uncertainty in the calibration step).
- **The EMA qualification of PROCOVA (EMA 2022) is referenced, but the manuscript does not discuss whether Ridge-Cal would need a separate qualification process.** If PROCOVA is already qualified, does a calibrated variant require additional regulatory engagement?

---

## 3. Major Concerns

1. **Redundant Results Section (Section 4).** Section 4 repeats Section 3.2 content. This must be resolved before publication.

2. **Under-specified simulation design.** Missing scenarios (small samples, varying event rates, non-Cox external models, varying $|\mathcal{C}|$, extreme shift, missing data) are important for a methods paper targeting JBS. At minimum, the authors should acknowledge these as limitations and provide additional simulations for the most critical gaps (small samples and non-Cox external models).

3. **The C-index threshold $\delta = 0.01$ lacks justification.** This is a critical design choice that determines when recalibration is triggered. The manuscript should either justify this threshold theoretically or provide simulation-based guidance on threshold selection.

4. **The non-collapsibility attenuation claim needs a more precise reference.** The formula $\beta_{trt}^2/6$ should be traced to a specific result, not just attributed to Struthers & Kalbfleisch (1986) generally.

5. **The MAP-Cox comparison is not a fair comparison.** The framing should be adjusted to acknowledge that MAP-Cox has access to more information (unblinded data, more parameters), and the comparison is about Ridge-Cal's efficiency in achieving comparable performance with less information.

---

## 4. Minor Concerns

1. Table 1 column header "Std" is ambiguous — clarify whether it means "Standard PROCOVA" or something else.
2. Reference formatting inconsistencies (et al. usage, journal name abbreviations).
3. The neural network adapter comparison (Section 5.4) uses only 200 replicates — insufficient for definitive claims.
4. The claim that the robust sandwich variance is valid for the prognostic coefficient's standard error needs clarification (it is valid for the treatment effect, not necessarily for the prognostic coefficient).
5. The pre-submission checklist at the top should be removed.
6. Consider adding a worked example or reporting template for regulatory submissions.

---

## 5. Verdict

**Major Revision**

The manuscript presents a genuinely useful method for a real problem in trial design. The core idea — regularized, blinded calibration of external prognostic scores — is novel and well-motivated. The simulation evidence is generally strong, and the regulatory discussion is appropriate.

However, the manuscript requires **major revision** before it can be considered for acceptance:

- The redundant Results section must be eliminated.
- The simulation study must be expanded to address critical gaps (small samples, non-Cox external models, varying calibration set sizes, and extreme shift).
- The C-index threshold $\delta = 0.01$ must be justified.
- The non-collapsibility attenuation claim needs a more precise theoretical reference.
- The MAP-Cox comparison framing needs adjustment.

With these revisions, the manuscript would be a strong candidate for acceptance in JBS. The method fills a real gap in the PROCOVA literature, and the blinded-data operation is a genuine operational advantage that regulators and trialists will appreciate.
