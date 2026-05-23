# Second-Opinion Review: Ridge-Cal Manuscript Update (Score-Stratified Log-Rank & Threshold Analysis)

**Reviewer:** Claude Sonnet (independent second reviewer)  
**Date:** 2026-05-22  
**Role:** Second opinion on proposed manuscript updates based on simulation outputs  
**Documents reviewed:**
- Original manuscript: `research-proposals/ridge-cal/ridge-cal-manuscript.md`
- Simulation report (screening): `ridge-cal/audit/logrank-sim-report.md`
- Core 10K simulation results: `ridge-cal/output/logrank-sim-results.txt`
- Threshold sweep results: `ridge-cal/output/logrank-threshold-results.txt`
- First panel review (Claude): `ridge-cal/audit/panel-claude-review.md`
- Second panel review (Gemini): `ridge-cal/audit/panel-gemini-review.md`
- Final execution plan: `ridge-cal/audit/logrank-final-execution-plan.md`

---

## Summary Verdict

The simulation data is solid and the findings are genuinely important. The proposed manuscript updates are directionally correct but will require careful execution on three fronts: (1) how ENET-Quartile is framed relative to 5-STAR, (2) how the threshold sweep's "no crossover" finding is narrated, and (3) a few numerical accuracy issues between the current manuscript text and the new 10K results. I flag these below. No finding from the simulation undermines the paper's core claims — if anything, the 10K results strengthen them.

---

## 1. Does the Draft Accurately Represent the Simulation Data?

> Note: As `manuscript-update-draft.md` does not yet exist at time of review, this assessment is prospective — I am reviewing what the draft *should* say based on the raw data files, and flagging concerns a draft author must address.

### 1a. Core 10K Results vs. Current Manuscript Numbers

The manuscript abstract and Section 3.2 cite results from an earlier run. The 10K results (`logrank-sim-results.txt`, 2026-05-22) are now the authoritative figures. Key discrepancies to watch for:

| Statistic | Manuscript (current) | 10K Results | Action needed |
|-----------|:--------------------:|:-----------:|:-------------:|
| Severe shift: Ridge-Cal power | 0.833 | — (Cox continuous) | Distinguish Cox from LR frame clearly |
| Severe shift: Score-adj power | 0.758 | — (Cox continuous) | Ditto |
| Severe shift: LR external-score | Not in ms | 0.6853 | Add to Section 3.3 |
| Severe shift: Ridge-Cal LR | Not in ms | 0.7481 | Add to Section 3.3 |
| Type I error (Ridge-Cal) | "nominal" | 0.0510 (Cox-Cal: 0.0579) | Both nominal; Cox-Cal slightly elevated but within 2 MC SE |
| Efficiency ratio (median) | "~13% loss" (from screening) | 1.093–1.186 (non-null) | Confirm median ≈ 1.13 — the 10K data supports this |

**Critical framing issue:** The manuscript's primary results (Table 1, 0.758 vs. 0.833) are from the *Cox* framework. The new log-rank results are a separate set of numbers in a separate framework. These must be presented in parallel, not as an update that replaces the Cox numbers. Any draft that does not maintain this distinction will confuse readers about what's being compared to what.

### 1b. Threshold Sweep Representation

The `logrank-threshold-results.txt` file presents 2K-rep results across 8 severity multipliers (0, 0.25, 0.5, 0.75, 1, 1.5, 2, 3). Key figures for the draft:

| Multiplier | Standard | ExtScore | RCCal | ENETQ | Delta-C | C_ext |
|:----------:|:--------:|:--------:|:-----:|:-----:|:-------:|:-----:|
| 0.00 | 0.507 | 0.759 | 0.746 | 0.731 | 0.032 | 0.968 |
| 0.25 | 0.537 | 0.754 | 0.760 | 0.740 | 0.048 | 0.952 |
| 0.50 | 0.522 | 0.732 | 0.752 | 0.734 | 0.081 | 0.919 |
| 0.75 | 0.525 | 0.715 | 0.756 | 0.734 | 0.119 | 0.881 |
| 1.00 | 0.530 | 0.686 | 0.743 | 0.718 | 0.140 | 0.860 |
| 1.50 | 0.530 | 0.643 | 0.739 | 0.716 | 0.196 | 0.804 |
| 2.00 | 0.534 | 0.620 | 0.742 | 0.745 | 0.227 | 0.773 |
| 3.00 | 0.525 | 0.563 | 0.731 | 0.738 | 0.295 | 0.705 |

