# Adaptive Phase II/III Pick-a-Winner Design — Intern Brief

> Project: Adaptive seamless phase II/III designs for oncology trials using ORR/DOR for interim dose/arm selection, with OS as the final confirmatory endpoint

---

## 1. Problem Statement

Traditional oncology development runs Phase II and III as separate sequential trials. This wastes time and patients — Phase II patients cannot be pooled into the final analysis. The goal: a single seamless Phase II/III trial that starts with multiple doses/arms, picks the winner based on **ORR** (binary, weeks), then confirms with **OS** (time-to-event, months-years). The different data types and imperfect correlation create the core challenge — selecting the best ORR arm doesn't guarantee the best OS arm, and shared patient data between selection and testing creates statistical bias that must be addressed.

---

## 2. Key References

### 2.1 Core Papers (Full Text)

| # | Authors | Year | Journal | Key Contribution |
|---|---------|------|---------|-----------------|
| 1 | Stallard & Todd | 2003 | *Stat Med* | Foundational pick-the-winner: two-stage, K treatments → select best at interim via efficient score. Works for binary, normal, TTE. |
| 2 | Bauer & Posch | 2004 | *Stat Med* | Origin of Bauer-Posch bias: using same patients' short-term data for selection and long-term for testing inflates type I error. |
| 3 | Dunnett | 1955 | *JASA* | Classic multiple comparison: K treatments vs control with FWER control. Building block for all pick-a-winner multiplicity adjustments. |
| 4 | Magirr et al. | 2012 | *Stat Med* | Canonical MAMS for TTE endpoints. Covariance structure for test statistics across stages — enables group sequential boundaries. |
| 5 | Wu et al. | 2023 | *Stat Med* | SCPRT-based MAMS. Analytical futility/efficacy boundaries for arbitrary stages/arms. Continuous outcomes only. |
| 6 | Zhang & Jin | 2025 | *Stat Biopharm Res* | **Directly addresses your setting.** Multi-stage group sequential Phase 2/3 with dose selection via ORR/PFS, OS as final. Cohort-separation + inverse normal combination + closed testing. |

**Stallard & Todd (2003).** The foundational design: K experimental arms vs control, select the most promising at interim via efficient score statistic, continue with selected arm + control. All patients from both stages included in the final test with multiplicity adjustment. Handles binary, normal, or failure-time data uniformly. Start here — implement this two-stage design first.

**Bauer & Posch (2004).** Demonstrates that using the same patients' short-term endpoint for selection and long-term for final testing inflates type I error. The magnitude depends on ρ between endpoints, the selection rule, and patient overlap. Motivated cohort-separation designs (Jenkins 2011, Zhang & Jin 2025).

**Dunnett (1955).** Exact critical values for comparing multiple treatments vs a single control with FWER control. The multivariate normal distribution of Dunnett statistics is the foundation for multiplicity adjustment throughout this literature.

**Magirr et al. (2012).** Extends MAMS to TTE outcomes with staggered entry and censoring. Derives the joint distribution of test statistics across stages — the covariance structure that Zhang & Jin (2025) builds on. Also provides a feasible boundary search algorithm.

**Wu et al. (2023).** SCPRT-based group sequential MAMS yielding analytical boundaries for any number of stages and arms, avoiding the exponential complexity of Magirr et al.'s search. Continuous outcomes only; boundary structure can be adapted for TTE.

**Zhang & Jin (2025).** Your most important paper. Extends two-stage seamless to **multi-stage group sequential** with TTE endpoints and dose selection via ORR/PFS. Key innovations: (1) **cohort-separation** — Cohort 1 (pre-selection, all arms) and Cohort 2 (post-selection, selected arm + control) combined via inverse normal combination with weights proportional to expected events; (2) **explicit covariance formula** for combined test statistics across stages; (3) **closed testing + Dunnett** for FWER at one-sided 0.025. Simulation confirms type I error control and favorable operating characteristics vs traditional Phase 2 + Phase 3.

### 2.2 Further Reading (Abstract Only)

