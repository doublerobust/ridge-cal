---
title: "From Concept to Submission in 8 Hours: An Agentic Research Workflow"
subtitle: "Ridge-Cal, Digital Twins, and the Birth of a Statistical Research Skill"
author: "Yue Shentu"
date: "May 18, 2026"
logo: merck
---

# The Tech Stack Journey

## Building the Infrastructure Before the Research Could Start

- **OpenClaw setup:** I configured an AI agent (code-named "Natasha") as my research assistant, connected via Telegram
- **Local models (LM Studio):** I tried running local LLMs first, but tool calling was unreliable — models would understand my requests but fail to execute tool calls consistently
- **DeepSeek API:** The breakthrough. At ~$0.15/M input tokens, cheap enough that I could let the agent work freely
- **Qwen via Ollama:** I added a second model with a different architecture so the agent could cross-check work — different AIs catch different bugs
- **Whisper:** I added speech-to-text so I could dictate research ideas while pacing around the kitchen
- **Dependencies:** R + glmnet/furrr, Python + matplotlib/whisper, pandoc + LaTeX

**Key lesson:** Start with the API that works, optimize later.

---

# The Spark

## The Problem That Started It All

- **PROCOVA** is EMA-qualified for improving trial efficiency via prognostic scores
- But it assumes the **external score is perfectly calibrated** for the trial population
- **Population shift** is the rule, not the exception — especially in oncology
- **No existing method** diagnoses or corrects miscalibration using blinded trial data

**The question:** Can we fine-tune a prognostic score using only the trial's own blinded data?

## The Ridge-Cal Idea

A simple insight I had: treat the external score as a **pre-trained model** and apply a **regularized correction** on blinded data:

1. **Diagnose:** Compare C-index of score alone vs. score + calibration covariates
2. **Calibrate:** Ridge-penalized Cox regression on blinded data, λ selected by CV
3. **Analyze:** Standard Cox PH with calibrated score + robust sandwich SE

6 parameters, blinded data, no additional data collection needed.

---

# The 8-Hour Journey

## Timeline: May 17-18, 2026