**The headline finding — no crossover — is real and defensible.** Ridge-Cal LR power remains above Standard LR power at every tested multiplier (range 0.731–0.760 vs. 0.507–0.537). The margin decreases from ~0.24 pp at multiplier 0 to ~0.21 pp at multiplier 3, but never closes. This is a genuinely strong result.

**However, the draft must represent the MC SE correctly.** At 2K reps, MC SE ≈ 0.0224 (for p=0.5). The threshold results file states MC SE (2x) = 0.0447. Ridge-Cal's minimum advantage over Standard is 0.731 − 0.525 = 0.206 at multiplier 3.0, which is approximately 4.6 MC SE. The "no crossover" conclusion is statistically well-grounded. The draft should state this explicitly rather than simply asserting "no crossover."

**ENET-Quartile exhibits a non-monotone pattern.** ENETQ power at multiplier 2.0 (0.745) exceeds multiplier 1.0 (0.718) and approximately matches Ridge-Cal. At multiplier 3.0 (0.738) it also nearly matches Ridge-Cal (0.731). This is unexpected and worth commenting on: at extreme miscalibration, the external score becomes nearly uninformative, and ENET-Quartile (which learns from scratch) can actually outperform Ridge-Cal, which is constrained to anchor on the external score. **Any draft narrative that positions Ridge-Cal as universally superior to ENET-Quartile is inconsistent with the data at multipliers ≥ 2.**

---

## 2. Are the Claims Justified?

### 2a. Main power claims (Cox framework) — JUSTIFIED

The manuscript's primary claims (7.5 pp power gain under severe shift, 80% bias reduction, nominal Type I error) come from the established 10K Cox simulation and are well-supported. Nothing in the new simulation results contradicts these.

### 2b. Score-stratified log-rank claims — JUSTIFIED with caveats

From the 10K results:

- "Score stratification adds 18–28 pp over standard log-rank" — **CORRECT**: 0.528 → 0.762 (no shift, external score) = +23.4 pp; 0.528 → 0.754 (no shift, Ridge-Cal) = +22.6 pp. Range 18–28 pp is supported.
- "Ridge-Cal beats external score under severe miscalibration" — **CORRECT**: 0.748 (Ridge-Cal LR) vs. 0.685 (external-score LR) at severe shift = +6.3 pp.
- "Discretization loss ≈ 13%" — **BROADLY CORRECT** but needs precision. The efficiency ratios in the 10K run range from 1.093 (external Cox/LR at severe shift) to 1.186 (Ridge-Cal at non-PH). The median across non-null scenarios for the Ridge-Cal method is approximately 1.12, consistent with the "~13%" claim from screening. **The draft should state "approximately 10–18% depending on scenario" rather than a single 13% figure**, because the ratio is notably scenario-dependent.

### 2c. ENET-Quartile positioning claims — MIXED

Any claim that "Ridge-Cal consistently outperforms ENET-Quartile" is **only partially justified**:

- In the 10K core simulation (severe shift): Ridge-Cal LR 0.748 vs. ENET-Q 0.728 — Ridge-Cal wins by +2.0 pp.
- In the threshold sweep (multipliers 2 and 3): ENET-Q 0.745 and 0.738 vs. Ridge-Cal 0.742 and 0.731 — ENET-Q wins or ties.

**The correct framing is:** "Ridge-Cal is superior to ENET-Quartile at mild-to-moderate miscalibration levels (multiplier ≤ 1), because the external score provides a reliable starting point. At extreme miscalibration (multiplier ≥ 2), ENET-Quartile — which learns entirely from trial data — becomes competitive, reflecting the diminishing value of the miscalibrated external score as an anchor."

This is actually a richer and more honest story. It tells practitioners exactly when to switch approaches. The draft should leverage this rather than smooth it over.

### 2d. "No crossover" claim for threshold analysis — JUSTIFIED but framing needs work

