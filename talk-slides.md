---
title: "From Concept to Submission in 8 Hours: An Agentic Research Workflow"
subtitle: "Ridge-Cal, Digital Twins, and the Birth of a Statistical Research Skill"
author: "Yue Shentu"
date: "May 18, 2026"
---

# The Spark

## The Problem That Started It All

- **PROCOVA** is EMA-qualified for improving trial efficiency via prognostic scores
- But it assumes the **external score is perfectly calibrated** for the trial population
- **Population shift** is the rule, not the exception — especially in oncology
- **No existing method** diagnoses or corrects miscalibration using blinded trial data

**The question:** Can we fine-tune a prognostic score using only the trial's own blinded data?

## The Ridge-Cal Idea

Simple insight: treat the external score as a **pre-trained model** and apply a **regularized correction** on blinded data:

1. **Diagnose:** Compare C-index of score alone vs. score + calibration covariates
2. **Calibrate:** Ridge-penalized Cox regression on blinded data, λ selected by CV
3. **Analyze:** Standard Cox PH with calibrated score + robust sandwich SE

6 parameters, blinded data, no additional data collection needed.

---

# The 8-Hour Journey

## Timeline: May 17-18, 2026

| Time | Milestone |
|:---:|:----------|
| ~21:00 | Initial concept: TMLE + Bayesian MCMC (too complex) |
| ~22:00 | Pivot to ridge regression on 5 covariates |
| ~23:00 | First simulation — bug found (non-PH wrong) |
| ~00:00 | 10K-rep simulation running |
| ~01:00 | MAP-Cox bug found (k applied after pooling) |
| ~06:00 | Manuscript drafted, code audit done |
| ~07:00 | Reviewer 2 (Gemini): Major Revision → 7 point fixes |
| ~08:00 | Revised, Qwen review: Major → Minor → Accept |
| ~09:00 | Digital twin landscape report for SVPs |
| ~10:00 | JBS formatting, Times New Roman, all checks |
| ~14:00 | Small strata investigation: voice note → white paper |
| ~15:00 | Skill refined, presentation ready |

## What Actually Got Built

\small
| Deliverable | Format | Audience |
|:------------|:------|:---------|
| Ridge-Cal manuscript | PDF, 12 pages | JBS submission |
| Response to Reviewer 2 | Markdown | Journal |
| Digital twin landscape survey | PDF, 12 pages, 3 diagrams | Merck SVPs |
| Small strata white paper | Markdown | Internal stat leads |
| Research workflow skill | SKILL.md | Future projects |
| Code + simulations | GitHub (public) | Reproducibility |
\normalsize

---

# The Multi-Model Review Loop

## Why One AI Isn't Enough

Same-model reviewers share the same **blind spots** and **hallucination patterns**.

**Our solution:** Two-loop review with different model architectures.

\pause

### Loop 1: Internal (OpenClaw)
- **Writer:** DeepSeek v4 Flash
- **Reviewer:** Qwen (different architecture, different training)
- **Cost:** Internal to platform, essentially free
- **Caught:** Section 4 redundancy, δ justification, missing data, table headers

### Loop 2: External (Gemini Pro)
- **Reviewer:** Gemini Pro (completely separate AI, separate company)
- **Cost:** Free tier / pasted manuscript
- **Caught:** Non-collapsibility, tone, event rates, LoRA framing

## The Convergence

\centering
\small
| Round | Reviewer | Verdict | Issues Found |
|:-----|:---------|:-------|:-------------|
| 1 | Gemini | Major Revision | 4 |
| 2 | Gemini | **Accept** | — |
| 3 | Qwen | Major Revision | 7 (different!)* |
| 4 | Qwen | Minor Revision | — |
| 5 | Qwen | **Accept** | — |
\normalsize

\raggedright
\small *Qwen caught issues Gemini missed: Section 4 redundancy, δ justification, table header ambiguity, MAP-Cox framing, sandwich variance scope, missing data, reference formatting.

---

