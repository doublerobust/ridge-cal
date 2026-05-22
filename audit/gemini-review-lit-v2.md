# Gemini 2.5 Pro — Senior Statistical Review

**Document:** Adaptive Phase II/III Pick-a-Winner Design — Literature Review
**Date:** 2026-05-20
**Reviewer role:** Gemini 2.5 Pro, acting as senior statistical reviewer for Merck

---

## 1. Strengths

- **Goal-directed scope.** The document tightly focuses on the specific setting the intern needs — pick-a-winner designs for oncology trials with ORR/DOR as short-term endpoints and OS as the confirmatory endpoint. This is not a generic survey; it's a targeted foundation for real design work.

- **Recent and relevant papers.** The inclusion of very recent papers (Zhang & Jin 2025, Zhong et al. 2025, Wu et al. 2023, Broglio et al. 2024, Zhu et al. 2024) is excellent. These push well beyond the familiar 2006–2011 canon (Bretz, Stallard, Jenkins) and show awareness of what's being published *right now*. The Telegram-extracted full-text notes on §2.3 are particularly valuable for the intern.

- **Regulatory framing.** The FDA guidance (2019), Project Optimus, and the estimand alignment note (§1.3) show awareness that this is not just a theoretical exercise — the design must pass regulatory muster. This is the right mindset.

- **Concrete simulation blueprint.** Section 5 provides an unusually detailed simulation framework (multi-state model, copula, parameter tables, decision rules, performance metrics, sensitivity analyses, R packages, Monte Carlo setup). The intern can go from this document straight to code. That's the highest-value output of a literature review.

- **Honest cataloging of limitations.** The "Papers Not Fully Reviewed" appendix, the candid discussion of ρ dependence on tumor type, and the notes on immune checkpoint inhibitor complications (§3.4) show appropriate epistemic humility.

---

## 2. Gaps / Missing Papers

### Critical Omissions

| Paper | Why It Matters |
|-------|----------------|
| **Magirr et al. (2012)** *Stat Med* — "A flexible MAMS design for time-to-event outcomes" | This is *the* canonical MAMS reference for TTE endpoints. The covariance structure for TTE test statistics across stages (extending the multivariate normal approach) underpins the Zhang & Jin (2025) and Dixit et al. (2021) papers reviewed here, but the original is never cited. |
| **Bauer & Posch (2004)** *Stat Med* — "Modification, adaptation and suboptimal combination tests" | The document mentions "Bauer-Posch bias" (§4.3, §5) but never cites the original. This is a foundational result that shows why using the same patients' short-term data for selection and long-term data for testing inflates type I error. |
| **Posch & Bauer (2000)** *Stat Med* — "Interim analysis and sample size reassessment" | Companion to the above; demonstrates the fundamental problem with correlated test statistics across stages. |
| **Kelly et al. (2005)** *Stat Med* — "A practical guide to implementing MAMS trials" | Practical implementation reference for multi-arm multi-stage designs; complements the Sydes et al. STAMPEDE paper. |
| **Dunnett (1955)** *JASA* — "A multiple comparison procedure for comparing several treatments with a control" | The foundation of the Dunnett-type adjustments used throughout. Should at least be cited in §4.1. |

### Important Gaps — Subject Areas

| Area | Missing |
|------|---------|
| **Bayesian adaptive designs** | No discussion of Bayesian approaches (Berry et al., Lee & Chu, the BATTLE/I-SPY 2 trials). Bayesian methods are widely used in oncology adaptive designs and offer a flexible alternative for pick-a-winner with DOR/ORR. The document is entirely frequentist. |
| **Copula modeling of ORR→OS** | §3.4 mentions copula models but doesn't cite the key cancer-specific copula joint modeling literature (e.g., Hu & Tsiatis 1996, *Biometrika*; Emura et al. 2017, *Stat Med*). If the intern implements a copula-based DGP, they need these references. |
| **Estimands (ICH E9(R1))**: | The estimand alignment issue is mentioned once in §1.3 but never elaborated. When stages use different endpoints (ORR vs OS), the estimand framework is critical: what is the target of estimation? How does intercurrent events handling (e.g., subsequent therapy, crossover) differ between endpoints? This is a regulatory hot topic. |
| **Probability of Correct Selection (PCS)** | The simulation framework lists PCS as a metric (§5.4) but doesn't cite any of the PCS-specific literature (Gibbons et al. 1987, *Selection and Ordering of Populations*; Bechhofer et al. 1995). Design parameters for guaranteeing PCS at a certain level are standard and should be mentioned. |
| **Sample size re-estimation** | §4.5 mentions it in one table row but there's no substantive discussion. In a pick-a-winner design, after dropping arms, the total sample size may need recalibration. The literature on adaptive sample size re-estimation (Wassmer, Brannath, Posch) is relevant. |
| **Winner's curse / shrinkage estimation** | §4.4 mentions regression to the mean but doesn't cite the estimation literature (e.g., Bowden & Glimm 2008, *Stat Med*; Kimani et al. 2013, *Stat Med*). After picking a winner, the naive treatment effect estimate is biased. How should we adjust? This is critical for regulatory submission. |
| **I-SPY 2 and platform trial literature** | The document focuses on two-stage seamless designs but the broader platform trial literature (Saville & Berry 2016, *Clin Trials*; Hobbs et al. 2018) is relevant context. |
| **Thall, Simon & Ellenberg (1988)** | One of the original two-stage selection design papers. Historical foundation, good for the intern to know. |

