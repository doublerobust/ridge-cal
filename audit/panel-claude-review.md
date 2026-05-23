# Panel Review: Ridge-Cal Expanded Simulation Plan
**Reviewer:** Claude Sonnet (panel member)
**Date:** 2026-05-22
**Documents reviewed:**
- Panel brief (`panel-brief.md`)
- Manuscript (`ridge-cal-manuscript.md`)
- Log-rank simulation plan (`score-stratified-logrank-plan.md`)
- Screening simulation report (`logrank-sim-report.md`)
- 5-STAR source code (`/tmp/fiveSTAR/R/5STARcorefun.R`, vignette)

---

## Executive Summary

The expanded simulation plan is well-motivated and the screening results are credible. The fundamental finding — that score stratification via Ridge-Cal recovers power under miscalibration in the log-rank testing framework — is both scientifically important and practically actionable. However, the two proposed extensions (5-STAR comparison and miscalibration threshold sweep) have meaningfully different risk profiles. The 5-STAR comparison is methodologically necessary but requires careful implementation choices that could undermine the analysis if done incorrectly. The threshold sweep is clean, straightforward, and high-value — I'd prioritize it over the 5-STAR comparison if resources are constrained.

Below I address each of the five panel questions in order, drawing on specific numbers from the screening results and 5-STAR source code.

---

## Question 1: Is the 6-Method Comparison Set Right?

**Short answer:** Yes, but the "5-STAR-inspired" method needs a sharper definition, and you should consider adding one more comparator.

### The current 5-method set (screening) is solid

The screening study already establishes the main story cleanly:
- Standard stratified LR: 0.540 (severe shift)
- External-score LR: 0.692 (severe shift) — **loses** power vs. no-shift (0.730)
- Ridge-Cal LR: **0.756** (severe shift) — **gains** power vs. no-shift (0.708)
- Oracle LR: 0.780 (severe shift)

Adding a 6th method is worthwhile if it illuminates the mechanism. The question is: what is 5-STAR actually doing that's different from the proposed "5-STAR-inspired" method?

### The 5-STAR algorithm is not just elastic net + quartiles

After reading the source code in detail, 5-STAR's distinguishing feature is **not** the elastic net filtering — it's the conditional inference tree (CTree) that discovers **data-driven risk strata** from filtered covariates, followed by a two-stage amalgamation (within-strata estimates → overall pooled estimate). The pipeline is:

1. ENET/RF filtering → select prognostic covariates
2. CTree (preliminary) on filtered covariates → preliminary strata ordered by RMST
3. CTree (final/pruning) on ordered preliminary strata → final 2–4 strata
4. Within-strata Cox → stratum-specific HRs
5. Minimum-p amalgamation → overall p-value and HR

The "5-STAR-inspired" method (elastic net selection → score quartiles) collapses steps 2–5 entirely and **replaces the tree-based strata with fixed quantile boundaries of the ENET-predicted score**. This is a much more radical simplification than it appears. The key properties you'd be attributing to 5-STAR but not actually testing:
- Tree-based strata are not uniform in size (CTree adapts to the data; quartiles do not)
- Tree-based strata are derived from the trial data itself (fully data-adaptive, no external reference distribution)
- The amalgamation step in 5-STAR explicitly accounts for stratum-specific HRs using a minimum-p approach; the stratified log-rank treats strata as exchangeable nuisance

**My concern:** If the "5-STAR-inspired" method performs poorly, reviewers familiar with 5-STAR will correctly object that you haven't tested 5-STAR — you've tested something simpler. If it performs well, you lose the ability to say anything interesting about the comparison.

### Recommendation for the 6-method set

**Option A (lower effort, more defensible):** Keep the "5-STAR-inspired" method but be explicit that it is a *restricted* 5-STAR that uses fixed quartile boundaries rather than tree-based strata. Name it "ENET-Quartile" or "ElasticNet-Stratified" to signal this clearly. The comparison then answers: *Does variable selection (ENET) before score stratification add value beyond Ridge-Cal calibration?* That is a useful, focused question.

