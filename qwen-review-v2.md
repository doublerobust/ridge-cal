# Peer Review: Ridge-Cal — Efficient Regularized Calibration of External Prognostic Scores Using Blinded Trial Data (v2)

**Journal:** Journal of Biopharmaceutical Statistics (JBS)  
**Manuscript Title:** Ridge-Cal: Efficient Regularized Calibration of External Prognostic Scores Using Blinded Trial Data  
**Author:** Yue Shentu  
**Reviewer:** Qwen (subagent peer review)  
**Date:** May 18, 2026  
**Status:** Re-review after major revision  

---

## 1. Summary of Contributions

The manuscript proposes **Ridge-Cal**, a two-step procedure for diagnosing and correcting miscalibration of external prognostic scores in randomized trials. The method: (1) compares the concordance index of the external score alone versus the score plus a small set of pre-specified calibration covariates on blinded trial data to detect miscalibration; and (2) when miscalibration is detected, fits a ridge-penalized Cox model on the blinded data to learn a regularized calibration correction, with the penalty strength selected by cross-validation. The calibrated score is then used in the primary Cox PH analysis with a robust sandwich variance estimator. The method is motivated by an analogy to Low-Rank Adaptation (LoRA) from deep learning. Simulation results (10,000 replicates) under seven scenarios demonstrate that Ridge-Cal recovers power under population shift while incurring minimal penalty when no shift is present.

---

## 2. Assessment by Dimension

### 2.1 Mathematical Rigor

**Strengths:**
- The formulation is clear and well-defined. The ridge-penalized Cox model (Section 2.3) is standard, and the use of `glmnet` with $\alpha=0$ is appropriate.
- The validity argument for Type I error preservation under randomization (Section 2.4, citing Schuler et al. 2022, Theorem 1 and Lin & Wei 1989) is correct in principle: because $\hat{S}^{(cal)}$ is a function of $W$ only and $A \perp W$, the Wald test for the treatment effect preserves asymptotic Type I error.
- The discussion of non-collapsibility attenuation in blinded calibration (Section 2.3) is a genuine and important insight. The quantitative approximation $\beta_{trt}^2/6$ is now properly contextualized.
- The distinction between $\mathcal{C}$ (calibration covariates) and $\mathcal{F}$ (fixed covariates) is well-motivated and clearly formalized.
- The non-collapsibility attenuation is now addressed with two layers of support: (1) a specific citation to Struthers & Kalbfleisch (1986, eq. 3.2) rather than a general reference, and (2) empirical verification in Section 3.3 showing mean attenuation of 0.011--0.012, consistent with the $\beta_{trt}^2/6 \approx 0.015$ approximation. This is a significant improvement.

**Remaining concerns:**
- **The claim that the robust sandwich variance estimator is "consistent even when the score is estimated from the same data" (Section 2.4)** is true for the treatment effect coefficient under randomization (Lin & Wei 1989), but the manuscript does not fully address the impact of estimating the score from the *same* data on the variance of the prognostic coefficient $\beta_{prog}$. This is a known issue in PROCOVA literature (Hajage et al. 2018 discuss this); the sandwich estimator is valid for the treatment effect but may be anti-conservative for the prognostic coefficient's standard error. The authors should clarify this distinction. This was flagged in the original review and remains unaddressed.
- **The C-index threshold $\delta = 0.01$** is now justified as "slightly above the Monte Carlo variability of the C-index difference under no shift (empirical 95th percentile $\approx 0.008$ in our simulations)." This is a reasonable empirical justification, though it is specific to the simulated DGP. The authors should note that the threshold may need recalibration for different sample sizes or event rates.

### 2.2 Statistical Innovativeness

**Strengths:**
- The LoRA analogy is creative and helps communicate the method's philosophy. The core idea — regularized, parameter-efficient fine-tuning of a prognostic score — is novel in the biostatistics literature.
- The diagnostic step (comparing C-index with and without calibration covariates on blinded data) is a simple but useful addition to the PROCOVA toolkit.
- The explicit treatment of the non-collapsibility issue in blinded calibration is a genuine contribution.