| Time | Milestone |
|:---:|:----------|
| ~21:00 | Initial concept brainstorm: TMLE + Bayesian MCMC (too complex — scrapped) |
| ~22:00 | Pivot to ridge regression on 5 covariates |
| ~23:00 | First simulation — agent found a bug (non-PH assumption violated) |
| ~00:00 | 10K-rep simulation running in background |
| ~01:00 | MAP-Cox bug surfaced by agent (k applied after pooling instead of before) |
| ~02:00 | Bug fixed, re-simulation triggered |
| ~06:00 | Manuscript drafted (agent wrote the prose; I reviewed and revised every section) |
| ~07:00 | I sent the draft to Gemini (Reviewer 2) — came back Major Revision, 4 issues |
| ~07:15 | Agent fixed all 4 issues per my instructions |
| ~08:00 | I sent the revised draft to Qwen for a second independent review — another 7 issues surfaced |
| ~09:00 | Digital twin landscape report drafted (agent's first pass, my edits) |
| ~10:00 | JBS formatting, self-verify, corrections |
| ~14:00 | Voice note while pacing the kitchen → small strata investigation |
| ~15:00 | Workflow codified into a reusable skill file |

## What Came Out of It

\small
| Deliverable | Format | Audience |
|:------------|:------|:---------|
| Ridge-Cal manuscript | PDF, 12 pages | JBS submission |
| Response to Reviewer 2 | Markdown | Journal |
| Digital twin landscape survey | PDF, 12 pages, 3 diagrams | BARDS leadership |
| Small strata white paper | Markdown | Internal stat leads |
| Research workflow skill | SKILL.md | Future projects |
| Code + simulations | GitHub (public) | Reproducibility |
\normalsize

---

# The Multi-Model Review Loop

## Why One AI Isn't Enough

Same-model reviewers share the same **blind spots** and **hallucination patterns**.

**My solution:** Cross-review with two different AI architectures.

### Loop 1: Internal (my OpenClaw agent)
- **Primary work:** DeepSeek v4 Flash (cost-effective, reliable tool calling)
- **Independent reviewer:** Qwen (different architecture, different training blind spots)
- **Cost:** ~$0.15/M tokens — pennies per review cycle
- **Caught:** Section 4 redundancy, δ justification, missing data section, table header clarity

### Loop 2: External (Google Gemini Pro)
- **Reviewer:** Completely separate AI, separate company, zero shared training
- **Cost:** Free tier — I just pasted the manuscript
- **Caught:** Non-collapsibility, tone issues, event rate concerns, LoRA framing

## The Convergence

\centering
\small
| Round | Reviewer | Verdict | Issues Found |
|:-----|:---------|:-------|:-------------|
| 1 | Gemini | Major Revision | 4 |
| 2 | Gemini | **Accept** | — |
| 3 | Qwen | Major Revision | 7 (different set!) |
| 4 | Qwen | Minor Revision | — |
| 5 | Qwen | **Accept** | — |
\normalsize

\raggedright
\small *Qwen caught things Gemini missed: Section 4 redundancy, δ justification, table header ambiguity, MAP-Cox framing, sandwich variance scope, missing data section, reference formatting.

**Takeaway:** Two independent AI reviewers converged faster and more thoroughly than any single reviewer could have.

---

# The Demo: Voice Note → White Paper

## The Workflow in 10 Minutes

**Input:** A voice note I recorded while pacing in the kitchen (transcribed by Whisper)

> "Do we need to pool small strata for CMH and MN methods?"

**Output:** A white paper with simulation results, proposed SAP language, and a mathematical appendix

## What Happened

| Step | Time | How |
|:----|:----:|:----|
| Voice note → text | < 1 min | Whisper (tiny model, local) |
| Problem scoping | 1 min | I dictated the question, agent structured it into a Phase 0 proposal |
| Independent review | 1 min | I had the agent spawn an isolated Qwen session to review the proposal |
| Revision | 1 min | I directed the fix, agent refined the scope |
| Code + simulation | 3 min | Agent drafted R code based on my specs; I reviewed; agent ran 5K reps |
| Code review v1 | 1 min | Qwen caught 3 bugs — Scenario 4 duplicated, RR variance, Wald vs MN label |
| Code review v2 | 1 min | Agent verified fixes, I confirmed |
| Final review | 1 min | White paper compiled, pushed to GitHub |
| **Total** | **~10 min** | **From an idle thought to a polished, peer-reviewed white paper** |

## The Three Code Reviews

\small
| Review | Verdict | What It Caught |
|:-------|:--------|:---------------|
| v1 | Minor Issues | Scenario 4 duplicated, CMH RR variance unstratified, Wald mislabeled as MN |
| v2 | Minor Issues | Scenario 4 label misleading, MN SE approximation (acknowledged) |
| Final | Pass | Verified against bootstrap empirical variance |
\normalsize

---

# The Emergent Workflow

## The Skill File (SKILL.md)

By the end of the day, we had a codified pipeline for future research projects:

### Phase 0: Topic ID
Identify the gap, map the literature, define "before" and "after" states

### Phase 1: Initial Writeup
Write a proposal → have the agent spawn an isolated reviewer → iterate

### Phase 2: Simulation
Test (2 reps) → Validate (20 reps) → Confirm (200 reps) → Full (10K reps)

### Phase 3: Multi-Agent QC
**Code review before big simulations — mandatory after we skipped it once and nearly delivered buggy results**

### Phase 4: Full Run
Background processing, scheduled, monitored

### Phase 4.5: Reproducibility Audit
Agent verifies code matches manuscript claims

### Phase 5: Manuscript
Write, verify references, PDF self-check, senior review

### Phase 6: Revision
Critique Parser → Math Reconciliation → Re-Simulation → Diff Check

### Phase 7: Pre-Submission Loop
Independent reviewer → Revise → Loop (max 3) until Accept

## Key Lessons Codified

1. **Isolate reviewers** — Fresh sessions only, no cross-contamination from prior discussion
2. **Diversify models** — Different AIs catch different bugs; one is as bad as one human
3. **PDF self-verify** — Automated checks before anything reaches colleagues
4. **Clean up cruft** — Stale code and language accumulates; clean explicitly at every milestone
5. **Push to GitHub at milestones** — Enables external review access
6. **Batch deliveries** — Don't send incremental fixes. Pace yourself.

---

# Key Takeaways

## What Worked Well

- **Independent AI reviewers caught 11 bugs** before human eyes ever saw the draft — citation errors, a broken method, non-collapsibility, framing weaknesses
- **Small tests before big runs** — we avoided roughly 5 dead ends this way
- **Human-in-the-loop was essential** — I directed 8 reframing cycles. Each one improved the method. The agent amplified my judgment, didn't replace it.
- **The LoRA analogy** resonated with both AI and human reviewers

## What We'd Do Differently

- **PDF generation was painful** — 5 failed attempts before we got it right. Images silently failed (RGBA→RGB, code block markers, missing paths). We now have a verification script baked into the workflow.
- **Code review was almost skipped** — would have delivered buggy simulation results. It's now a hard checkpoint in the pipeline.
- **Stale artifacts accumulated** — old PDFs, old labels, old comments. We now have explicit cleanup at every milestone.

---

# Q&A

## Thank You

\centering
\Huge Questions?
\normalsize

\vfill

**The key insight:** An AI agent doesn't replace the statistician. It replaces the *drafting lag* and the *review cycle*. I still had to think, direct, and decide — but what used to take a week of calendar coordination now takes an evening.

**Repos:**
- Ridge-Cal: `github.com/doublerobust/ridge-cal`
- Small strata: `github.com/doublerobust/small-strata-pooling`

**The skill:** Lives in my OpenClaw workspace — happy to share.
