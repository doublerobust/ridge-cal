# Phase II Calibration Simulation

Simulation code for "Phase II-Calibrated Prognostic Scores with
Semiparametric Efficient Estimation for Seamless Phase II/III Clinical Trials."

## Quick Start

```bash
cd simulation

# Quick test (100 reps each, all scenarios)
Rscript run_all.R --quick

# Full run (1000 reps each, all scenarios, ~8-10 hours)
Rscript run_all.R

# Single scenario
Rscript scripts/run_simulation.R --scenario 1 --n_sim 100

# View results
Rscript scripts/report.R

# LaTeX tables
Rscript scripts/report.R --latex
```

## Directory Layout

```
simulation/
├── run_all.R                  # Master runner (all scenarios, parallel)
├── R/
│   ├── data_generation.R      # Covariate generation, survival times, censoring
│   ├── training.R             # External model training, Bayesian calibration
│   └── analysis_methods.R     # All 11 comparison methods
├── scripts/
│   ├── run_simulation.R       # Single-scenario runner + aggregation
│   └── report.R               # Results tabulation
├── output/                    # Saved .rds results
└── _targets/                  # Targets cache (optional)
```

## Environment Setup

### Option A: Conda (cross-platform, recommended)

```bash
conda env create -f ../setup/environment.yml -n ph2cal-sim
conda activate ph2cal-sim
```

### Option B: Manual R installation (Linux/macOS via brew)

```bash
bash ../setup/setup.sh
```

### Option C: Windows

```powershell
powershell -ExecutionPolicy Bypass -File ..\setup\setup_windows.ps1
```

## GPU Acceleration (Optional)

The RTX 1080 can speed up the Bayesian calibration via NumPyro/JAX:

```bash
conda activate ph2cal-sim
# JAX will detect CUDA automatically if NVIDIA drivers are installed
python3 -c "import jax; print(jax.devices())"
```

Replace `calibrate_bayesian()` in `R/training.R` with `calibrate_numpyro()`
(see `scripts/gpu_calibration.py`).

## Scenarios

| ID | Name | Key variation |
|----|------|--------------|
| 1 | No shift | External model correctly specified |
| 2 | Moderate shift | 1.25× baseline hazard, 15% β shift |
| 3 | Severe shift | 2× baseline hazard, 40% β shift |
| 4 | Small Phase II | n₁ = 50 |
| 5 | Large Phase II | n₁ = 200 |
| 6 | Delayed effect | HR=1 for 0-4mo, then HR=0.6 (PH violation) |
| 7 | Diminishing effect | HR=0.5 for 0-6mo, then HR=0.9 (PH violation) |
| 8 | Informative censoring | Censoring depends on tumor volume |
| 9 | Small external data | n_ext = 200 |
| 10 | High-dimensional | p = 100, 8 true signals |
| 11 | Null case | β_trt = 0 (Type I error) |

## Comparison Methods

1. Cox-Standard — pre-specified covariates
2. Stratified Log-Rank — baseline comparison
3. PROCOVA (Ext Score) — external score, no calibration
4. Cox-Calibrated — proposed primary analysis
5. AIPW-Calibrated — doubly-robust sensitivity
6. TMLE-Calibrated — proposed efficient analysis
7. RMST-Calibrated — restricted mean survival time
8. MAP-Cox — Bayesian dynamic borrowing
