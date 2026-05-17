# ============================================================
# setup_windows.ps1 — Windows setup for Phase II Calibration Sim
# ============================================================
# Run from PowerShell (as Admin recommended for conda install):
#   cd research-proposals
#   powershell -ExecutionPolicy Bypass -File setup/setup_windows.ps1
# ============================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Phase II Calibration Simulation — Windows Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# --- Step 1: Check for R ---
$Rpath = Get-Command "R" -ErrorAction SilentlyContinue
if ($Rpath) {
    Write-Host "✅ R found at: $($Rpath.Source)" -ForegroundColor Green
    $Rversion = & R --version | Select-String "version"
    Write-Host "   R $Rversion"
} else {
    Write-Host "❌ R not found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option A: Install R from https://cran.r-project.org/bin/windows/base/" -ForegroundColor Cyan
    Write-Host "Option B: Install conda + R environment (recommended for GPU support)" -ForegroundColor Cyan
    Write-Host ""

    $choice = Read-Host "Install conda environment? (y/n)"
    if ($choice -eq "y") {
        # --- Install Miniforge ---
        Write-Host "⬇️  Downloading Miniforge..." -ForegroundColor Cyan
        $url = "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe"
        $out = "$env:TEMP\Miniforge3.exe"
        Invoke-WebRequest -Uri $url -OutFile $out

        Write-Host "📦 Installing Miniforge..." -ForegroundColor Cyan
        Start-Process -Wait -FilePath $out -ArgumentList "/InstallationType=JustMe", "/AddToPath=0", "/S", "/D=$env:USERPROFILE\miniforge3"
        $env:Path = "$env:USERPROFILE\miniforge3\Scripts;$env:Path"

        Write-Host "📦 Creating conda environment..." -ForegroundColor Cyan
        conda env create -f setup/environment.yml -n ph2cal-sim

        Write-Host "✅ Conda environment 'ph2cal-sim' created." -ForegroundColor Green
        Write-Host "   Activate with: conda activate ph2cal-sim"
    } else {
        Write-Host "Please install R manually, then re-run this script." -ForegroundColor Yellow
        exit 1
    }
}

# --- Step 2: Install R packages (standalone R only; conda handles this) ---
if ($Rpath) {
    Write-Host "📦 Installing R packages..." -ForegroundColor Cyan
    & Rscript -e "
        packages <- c(
            'survival', 'glmnet', 'ranger', 'xgboost',
            'SuperLearner', 'origami',
            'rstan', 'StanHeaders', 'loo',
            'riskRegression', 'prodlim',
            'furrr', 'future', 'future.apply',
            'targets', 'withr', 'yaml', 'here', 'renv',
            'tidyverse', 'data.table',
            'knitr', 'rmarkdown', 'tinylabels'
        )
        for (pkg in packages) {
            if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
                cat(sprintf('Installing %s...\n', pkg))
                install.packages(pkg, repos = 'https://cloud.r-project.org')
            } else {
                cat(sprintf('  %s ✓\n', pkg))
            }
        }
    "
}

# --- Step 3: GPU check ---
Write-Host ""
Write-Host "🔍 Checking for NVIDIA GPU..." -ForegroundColor Cyan
$nvidia = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
if ($nvidia) {
    & nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    Write-Host "✅ NVIDIA GPU detected. JAX/NumPyro will use GPU automatically." -ForegroundColor Green
    Write-Host "   (Requires CUDA toolkit: conda install -c conda-forge cudatoolkit=11.8)" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  No NVIDIA driver detected. Simulations will run on CPU." -ForegroundColor Yellow
    Write-Host "   This is fine — the simulation is CPU-bound for R-based methods." -ForegroundColor Yellow
    Write-Host "   To use GPU for NumPyro calibration: install CUDA toolkit + NVIDIA driver." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "✅ Windows setup complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "👉 To run the simulation:"
Write-Host "   cd simulation"
Write-Host "   Rscript run_all.R"