The file correctly states no crossover within the tested range. The draft should not say "Ridge-Cal is always better than standard log-rank regardless of miscalibration severity" without the qualifier that this holds within the N=400, 5-covariate calibration set, HR=0.70 setting. Extrapolation to more extreme settings is not supported by the simulation.

---

## 3. Is the Narrative Consistent with the Rest of the Paper?

### 3a. Strong consistency: blinded-data theme

The paper's core positioning — "diagnose and correct miscalibration using only blinded data" — is preserved and strengthened by the log-rank results. ENET-Quartile also uses only blinded data, so the comparison is fair within this constraint. ENET-Cox likewise. This theme should be reinforced in Section 3.3's opening paragraph.

### 3b. Tension with abstract and conclusion

The current abstract reads: *"Ridge-Cal recovers 7.5 percentage points of power over standard covariate adjustment with an external prognostic score (0.758 vs. 0.833)"*. These are Cox numbers. The log-rank framework tells a different but complementary story (0.685 → 0.748, +6.3 pp at severe shift in the LR testing framework). The draft must clarify which framework each set of numbers belongs to, particularly in the abstract. A simple parenthetical "(Cox estimation framework)" and "(stratified log-rank testing framework)" would suffice.

The conclusion in §4.6 should be updated to mention the log-rank finding. Currently it ends with Cox-only claims. A new sentence like: *"In the log-rank testing framework, which is the primary paradigm in oncology trials, score-stratified analyses recover the majority of the Cox efficiency gain, with Ridge-Cal-stratified log-rank outperforming external-score stratification by 6.3 pp under severe miscalibration and by 7.1 pp under treatment-by-covariate interaction."*

### 3c. LoRA analogy proportionality

The panel-claude review correctly noted that the LoRA analogy may become disproportionately prominent as the paper grows. This remains true. The new results are simulation-driven; the LoRA framing is conceptual scaffolding. In revisions, the abstract should lead with the simulation evidence, not the LoRA concept. The current abstract opens with methods (correctly), but the framing of Ridge-Cal as "inspired by LoRA" should be softened or moved entirely to §1.4.

### 3d. Estimand discussion

The manuscript already has a well-developed estimand discussion in §2.4. The log-rank results do not introduce new estimand complications — the stratified log-rank test is a valid test of the same sharp null hypothesis. The draft does not need to revisit estimand language in §3.3.

---

## 4. ENET-Quartile, 5-STAR, and Threshold Analysis Positioning

### 4a. ENET-Quartile labeling — CRITICAL

The execution plan correctly adopted "ENET-Quartile" as the label (not "5-STAR-inspired"). This must be maintained uniformly across all output files, figures, and manuscript text. The threshold results file (`logrank-threshold-results.txt`) already uses "ENETQ" — good. The core results file uses "ENETQ" — good. Any manuscript text that uses "5-STAR-inspired" must be corrected before the author sees it.

Additionally, the manuscript's Section 3.3 currently references "5-STAR" comparison without describing the ENET-Quartile approach. The draft must add a brief methods paragraph defining ENET-Quartile:

> "A simplified data-adaptive stratification (ENET-Quartile) was included as a reference: an elastic net Cox model (α = 0.5, 5-fold CV) was fit on blinded trial data using all 20 covariates, and the resulting predicted scores were discretized into quartiles as additional stratification factors. This method approximates the variable-selection step of Mehrotra & Marceau West's 5-STAR algorithm (2021) while using fixed quartile boundaries rather than conditional inference tree strata; it tests whether blinded variable selection alone adds value independent of Ridge-Cal's external-score calibration."

This framing is transparent, factually accurate, and pre-empts the obvious reviewer objection.

### 4b. Full 5-STAR omission — NOTE FOR THE AUTHOR

Neither the 10K run nor the threshold sweep included the full `run5STAR()` implementation. The draft must acknowledge this explicitly as a limitation in §4.3 or a footnote in §3.3. Suggested language:

> "The ENET-Quartile comparator approximates the variable-selection phase of the 5-STAR algorithm (Mehrotra & Marceau West, 2021) but does not implement the conditional inference tree or amalgamation steps. A rigorous comparison with the full 5-STAR pipeline — which would require substantially greater computation at 10,000 replicates — is left for future work."

