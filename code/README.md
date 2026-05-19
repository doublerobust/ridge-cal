# Ridge-Cal Simulation

Simulation code for "Ridge-Cal: Efficient Regularized Calibration of External Prognostic Scores Using Blinded Trial Data."

## Quick Start

```bash
cd simulation

# Full 10K × 7 scenarios (5 methods, ~27 min on 12 cores)
Rscript run_clean.R

# Interactive version with MAP-Cox (6 methods, ~35 min)
Rscript run_standalone.R
```

## Directory Layout

```
simulation/
├── run_clean.R                  # 10K × 7 scenarios (5 methods: Std, Orac, LR, PRO, RCal)
├── run_standalone.R             # Interactive version (6 methods, includes MAP-Cox)
├── R/
│   ├── data_generation.R        # Covariate generation, survival times, censoring
│   ├── training.R               # External model training
│   ├── analysis_methods.R       # All analysis functions
│   └── map_proper.R             # Proper MAP prior precision-weighted implementation
├── scripts/
│   └── report.R                 # Legacy report generation (for .rds-based output)
├── map_cox_results.txt          # Pre-computed MAP-Cox results
├── launch_now.sh                # Quick launch (detached)
└── launch_sim.sh                # Cron-ready launch
```

## Environment Setup

### Option A: Conda (cross-platform, recommended)

```bash
conda env create -f ../setup/environment.yml -n ridgecal-sim
conda activate ridgecal-sim
```

### Option B: Manual R installation (Linux/macOS via brew)

```bash
bash ../setup/setup.sh
```

### Option C: Windows

```powershell
powershell -ExecutionPolicy Bypass -File ..\setup\setup_windows.ps1
```

## Scenarios

| ID | Name | Treatment effect | Key variation |
|:--:|:-----|:---------------:|--------------|
| 1 | No shift | HR = 0.70 | External model correctly specified |
| 2 | Moderate shift | HR = 0.70 | Small coefficient differences |
| 3 | Severe shift | HR = 0.70 | Marker X flips, sex becomes prognostic |
| 4 | Interaction | HR = 0.70 | Marker X × treatment interaction |
| 5 | Null | HR = 1.00 | Type I error assessment |
| 6 | Non-PH | HR = 0.70 (delayed) | 2-month onset delay |
| 7 | Smaller effect | HR = 0.75 | Weaker treatment effect |

## Comparison Methods

1. Cox-2 — Standard Cox with 2 stratification variables (ECOG, sex)
2. Oracle Cox — All 20 covariates (theoretical upper bound)
3. Stratified Log-Rank — Non-parametric baseline
4. PROCOVA — External prognostic score, no calibration
5. Ridge-Cal (proposed) — Ridge-penalized Cox with CV-selected λ
6. MAP-Cox (sensitivity) — Bayesian MAP prior borrowing

## Running the Simulation

```bash
# Full 10K × 7 (5 methods, ~27 min on 12 cores)
Rscript run_clean.R

# Interactive with MAP-Cox (6 methods, ~35 min)
Rscript run_standalone.R
```

## Reproducibility

- Seed-based: `set.seed(20260517 + scenario_id * 100000 + replicate_id)`
- All code at `github.com/doublerobust/ridge-cal`
- Results reproducible via `run_clean.R` (10K reps)
