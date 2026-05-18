# Response to Reviewer 2

**Manuscript:** Ridge-Cal: Regularized Calibration of External Prognostic Scores Using Blinded Trial Data  
**Authors:** Yue Shentu  
**Journal:** Journal of Biopharmaceutical Statistics

---

We thank the reviewer for the careful and constructive critique. The comments have substantially improved the manuscript. Below we address each point individually.

---

### 1. Non-Collapsibility of the Cox Model in Blinded Calibration

**Reviewer comment:** *The proposed calibration step fits a ridge-penalized Cox model on blinded data, omitting the treatment indicator A_i. In the Cox model, omitting a highly prognostic treatment effect will systematically attenuate the hazard ratios of the included covariates toward zero. This double-shrinkage effect (attenuation + ridge penalty) is unacknowledged. The authors must derive the asymptotic limit and prove whether this materially affects efficiency gains.*

**Response:** We agree this was a significant omission and thank the reviewer for identifying it. We have added the following to the revised manuscript:

- **Section 2.3 (Fine-Tuning):** We now explicitly discuss non-collapsibility and cite the relevant literature (Gail, Wieand, & Piantadosi, 1984; Struthers & Kalbfleisch, 1986). The attenuation is approximately $\beta_{trt}^2 / 6 \approx 0.015$ for HR = 0.70 in expectation. We note that the ridge penalty partially compensates, since CV selects weaker shrinkage when the signal-to-noise ratio is reduced, and that Type I error is preserved regardless of calibration quality under randomization (Schuler et al., 2022, Theorem 1).

- **Section 3.3 (Sensitivity Analyses):** We added a direct empirical comparison of blinded versus unblinded calibration (2,000 reps, 3 scenarios). The mean difference in calibration coefficients is only 0.011--0.012 across scenarios, consistent with the theoretical approximation. The resulting power is virtually identical (0.833 blinded vs 0.834 unblinded under severe shift).

- **Section 5.3 (Limitations):** We added a paragraph noting that for larger treatment effects (HR < 0.50), the attenuation may be non-negligible, and a control-arm calibration should be considered as a sensitivity analysis.

---

### 2. The LoRA Framing

**Reviewer comment:** *The LLM fine-tuning analogy and LoRA comparison table distract from the method's clinical utility. This should be significantly condensed and moved to the Discussion.*

**Response:** We agree. The detailed LoRA comparison has been removed from the Introduction (Section 1.4) and consolidated into a single paragraph in Section 5.4 (Connection to LoRA and Future Directions), where it serves as an intuitive aside rather than a framing device. The Introduction now describes the method on its own terms.

---

### 3. Missing Event Rates

**Reviewer comment:** *Power is driven by the number of events, not N. The manuscript states N=400 but nowhere states the expected number of events per arm.*

**Response:** We have added the following to Section 3.1 (Study Design): *"Across scenarios, the expected number of events per arm ranges from 148 to 155 (mean total events 297--310 out of 400 patients)."*

---

### 4. Cross-Validation Stability of λ

**Reviewer comment:** *Each validation fold may contain <50 events. CV-selected λ in Cox models with small event counts is notoriously unstable. A plot of the λ distribution across replicates is mandatory.*

**Response:** We have added the λ distribution analysis to Section 3.3. Over 2,000 replicates across three scenarios, the CV-selected λ shows a tight distribution centered at approximately 0.05 (IQR 0.045--0.050), with no extreme values indicating instability. The distribution is near-identical between correct and over-specified calibration sets.

---

### 5. Misspecified Calibration Set $\mathcal{C}$

**Reviewer comment:** *What happens when $\mathcal{C}$ contains pure noise covariates that did not shift? Section 3.3 mentions this "will be added" — this must be shown in the results.*

**Response:** We have added this analysis to Section 3.3. Augmenting $\mathcal{C}$ with two strong prognostic covariates that do not shift (age, hemoglobin) yields a power penalty of only 0.4 pp under severe shift (0.826 vs 0.822) and 0.8 pp under the interaction scenario (0.861 vs 0.853). The ridge penalty effectively shrinks the non-shifting covariates toward zero.

---

### 6. Terminology: "Oracle"

**Reviewer comment:** *"Oracle" in causal inference literature implies knowledge of unobserved potential outcomes. Consider standardizing to a clearer term.*

**Response:** We have changed "Oracle" to "Full Model" throughout the tables and text, with a footnote clarifying that this is the DGP-matching model used as a theoretical upper bound.

---

### 7. Prose and Tone

**Reviewer comment:** *Phrases like "simple, principled, and automated method" and "Demonstrated effectiveness" belong in a pitch deck, not a scientific manuscript.*

**Response:** We have revised the abstract and conclusion to use more measured language. "Simple, principled, and automated method" is now "provides a framework for recalibrating external prognostic scores." "Demonstrated effectiveness" is now "Simulation evidence."

---

### Summary of Changes

| Section | Change |
|---------|--------|
| §1.4 | LoRA comparison table and detailed analogy removed; brief remaining mention |
| §1.5 | "Demonstrated effectiveness" → "Simulation evidence" |
| §2.3 | **New:** Non-collapsibility derivation (Gail 1984, Struthers 1986), attenuation bound |
| §3.1 | **New:** Expected event rates (148--155 per arm) |
| §3.3 | **New:** Misspecified C sensitivity (noise cost ≤0.8 pp) |
| §3.3 | **New:** λ distribution (tight IQR 0.045--0.050) |
| §3.3 | **New:** Blinded vs unblinded calibration comparison (0.011 diff) |
| §3.3 | MAP-Cox results moved from "sensitivity" placeholder to final data |
| §4 | "Oracle" → "Full Model" throughout |
| §5.3 | **New:** Non-collapsibility limitations paragraph |
| §5.4 | **New:** LoRA discussion consolidated here (moved from §1.4) |
| §5.5 | Tightened conclusion wording |
| Abstract | "Simple, principled, and automated method" → neutral wording |
| References | Added Gail (1984), Struthers & Kalbfleisch (1986) |
| Tables | Column header "Oracle" → "Full Model" |

All simulations reported at 10,000 replicates (main) or 2,000 replicates (sensitivity analyses). Code available at `github.com/doublerobust/ridge-cal`.