**Remaining concerns:**
- **The method is essentially ridge regression applied to a specific problem.** While the application is novel, the statistical core is well-established. JBS readers familiar with PROCOVA and regularized regression may find the innovation less substantial than presented. The manuscript should more clearly position Ridge-Cal relative to other PROCOVA extensions (e.g., Hajage et al. 2018's discussion of score estimation uncertainty, or Schuler et al. 2022's own extensions). This was not addressed in the revision.
- **The neural network adapter comparison (Section 4.4) is underpowered.** The manuscript now acknowledges this limitation ("200 reps each") and reframes the claim as exploratory rather than definitive. This is an acceptable mitigation — the comparison is no longer presented as a conclusive result, but as motivation for future work.

### 2.3 Simulation Completeness

**Strengths:**
- 10,000 replicates per scenario provides good precision for power and Type I error estimates.
- The seven scenarios cover a reasonable range of conditions.
- The inclusion of MAP-Cox as a sensitivity comparison is valuable.
- The misspecified calibration set sensitivity analysis (over-inclusive $\mathcal{C}$) is well-designed and reassuring.
- **The Limitations section (§4.3) now explicitly acknowledges the missing scenarios** that were flagged in the original review: small trials ($N < 200$), sparse events ($< 100$ events), non-Cox external models (random survival forests, boosting), and varying calibration set sizes. This is a good mitigation — the authors acknowledge the gaps rather than pretending they don't exist.

**Remaining concerns:**
- **The oracle/full model comparison** is still presented prominently as a benchmark despite being "not achievable in practice." The manuscript now includes a terminology note distinguishing this usage from causal inference conventions, which helps. However, the gap between Ridge-Cal (0.833) and the full model (0.843) in the severe shift scenario (1.0 pp) is still not analyzed: is this gap due to the ridge penalty, the limited calibration set, or the fact that the external score cannot perfectly replicate the full model?
- **The MAP-Cox comparison is now properly reframed** in the manuscript to acknowledge that MAP-Cox uses unblinded data and 21 parameters while Ridge-Cal uses blinded data and 6 parameters. The text now reads: "That Ridge-Cal achieves similar power to MAP-Cox despite having substantially less information underscores the efficiency of the regularized calibration approach." This is a good fix.
- **Missing data** remains unaddressed. If covariates in $\mathcal{C}$ have missing data, the calibration step cannot proceed without imputation, which introduces additional uncertainty. This is a practical concern for real trials.
- **Extreme population shift** ($\Delta\beta > 1.0$) is still not tested. The "severe shift" scenario ($\Delta\beta \approx 0.3$--0.75) is moderate by clinical standards.

### 2.4 Prose and Formatting

**Strengths:**
- The writing is clear and well-organized.
- The LoRA analogy table (Section 1.4) is an effective visual aid.
- The notation is consistent and well-defined.
- The manuscript is well-structured with clear section headings.

**Remaining concerns:**
- **Section 4 ("Discussion") is no longer redundant with Section 3.2.** Section 4 now contains the Discussion (Summary, Relationship to Existing Methods, Limitations, Connection to LoRA and Future Directions, Regulatory and Operational Considerations, Conclusion) rather than repeating results. Section 3 contains the Simulation Study with all results. This structural issue has been resolved.
- **The "Std" table header issue.** Table 1 now uses "LR" (Log-Rank) instead of the ambiguous "Std" header. This has been fixed.
- **Reference formatting is still inconsistent.** Some references use "et al." and some do not; journal names are abbreviated inconsistently. JBS has specific reference style requirements. This was flagged in the original review and remains unaddressed.
- **The pre-submission checklist** at the top of the manuscript is still present. This should be removed before submission.
- **The terminology note about "oracle"** is now in the main text as a paragraph rather than a footnote, which is more appropriate.

### 2.5 Regulatory and Operational Fit

**Strengths:**
- The method's use of blinded data is a significant operational advantage.
- The pre-specified calibration set $\mathcal{C}$ aligns well with regulatory expectations.
- The discussion of regulatory frameworks (FDA 2023, EMA 2015/2022) is appropriate.
- The method's parsimony (6 parameters vs. 21 for MAP-Cox) is a genuine advantage for regulatory acceptance.

**Remaining concerns:**
- **The manuscript does not address how Ridge-Cal would be presented in a clinical trial report.** Regulators will want to know: how was $\mathcal{C}$ chosen? What was the diagnostic result? What was the selected $\lambda$? What were the recalibrated coefficients? The manuscript should include a worked example or a template for reporting Ridge-Cal in a trial report. This remains unaddressed.
- **The claim that "no new data collection, sample size adjustment, or unblinding is required" needs qualification.** The manuscript does not discuss whether the sample size should account for the possibility that Ridge-Cal might be triggered (and the associated uncertainty in the calibration step).
- **The EMA qualification of PROCOVA (EMA 2022) is referenced, but the manuscript does not discuss whether Ridge-Cal would need a separate qualification process.** If PROCOVA is already qualified, does a calibrated variant require additional regulatory engagement?

