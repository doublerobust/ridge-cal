# Ridge-Cal Panel Brief: Simulation Plan & Paper Integration

## Context

Ridge-Cal is a regularized calibration method for external prognostic scores using blinded trial data. The paper has 10K-rep simulation results showing it recovers power under population shift. We're now expanding to address two reviewer/human questions.

## Current Status

**Manuscript:** 24-page JBS submission-ready PDF. Key edits from human review applied (removed PROCOVA branding, added stratified log-rank discussion, covariate shift note, etc.)

**Screening simulation completed (500 reps × 7 scenarios):**

Score-stratified log-rank results:
| Method | No shift | Severe shift | Interaction | Null (Type I) |
|--------|:-------:|:-----------:|:-----------:|:------------:|
| Standard LR | 0.516 | 0.540 | 0.476 | 0.044 |
| External-score LR | 0.730 | 0.692 | 0.674 | 0.040 |
| Ridge-Cal LR | 0.708 | **0.756** | **0.744** | 0.052 |
| Oracle LR | 0.748 | 0.780 | 0.788 | 0.048 |

Cox continuous results (for efficiency ratio):
| Method | No shift | Severe shift |
|--------|:-------:|:-----------:|
| Cox + external score | 0.834 | 0.736 |
| Cox + calibrated score | 0.814 | **0.852** |

Key finding: Score stratification adds 18-28pp power over standard log-rank. Ridge-Cal beats external score under miscalibration (+6.4pp severe, +7.0pp interaction). Discretization loss ≈ 13% (efficiency ratio ~1.13).

## Two New Questions from the Human

### Question 1: 5-STAR Comparison

Devan Mehrotra's 5-STAR method (Merck, Statistics in Medicine 2021) is an alternative approach that builds risk strata from blinded trial data using elastic net Cox regression. Available at `github.com/rmarceauwest/fiveSTAR` (R package by Rachel Marceau West & Devan Mehrotra).

**Key difference from our approach:**
- 5-STAR: elastic net selects variables → conditional inference trees → risk strata → amalgamated estimate
- Ridge-Cal: external score → ridge calibration → score quartiles → standard stratified analysis
- External-score: external score → score quartiles → standard stratified analysis

We propose a 6-method comparison adding a "5-STAR-inspired" method (elastic net selection → score quartiles) to the log-rank simulation.

### Question 2: Miscalibration Threshold

At what point is the external score so miscalibrated that Ridge-Cal's effort is not worth it, and we should just use standard stratified log-rank?

Proposal: Run the severe shift scenario at varying severity levels (multiply shift magnitude by 0, 0.5, 1, 1.5, 2, 3) to find the crossover point where Ridge-Cal-stratified power drops below standard LR.

## Panel's Task

Please review:

1. **Simulation plan:** Is the 6-method comparison the right set? Are we missing anything?
2. **5-STAR implementation:** The simplified "5-STAR-inspired" approach (elastic net + quartiles) vs. the full 5-STAR algorithm (elastic net + partykit trees + amalgamation) — is our simplification defensible? Or do we need the full algorithm?
3. **Miscalibration threshold:** Is the proposed severity sweep the right approach? How to define the "crossover point" operationally?
4. **Paper integration:** How should these new results fit into the manuscript structure?
   - New section? Appendix? Sensitivity analysis within existing Results section?
   - Should 5-STAR be in the main paper or supplementary?
   - Should the threshold analysis be in the Discussion or Results?
5. **Narrative:** What's the right story to tell? The paper currently positions Ridge-Cal as "regularized calibration." Adding score-stratified log-rank + 5-STAR comparison changes the narrative. Is it still the same paper?

## Key Documents to Read

- Manuscript: /home/yue-shentu/.openclaw/workspace/research-proposals/ridge-cal/ridge-cal-manuscript.md
- Log-rank simulation plan: /home/yue-shentu/.openclaw/workspace/ridge-cal/score-stratified-logrank-plan.md
- Screening results report: /home/yue-shentu/.openclaw/workspace/ridge-cal/audit/logrank-sim-report.md
- 5-STAR source: cloned at /tmp/fiveSTAR/
- 5-STAR paper: Mehrotra (2021) Statistics in Medicine, 40(22), 4871-4894

## Output

Write your review to: /home/yue-shentu/.openclaw/workspace/ridge-cal/audit/panel-{modelname}-review.md

Address all 5 questions. Be specific and actionable. Use data from the screening results where relevant.
