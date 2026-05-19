# ============================================================
# setup_windows.ps1 -- Windows setup for Ridge-Cal Simulation
# ============================================================
# Run from PowerShell (as Admin recommended for conda install):
#   cd research-proposals
#   powershell -ExecutionPolicy Bypass -File setup/setup_windows.ps1
# ============================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Ridge-Cal Simulation -- Windows Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# --- Step 1: Check for R ---
$Rpath = Get-Command "R" -ErrorAction SilentlyContinue
if ($Rpath) {
    Write-Host "R found at: $($Rpath.Source)" -ForegroundColor Green
    $Rversion = & R --version | Select-String "version"
    Write-Host "   R $Rversion"
} else {
    Write-Host "R not found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option A: Install R from https://cran.r-project.org/bin/windows/base/" -ForegroundColor Cyan
    Write-Host "Option B: Install conda + R environment (recommended)" -ForegroundColor Cyan
    Write-Host ""

    $choice = Read-Host "Install conda environment? (y/n)"
    if ($choice -eq "y") {
        # --- Install Miniforge ---
        Write-Host "Downloading Miniforge..." -ForegroundColor Cyan
        $url = "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe"
        $out = "$env:TEMP\Miniforge3.exe"
        Invoke-WebRequest -Uri $url -OutFile $out

        Write-Host "Installing Miniforge..." -ForegroundColor Cyan
        Start-Process -Wait -FilePath $out -ArgumentList "/InstallationType=JustMe", "/AddToPath=0", "/S", "/D=$env:USERPROFILE\miniforge3"
        $env:Path = "$env:USERPROFILE\miniforge3\Scripts;$env:Path"

        Write-Host "Creating conda environment..." -ForegroundColor Cyan
        conda env create -f setup/environment.yml -n ridgecal-sim

        Write-Host "Conda environment 'ridgecal-sim' created." -ForegroundColor Green
        Write-Host "   Activate with: conda activate ridgecal-sim"
    } else {
        Write-Host "Please install R manually, then re-run this script." -ForegroundColor Yellow
        exit 1
    }
}

# --- Step 2: Install R packages (standalone R only; conda handles this) ---
if ($Rpath) {
    Write-Host "Installing R packages..." -ForegroundColor Cyan
    & Rscript -e "
        packages <- c(
            'survival', 'glmnet',
            'furrr', 'future', 'future.apply',
            'withr', 'yaml', 'here', 'renv',
            'tidyverse', 'data.table',
            'knitr', 'rmarkdown'
        )
        for (pkg in packages) {
            if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
                cat(sprintf('Installing %s...\n', pkg))
                install.packages(pkg, repos = 'https://cloud.r-project.org')
            } else {
                cat(sprintf('  %s OK\n', pkg))
            }
        }
    "
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Windows setup complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run the simulation:"
Write-Host "   cd simulation"
Write-Host "   Rscript run_clean.R"