| Paper | One-Liner |
|-------|-----------|
| Jin & Zhang (2021), *Stat Methods Med Res* | Adaptive seamless Phase 2-3 with multiple endpoint closed testing |
| Jenkins et al. (2011), *Pharm Stat* | Original cohort-separation using correlated different TTE endpoints |
| Bretz et al. (2006), *Biom J* | Foundational framework for confirmatory seamless designs |
| Schmidli et al. (2006), *Biom J* | Applications of Bretz et al. — practical implementation |
| Friede & Stallard (2008), *Biom J* | Compares 4 methods: Dunnett, adaptive Dunnett, combination test, group sequential |
| Sun et al. (2020), *Stat Biopharm Res* | ORR/PFS for adaptive seamless decisions; 2-in-1 design |
| Dixit et al. (2021), *J Biopharm Stat* | MAMS for TTE with non-proportional hazards |
| Sydes et al. (2012), *Trials* | STAMPEDE — landmark MAMS implementation |
| Kelly et al. (2005), *Stat Med* | Practical MAMS implementation guide |
| Mehta & Tsiatis (2001), *Biometrics* | Information-based monitoring for interim timing with immature endpoints |
| Zhong et al. (2025), *Stat Med* | Derives ρ(ORR, OS) analytically; drop-the-losers |
| Broglio et al. (2024), *Ther Innov Regul Sci* | Systematic review of adaptive seamless designs |
| Friede et al. (2019), *arXiv / R asd* | R package `asd` for treatment/subgroup selection |

### 2.3 Bayesian Alternative (Brief)

Bayesian approaches (Berry et al. 2002; Lee & Liu 2008) use predictive probability: P(treatment beats control at final given interim data). Naturally handles ORR-OS correlation through the joint posterior. This project uses the frequentist framework because (1) regulators expect well-characterized frequentist type I error control, (2) cohort-separation cleanly solves the Bauer-Posch bias, (3) the literature you'll build on is almost entirely frequentist.

---

## 3. Design Options

**2-in-1 Design (Jin & Zhang 2021, Sun et al. 2020).** Operationally seamless: separate protocols with continuous recruitment. Phase II data used for selection only, not pooled into Phase III. Simpler but less efficient than inferentially seamless.

**MAMS with Group Sequential (Zhang & Jin 2025, Magirr et al. 2012).** † *Your primary candidate.* Inferentially seamless: one protocol, two cohorts. Cohort 1 randomized across K doses + control. After ORR-based selection, Cohort 2 enrolls selected dose + control. OS combined via inverse normal combination. Group sequential looks. Cohort-separation avoids Bauer-Posch bias.

**Drop-the-Losers (Zhong et al. 2025).** Uses ORR for selection. Derives ρ(ORR, OS) under PH; FWER inflation = f(ρ, Δ). When ρ = 0, no inflation. For solid tumors, ρ ∈ [0.3, 0.7].

**Rank-Based Dunnett (Wang et al. 2023).** *Abstract only.* Rank-based statistics in Dunnett framework. Fewer assumptions; less regulatory familiarity.

**Subpopulation Selection (Jenkins et al. 2011).** *Abstract only.* Continue in all patients, subgroup, or both. Cohort-separation idea inspired Zhang & Jin.

**SCPRT Boundaries (Wu et al. 2023).** Analytical futility/efficacy boundaries for any stages×arms. Continuous outcomes; adaptable.

---

## 4. Statistical Challenges

**FWER Control.** Must control across (1) selection among K doses and (2) multiple group sequential OS looks. Zhang & Jin uses closed testing + Dunnett + alpha spending. Any deviation from pre-specified selection rule (e.g., safety override) must preserve control.

**ρ(ORR, OS).** The central parameter. High ρ (≥ 0.7) → ORR selection nearly optimal for OS. Low ρ (≤ 0.3) → power loss. FWER ↑ monotonically with ρ. Calibrate from meta-analyses (Prasad et al. 2015).

**Bauer-Posch Bias.** Shared patients for selection and testing inflates type I error. Solved by cohort-separation: only Cohort 1's ORR used for selection; OS from both cohorts combined via combination tests.