**Option B (higher effort, more rigorous):** Implement the full `run5STAR()` pipeline from the `fiveSTAR` package. This is the honest comparison and would be the most defensible against reviewer criticism. Practical concern: `run5STAR()` is substantially slower than quartile-based methods (two CTree fits per replicate + ENET with 10-fold CV + amalgamation), and it requires the `partykit`, `glmnet`, `c060`, and `randomForestSRC` packages. At 10K reps × 7 scenarios = 70K calls to `run5STAR()`, runtime could be prohibitive. A possible compromise: run full 5-STAR at 2K reps for the key scenarios (severe shift, interaction) and use ENET-Quartile as a proxy for the remaining scenarios and the full 10K run.

**Option C (recommended additional comparator):** Add **ENET-Cox** — elastic net Cox regression on the full covariate set (all 20 covariates) applied to blinded trial data, without external score. This isolates whether the external score is adding anything beyond what could be obtained by purely data-adaptive variable selection within the trial. This method is computationally cheap (already have ENET infrastructure), theoretically important (directly addresses "why not just fit a new model?"), and contextualizes Ridge-Cal's efficiency relative to both the external-score approaches and a purely trial-data approach.

### What the current screening tells us about 5-STAR positioning

The Cox results (Table in panel brief) show:
- Cox + external score (severe shift): 0.736
- Cox + calibrated score (severe shift): **0.852**

This 11.6 pp gap in the Cox framework becomes 6.4 pp in the log-rank framework (0.692 → 0.756). 5-STAR, by building strata from scratch rather than calibrating an external score, would likely fall somewhere between "External-score LR" and "Ridge-Cal LR" under miscalibration — depending on how well ENET recovers the true prognostic variables from 500 blinded trial observations. The panel brief's description of 5-STAR's advantage ("builds risk strata from blinded trial data using elastic net Cox regression") could equally describe the worst case for 5-STAR: with N=400 and 20 covariates, ENET needs to learn the prognostic structure from scratch. Ridge-Cal starts from the external score (which has the structure roughly right) and makes targeted corrections.

**The key scientific prediction:** Under no shift, 5-STAR should be competitive with or possibly superior to Ridge-Cal (no external score noise). Under severe shift, 5-STAR may be *worse* than Ridge-Cal because Ridge-Cal preserves the correct prognostic structure from the external model while only correcting the miscalibrated components, whereas 5-STAR must relearn everything from N=400 trial patients. This is the hypothesis worth testing.

---

## Question 2: Full 5-STAR vs. "5-STAR-Inspired" — Is the Simplification Defensible?

**Short answer:** Not fully as stated. The simplification changes the nature of the comparison in ways that could mislead readers.

### What the simplification discards

Reading `5STARcorefun.R` carefully, the full 5-STAR algorithm does three things the simplified version doesn't:

1. **Adaptive strata formation.** CTree finds strata that minimize within-strata variance in the prognostic score. Fixed quartile boundaries don't respect the score distribution's natural breakpoints. In a scenario where the score distribution is bimodal (e.g., two distinct risk groups), quartiles would split within each mode; CTree would correctly identify the two groups.

2. **Pruning step (3B).** After the preliminary tree, 5-STAR runs a second CTree on the ordered preliminary strata to prevent over-stratification. This post-pruning step is a key design decision in Mehrotra & Marceau West (2020) and is what allows 5-STAR to produce 2–4 strata rather than the many leaves a naive CART would produce. The simplified version always produces exactly K quartiles.

3. **Amalgamation accounting for heterogeneous HRs.** 5-STAR's Step 5 uses a minimum-p approach (or variance-weighted average for estimation) that accounts for stratum-specific heterogeneity. The stratified log-rank test implicitly assumes the stratum-specific log-rank statistics are exchangeable (same HR across strata). When the HR varies by risk stratum — which it does in the interaction scenario (Scenario 4) — 5-STAR's amalgamation is materially different from the stratified log-rank.

### When is the simplification acceptable?

For the **no-shift** and **moderate-shift** scenarios, where the external score is a good proxy for the prognostic score and the HR is homogeneous across risk groups, the simplification is probably defensible. The ENET filtering step would select approximately the same variables as Ridge-Cal's calibration, and the quartiles would approximate the CTree strata.