### Organizational Gaps

- The summary table (§2.1) does not include the three papers detailed in §2.3 (Zhang & Jin 2025, Zhong et al. 2025, Wu et al. 2023). These should be added to the table.
- The "Two-in-One" design from Chen, Sun, et al. is mentioned in the terminology table (§1.2) but never fully cited or described. The intern will search for this and not find it.

---

## 3. Methodological Concerns

### 3.1 Selection Independence Claim (§4.2)

> "The decision to 'pick the winner' is based on short-term endpoint data, not the OS data — this means the selection rule is independent of the OS-based hypothesis test."

**This is misleading in its simplicity.** The selection rule and the final test are conditionally independent only if:
1. The short-term endpoint used for selection is **completely different data** from what feeds the final test, **or**
2. A cohort-separation framework (Jenkins et al. 2011) is used.

If the *same patients* contribute both short-term and long-term data, the selection is not independent of the final test due to shared patient-level information. The Bauer-Posch bias arises precisely because of this violation. The document acknowledges this elsewhere (§4.3, §5 with Jenkins solution) but the phrasing in §4.2 contradicts the earlier nuance.

**Fix:** Clarify that independence holds only under specific design choices (cohort separation) or when the endpoints are based on non-overlapping data.

### 3.2 Patient-Level vs. Arm-Level Correlation (§4.3)

> "When ρ is high, selection based on S is nearly optimal for T"

