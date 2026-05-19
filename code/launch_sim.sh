#!/bin/bash
# launch_sim.sh — Launches the Ridge-Cal simulation and detaches it
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
cd /home/yue-shentu/.openclaw/workspace/research-proposals/simulation
exec setsid Rscript run_clean.R > ridgecal_sim.log 2>&1
