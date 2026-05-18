# Ridge-Cal: Regularized Calibration of External Prognostic Scores

**Author:** Yue Shentu  
**Status:** Submission-ready for Journal of Biopharmaceutical Statistics  
**Date:** May 2026

---

## Overview

Ridge-Cal is a two-step procedure that (1) diagnoses miscalibration of external prognostic scores by comparing predictive accuracy of the score alone versus the score plus calibration covariates, and (2) recalibrates the score via ridge-penalized Cox regression on the trial's blinded data. The ridge penalty is selected automatically by cross-validation within the trial.

## Key Results

- Under severe population shift: recovers **+7.5 pp** power over PROCOVA (0.758 → 0.833)
- Reduces bias by **80%** (0.035 → 0.007)
- Nominal Type I error (0.052)
- No-shift penalty: minimal (−0.8 pp)
- 10,000 reps × 7 scenarios + MAP-Cox sensitivity

## Repository Contents

| File | Description |
|------|-------------|
| `probabilistic-digital-twin-trial.md` | Full manuscript (markdown) |
| `manuscript.pdf` | Compiled PDF (JBS-formatted) |
| `response-to-reviewer.md` | Point-by-point rebuttal |
| `simulation-plan.md` | Simulation study design |
| `simulation/` | Complete R simulation code |
| `simulation/run_clean.R` | 10K × 7 scenario runner |
| `simulation/run_standalone.R` | Interactive runner with MAP-Cox |
| `simulation/R/` | Analysis methods, data generation, training |
| `figures/` | Professional diagrams for digital twin report |
| `digital-twin-landscape-survey.md` | Digital twin landscape report |
| `nn-cal-extension-plan.md` | Neural network calibration extension |
| `code-audit-report.md` | Independent code audit |
| `cross-file-audit.md` | Cross-file consistency check |
| `qwen-review.md` | Independent AI review (Qwen) |
| `talk-slides.md` | Presentation slides |

## Methods Compared

- **Cox-2:** Cox PH with 2 stratification variables
- **Full Model:** Cox PH with all 20 covariates (theoretical upper bound)
- **Log-Rank:** Stratified log-rank test
- **PROCOVA:** External prognostic score as sole covariate
- **Ridge-Cal (proposed):** Ridge-penalized calibration on blinded data
- **MAP-Cox:** Precision-weighted Bayesian borrowing (sensitivity)

## Simulation Scenarios (10,000 reps each)

1. No shift (null calibration)
2. Moderate population shift
3. Severe population shift
4. Treatment-by-covariate interaction
5. Null treatment effect (Type I error)
6. Non-proportional hazards
7. Smaller treatment effect (HR = 0.75)

## Key Features

- Works with any black-box prognostic score
- Uses only **blinded trial data** — no unblinding
- Automatic regularization via cross-validation
- Pre-specified calibration covariates (SAP-friendly)
- Robust sandwich variance — valid Type I error

## Dependencies

- R ≥ 4.0
- survival, glmnet, furrr, future

## Reproducing Results

```bash
cd simulation
export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH
Rscript run_clean.R     # 10K × 7 scenarios (~27 min)
Rscript run_standalone.R  # Interactive with MAP-Cox (~35 min)
```

## Acknowledgments

This work was conducted as part of the author's role in biostatistical methodology development at Merck & Co., Inc.

## References

Schuler A, et al. (2022). Increasing the efficiency of randomized trial estimates via linear adjustment for a prognostic score. *Int J Biostatistics* 18(2):329-356.

EMA (2022). Qualification opinion for PROCOVA. EMA/CHMP/656613/2022.