**Not necessarily true.** ρ here is the *patient-level* correlation between S and T. Selection optimality depends on *arm-level* rank concordance (whether the arm ranked best on S is also best on T). Even with high patient-level ρ, if S is a poor surrogate (i.e., the treatment effect on S doesn't predict the treatment effect on T), the arm ranking can diverge. This is the fundamental issue behind Buyse et al.'s trial-level surrogacy framework (2012, referenced in §6 but not integrated here).

**Fix:** Distinguish between patient-level ρ and trial-level surrogacy. The distinction is critical for understanding when pick-a-winner based on ORR fails.

### 3.3 Conservatism of ρ = 1 (§5.5, from Zhong et al.)

The suggestion to "conservatively set ρ = 1" when calibrating FWER is mentioned without adequate caveat. **Setting ρ = 1 will be extremely conservative** — essentially assuming perfect correlation between ORR and OS, which rarely holds in solid tumors. This would substantially over-penalize the multiplicity adjustment, reducing power. 

**Better guidance for the intern:** Start with ρ = 1 as an upper bound, then calibrate using tumor-specific historical data (e.g., from a meta-analysis of past trials in the same indication). The span between ρ = 0.3 and ρ = 0.7 is where most real oncology scenarios live.

### 3.4 Duplicate and Reorganized Content

The document has two versions of several sections merged together:
- §2.1 (original table, 14 papers) and §2.3 (3 additional papers with full-text notes)
- §3.1–3.3 appear in two versions (one original, one revised)

This creates a structural issue. The intern will be confused about which supersedes which. The three papers in §2.3 should be integrated into §2.1, and the duplicate endpoint sections should be consolidated.

### 3.5 Table Note on More Arms → Greater Bias (§5.5)

> "More arms → more selection pressure → greater bias"

This is true in general but the mechanism needs clarification. The bias from selection increases with K because the maximum of K independent estimates is an increasing function of K (order statistics of the maximum). But importantly, this is *optimism*, not measurement bias in the traditional sense. The corrected estimate requires specific bias-adjustment methods (e.g., bootstrap, conditional likelihood). The document should note that this optimism affects estimation more severely than it affects hypothesis testing (where multiplicity adjustment handles the testing side).

### 3.6 Notation Inconsistency

- Zhong et al. (2025) use ρ_jk for correlation
- The document uses ρ in §4.3 for endpoint correlation
- The copula approach mentions "Gaussian or Clayton copula"
- No consistent notation is established for the correlation parameter space

This is minor but for an intern trying to implement (see §5), having consistent notation across sections would be helpful.

---

## 4. Suggestions for the Intern

### Priority Order of Work

1. **Read the 6 high-priority papers in full** (in this order):
   - Sun et al. (2020) — most directly applicable setting
   - Jenkins et al. (2011) — the bias solution framework
   - Zhang & Jin (2025) — the closest concrete design to what we need
   - Stallard & Todd (2003) — the pick-a-winner foundation
   - Zhong et al. (2025) — the ρ(ORR, OS) analytic formula
   - Jin & Zhang (2021) — multiple endpoint framework

2. **Fill the missing literature** — add at least 5 more papers:
   - Magirr et al. (2012) for the TTE MAMS machinery
   - Bauer & Posch (2004) for the bias origin
   - Dunnett (1955) for the multiplicity foundation
   - A surrogate endpoint paper (Buyse et al. or Prasad et al. — already in refs)
   - A copula joint model paper for the DGP implementation

3. **Consolidate the document** — merge §2.1 and §2.3 into one continuous table, reconcile the duplicate §3 sections, and clean up notation. This will make the review a living document you can extend.

### Simulation Work Plan

4. **Start with simplified validation** — Before tackling the full multi-state model, implement a binary→binary version (ORR interim, "responder status at end" as primary) to verify the methodology without TTE complexity. This catches coding errors fast.

5. **Implement the multi-state DGP** (the recommended approach in §5.1) — The states:
   ```
   No Response → Response → Progression → Death
   ```
   This is the right strategy. Calibrate transition intensities from published Kaplan-Meier curves. Use the `simtrial` or `mstate` R packages.

6. **Compare pick-a-winner vs. drop-the-losers** — These have different operating characteristics that vary by scenario. Drop-the-losers is more conservative; pick-a-winner is more efficient when one arm is clearly best. Quantify the tradeoff.

7. **Calibrate ρ(ORR, OS) from historical data** — Don't simulate with arbitrary ρ values. Find 3-5 historical oncology trials in the same tumor type with ORR and OS data, compute the empirical ρ, and use that for calibration. The paper does a good job flagging this (§5.5) but the intern should actually do it before running the main simulation.

### Beyond the Internship

8. **Estimand work** — Draft a section on ICH E9(R1) estimands for the pick-a-winner setting. This is increasingly expected by regulators and will strengthen any methodology publication or regulatory submission you produce from this work.

9. **Publish the simulation framework** — The R code implementing this design (with multi-state DGP, pick-a-winner decision rules, adjusted final analysis) would be a valuable GitHub repository / R package vignette. Career-wise, this is the kind of deliverable that gets noticed.

---

## 5. Overall Verdict

### **Major Revision**

**Rationale:** The document has strong bones — excellent scope, contemporaneous references, detailed simulation blueprint, good regulatory awareness. However, two issues push this to Major Revision rather than Minor:

1. **Missing critical references** (§2 above, especially Magirr 2012, Bauer & Posch 2004) — these are not optional additions. The intern cannot properly understand the TTE MAMS framework or the interim-decision bias without them. The document currently has a blind spot in the MAMS-specific TTE literature.

2. **Organizational fragmentation** — The merged document structure (the main body from v1 plus §2.3 from a later addition, duplicate endpoint sections, §2.1 not updated with §2.3 papers) will confuse a junior researcher. The intern needs a clean, consolidated document to work from.

**What would bump this to Minor Revision or Acceptance:**

- Add the 5+ missing critical references and integrate them into the discussion
- Consolidate §2.1 and §2.3 into a unified table
- Reconcile the duplicate §3 sections
- Soften or qualify the more problematic claims identified in §3 of this review

**Bottom line:** Excellent foundation, solid direction. The intern should clean it up before using it as their primary reference document, but the heavy lifting — identifying the right design space, the right endpoint combination, and the right simulation framework — is already done.