Omitting this note would be a significant vulnerability with reviewers from the 5-STAR authors' group (who are at Merck, same institution as this paper's author).

### 4c. Threshold sweep — placement and narrative

The threshold sweep results support Section 3.4 placement in the main paper, as recommended by the panel. The key finding (no crossover within practical ranges) is not a null result — it is actively informative. It tells practitioners: "Even when the external score is highly miscalibrated, Ridge-Cal does not become harmful relative to standard log-rank. It may become less advantageous relative to ENET-Quartile, but it never falls below the naive baseline."

The narrative arc for Section 3.4 should be:

1. **Motivation**: At what severity does miscalibration make Ridge-Cal not worth using?
2. **Result**: No crossover with standard LR within practical ranges (multiplier 0–3, ΔC 0.03–0.30).
3. **Nuance**: ENET-Quartile becomes competitive at extreme miscalibration (multiplier ≥ 2), suggesting a decision rule for practitioners: "If the diagnostic ΔC > 0.20, consider ENET-Quartile as an alternative or complementary approach."
4. **Practical guidance**: The diagnostic C-index difference (reported in the threshold sweep as "Delta-C") provides a blinded, pre-specifiable criterion for this decision.

This "decision rule" framing is novel and clinically useful. It ties the diagnostic step (§2.2) to the threshold sweep in a way that practitioners can actually use.

### 4d. Trend test — remove or relegate

The Tarone trend test results (power ≈ 0.000–0.004 across all scenarios) are not informative for homogeneous treatment effects and should not appear in the main results table. They can be:
- Relegated to a footnote explaining the test was evaluated and found to have no power for constant HR
- Kept in the supplementary appendix with the explanation from the simulation report (§5)
- Removed entirely from the 10K results table to avoid confusing readers

If the trend test is retained, the draft must include the explanation from §5 of the simulation report: the Tarone test is designed to detect *heterogeneous* treatment effects across risk groups, not constant HRs, and its near-zero power in all scenarios is expected and not a code error.

---

## 5. Specific Issues and Suggestions Before the Author Sees It

### Issue 1 — Type I error for Cox-Cal is borderline [LOW RISK]

The 10K results show Cox-Cal Type I error = 0.0579 (null scenario). This is the highest observed Type I error, and at n=10,000 reps the MC SE is ±0.0043, so the 95% CI is [0.049, 0.067]. This is nominally within two standard errors of 0.05 but is at the upper boundary. The manuscript currently claims "nominal Type I error" across all methods. This specific value should be flagged transparently:

> "Type I error was maintained at nominal levels across all methods. The Cox model with calibrated score exhibited a Type I error of 0.058 (95% MC CI: 0.049–0.067), which is within the simulation's Monte Carlo margin but warrants monitoring in future work."

Do not suppress this figure or smooth over it. Reviewers will find it.

### Issue 2 — Efficiency ratio denominator inconsistency [MEDIUM RISK]

The efficiency ratio table divides "Cox continuous power" by "log-rank quartile power." For the Trend method, this produces ratios of 850.7, 833.7, etc. — trivially meaningless (dividing ~0.84 by ~0.001). These should be removed from the table or the table should exclude the Trend method from the efficiency ratio calculation. Leaving absurd efficiency ratios in a table is the kind of thing that gets noted in peer review.

### Issue 3 — ENET-Quartile beats Ridge-Cal at extreme shift — must be addressed [HIGH RISK]

As noted in §2c above, the threshold sweep shows ENET-Q ≥ Ridge-Cal at multipliers 2.0 and 3.0. If the draft contains language like "Ridge-Cal consistently outperforms ENET-Quartile" or "Ridge-Cal is always preferred when an external score is available," that claim is contradicted by the simulation data and must be corrected before it reaches the author. The correct claim is conditional on miscalibration severity.

### Issue 4 — No Delta-C at crossover (because no crossover) [LOW RISK, FRAMING]

