#!/bin/bash
# Fully detached launcher for Ridge-Cal full simulation
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
cd /home/yue-shentu/.openclaw/workspace/research-proposals/simulation
rm -f full_sim_20260517.log
nohup Rscript run_clean.R > ridgecal_sim.log 2>&1 &
echo $! > /tmp/ridgecal_sim.pid
echo "Launched Ridge-Cal 10K sim with PID $(cat /tmp/ridgecal_sim.pid) -> ridgecal_sim.log"