---

## 3. Re-evaluation of Previous Concerns

### Concern 1: Section 4 redundant with Section 3.2
**Status: ✅ RESOLVED.** Section 4 is now the Discussion, not a redundant Results section. The simulation results are contained entirely in Section 3.2.

### Concern 2: "Std" ambiguous table header
**Status: ✅ RESOLVED.** Table 1 now uses "LR" (Log-Rank) instead of "Std."

### Concern 3: $\delta = 0.01$ threshold unjustified
**Status: ✅ RESOLVED.** The manuscript now provides an empirical justification: "slightly above the Monte Carlo variability of the C-index difference under no shift (empirical 95th percentile $\approx 0.008$ in our simulations)." A minor caveat remains that this threshold is DGP-specific.

### Concern 4: Struthers & Kalbfleisch ref imprecise
**Status: ✅ RESOLVED.** The manuscript now cites "Struthers & Kalbfleisch (1986, eq. 3.2)" specifically, and Section 3.3 provides empirical verification (mean attenuation 0.011--0.012 vs. predicted 0.015).

### Concern 5: MAP-Cox unfair comparison
**Status: ✅ RESOLVED.** The manuscript now explicitly acknowledges the asymmetry: "MAP-Cox has access to unblinded trial data and fits 21 parameters (all 20 covariates + treatment), while Ridge-Cal uses only 6 parameters on blinded data." The framing now emphasizes Ridge-Cal's efficiency rather than claiming parity.

### Concern 6: Missing scenarios (small N, non-Cox, sparse events)
**Status: ⚠️ PARTIALLY RESOLVED.** The manuscript now explicitly lists these as limitations in §4.3 ("Simulation scope"). This is a good acknowledgment, but no new simulations have been added. The authors have chosen to acknowledge rather than address, which is acceptable for a JBS paper if the scope is clearly bounded. However, a small-N scenario ($N = 200$) would strengthen the paper considerably.

### Concern 7: NN comparison underpowered (200 reps)
**Status: ✅ RESOLVED.** The manuscript now reframes the NN comparison as exploratory ("A neural network adapter may offer advantages in larger trials") rather than definitive. The limitation is acknowledged ("200 reps each") and the comparison is placed in "future directions."

---

## 4. Remaining Concerns

Despite the revisions, the following issues remain:

1. **Prognostic coefficient variance (Section 2.4).** The manuscript does not address whether the robust sandwich variance estimator is valid for $\beta_{prog}$ when the score is estimated from the same data. This is a known issue in PROCOVA literature and should be discussed.

2. **Reference formatting inconsistencies.** Journal name abbreviations and "et al." usage are inconsistent. This is a housekeeping issue but should be fixed before submission.

3. **Pre-submission checklist still present.** The checklist at the top of the manuscript should be removed.

4. **No worked example or reporting template.** Regulators will need to understand how to evaluate Ridge-Cal in a trial report. A brief worked example would significantly improve the paper's practical utility.

5. **Oracle benchmark gap unexplained.** The 1.0 pp gap between Ridge-Cal and the full model in the severe shift scenario is not analyzed.

6. **Missing data not addressed.** This is a practical concern for real-world application.

---

## 5. Verdict

**Minor Revision**

The authors have addressed all seven of the major concerns from the previous review. The structural issues (redundant section, ambiguous table header) are resolved. The methodological concerns (threshold justification, imprecise reference, unfair comparison framing, underpowered NN comparison) are addressed with either empirical evidence or appropriate reframing. The missing simulation scenarios are acknowledged as limitations rather than addressed with new simulations — this is a reasonable trade-off for a paper of this scope.

The remaining concerns are genuinely minor:
- Clarify the scope of the sandwich variance estimator's validity (treatment effect vs. prognostic coefficient).
- Fix reference formatting.
- Remove the pre-submission checklist.
- Consider adding a brief worked example for regulatory reporting.

The manuscript is now in good shape for JBS submission. The method is novel, well-motivated, and supported by strong simulation evidence. The blinded-data operation is a genuine operational advantage, and the regulatory discussion is appropriate.
