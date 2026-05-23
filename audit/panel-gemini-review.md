# Internal Panel Review: Ridge-Cal Simulation Plan & Paper Integration

**Date:** 2026-05-22
**Reviewer:** Senior Statistical Methodology Reviewer (Subagent)

Here is my thorough review addressing the 5 questions raised in the panel brief.

## 1. Simulation Plan Evaluation

**Assessment:** The proposed 6-method comparison (Standard LR, Oracle LR, External-score LR, Ridge-Cal LR, 5-STAR-inspired LR, and perhaps MAP-Cox as an unblinded sensitivity) is structurally appropriate and addresses the current methodological gap realistically. 

**Feedback & Recommendations:**
- The inclusion of the "5-STAR-inspired" method is critical for addressing the reviewer comment, but the methodology selected must be clearly defined. The current simulated environment operates under various proportional hazards and non-PH settings, relying on 20 covariates. 
- The existing log-rank simulation uses `ECOG + region` for the standard stratification approach, but the original Cox model simulation utilized `ECOG + sex`. To maintain consistency across the paper, you should **align the baseline stratification factors** or explicitly highlight why they differ (e.g. region was added to the data generation just for the log-rank analysis).
- You must report both the **discretized log-rank test results** and the **continuous Cox continuous p-values (and efficiency metrics)** to fully document the 13% efficiency loss from converting the continuous score into quartiles.

## 2. 5-STAR Implementation (Inspired vs. Full)

**Assessment:** Your proposed simplified "5-STAR-inspired" approach (elastic net selection $\rightarrow$ score quartiles) captures the *spirit* of 5-STAR's variable selection phase but fundamentally skips its core mechanism. 

**Feedback & Recommendations:**
- **The "Inspired" approach is likely not defensible for a pure comparison** because the true Mehrotra 5-STAR method relies critically on conditional inference trees (`partykit`) to amalgamate and form risk strata, not just elastic net + simple quartiles. 
- *However*, using the full 5-STAR R package (`fiveSTAR`) in a 10,000 replicate simulation might be computationally prohibitive, especially if tree growing and cross-validation inside the loop scale poorly.
- **Recommendation:** Run the full 5-STAR algorithm using the local cloned `R/5STARcorefun.R` for a **smaller subset of replicates (e.g., 500-1000)** to calibrate the "5-STAR-inspired" method. If the inspired method closely mimics the full 5-STAR strata assignments, you can justify using the simplified version for the massive 10K simulation. Otherwise, use the full 5-STAR for the final results, or clearly state the limitation that the comparison is against an external-elastic-net-quartile baseline, not true 5-STAR.

## 3. Miscalibration Threshold

**Assessment:** The proposed severity sweep (multiplying shift magnitude by 0, 0.5, 1, 1.5, 2, 3) is a robust and highly informative empirical approach. 

**Feedback & Recommendations:**
- **Defining the Crossover Point:** Operationally, the crossover point should be defined as the severity multiplier where the expected power of Ridge-Cal stratified log-rank drops below that of the Standard stratified log-rank. 
- You should define this by plotting a smoothed LOESS curve of power versus the severity multiplier, and reading the intercept where $\text{Power}_{RidgeCal} < \text{Power}_{StandardLR}$.
- Additionally, report the **diagnostic C-index difference ($C_2 - C_1$)** at this crossover point. This gives practitioners a concrete statistical threshold: "If the trial's blinded diagnostic $\Delta C$ exceeds $X$, standard LR is safer than attempting recalibration."

## 4. Paper Integration

**Assessment:** Adding log-rank framework analyses and 5-STAR comparisons structurally bulks up the manuscript. 

**Feedback & Recommendations:**
- **5-STAR Comparison:** This should go into the **Discussion** or a dedicated **Section 3.X (Secondary Methodological Comparisons)**. Because 5-STAR uses internal unblinded data (or purely internal blinded data depending on exact phase) and conditional trees, it is mechanically distinct from Ridge-Cal's fine-tuning of an *external* score. 
- **Log-Rank Results:** Do **not** rewrite the primary results. Keep the primary results focused on the Cox estimation framework, where Ridge-Cal natively operates. 
- Introduce the **Score-Stratified Log-Rank** as a pragmatic **Section 3.3 (Sensitivity / Extension to Testing Frameworks)** to definitively answer "How do we test this in standard oncology?"
- **Miscalibration Threshold Analysis:** This belongs in the **Discussion** as practical guidance for trial statisticians regarding the limits of the method.

## 5. Narrative Impact

**Assessment:** Does adding these changing the narrative? No, but it *grounds* it. 

**Feedback & Recommendations:**
- The paper remains about **Regularized Calibration of External Scores (the LoRA analogy)**. 
- The log-rank addition simply recognizes the realities of the FDA/EMA oncology testing environment. It acts as a bridge. 
- The 5-STAR comparison acts as a defense against existing alternative covariate adjustment philosophies. It validates that Ridge-Cal's approach (fine-tuning an external base) is competitive against or superior to training risk strata internally from scratch.
- **Story to tell:** "Ridge-Cal optimizes the estimation (Cox) of treatment effects suffering from population shift. For strict regulatory testing paradigms, the continuous recalibrated score can be cleanly discretized into strata, recovering the majority ($~87\%$) of the continuous efficiency gain while preserving nominal structural Type I error."