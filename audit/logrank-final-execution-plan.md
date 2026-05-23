# Ridge-Cal Log-Rank Simulation — Final Execution Plan

## Task
Run the full score-stratified log-rank simulation incorporating panel recommendations.

## Phase 0: Read Existing Work
1. Read the existing R code: `/home/yue-shentu/.openclaw/workspace/ridge-cal/code/`
   - `run_clean.R`, `R/data_generation.R`, `R/analysis_methods.R`, `R/training.R`
2. Read the existing screening simulation code: `/home/yue-shentu/.openclaw/workspace/ridge-cal/code/run_logrank_sim.R`
3. Read the screening report: `/home/yue-shentu/.openclaw/workspace/ridge-cal/audit/logrank-sim-report.md`
4. Read the plan: `/home/yue-shentu/.openclaw/workspace/ridge-cal/score-stratified-logrank-plan.md`

## Phase 1: Update Simulation Code

Update `/home/yue-shentu/.openclaw/workspace/ridge-cal/code/run_logrank_sim.R` to implement 7 methods:

| # | Name | Description |
|---|------|-------------|
| 1 | Standard LR | Stratified by ECOG + region |
| 2 | External-score LR | + external score quartiles (pre-specified from external data) |
| 3 | Ridge-Cal LR | + Ridge-Cal calibrated score quartiles (trial data adaptive) |
| 4 | ENET-Quartile | Elastic net Cox on blinded trial data → score quartiles |
| 5 | ENET-Cox | Elastic net Cox on blinded trial data → continuous Cox p-value |
| 6 | Oracle LR | + true prognostic LP quartiles |
| 7 | Trend test (Tarone) | Ordered trend across external-score quartiles |

### Notes on ENET-Quartile (Method 4):
- Run cv.glmnet(alpha=0.5, nfolds=5) on blinded trial data (Surv(time, event) ~ all 20 covariates)
- Get predicted score from the elastic net model
- Cut at trial data quartiles
- Use as additional stratum in log-rank (like Methods 2-3)
- This is NOT the full 5-STAR algorithm — label it clearly as "ENET Quartile"

### Notes on ENET-Cox (Method 5):
- Same elastic net model as Method 4
- But use the predicted score as a continuous covariate in Cox PH
- Record Wald test p-value and HR
- This isolates the external score's value vs. learning from scratch

## Phase 2: Run Core Simulation (10K reps × 7 scenarios)

Run the 7 methods across the standard 7 scenarios (same as existing run_clean.R):

| # | Scenario | HR | Shift | Special |
|---|----------|:--:|:-----:|---------|
| 1 | No shift | 0.70 | None | Baseline |
| 2 | Moderate shift | 0.70 | Moderate | |
| 3 | Severe shift | 0.70 | Severe | Primary interest |
| 4 | Interaction | 0.70 | Severe | Treatment × marker |
| 5 | Null | 1.0 | None | Type I error |
| 6 | Non-PH | 0.70 | Severe | 2-month delay |
| 7 | Smaller effect | 0.75 | Severe | |

Parameters: N=400, ~180 PFS events, ECOG + region stratification, K=4 quartiles.

Record for each rep: p-value, null/alt indicator, sparse-strata flag, HR estimate.

Parallelize using future_map() matching run_clean.R's pattern.

## Phase 3: Miscalibration Threshold Sweep

Run the severe shift scenario at varying severity levels with 2K reps each:

| Multiplier | Description |
|:----------:|-------------|
| 0.0 | No shift |
| 0.25 | Very mild |
| 0.5 | Mild |
| 0.75 | Moderate-light |
| 1.0 | Standard severe (baseline) |
| 1.5 | High |
| 2.0 | Very high |
| 3.0 | Extreme |

Report for each level: Power(Standard LR), Power(External-score LR), Power(Ridge-Cal LR), Power(ENET-Quartile), diagnostic C-index difference ΔC.

Define the crossover as: first severity multiplier where Power(Ridge-Cal) ≤ Power(Standard LR) + 2×MC SE.

## Phase 4: Write Report

Write to `/home/yue-shentu/.openclaw/workspace/ridge-cal/audit/logrank-sim-final-report.md` including:

1. **Core results table** — 7 methods × 7 scenarios, power + Type I error
2. **Efficiency ratio table** — Power(Cox continuous) / Power(log-rank quartile) for each method
3. **Threshold sweep table** — power across severity levels, crossover point, ΔC at crossover
4. **Sparse strata diagnostics** — proportion of reps with <5 events in any stratum-cell
5. **Code correctness verification** — confirm oracle fix from screening, etc.
6. **Recommendations for manuscript integration**

## Output Files
- Code: `/home/yue-shentu/.openclaw/workspace/ridge-cal/code/run_logrank_sim.R`
- Results (core): `/home/yue-shentu/.openclaw/workspace/ridge-cal/output/logrank-sim-results.txt`
- Results (threshold): `/home/yue-shentu/.openclaw/workspace/ridge-cal/output/logrank-threshold-results.txt`
- Full data: `/home/yue-shentu/.openclaw/workspace/ridge-cal/output/logrank-sim-results.rds`
- Report: `/home/yue-shentu/.openclaw/workspace/ridge-cal/audit/logrank-sim-final-report.md`
