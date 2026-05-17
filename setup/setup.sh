#!/usr/bin/env bash
# ============================================================
# setup.sh — Linux/macOS setup for Phase II Calibration Simulation
# ============================================================
# Run from the research-proposals/ directory:
#   cd research-proposals
#   bash setup/setup.sh
#
# This script installs R (via Homebrew or conda) and all required
# R packages. If brew is not found, falls back to conda.
# ============================================================
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"
echo "📁 Working directory: $DIR"

# --- Detect platform ---
OS="$(uname -s)"
echo "🖥️  Detected OS: $OS"

# --- Step 1: Ensure R is available ---
install_r_via_brew() {
    echo "📦 Installing R via Homebrew..."
    brew install r
}

install_r_via_conda() {
    echo "📦 Installing R via conda..."
    if ! command -v conda &>/dev/null; then
        echo "⬇️  Installing Miniforge..."
        curl -L -o /tmp/miniforge.sh \
            "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
        bash /tmp/miniforge.sh -b -p "$HOME/miniforge3"
        export PATH="$HOME/miniforge3/bin:$PATH"
    fi
    conda env create -f setup/environment.yml -n ph2cal-sim
    echo "✅ Conda environment 'ph2cal-sim' created."
    echo "   Activate with: conda activate ph2cal-sim"
}

if command -v R &>/dev/null; then
    echo "✅ R $(R --version | head -1 | grep -oP '[\d]+\.[\d]+\.[\d]+') already installed."
elif command -v brew &>/dev/null; then
    install_r_via_brew
else
    echo "⚠️  No Homebrew found. Falling back to conda."
    install_r_via_conda
    # If using conda, we're done (packages included in environment.yml)
    echo "✅ Setup complete via conda."
    exit 0
fi

# --- Step 2: Install R packages (brew path) ---
# Check if renv is available; if so, let renv handle it.
if [ -f renv.lock ]; then
    echo "📦 Using renv to restore packages from lockfile..."
    Rscript -e 'if (!require("renv")) install.packages("renv", repos="https://cloud.r-project.org"); renv::restore()'
else
    echo "📦 Installing R packages..."
    Rscript -e '
        packages <- c(
            "survival", "glmnet", "ranger", "xgboost",
            "SuperLearner", "origami",
            "rstan", "StanHeaders", "loo",
            "riskRegression", "prodlim",
            "furrr", "future", "future.apply",
            "targets", "withr", "yaml", "here", "renv",
            "tidyverse", "data.table",
            "knitr", "rmarkdown", "tinylabels"
        )
        for (pkg in packages) {
            if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
                cat(sprintf("Installing %s...\n", pkg))
                install.packages(pkg, repos = "https://cloud.r-project.org")
            } else {
                cat(sprintf("  %s ✓\n", pkg))
            }
        }
    '
fi

# --- Step 3: Create renv lockfile for future reproducibility ---
echo "🔒 Creating renv lockfile..."
Rscript -e '
    if (!require("renv")) install.packages("renv", repos="https://cloud.r-project.org")
    renv::init(bare = TRUE)
    renv::snapshot(type = "all", confirm = FALSE)
'

echo ""
echo "============================================"
echo "✅ Setup complete!"
echo "   R packages installed: $(Rscript -e 'cat(length(installed.packages()[,1]))')"
echo "============================================"
echo ""
echo "👉 To run the simulation:"
echo "   cd simulation"
echo "   Rscript run_all.R"
echo ""
echo "👉 To run individual scenarios:"
echo "   Rscript scripts/run_scenario.R --scenario 1 --n_sim 100"