**Non-Proportional Hazards.** IO agents often show delayed separation (curves overlap 3-6 months). Violates PH assumptions in Zhang & Jin covariance formulas. Use weighted log-rank or RMST in sensitivity. Include delayed-separation scenarios (HR 1.0 → 0.75 over 6 months).

---

## 5. Simulation Roadmap (8 Weeks)

| Week | Focus | Deliverable |
|------|-------|-------------|
| **1–2** | Read Stallard & Todd (2003), Bauer & Posch (2004), Zhang & Jin (2025). Set up R. | Paper notes. R skeleton (`gsDesign`, `rpact`, `simtrial`, `mvtnorm`). |
| **3–4** | Implement Stallard & Todd two-stage pick-the-winner with binary→binary (ORR for both). Validate published results. | Working simulation; type I error ≈ 0.025 ± MC error. |
| **5–6** | Extend to ORR→OS. Multi-state data generation. Cohort-separation + group sequential. Run null + 3-4 alternative scenarios. | Full simulation grid; 5k–10k reps per scenario. |
| **7** | Sensitivity: ρ ∈ {0.3, 0.5, 0.7}. Non-PH scenario. Compare pick-a-winner vs drop-the-losers vs traditional Phase 2+3. | Results with MC standard errors. |
| **8** | Presentation prep. Figures (power curves, FWER contours). Reproducible vignette. | 15-min presentation + reproducible package. |

**Starting parameters:** K=2-3 arms, Stage 1 n=30-40/arm, total N=300-600, ORR_control=0.15, ORR_exp=0.25-0.45, OS HR=0.70-0.85, ρ ∈ {0.3, 0.5, 0.7}, interim at N=120. Save RNG seed + full parameters + full results for every run.

---

## 6. References

**Core Papers**

1. Stallard N, Todd S. Sequential designs for phase III clinical trials incorporating treatment selection. *Stat Med*. 2003;22(5):689-703.
2. Bauer P, Posch M. Modification, adaptation and suboptimal combination tests. *Stat Med*. 2004;23(10):1651-1670.
3. Dunnett CW. A multiple comparison procedure for comparing several treatments with a control. *JASA*. 1955;50(272):1096-1121.
4. Magirr D, Jaki T, Whitehead J. A flexible MAMS design for time-to-event outcomes. *Stat Med*. 2012;31(25):3060-3072.
5. Wu J, Li Y, Zhu L. Group sequential multi-arm multi-stage trial design with treatment selection. *Stat Med*. 2023;42:1480-1491.
6. Zhang EP, Jin M. A Multi-Arm Multi-Stage Group Sequential Phase 2/3 Design with Dose Selection for Oncology Trials. *Stat Biopharm Res*. 2025.
7. Prasad V, et al. The strength of association between surrogate end points and survival in oncology. *JAMA Intern Med*. 2015;175(8):1389-1398.

**Further Reading**

8. Jin M, Zhang P. *Stat Methods Med Res*. 2021;30(4):1143-1151.
9. Jenkins M, Stone A, Jennison C. *Pharm Stat*. 2011;10(4):347-356.
10. Bretz F, et al. *Biom J*. 2006;48(4):623-634.
11. Sun LZ, et al. *Stat Biopharm Res*. 2020;12(2):224-233.
12. Dixit V, et al. *J Biopharm Stat*. 2021;31(6):838-851.
13. Sydes MR, et al. *Trials*. 2012;13:168.
14. Kelly PJ, et al. *Stat Med*. 2005;24(4):559-577.
15. Friede T, et al. *arXiv:1901.08365*. 2019.
16. Mehta CR, Tsiatis AA. *Biometrics*. 2001;57(3):850-857.
17. Zhong W, et al. *Stat Med*. 2025;44:e70209.
18. Stallard N, Todd S. *Stat Med*. 2008;27(29):6209-6227.
19. Broglio K, et al. *Ther Innov Regul Sci*. 2024;58:917-929.
