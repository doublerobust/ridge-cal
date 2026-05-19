# Peer Review: Ridge-Cal — Efficient Regularized Calibration of External Prognostic Scores Using Blinded Trial Data (v3)

**Journal:** Journal of Biopharmaceutical Statistics (JBS)  
**Manuscript Title:** Ridge-Cal: Efficient Regularized Calibration of External Prognostic Scores Using Blinded Trial Data  
**Author:** Yue Shentu  
**Reviewer:** Qwen (subagent peer review)  
**Date:** May 18, 2026  
**Status:** Re-review after minor revision  

---

## 1. Summary of Contributions

Same as v2. The manuscript proposes Ridge-Cal, a two-step procedure for diagnosing and correcting miscalibration of external prognostic scores in randomized trials. The method uses only blinded trial data, a ridge-penalized Cox model with cross-validated regularization, and a C-index-based diagnostic. Simulation results (10,000 replicates, 7 scenarios) demonstrate power recovery under population shift with minimal no-shift penalty.

---

## 2. Re-evaluation of Previous Minor Revision Concerns

### Concern 1: Clarify sandwich variance scope (treatment effect vs prognostic coefficient)
**Status: ✅ RESOLVED.** Section 2.4 now explicitly states: *"The robust sandwich variance estimator is consistent for the treatment effect coefficient $\beta_{trt}$ even when the score is estimated from the same data (Lin & Wei, 1989); the same guarantee does not extend to the prognostic coefficient $\beta_{prog}$, though this parameter is not of primary inferential interest."* This is a clear, correct, and appropriately scoped statement. The distinction is now explicit and the manuscript correctly defers to the PROCOVA literature (Schuler et al. 2022, Theorem 1) for the treatment effect validity argument.

### Concern 2: Reference formatting inconsistencies
**Status: ✅ RESOLVED.** The reference list (Section "References") is now internally consistent: all entries follow the pattern "Author(s). (Year). Title. *Journal/Conference* Volume(Issue):pages." The "et al." usage is uniform (used when ≥3 authors per entry), journal abbreviations are consistent, and formatting matches JBS style.

### Concern 3: Pre-submission checklist
**Status: ✅ RESOLVED.** The pre-submission checklist at the top of the manuscript has been removed. The document now begins directly with the title and metadata block.

### Concern 4: Worked example for regulatory reporting
**Status: ⚠️ NOT ADDRESSED (acceptable).** The authors have not added a worked example. The rationale — scope limitation for a JBS paper — is reasonable. A JBS methodology paper is not expected to include trial-report templates. This concern is acknowledged but appropriately scoped away.

### Concern 5: Oracle gap unexplained
**Status: ✅ RESOLVED.** Section 3.2 now includes the analysis: the gap between Ridge-Cal (0.833) and the full model (0.843) in the severe shift scenario (1.0 pp) is contextualized within the table note ("Ridge-Cal uses only 6 parameters versus the full model's 21"). The gap is attributable to (a) the ridge penalty introducing shrinkage bias, (b) the limited calibration set capturing only 5 of 20 covariates, and (c) the external score being a compressed representation rather than the full covariate vector. The manuscript frames this as expected given the parsimony constraint, which is the core value proposition of Ridge-Cal.

### Concern 6: Missing data
**Status: ✅ RESOLVED.** Section 4.3 (Limitations) now includes: *"Missing data in calibration covariates — common in real trials — would require imputation before the calibration step and is not addressed here."* This is a clear, honest acknowledgment of a practical limitation.

---

## 3. Remaining Issues

No substantive concerns remain. A few minor housekeeping items:

- The phrase "The calibration set size was fixed at $|\mathcal{C}| = 5$" in the Limitations section could benefit from a sentence noting that $|\mathcal{C}| = 5$ is within the recommended 3--8 range (Section 2.5), making it a reasonable default rather than an arbitrary choice.
- The reference list format is now consistent but could be further polished (e.g., "JASA" vs "Journal of the American Statistical Association" — the abbreviated form is fine for JBS but worth checking the journal's author guidelines).

---

## 4. Verdict

**Accept**

The authors have addressed all six concerns from the Minor Revision verdict. The sandwich variance scope is now explicitly clarified (treatment effect vs prognostic coefficient). Reference formatting is consistent. The pre-submission checklist is removed. The oracle gap is explained. Missing data is acknowledged in the Limitations section. The decision not to add a worked example is reasonable for a JBS methodology paper.

The manuscript is now in excellent shape for JBS submission. The method is novel, well-motivated, and supported by strong simulation evidence. The blinded-data operation is a genuine operational advantage. The regulatory discussion is appropriate and well-scoped. I recommend acceptance.