# The Demo: Voice Note → White Paper

## The Workflow in 10 Minutes

**Input:** Voice note pacing in the kitchen (transcribed by Whisper)

> "Do we need to pool small strata for CMH and MN methods?"

**Output:** White paper with simulation results, proposed SAP language, and mathematical appendix

## What Happened

| Step | Time | Tool |
|:----|:----:|:-----|
| Voice transcription | < 1 min | Whisper (tiny model) |
| Problem scoping | 1 min | Phase 0 proposal |
| Independent review | 1 min | Qwen (isolated) |
| Revision | 1 min | Refine scope |
| Code + simulation | 3 min | R, 5K reps |
| Code review v1 | 1 min | Caught 3 bugs |
| Code review v2 | 1 min | Verified fixes |
| Final review | 1 min | White paper + code |
| Push to GitHub | < 1 min | Public repo |
| **Total** | **~10 min** | |

## The Three Code Reviews

\small
| Review | Verdict | What It Caught |
|:-------|:--------|:---------------|
| v1 | Minor Issues | Scenario 4 duplicated, CMH RR variance unstratified, Wald mislabeled as MN |
| v2 | Minor Issues | Scenario 4 label misleading, MN SE approximation (acknowledged) |
| Final | Pass | Verified against bootstrap empirical variance |
\normalsize

All bugs fixed before delivery. **Never trust your own code without independent review.**

---

# The Emergent Workflow

## The Skill File (SKILL.md)

A complete pipeline from concept to submission:

### Phase 0: Topic ID
Identify gap, map literature, define "before" and "after"

### Phase 1: Initial Writeup
Write proposal → spawn isolated reviewer → iterate

### Phase 2: Simulation
Test (2 reps) → Validate (20 reps) → Confirm (200 reps) → Full (10K reps)

### Phase 3: Multi-Agent QC
**Code review before big simulations — DO NOT SKIP**

### Phase 4: Full Run
Background, cron scheduling, monitoring

### Phase 4.5: Reproducibility Audit
Does the code match the manuscript?

### Phase 5: Manuscript
Write, verify references, PDF self-check, senior review

### Phase 6: Revision
Critique Parser → Math Reconciliation → Re-Simulation → Diff Check

### Phase 7: Pre-Submission Loop
Independent reviewer → Revise → Loop (max 3) until Accept

## Key Rules That Emerged

1. **Isolate reviewers** — `context="isolated"`, no discussion history
2. **Diversify models** — Different AIs catch different bugs
3. **PDF self-verify** — Programmatic checks before sending to human
4. **Clean up cruft** — Every iteration leaves stale code/language
5. **Push at milestones** — GitHub for external review access
6. **Batch deliveries** — Don't send incremental fixes, pace yourself

---

# Key Lessons

## What Went Right

- **Independent reviewers caught more bugs than expected** — 3 citation errors, 1 broken method, 1 non-collapsibility issue, and several framing weaknesses
- **Small tests before big runs** — ~5 dead ends avoided
- **Human-in-the-loop** — 8 reframing cycles, each improved the method
- **LoRA analogy won** — Both AI and human reviewers found it helpful

## What Went Wrong

- **PDF verification was a disaster** — 5 failed attempts before getting it right. Images silently failed (RGBA→RGB, code block markers, missing paths). **Now has a verification script.**
- **Code review was skipped initially** — Would have delivered buggy results. **Now has a "🚨 DO NOT SKIP" in the skill.**
- **Fast iteration exhausted the human** — I was sending too many incremental fixes. **Now batching is built into the workflow.**
- **Stale artifacts accumulated** — Old PDFs, old labels, old comments. **Now has explicit cleanup at every milestone.**

---

# Q&A

## Thank You

\centering
\Huge Questions?
\normalsize

\vfill

**Repos:**
- Ridge-Cal: `github.com/doublerobust/ridge-cal`
- Small strata: `github.com/doublerobust/small-strata-pooling`

**The skill:** Lives in my OpenClaw workspace — can be shared.
