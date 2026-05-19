---
title: "From Concept to Submission in 8 Hours"
subtitle: "An Agentic Research Workflow"
author: "Yue Shentu"
date: "May 18, 2026"
header-includes:
  - \usepackage{tikz}
---

# The Tech Stack Journey

## Building the Infrastructure

- **OpenClaw setup:** Configured an AI agent as my research assistant, connected via Telegram
- **Local models (LM Studio):** Tool calling was unreliable --- had to pivot
- **DeepSeek API:** The breakthrough --- cheap (~\$0.15/M input), fast, reliable
- **Qwen via Ollama:** Second model for cross-checking (different architecture)
- **Whisper:** Speech-to-text for dictating ideas while pacing the kitchen
- **Dependencies:** R + glmnet/furrr, Python + matplotlib/whisper, Pandoc + LaTeX

**Lesson:** Start with the API that works, optimize later.

# The Problem

## PROCOVA's Blind Spot

- **PROCOVA** is EMA-qualified for improving trial efficiency via prognostic scores
- But it assumes the **external score is perfectly calibrated** for the trial population
- **Population shift** is the rule, not the exception --- especially in oncology
- **No existing method** diagnoses or corrects miscalibration using blinded trial data

# The Idea

## Ridge-Cal

Treat the external score as a **pre-trained model** and apply a **regularized correction** on blinded data:

- **Diagnose:** Compare C-index of score alone vs. score + calibration covariates
- **Calibrate:** Ridge-penalized Cox regression on blinded data, $\lambda$ by CV
- **Analyze:** Standard Cox PH with calibrated score + robust sandwich SE

6 parameters, blinded data, no additional data collection needed.

# The Timeline

## May 17--18, 2026

\small
| Time | Milestone |
|:---:|:----------|
| ~21:00 | Concept brainstorm (TMLE + Bayesian MCMC --- too complex, scrapped) |
| ~22:00 | Pivot to ridge regression on 5 covariates |
| ~23:00 | First simulation --- agent found a bug (non-PH assumption) |
| ~00:00 | 10K-rep simulation running in background |
| ~01:00 | MAP-Cox bug surfaced (k applied after pooling) |
| ~02:00 | Bug fixed, re-simulation triggered |

# The Timeline (cont.)

| Time | Milestone |
|:---:|:----------|
| ~06:00 | Manuscript drafted --- agent wrote prose, I reviewed every section |
| ~07:00 | Sent to Gemini --- Major Revision, 4 issues |
| ~08:00 | Sent to Qwen for independent review --- 7 MORE issues |
| ~09:00 | Digital twin landscape report drafted |
| ~10:00 | JBS formatting, self-verify, corrections |
| ~14:00 | Voice note $\rightarrow$ small strata investigation |
| ~15:00 | Workflow codified into reusable skill |
\normalsize

# Deliverables

## What Came Out of It

| Deliverable | Format | Audience |
|:------------|:------|:---------|
| Ridge-Cal manuscript | PDF, 12 pages | JBS submission |
| Response to Reviewer 2 | Markdown | Journal |
| Digital twin survey | PDF, 12 pages | BLT (BARDS Leadership Team) |
| Small strata white paper | Markdown | Internal stat leads |
| Research Workflow skill | SKILL.md | Future projects |
| Simulation code | GitHub (public) | Reproducibility |

# Multi-Model Review

## Why Not One AI?

Same-model reviewers share the same **blind spots**.

\vspace{0.5em}

**Internal Loop (my agent, ~\$0.15/M tokens)**

- Primary: DeepSeek v4 Flash \quad | \quad Reviewer: Qwen
- Caught: Section 4 redundancy, $\delta$ justification, missing data, table headers

\vspace{0.5em}

**External Loop (separate company)**

- Gemini Pro --- completely different training
- Caught: Non-collapsibility, tone, event rates, LoRA framing

# The Convergence

## Review Results

| Round | Reviewer | Verdict | Issues |
|:-----|:---------|:-------|:------:|
| 1 | Gemini | Major Revision | 4 |
| 2 | Gemini | **Accept** | -- |
| 3 | Qwen | Major Revision | **7 (different)** |
| 4 | Qwen | Minor Revision | -- |
| 5 | Qwen | **Accept** | -- |

**Qwen caught things Gemini missed:** redundancy, $\delta$ justification, table headers, MAP-Cox framing, sandwich variance scope, missing data, references.

**Takeaway:** Model-diverse review converges faster than any single reviewer.

# Demo: Voice Note $\rightarrow$ Paper

## 10 Minutes Start to Finish