For the **interaction scenario** (Scenario 4), the simplification is **not** defensible. The interaction between marker_x and treatment means the HR is heterogeneous across risk groups. 5-STAR's amalgamation is designed for exactly this case; the simplified version would fail to exploit this information.

### My recommendation

If you implement a 6th method, it should be one of:
- Full `run5STAR()` with 2K reps for the key scenarios, clearly labeled
- "ENET-Quartile" clearly labeled as a simplified variant that tests a specific component of 5-STAR (variable selection) while holding the stratification mechanism constant

Do **not** label a quartile-based ENET method as "5-STAR-inspired" in the paper without a detailed footnote explaining what has been simplified and why. This will invite reviewer pushback from the 5-STAR authors.

### Operational recommendation: start with ENET-Quartile, add full 5-STAR if feasible

The pragmatic path: implement ENET-Quartile now (it's fast, fits the existing simulation framework), report it under a name that accurately describes it, and note in the manuscript that a comparison with the full 5-STAR algorithm is a limitation and topic for future work. If the full 5-STAR comparison matters enough to the authors, it can be run at 2K reps for a sensitivity table.

---

## Question 3: Miscalibration Threshold Analysis — Is the Severity Sweep the Right Approach?

**Short answer:** Yes, the severity sweep is the right conceptual approach, but the operational definition of "crossover point" needs care.

### The proposed design is well-motivated

The proposed sweep (multiply shift magnitude by 0, 0.5, 1, 1.5, 2, 3) directly addresses the practical question: "When is the external score so bad that Ridge-Cal can't help, and the clinician should just use standard stratified log-rank?" This is a genuinely useful clinical and methodological question that could influence how trialists decide whether to pre-specify Ridge-Cal in their SAP.

### Define "crossover" carefully — there are two different crossovers

The panel brief asks when Ridge-Cal power "drops below standard LR." There are actually **two** distinct crossover questions worth answering:

**Crossover 1 (Ridge-Cal vs. Standard LR):** At what miscalibration severity does Ridge-Cal-stratified LR power fall to the level of standard stratified LR (no score)? This is the "Ridge-Cal breaks even with naive" crossover.

**Crossover 2 (External-score vs. Standard LR):** At what miscalibration severity does external-score-stratified LR power fall below standard stratified LR? This is the "external score hurts you" crossover.

The screening data already shows that severe miscalibration (multiplier = 1) reduces external-score-stratified power to 0.692, below the no-shift value of 0.730 but still substantially above standard LR (0.540). Ridge-Cal at severity 1 is 0.756. The question is at what multiplier Ridge-Cal itself crosses back to 0.540.

**A third crossover is also worth documenting:** At what severity does Ridge-Cal's power *exceed* the no-miscalibration external-score power (0.730)? The screening data at severity 1 shows Ridge-Cal-stratified at 0.756 > 0.730, meaning miscalibration actually *helps* Ridge-Cal relative to using a well-calibrated external score directly. This is counterintuitive and worth explaining.

### Recommended design for the severity sweep

**Multipliers:** {0, 0.25, 0.5, 0.75, 1, 1.5, 2, 3, 5}

Rationale: The current proposal (0, 0.5, 1, 1.5, 2, 3) is reasonable but could miss a nonlinearity between 0 and 0.5. Adding 0.25 helps characterize the onset of the regime change. Adding 5 helps determine whether there's an asymptote or continued degradation at extreme miscalibration.

**Reps:** 2,000 reps per multiplier × 9 levels = 18K total reps. This gives power precision of ±0.011 at 50% power — enough to characterize the curve shape reliably. A full 10K run per multiplier would be 90K total reps and is probably not justified for what is essentially a sensitivity analysis.

**Methods to include in the sweep:** 
- Standard LR (flat reference line — doesn't change with severity)
- External-score LR
- Ridge-Cal LR
- (Optionally) Cox with external score and Cox with calibrated score, for the efficiency ratio

**Operational definition of the crossover point:** Fit a smoothing spline to (severity, power) for each method and find the severity at which the Ridge-Cal curve intersects the standard LR power level. Report with 95% bootstrap CI. Do not interpolate linearly — the power curve is likely nonlinear, with a plateau at low severity and a steeper decline at high severity.

**Pre-register the null hypothesis before running:** The sweep should be designed to test the null that "Ridge-Cal provides no power gain over standard LR at severity X." This means you need a criterion for declaring the crossover, not just eyeballing the curve. A reasonable criterion: the crossover point is the smallest severity multiplier at which Ridge-Cal LR power is not statistically distinguishable from standard LR at 2K reps (95% CI for Ridge-Cal power includes standard LR power). This is admittedly a low-power test at 2K reps but is clearly pre-specified.

### What the screening data predicts about the crossover

The screening results at severity 1 show:
- Standard LR: 0.540
- Ridge-Cal LR: 0.756
- Gap: +21.6 pp

For Ridge-Cal to close this gap, the severity multiplier would need to induce enough miscalibration to overwhelm the calibration correction. Given that Ridge-Cal uses ridge regularization (which handles noisy calibration gracefully), I'd predict the crossover — if it exists in a practically relevant range — occurs at multiplier ≥ 3–5. At severity 3, the external score coefficients would be so far from the trial's true coefficients that Ridge-Cal would need to learn almost entirely from the trial data. With N=400 and 5 calibration covariates, this is feasible but increasingly difficult.

**The more interesting finding may be no crossover within practical ranges.** If Ridge-Cal maintains advantage over standard LR even at extreme miscalibration, this is a strong result: it says Ridge-Cal is robust to arbitrarily bad external scores. The standard LR doesn't get worse as miscalibration increases (it never uses the external score), so the question is whether Ridge-Cal's advantage shrinks but persists.

---

## Question 4: Paper Integration — How Should These Results Fit the Manuscript?

**Short answer:** The log-rank results belong in the main paper. The 5-STAR comparison and the threshold analysis should be structured differently depending on their final results, but a clear placement recommendation is possible now.

### Current manuscript structure assessment

The manuscript is 24 pages and already has a clear four-section structure (Introduction → Method → Simulation → Discussion). Section 3.3 is the existing hook for the log-rank results ("A dedicated simulation study evaluating this approach is reported in Section 3.3 and supplementary materials"). Section 3.3 currently covers sensitivity analyses: misspecified calibration set, score-stratified log-rank (placeholder), lambda distribution, and blinded vs. unblinded calibration.

The current placeholder text is brief and adequate. The 500-rep screening results now provide enough content to make Section 3.3 a substantial addition.

### Recommended structure for the expanded paper

**Section 3.3 (now fully populated):** Score-Stratified Log-Rank Analysis

- 3.3.1: Methods (5-method comparison, describe each method concisely)
- 3.3.2: Type I error verification (table)
- 3.3.3: Power across scenarios (main table)
- 3.3.4: Cox-to-log-rank efficiency ratio (critical for contextualization)
- 3.3.5: Sparse strata diagnostics (brief; reassuring result)

This section should be **in the main paper.** The reason: for oncology trials, the stratified log-rank is the primary analysis. If Ridge-Cal's efficiency gains evaporate when translated from Cox estimation to log-rank testing, the method's practical value is much reduced. The screening results show the gains survive (0.540 → 0.756 under severe shift), so this is a positive result that strengthens the paper's claim.

**Section 3.4 (new): Miscalibration Threshold Analysis**

- One paragraph: motivation and design
- One figure: power vs. severity multiplier (3-curve plot: Standard LR, External-score LR, Ridge-Cal LR)
- One table: crossover point with CI
- One paragraph: interpretation

Place in the main paper, not an appendix. This is a clinically actionable result — it tells readers when to bother with Ridge-Cal. The Discussion can then reference this table when discussing limitations (§4.3, "when to use Ridge-Cal").

**Appendix A (new): 5-STAR Comparison**

Place the 5-STAR comparison in a supplementary appendix, not the main paper. Reasons:
1. The comparison requires justifying implementation choices (simplified vs. full 5-STAR) that add length and complexity without advancing the main Ridge-Cal story.
2. 5-STAR and Ridge-Cal address different questions: 5-STAR builds risk strata from scratch; Ridge-Cal calibrates an existing external score. They are more complementary than competing, and framing them as head-to-head competitors risks positioning Ridge-Cal as a replication of prior work.
3. Reviewer familiarity: Mehrotra and Marceau West are at Merck (same company as the author per the Disclosure Statement). The comparison will be scrutinized. Placing it in a supplementary appendix reduces the headline surface area while still providing the rigorous comparison for interested readers.

If the 5-STAR comparison is included in the main paper, it should appear in Section 3.3 with a clearly labeled sub-comparison framing: "For context, we compare Ridge-Cal to two alternative approaches that also use blinded trial data for risk stratification: an external-score-based stratification and a simplified elastic net approach." The word "inspired" should be dropped from "5-STAR-inspired" in all labels.

### Section 3 structure summary

| Section | Content | Location |
|---------|---------|----------|
| 3.1 | Original 10K Cox results (existing) | Main |
| 3.2 | Bias, Type I error (existing) | Main |
| 3.3 | Score-stratified log-rank (screening → 10K) | Main |
| 3.4 | Miscalibration threshold sweep | Main |
| Appendix A | 5-STAR comparison (ENET-Quartile or full 5-STAR) | Supplementary |
| Appendix B | Sensitivity (lambda, blinded vs. unblinded, misspecified C) | Supplementary |

---

## Question 5: The Narrative — Is This Still the Same Paper?

**Short answer:** Yes, but the narrative needs a modest reframe. The current framing ("regularized calibration, LoRA analogy") remains valid and appropriate. The additions don't change the paper's core identity — they *strengthen* it by completing the argument.

### What the original paper argues

The manuscript makes a clean, three-part argument:
1. External prognostic scores improve trial efficiency, but miscalibration under population shift can reduce or reverse this gain.
2. Ridge-Cal — a ridge-penalized Cox model on blinded data — diagnoses and corrects miscalibration using only trial-available data.
3. In simulations, Ridge-Cal recovers 7.5 pp of power under severe shift with nominal Type I error and a minimal no-shift penalty.

The LoRA analogy is a framing device that differentiates Ridge-Cal from naive refitting. It doesn't define the paper's contribution — the simulation evidence does.

### What the additions contribute

The score-stratified log-rank simulation and the threshold analysis don't change the paper's core argument. They answer two follow-up questions that a practical reader would ask:

- *"But I use the stratified log-rank as my primary test — does any of this matter for me?"* → Yes: 18–28 pp power gain from score stratification, and Ridge-Cal preserves this under miscalibration.
- *"At what point is my external score so bad that I shouldn't bother with Ridge-Cal?"* → The threshold analysis provides a quantitative answer.

These additions make the paper *more useful* to practitioners without fundamentally changing what the paper claims to contribute.

### What changes (and what to watch for)

**The headline finding is now richer.** The paper currently positions Ridge-Cal as a Cox-estimation method. The log-rank results reposition it (correctly) as a method that improves *testing* efficiency as well, with quantified discretization loss. This is a stronger claim and needs to be carried through into the abstract and conclusion.

**The 5-STAR comparison changes the competitive landscape.** The introduction currently discusses Bayesian dynamic borrowing and domain adaptation as alternatives, not 5-STAR. Adding a 5-STAR comparison introduces a methodological competitor in the same framework (blinded trial data, risk stratification). The introduction will need a new paragraph positioning Ridge-Cal relative to 5-STAR. Suggested framing: "5-STAR builds risk strata from blinded trial data using elastic net and conditional inference trees, without relying on an external prognostic score. Ridge-Cal takes a complementary approach: it starts from an existing external score and makes targeted, regularized corrections for population shift. The two methods are most directly comparable when an external score is available — exactly the scenario for which Ridge-Cal is designed."

**The LoRA analogy becomes less central.** As the paper grows to include log-rank results, threshold analysis, and a 5-STAR comparison, the LoRA framing risks feeling disproportionately prominent relative to the paper's content. I'd recommend retaining the LoRA analogy in Section 1.4 (it's a useful conceptual bridge) but reducing its presence in the abstract and conclusion. The practical simulation evidence is the paper's strength; the LoRA analogy is explanatory scaffolding, not the core contribution.

**The paper remains one paper.** There's no identifiable narrative split that would require splitting this into two papers. The log-rank results are a natural Section 3.3 extension; the threshold analysis is a Section 3.4 sensitivity analysis. The 5-STAR comparison in an appendix adds context without diluting the focus. A 28–30 page paper with a rich supplementary appendix is well within JBS norms for methodology papers.

---

## Specific Actionable Recommendations

### Immediate (pre-10K run)

1. **Rename "5-STAR-inspired" to "ENET-Quartile"** in all simulation code, reports, and manuscript drafts. The current name implies a closer relationship to the full 5-STAR algorithm than exists.

2. **Add two metrics to the severity sweep design:**
   - Diagnostic C-index Δ (C-index_augmented − C-index_base) at each severity level. This connects the threshold analysis back to the diagnostic step in Section 2.2.
   - Ridge penalty λ selected by CV at each severity level. This addresses whether the CV selection mechanism adapts appropriately to increasing severity.

3. **Pre-specify the crossover criterion** before running the sweep: define the crossover as the first severity multiplier at which Ridge-Cal-stratified power ≤ Standard-LR power + 2 × MC SE (i.e., not statistically distinguishable at the simulation precision being used).

4. **Verify oracle stratification bug is fixed** in the 10K run. The report notes the oracle stratification was initially using the LP including treatment effect (which biases the stratification). The fix (v2) should be confirmed before the 10K run and noted in the methods.

### For the 10K run

5. **Use 2K reps for the 5-STAR/ENET-Quartile comparison**, not 10K. Reserve 10K reps for the core 5-method comparison (Standard LR, External-score LR, Ridge-Cal LR, Trend test, Oracle). This keeps runtime manageable and is justified because the 5-STAR comparison is supplementary.

6. **Parallelize** using `future_map()` as described in the screening report. At 10K × 7 scenarios × 4 core methods, sequential runtime is unacceptable (~154 minutes estimated in the report).

7. **Report one-sided p-values consistently** throughout. The panel brief tables and manuscript both discuss one-sided α = 0.05, but the screening report flags that the code uses two-sided. Clarify and standardize before the 10K run.

### For the manuscript

8. **Rewrite the abstract** to include: (a) the score-stratified log-rank finding (+18–28 pp over standard LR from score stratification), (b) the Ridge-Cal advantage under miscalibration in the log-rank framework (+6.4 pp severe shift), and (c) a reference to the threshold analysis.

9. **Add a two-sentence positioning paragraph for 5-STAR** in Section 1.3 (Existing Approaches). This prevents reviewers from asking "why isn't 5-STAR discussed in the introduction?"

10. **Update Table 1** (main Cox results) to include a column for "Log-Rank (Ridge-Cal stratified)" for the complete side-by-side comparison. Or present a parallel Table 3 with log-rank results — this gives reviewers a single place to find all the simulation results.

11. **The discretization loss finding (efficiency ratio ~1.13) must appear in the Discussion**, not just the results. The implication is: Ridge-Cal Cox (continuous) provides 13% more power than Ridge-Cal log-rank (quartile) for the same underlying method. Trialists designing studies should account for this when choosing the primary analysis.

---

## Summary Verdict

| Question | Verdict | Confidence |
|---------|---------|-----------|
| 6-method set correct? | Mostly yes; rename "5-STAR-inspired" → "ENET-Quartile" | High |
| Full 5-STAR or simplified? | Simplified is defensible with honest naming; full 5-STAR preferred for rigor | Medium |
| Severity sweep approach correct? | Yes; add more points at low severity and extreme end | High |
| Crossover definition? | Need pre-specified criterion; suggest CI-based rule | High |
| Paper integration? | Log-rank + threshold in main paper; 5-STAR in appendix | High |
| Same paper? | Yes; reframe abstract and conclusion to include testing claims | High |

The simulation plan is sound, the screening results are informative, and the proposed expansions are well-motivated. The main risk is the 5-STAR comparison being perceived as inadequate if the implementation is not defensible. Address the naming and implementation choices before committing to the final run.

---

*Review prepared for the Ridge-Cal panel advisory session. Not for external distribution.*
