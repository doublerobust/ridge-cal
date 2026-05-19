# Ridge-Cal: Covariate Calibration via Ridge-Regularized Cox Regression

**Author:** Yue Shentu  
**Repository:** github.com/doublerobust/ridge-cal

## Structure

```
ridge-cal/
├── README.md
├── talk-slides.md / .pdf / .html          # Presentation
├── response-to-reviewer.md                # Journal rebuttal
├── code/                                  # All code
│   ├── run_clean.R                       # Master simulation
│   ├── R/                                # R analysis code
│   ├── scripts/report.R                  # Results reporting
│   ├── generate_figures.py               # Figure generation
│   ├── generate_slides.py                # Slide generator
│   ├── verify_pdf.py                     # PDF verification
│   ├── simulation-plan.md                # Simulation specification
│   ├── setup/                            # Environment setup
│   └── output/                           # Simulation results
├── figures/                              # Generated figures
├── audit/                                # Independent reviews
│   ├── code-audit-report.md
│   ├── cross-file-audit.md
│   └── qwen-review.md (v1-v3)
└── extensions/                           # Related work
    ├── nn-cal-extension-plan.md          # Neural network extension
    ├── digital-twin-landscape-survey.md/pdf
    └── probabilistic-digital-twin-trial.md/pdf
```

## Reproducing

```bash
# Setup
conda env create -f code/setup/environment.yml

# Full simulation
Rscript code/run_clean.R

# Figures
python code/generate_figures.py

# Slides
python code/generate_slides.py
```