**Input:** Voice note while pacing the kitchen (Whisper transcription)

> "Do we need to pool small strata for CMH and MN methods?"

| Step | Time | How |
|:----|:----:|:-----|
| Transcription | < 1 min | Whisper |
| Problem scoping | 1 min | I dictated, agent structured |
| Independent review | 1 min | Qwen caught framing weakness |
| Revision | 1 min | I directed, agent refined |
| Code + simulation | 3 min | Agent drafted code, 5K reps |
| Code review v1 | 1 min | Qwen caught 3 bugs |
| Code review v2 | 1 min | Verified fixes |
| Final + push | 1 min | White paper to GitHub |

# Code Reviews

## Three Rounds

| Review | Verdict | What It Caught |
|:-------|:--------|:---------------|
| v1 | Minor Issues | Scenario 4 duplicated, CMH RR variance unstratified, Wald mislabeled as MN |
| v2 | Minor Issues | Scenario 4 label misleading, MN SE approximation |
| Final | Pass | Verified against bootstrap empirical variance |

All bugs fixed before delivery.

# The Workflow: Phases

## Research Skill File

| Phase | Description |
|:------|:------------|
| **Ph 0: Topic ID** | Identify gap, map contradictory literature |
| **Ph 1: Writeup** | Write, spawn isolated reviewer, iterate |
| **Ph 2: Simulate** | 2 $\rightarrow$ 20 $\rightarrow$ 200 $\rightarrow$ 10K reps |
| **Ph 3: QC** | **Code review before big runs --- mandatory** |
| **Ph 4: Full Run** | Background, scheduled, monitored |
| **Ph 4.5: Audit** | Verify code matches manuscript claims |
| **Ph 5: Manuscript** | Write, verify refs, PDF self-check |
| **Ph 6: Revision** | Parse $\rightarrow$ Reconcile $\rightarrow$ Re-sim |
| **Ph 7: Submit** | Reviewer $\rightarrow$ Revise $\rightarrow$ Max 3 |

# The Workflow: Rules

## Key Lessons Codified

1. **Isolate reviewers** --- fresh sessions, no cross-contamination
2. **Diversify models** --- different AIs catch different bugs
3. **Code review BEFORE big simulations** --- trust but verify
4. **PDF self-verify** --- automated checks before reaching humans
5. **Clean up cruft** --- stale files cause confusion
6. **Push to GitHub at milestones** --- enables external review
7. **Batch deliveries** --- pace yourself

# What Worked Well

## Results

- **Independent AI reviewers caught 11 bugs** before human eyes saw the draft
- **Small tests before big runs** --- avoided ~5 dead ends
- **Human-in-the-loop essential** --- I directed 8 reframing cycles
- **The agent amplified my judgment, did not replace it**

# What I'd Do Differently

## Lessons Learned

- **PDF generation was painful** --- 5 failed attempts with silent image failures. Now has a verification script.
- **Code review almost skipped** --- hard checkpoint now in the pipeline.
- **Stale artifacts accumulated** --- explicit cleanup at every milestone now.

# AI-Human Collaboration Lessons

## How We Work Better Together (1/2)

- **Use sub-agents for heavy computation.** Long simulations (10K+ reps) should run in sub-agents so the AI stays available for discussion. The human should never ask "are you still there?" more than once.

- **Discuss before running big simulations.** A 100-rep test costs seconds; a mis-specified 10K run costs 20 minutes. Check the design with the human first -- they catch what no textbook will tell you.

- **Real-world context beats defaults.** Real oncology trials use 2-look OBF at 70\% IA, not 3-look at 33\%. The human's experience caught this immediately.

## How We Work Better Together (2/2)

- **Listen when something looks wrong.** Every time the human said "that doesn't look right," there was a real bug. Running more simulations doesn't fix a wrong design.

- **Close the loop before scaling up.** Present findings to the human before each big decision. Let their judgment guide the next direction.

# The Bottom Line

## Economics

- **Session cost:** ~500K DeepSeek tokens, **well under \$1.00**
- **That bought:** 1 manuscript, 1 BLT report, 1 white paper, 1 reusable skill, 3 AI reviews from 2 models, 3 GitHub repos
- **Key insight:** The agent replaces the drafting lag, not the statistician

# Questions?

\centering
\Large Thank You

\vspace{1em}
\normalsize
\raggedright
**Repos:**
- \texttt{github.com/doublerobust/ridge-cal}
- \texttt{github.com/doublerobust/small-strata-pooling}

**The skill:** SKILL.md in my OpenClaw workspace --- available on request.