The threshold results file reports the "crossover analysis" as "No crossover observed." This is excellent scientifically, but the draft should still report the Delta-C values across multipliers (they range from 0.032 to 0.295) because they provide the link back to the diagnostic step. A table or figure of (multiplier, Delta-C, Power_RidgeCal, Power_Ext, Power_Standard) would be the ideal presentation.

### Issue 5 — Stratum base: ECOG + region vs. ECOG + sex [LOW RISK, COSMETIC]

The simulation report (§1) flags that the standard stratification uses ECOG + region (not ECOG + sex as in the primary Cox analysis). The draft should acknowledge this explicitly in §3.3 to preempt the obvious reviewer question. A brief note: "The stratified log-rank analyses used ECOG performance status and geographic region (included as a stratification factor in the log-rank sensitivity analyses; see §3.1 for the primary analysis stratification factors)."

### Issue 6 — Sample size for threshold sweep [LOW RISK]

The threshold sweep used 2K reps per multiplier, giving MC SE ≈ ±0.022. This is adequate for concluding "no crossover" (the gap of ~0.20 is ~9 MC SE) but the draft should state the rep count explicitly to allow readers to assess the precision claim.

### Suggestion 1 — Add a figure for the threshold sweep

A single line plot — Multiplier (x-axis) vs. Power (y-axis), three curves: Standard LR (flat), External-score LR (declining), Ridge-Cal LR (nearly flat but above Standard) — would communicate the threshold finding more effectively than any table. This is a figure worth creating for the paper.

### Suggestion 2 — Decision tree for practitioners

The Discussion (§4.5 or §4.3) should add a practical decision framework:

1. Is there an external prognostic score? → If no: use ENET-Quartile or standard stratification.
2. Run the diagnostic (ΔC). Is ΔC > 0.01? → If no: use external score directly (no recalibration needed).
3. Is ΔC > 0.20? → If yes: consider whether ENET-Quartile provides additional value alongside Ridge-Cal.
4. Otherwise: apply Ridge-Cal.

This ties together the diagnostic step, the threshold sweep, and the ENET-Quartile comparison in a way that is maximally useful to practitioners.

### Suggestion 3 — Update Table 1 footnote

The current Table 1 in the manuscript footnote should reference that Cox-framework power figures differ from log-rank framework figures (which appear in the new Section 3.3 table). A cross-reference prevents reader confusion.

---

## 6. Summary Scorecard

| Area | Assessment | Severity |
|------|-----------|---------|
| Core Cox results (abstract/Tables 1–2) | Valid; no changes needed | — |
| Log-rank results representation | Not yet drafted; must distinguish LR from Cox frames | HIGH |
| ENET-Quartile labeling | "ENET-Quartile" correctly used in output files | LOW |
| ENET-Q vs. Ridge-Cal at extreme shift | Must be reported accurately; draft must not overclaim | HIGH |
| Threshold "no crossover" framing | Valid finding; needs MC SE quantification | MEDIUM |
| 5-STAR full algorithm omission | Must acknowledge in limitations | MEDIUM |
| Trend test efficiency ratios (absurd values) | Must remove from table | MEDIUM |
| Type I error (Cox-Cal 0.058) | Report transparently, don't suppress | LOW |
| ECOG+region vs. ECOG+sex inconsistency | Note in §3.3 | LOW |
| Decision framework for practitioners | Add to Discussion | SUGGESTION |
| Threshold sweep figure | Strongly recommended | SUGGESTION |
| Abstract update for LR claims | Needed; clear framework labeling | MEDIUM |

---

## Final Recommendation

The simulation is complete and well-executed. The findings are strong and support the paper's core message. Before the author sees a manuscript draft, the draft author should:

1. **Resolve the ENET-Q vs. Ridge-Cal at extreme shift narrative** — this is the single most important accuracy issue.
2. **Maintain strict Cox/LR framework separation** in all numbers cited.
3. **Add the 5-STAR omission limitation** to §4.3.
4. **Remove Trend test from the efficiency ratio table** or add a footnote explaining why the ratios are not informative.
5. **State the no-crossover finding with MC SE quantification**, not as an unsupported assertion.

With these corrections, the manuscript update will accurately represent the data and be defensible to reviewers.

---

*Second-opinion review prepared for internal use. Not for external distribution.*
