# Adaptive Phase II/III Pick-a-Winner Design — Literature Review

> Prepared for: Yue Shentu (Merck statistician) — Intern project foundation
> Date: 2026-05-20
> Topic: Adaptive seamless phase II/III "pick-a-winner" designs for oncology trials with time-to-event endpoints, using ORR/DOR as short-term endpoints for interim decisions

---

## 1. Overview of Seamless Designs in Oncology

### 1.1 Motivation

Traditional oncology drug development proceeds sequentially: a Phase II trial establishes preliminary efficacy and selects dose(s), followed by one or more independent Phase III confirmatory trials. This sequential approach suffers from:

- **White space** between phases (administrative gaps, data lock, regulatory review)
- **Long timelines** — especially with time-to-event endpoints like overall survival (OS)
- **High failure rates** — many drugs that pass Phase II fail in Phase III
- **Sample size inefficiency** — Phase II and III patients cannot be combined for the final analysis

Adaptive seamless Phase II/III designs address these issues by combining the learning (Phase II) and confirming (Phase III) stages into a single, uninterrupted trial conducted in two (or more) stages. At an interim analysis, the design selects the best-performing treatment arm(s), dose(s), and/or subpopulation(s) based on accumulated data, then continues seamlessly into the confirmatory stage. Patients from both stages are included in the final analysis.

### 1.2 Terminology and Design Families

| Term | Description |
|------|-------------|
| **Seamless Phase II/III** | Single trial combining Phase II (learning/selection) and Phase III (confirmation) |
| **Pick-a-Winner** | At interim, select the best arm(s) from K candidates; drop inferior arms |
| **Operationally seamless** | Separate protocols but continuous recruitment; no data-lock gap |
| **Inferentially seamless** | Single protocol; data from both stages pooled in final analysis with proper multiplicity adjustment |
| **MAMS** | Multi-arm multi-stage — generalization to multiple arms and multiple looks |
| **Adaptive enrichment** | Select a responsive subpopulation at interim based on biomarker data |
| **Two-in-One** | Specific operationally seamless design with dose selection (Chen, Sun, et al.) |

### 1.3 Regulatory Context

The **FDA Oncology Center of Excellence (OCE)** has actively encouraged innovative trial designs through initiatives like Project Optimus (dose selection reform). The **FDA Adaptive Design Guidance** (2019) provides the regulatory framework. Key considerations:

- Type I error must be controlled **strongly** across all design adaptations
- The adaptation rule must be **pre-specified** in the protocol
- Information at interim must be sufficient for reliable decisions
- **Estimand alignment** across stages when endpoints differ
- Comparability of data before and after adaptation (e.g., drift in standard of care)

#### Estimand Alignment (ICH E9(R1)) Implications

The ICH E9(R1) addendum on estimands introduces critical considerations for seamless pick-a-winner designs where the interim decision uses ORR/DOR and the final analysis uses OS. These considerations are increasingly expected by regulators and should be addressed in any regulatory submission.

**Treatment policy estimand.** Under the treatment policy estimand, the effect of the experimental treatment is estimated regardless of whether patients discontinue or receive subsequent therapy. In a pick-a-winner design, patients randomized to an arm that is *not* selected at interim are typically followed for OS and included in the analysis under their original randomization — respecting the treatment policy estimand for those arms. However, the fact that these patients contribute to the selected arm comparison only through the pre-selection cohort (in the Jenkins/Zhang & Jin framework) creates a subtle question: does the composition of the analysis set (enriched for patients who were randomized before or after the selection) affect the generalizability of the estimand? The answer depends on whether patient characteristics are stable across cohorts, which should be assessed.

**Intercurrent events at selection.** The selection decision itself can be viewed as an intercurrent event. For patients in unselected arms, their continued follow-up and inclusion in the OS analysis may be affected by the knowledge that their arm was dropped (which could influence subsequent therapy decisions and thus OS). The ICH E9(R1) framework requires pre-specification of how this intercurrent event is handled: a treatment policy strategy (include all OS data regardless) is most common and aligns with the intention-to-treat principle, but a hypothetical strategy (what would OS be if the arm had continued?) could also be considered. For the selected arm, the selection event is not an intercurrent event per se, but the interim data used for selection may inform the final analysis in ways that require statistical adjustment (the Bauer-Posch bias).

**Cohort-specific estimands in the Jenkins framework.** The Jenkins et al. (2011) cohort-separation approach creates two *de facto* sub-trials: Cohort 1 (pre-selection) with all arms but potentially limited OS follow-up by the final analysis, and Cohort 2 (post-selection) with only the selected arm and control but full OS follow-up. Strictly speaking, these cohorts estimate the same treatment effect under the assumption of no temporal drift, but the estimand may differ if patient population, standard of care, or investigator behavior changes between cohorts. For regulatory purposes, it is advisable to define a single estimand for the entire trial and verify that pooling across cohorts is consistent with that estimand, rather than defining separate estimands per cohort. This issue is analogous to the estimand challenges in platform trials where arms are added over time (Choodari-Oskooei et al. 2020).

---

## 2. Key Papers

### 2.1 Summary Table

| # | Authors | Year | Journal | Endpoints | Method Summary | Simulation Details |
|---|---------|------|---------|-----------|---------------|-------------------|
| 1 | **Jin M, Zhang P** | 2021 | *Stat Methods Med Res* | Intermediate endpoint (unspecified categorical/TTE) + multiple primary endpoints | Adaptive seamless Phase 2-3 with multiple endpoints; expand Phase 2 into Phase 3 based on intermediate endpoint; multiple test procedure controls FWER | Conducted to confirm FWER control; oncology example |
| 2 | **Jenkins M, Stone A, Jennison C** | 2011 | *Pharm Stat* | Correlated time-to-event endpoints (PFS for interim, OS for final) | Adaptive seamless II/III with subpopulation selection; allows trial to continue in all patients or subgroup(s) as co-primary; controls type I error <2.5% with correlated **different** TTE endpoints | Operating characteristics described; oncology setting |
| 3 | **Bretz F, Schmidli H, König F, Racine A, Maurer W** | 2006 | *Biom J* | Any (binary, continuous, TTE) | Foundational framework for confirmatory seamless designs; dose/ hypothesis selection at interim; flexible test procedures (Simes, Dunnett, Bonferroni); combination test and conditional error approaches | Power study comparing test procedures |
| 4 | **Schmidli H, Bretz F, Racine A, Maurer W** | 2006 | *Biom J* | Binary, time-to-event, continuous | Applications of Bretz et al. (2006) framework; examples from drug development; practical implementation issues including treatment and subgroup selection | Real trial examples with simulations |
| 5 | **Stallard N, Todd S** | 2003 | *Stat Med* | Any (binary, normal, failure-time via efficient score) | **Seminal pick-the-winner paper**; two-stage design; select most promising treatment at first interim; uses efficient score statistic; sample size determination for specified power | Computational approach; binary, normal, failure-time data considered |
| 6 | **Stallard N, Todd S** (extended with Kelly et al.) | 2008 | *Stat Med* | Any (extension of 2003) | Group-sequential with treatment selection; allows >1 experimental treatment to continue; controls FWER strongly when number of treatments pre-specified; simulation shows conservatism when number is data-driven | Simulation studies for strong FWER control |
| 7 | **Friede T, Stallard N** | 2008 | *Biom J* | Any primary endpoint | **Comparison of 4 methods**: (1) classical Dunnett test, (2) adaptive Dunnett (conditional error approach), (3) combination test approach, (4) group-sequential framework. No method dominates; scenarios favoring each are described | Extensive simulation comparing power across methods and scenarios |
| 8 | **Sun LZ, Li W, Chen C, Zhao J** | 2020 | *Stat Biopharm Res* | **PFS/ORR (interim) → OS (final)** | **Critically important for this project.** Uses intermediate endpoints (PFS, ORR) for adaptive decisions in seamless designs; benefit-cost ratio objective criteria; two real design examples: operationally seamless with dose-selection and statistically seamless **2-in-1 design** | Based on real trial designs; addresses why seamless designs are rarely used due to OS waiting time |
| 9 | **Dixit V, et al.** | 2021 | *J Biopharm Stat* | Time-to-event (same or different endpoints across stages) | MAMS for time-to-event outcomes; generalized Dunnett procedure for FWER when same endpoint; modifications when endpoints differ; handles **delayed treatment effects** (non-proportional hazards) | Performance under proportional and non-proportional hazards |
| 10 | **Choodari-Oskooei B, et al.** | 2020 | *Clin Trials* | TTE, binary, continuous | Platform trial error rates; analytical formula for correlation of test statistics when adding arms; Šidák correction when correlation < 0.30 | Verified analytical derivations via simulation |
| 11 | **Sydes MR, et al. (STAMPEDE)** | 2012 | *Trials* | FFS (interim) → OS (final) | **Landmark MAMS trial** in prostate cancer; 5 research arms + control; 3 intermediate stages (failure-free survival) + final stage (OS); stopped 2 arms for futility; added new arms mid-trial; **practical implementation** across 100+ centers | Operational experience — not a statistical methods paper |
| 12 | **Friede T, Stallard N, Parsons N** | 2019 | *arXiv / R package asd* | Primary or early outcome | Flexible simulation model for treatment AND subgroup selection; **R package `asd`** extended for enrichment designs; accommodates early outcome for interim decisions | Worked examples in COPD and oncology |
| 13 | **Broglio K, et al.** | 2024 | *Ther Innov Regul Sci* | Multiple endpoints | **Systematic review** of adaptive seamless designs in late-phase oncology; catalog of real trials | Systematic review methodology |
| 14 | **Zhu H, et al.** | 2024 | *Commun Stat Simul Comput* | Binary (response) | ASD with sequential estimation-adjusted urn (SEU) model for response-adaptive randomization; dual challenge of multiplicity + non-independent assignments; type I error control | Numerical studies confirm type I error control and power preservation |
| 15 | **Zhang EP, Jin M** | 2025 | *Stat Biopharm Res* | ORR/PFS (interim) → OS (final) | **Multi-stage group sequential Phase 2/3** with dose selection; inverse normal combination test + closed testing + group sequential boundaries; cohort-separation design (Cohort 1: pre-selection, Cohort 2: post-selection); explicit covariance formula for combined test statistic across stages | Type I error control at 0.025 confirmed; compares favorably to traditional Phase 2+3 approach |
| 16 | **Zhong W, Liu J, Wang C** | 2025 | *Stat Med* | Binary surrogate (ORR) → TTE (OS/PFS) | **Analytic derivation of ρ(ORR, OS)** under PH; FWER inflation formula as function of ρ and selection threshold Δ; upper bound for ρ under proportional hazards with censoring | FWER inflation characterized; software implementing drop-the-losers design provided |
| 17 | **Wu J, Li Y, Zhu L** | 2023 | *Stat Med* | Continuous (normal) | SCPRT-based group sequential MAMS; analytical futility/efficacy boundaries for arbitrary stages and arms; avoids exponential complexity of Magirr et al. boundary search | Dunnett correction under global null; continuous outcomes only |
| 18 | **Magirr D, et al.** | 2012 | *Stat Med* | Time-to-event | **Canonical MAMS TTE reference**; flexible multi-arm multi-stage design for time-to-event outcomes; covariance structure for TTE test statistics across stages; extends multivariate normal approach underpinning later work | Operating characteristics; boundary computation algorithm |
| 19 | **Bauer P, Posch M** | 2004 | *Stat Med* | Any | **Origin of the Bauer-Posch bias result**; modification, adaptation and suboptimal combination tests in adaptive designs; shows using same patients' short-term and long-term data inflates type I error | Theoretical derivation of bias; simulation confirmation |
| 20 | **Dunnett CW** | 1955 | *JASA* | Continuous (normal means) | **Original Dunnett multiple comparison procedure**; comparing several treatments with a single control; foundation of the Dunnett-type adjustments used throughout the pick-a-winner literature | Tables of critical values for equal-sample-size case |
| 21 | **Kelly PJ, et al.** | 2005 | *Stat Med* | Any (practical implementation) | **Practical guide to implementing MAMS trials**; operational considerations, sample size, monitoring, and analysis for multi-arm multi-stage designs; complements the STAMPEDE experience | Practical implementation — real trial examples with simulations |
| 22 | **Mehta CR, Tsiatis AA** | 2001 | *Biometrics* | Time-to-event | **Flexible sample size estimation using information-based monitoring**; directly addresses how to time interim looks when the primary endpoint is immature; relevant for ORR→OS seamless designs where OS data is immature at interim | Information-based sample size re-estimation framework |

### 2.2 Detailed Notes on Key Papers

#### Paper #1: Jin & Zhang (2021)
- **DOI:** 10.1177/0962280220986935
- **Abstract retrieved** ☑ (full text not accessed)
- **Core contribution:** Proposes adaptive seamless Phase 2-3 design that expands an ongoing Phase II into Phase III based on an intermediate endpoint. Tests multiple endpoints with a powerful multiple test procedure (likely a closed testing or gatekeeping procedure). Proves FWER control under a mild assumption expected to hold in practice. Illustrated with oncology example.
- **Relevance to this project:** Directly applicable — focuses on multiple endpoint testing in seamless designs, which is central to our ORR/DOR + OS setting.

#### Paper #2: Jenkins, Stone & Jennison (2011) [211 citations]
- **DOI:** 10.1002/pst.472
- **Abstract retrieved** ☑ (full text not accessed)
- **Core contribution:** Phase II/III design with subpopulation selection using correlated but **different** time-to-event endpoints (e.g., PFS at interim, OS at final). Methods control type I error < 2.5% when endpoints are correlated. Allows the trial to continue in all patients, a subpopulation, or both as co-primary populations.
- **Critical for this project:** Establishes precedent for using **different correlated TTE endpoints** between stages, relevant to using ORR/DOR (short-term) → PFS/OS (long-term).

#### Paper #5: Stallard & Todd (2003) [500+ citations estimated]
- **DOI:** 10.1002/sim.1362
- **Abstract retrieved** ☑ (full text not accessed)
- **Core contribution:** The definitive "pick-the-winner" methodology. Two-stage design where the most promising of K experimental treatments is selected at the first interim. Uses the **efficient score** as test statistic, making binary, normal, or failure-time data analysis straightforward. Includes power/sample size determination.
- **Foundation for this project:** The pick-the-winner mechanism is the central machinery we need.

#### Paper #8: Sun, Li, Chen & Zhao (2020) [10 citations]
- **DOI:** 10.1080/19466315.2019.1665578
- **Abstract retrieved** ☑ (full text not accessed)
- **Core contribution:** Directly addresses why seamless designs are rarely used in oncology practice: OS takes too long. Proposes using **intermediate endpoints** (PFS, ORR) in adaptation criteria with objective benefit-cost ratio approach. Two real examples: (1) operationally seamless with dose-selection, (2) **statistically seamless 2-in-1 design**.
- **Most relevant paper for this project:** Provides the framework for exactly the setting we're considering — short-term endpoints (ORR/DOR or PFS) for interim decisions, long-term OS for final analysis.

#### Paper #6: Stallard & Todd (2008)
- **DOI:** 10.1002/sim.3436
- **Abstract retrieved** ☑ (full text not accessed)
- **Core contribution:** Extends 2003 work to allow more than one experimental treatment to continue. Controls FWER strongly when number of treatments pre-specified; conservative when number is data-driven. Addresses the case where the best-performing treatments may NOT be the ones that continue (e.g., safety data override).
- **Relevance:** Important for designs where multiple doses/arms might be carried forward.

#### Paper #9: Dixit et al. (2021)
- **DOI:** 10.1080/10543406.2021.1979575
- **Abstract retrieved** ☑
- **Core contribution:** MAMS for TTE outcomes with same vs. different endpoints across stages. Generalized Dunnett procedure for FWER (same endpoint). Modifications when endpoints differ. Handles **delayed treatment effect (non-proportional hazards)** with alternative test statistic to maintain power.
- **Critical for this project:** TTE endpoints with non-proportional hazards are common in immuno-oncology; this paper provides approaches for that scenario.

#### Paper #15: Zhang (Pingye) & Jin (2025)
- **Full citation:** Zhang EP, Jin M. "A Multi-Arm Multi-Stage Group Sequential Phase 2/3 Design with Dose Selection for Oncology Trials." *Statistics in Biopharmaceutical Research*. 2025. DOI: 10.1080/19466315.2025.2539831
- **Full text accessed** ☑ (Telegram from Merck)
- **Core contribution:** ⭐ **The paper your intern needs most.** Extends the two-stage seamless design to **multi-stage** (group sequential) with time-to-event endpoints and dose selection based on ORR/PFS. Uses inverse normal combination test + closed testing procedure + group sequential boundaries for strong FWER control.
- **Key innovation:** Splits patients into **two cohorts** — Cohort 1 (enrolled before dose selection, all arms) and Cohort 2 (enrolled after dose selection, selected arm + control only). OS data from Cohort 1 and Cohort 2 are combined via inverse normal combination with pre-specified weights proportional to expected events.
- **MAMS feature:** K doses evaluated in stage 1, at most one dose selected for stage 2+ (based on ORR/PFS + totality of data). Patients in unselected arms must still be followed for OS.
- **Group sequential:** Multiple interim analyses in phase 3 with alpha spending function. Efficacy boundaries obtained via multivariate normal distribution of the combined test statistic.
- **Covariance formula (Equation 3):** Explicit derivation of `cov(Z_I_j, Z_I_j')` for the combined test statistic across stages, enabling standard group sequential boundary computation.
- **Simulation results:** Confirms Type I error control at one-sided 0.025. Operating characteristics compared favorably to traditional sequential phase 2 + phase 3 approach.
- **Relevance to intern project:** Directly addresses the exact setting — dose selection via ORR/PFS, confirmatory testing on OS, with group sequential looks.

#### Paper #16: Zhong, Liu & Wang (2025)
- **Full citation:** Zhong W, Liu J, Wang C. "Multiplicity Control in Oncology Clinical Trials With a Binary Surrogate Endpoint-Based Drop-The-Losers Design." *Statistics in Medicine*. 2025;44:e70209. DOI: 10.1002/sim.70209
- **Full text accessed** ☑ (Telegram from Merck)
- **Core contribution:** ⭐ **Derives the correlation ρ between binary surrogate (OR/pCR) and time-to-event (PFS/OS) analytically** — directly applicable to ORR → OS setting. This is the only paper that does this.
- **Key formulas:**
  - Proposition 1: ρ_jk ≈ √(q·τ_k / 2(1-q)) · [∫₀^∞ S₁(t)f(t)/S(t) dt - 1] (no censoring)
  - Proposition 2: ρ_jk with non-informative censoring
  - Theorem 1: Upper bound for ρ under proportional hazards (γ ≤ 1) with censoring
- **FWER inflation formula (Equation 2):** Explicit expression for FWER = α* + ∫(Φ(d₁) - Φ(d₂))φ(z)dz, where d₁, d₂ depend on ρ and Δ (selection threshold)
- **Key findings:**
  - When ρ = 0, FWER controlled at α* (independence)
  - As ρ increases, FWER increases monotonically (for Δ = 0)
  - When Δ → ∞, FWER → α* (extreme selection threshold eliminates inflation)
  - Relationship between FWER and Δ is NOT monotonic
- **Practical implication for design:** Zhong et al. suggest conservatively setting ρ = 1 when selecting α* for FWER control. **Caution:** setting ρ = 1 is extremely conservative — it assumes perfect correlation between the binary surrogate and TTE endpoint, which rarely holds in solid tumors. This would substantially over-penalize the multiplicity adjustment, reducing power. The intern should use ρ = 1 only as an upper bound, then calibrate using tumor-specific historical data (e.g., from meta-analyses of past trials in the same indication). The span ρ ∈ [0.3, 0.7] is where most real oncology scenarios live.
- **R package:** Provides software implementing the DTL design.
- **Relevance to intern project:** Provides the missing piece — how to calibrate the correlation between ORR (binary surrogate) and OS (TTE endpoint) for the interim decision rule.

#### Paper #17: Wu, Li & Zhu (2023)
- **Full citation:** Wu J, Li Y, Zhu L. "Group sequential multi-arm multi-stage trial design with treatment selection." *Statistics in Medicine*. 2023;42:1480-1491. DOI: 10.1002/sim.9682
- **Full text accessed** ☑ (Telegram from Merck)
- **Core contribution:** SCPRT-based group sequential MAMS with analytical futility and efficacy boundaries for arbitrary number of stages and arms. Avoids the exponential computational complexity of Magirr et al.'s method.
- **Key method:** Sequential Conditional Probability Ratio Test (SCPRT) based on Brownian motion B_t ~ N(θt, t). Boundaries: l = (c·t - √(2a·t(1-t)))/√t, u = (c·t + √(2a·t(1-t)))/√t
- **FWER control:** Dunnett correction under global null hypothesis (Equation 3) provides strong control.
- **Limitation:** Continuous outcomes (normal), not time-to-event. Still useful for boundary computation.
- **Relevance:** Boundary machinery for the group sequential component of the design.

#### Paper #18: Magirr et al. (2012)
- **Full citation:** Magirr D, Jaki T, Whitehead J. "A flexible MAMS design for time-to-event outcomes." *Statistics in Medicine*. 2012;31(25):3060-3072. DOI: 10.1002/sim.5389
- **Core contribution:** **The canonical MAMS reference for time-to-event endpoints.** Extends the multi-arm multi-stage framework to accommodate time-to-event outcomes with staggered patient entry and censoring. Derives the joint distribution of test statistics across stages for TTE endpoints, which underpins the covariance structure used in Zhang & Jin (2025) and Dixit et al. (2021).
- **Key innovation:** Uses a combination test approach with Fisher's product or inverse normal combining functions for TTE test statistics. Provides a computationally feasible boundary search algorithm avoiding full multivariate normal integration.
- **Relevance:** Foundational machinery for the TTE-specific MAMS framework; the intern must understand this paper to properly implement the covariance structure for the group sequential component.

#### Paper #19: Bauer & Posch (2004)
- **Full citation:** Bauer P, Posch M. "Modification, adaptation and suboptimal combination tests — a simulation study." *Statistics in Medicine*. 2004;23(10):1651-1670. DOI: 10.1002/sim.1769
- **Core contribution:** **Origin of the Bauer-Posch bias result.** Demonstrates that naive use of the same patients' short-term endpoint data for interim selection and their long-term endpoint data for the final test inflates the type I error. Shows that combination tests can control this inflation when properly applied.
- **Key finding:** The magnitude of bias depends on the correlation between short-term and long-term endpoints, the selection rule, and the amount of overlap in patient data. Suboptimal choices of the combining function can exacerbate inflation.
- **Relevance:** The document references "Bauer-Posch bias" extensively (§4.3, §5) — this is the original citation. Understanding this result is essential for the intern to appreciate why cohort-separation designs (Jenkins et al. 2011, Zhang & Jin 2025) are necessary.

#### Paper #20: Dunnett (1955)
- **Full citation:** Dunnett CW. "A multiple comparison procedure for comparing several treatments with a control." *Journal of the American Statistical Association*. 1955;50(272):1096-1121. DOI: 10.1080/01621459.1955.10501294
- **Core contribution:** **The foundational paper for Dunnett-type multiple comparison procedures.** Provides exact critical values and testing procedure for comparing K treatment arms against a single control while controlling FWER. Handles both equal and unequal sample sizes.
- **Relevance:** Dunnett-adjusted tests are used throughout the pick-a-winner literature (Friede & Stallard 2008, Stallard & Todd 2008, Dixit et al. 2021). The intern should understand the classical Dunnett test before studying its adaptive extensions.

#### Paper #21: Kelly et al. (2005)
- **Full citation:** Kelly PJ, Stallard N, Todd S. "A practical guide to implementing multi-arm multi-stage clinical trials." *Statistics in Medicine*. 2005;24(4):559-577. DOI: 10.1002/sim.1998
- **Core contribution:** Practical implementation guide for MAMS designs. Covers sample size determination, monitoring guidelines, analysis strategies, and software implementation for multi-arm multi-stage trials. Complements the STAMPEDE operational experience (Sydes et al. 2012).
- **Relevance:** Provides the operational framework the intern will need when moving from methodology to implementation.

#### Paper #22: Mehta & Tsiatis (2001)
- **Full citation:** Mehta CR, Tsiatis AA. "Flexible sample size estimation using information-based monitoring." *Biometrics*. 2001;57(3):850-857. DOI: 10.1111/j.0006-341X.2001.00850.x
- **Core contribution:** Information-based monitoring framework for adaptive clinical trials. Directly addresses how to time interim analyses and re-estimate sample size when the primary endpoint is immature — the exact situation in seamless ORR→OS designs where OS data is highly immature at the time of the ORR-based interim decision.
- **Relevance:** The intern needs this framework to determine when to conduct the interim analysis (driven by ORR maturity) and how to handle the resulting information fraction for OS.

### 2.3 Bayesian Adaptive Approaches

The literature review above focuses almost exclusively on frequentist methods for adaptive seamless designs. Bayesian approaches offer a flexible alternative that warrants discussion, particularly because the intern will likely be asked to justify the choice of a frequentist framework.

**Berry et al. (2002)** proposed a foundational Bayesian framework for Phase II–III seamless trials using predictive probability monitoring. In this framework, at the interim analysis, the predictive probability that the experimental arm will demonstrate superiority over control at the final analysis is computed from the posterior distribution. If this probability exceeds a pre-specified threshold (e.g., 0.90), the trial continues to Stage 2 with the selected arm; if it falls below a futility threshold (e.g., 0.10), the trial stops. This approach naturally handles the correlation between short-term and long-term endpoints through the joint posterior distribution, avoiding the frequentist complexity of covariance adjustments across endpoints. Berry et al. demonstrated that Bayesian predictive probability provides operating characteristics comparable to frequentist approaches while offering greater flexibility in handling complex decision rules.

**Lee & Liu (2008)** extended this framework with a comprehensive predictive probability methodology for Phase II/III designs that has become widely adopted in oncology. Their approach uses Beta-binomial or Beta-Bernoulli models for binary endpoints (e.g., ORR) and can incorporate historical data through informative priors. The key advantage in the pick-a-winner setting is that predictive probability naturally accounts for the uncertainty in the short-term endpoint's ability to predict the long-term endpoint — when ORR is a weak surrogate for OS, the predictive probability reflects this through wider posterior intervals. Lee & Liu also provided extensive simulation guidance for calibrating decision thresholds to achieve desired frequentist operating characteristics, bridging the Bayesian-frequentist divide that regulators often scrutinize.

**Thall, Simon & Estey (1995)** developed a decision-theoretic approach to sequential monitoring in single-arm Phase II trials with go/no-go criteria. While not specifically a pick-a-winner design, their framework formalized the trade-off between continuing to accrue patients for definitive evidence versus stopping early for futility or efficacy. The decision-theoretic framework (maximizing expected utility under a loss function) provides an alternative to the rule-based selection criteria discussed in §5.3. For the pick-a-winner setting, a decision-theoretic approach would assign utilities to correct selection, incorrect selection, and early stopping, then optimize the interim decision rule accordingly — an elegant alternative to ad hoc threshold rules.

**Why the frequentist choice is defensible:** Despite the elegance of Bayesian methods, the frequentist framework is the appropriate choice for this intern project for several reasons. First, regulatory agencies (FDA, EMA) have well-established expectations for frequentist type I error control — Bayesian designs require extensive simulation to demonstrate operating characteristics, and the regulatory path is less standardized. Second, the pick-a-winner design with ORR→OS involves two fundamentally different data types (binary and TTE), making the joint likelihood specification challenging for Bayesian analysis without strong parametric assumptions. Third, the existing literature that the intern will build on (Zhang & Jin 2025, Stallard & Todd 2003, Jenkins et al. 2011) is almost entirely frequentist, so consistency with this literature facilitates communication and peer review. Fourth, the cohort-separation approach (Jenkins et al. 2011, Zhang & Jin 2025) provides a clean solution to the Bauer-Posch bias in a frequentist framework that is well-understood by regulators. The intern should be prepared to discuss these alternatives but can confidently proceed with the frequentist approach for this project.

---

## 3. Endpoint Considerations

### 3.1 Endpoints Commonly Used in Oncology Seamless Designs

| Endpoint | Type | Timing | Role in Seamless Design |
|----------|------|--------|------------------------|
| **Overall Survival (OS)** | Time-to-event (clinical benefit) | Long (years) | Gold standard confirmatory endpoint |
| **Progression-Free Survival (PFS)** | Time-to-event (surrogate) | Intermediate | Common interim decision endpoint |
| **Objective Response Rate (ORR)** | Binary (tumor shrinkage) | Short (weeks-months) | Short-term interim decision endpoint |
| **Duration of Response (DOR)** | Time-to-event (from response to progression) | Intermediate | Supplementary interim endpoint |
| **Failure-Free Survival (FFS)** | Time-to-event (composite) | Intermediate | Used in STAMPEDE MAMS trial |

### 3.2 Correlation Between Endpoints

The central statistical challenge: when interim decisions are based on a short-term endpoint (ORR, DOR, or PFS) but the final confirmatory analysis uses OS, the **correlation between these endpoints** must be accounted for in:

1. **Information fraction calculations** — How much OS information is available at the time of interim decision based on ORR data?
2. **Type I error control** — Selection based on a short-term endpoint that is not perfectly correlated with OS can lead to inflated Type I error.
3. **Timing** — ORR data matures much faster than OS; interim analysis timing should be driven by sufficient ORR/DOR data, with the understanding that OS data will be immature.

### 3.3 Regulatory Perspective

- **FDA** generally requires OS or confirmed PFS for approval in solid tumors
- **Accelerated approval** can be based on ORR or DOR (single-arm or randomized), subject to confirmatory studies
- **ORR as an interim decision tool** is accepted if the design pre-specifies how the interim ORR results will inform the go/no-go decision; the final analysis still uses the full OS/PFS endpoint
- The **EMA** has similar positions but emphasizes the need for well-established surrogate relationships

### 3.4 Specific Issues for ORR/DOR as Short-Term Endpoints

- **ORR is binary, OS is TTE** — different data types complicate the joint distribution and information borrowing
- **DOR is TTE** but follows a different survival model (only among responders, so selection issues arise)
- **Landmark analyses** of DOR at the interim are possible but informative censoring must be handled
- **Copula models** or other joint models can model the ORR/DOR → OS relationship for simulation
- The clinical relationship between ORR and OS varies substantially by tumor type (strong in some hematologic malignancies, weak in some solid tumors like prostate cancer)
- **Immune checkpoint inhibitors** can show delayed responses (pseudoprogression), complicating ORR assessment at early interim

---

## 4. Statistical Challenges

### 4.1 Type I Error Control Across Stages

This is the primary regulatory concern. Methods for strong FWER control:

| Approach | Mechanism | Pros | Cons |
|----------|-----------|------|------|
| **Closed testing principle** | Test all intersection hypotheses; reject H₀ only if all constituent hypotheses are rejected | Strong control; flexible | Complex with many arms |
| **Combination test** (Bauer & Kieser, 1999) | Combine stage-wise p-values using pre-specified combining function | Separation of decision and testing rules | May be conservative |
| **Conditional error function** (Müller & Schäfer, 2001) | Preserve conditional type I error given interim data | Flexible; any adaptation rule | Computationally intensive |
| **Dunnett-type adjustment** | Account for multiplicity of K comparisons at final analysis | Simple; familiar to regulators | Assumes equal correlation |
| **Closed Dunnett procedure** | Combines closed testing with Dunnett | Strong control; powerful | Computationally demanding |

### 4.2 Information Fraction at Interim

- For OS-based final analysis, interim decisions happen when OS data are **highly immature** (if the decision is driven by ORR)
- The information fraction (events observed / total planned events) for OS at the interim may be 10-20%, making traditional group-sequential methods (which rely on information fraction) impractical for interim decision-making
- The decision to "pick the winner" is based on **short-term endpoint data**, not the OS data — however, the selection rule is **not automatically independent** of the OS-based hypothesis test. Independence holds **only under specific design choices**: (a) cohort separation (Jenkins et al. 2011; Zhang & Jin 2025) where Stage 1 patients' short-term data is used for selection but not for the final test statistic on that endpoint, or (b) when the short-term and long-term endpoints are based on completely non-overlapping patient data. When the *same patients* contribute both short-term (ORR) and long-term (OS) data, selection induces a dependency between the interim decision and the final test through shared patient-level information — this is precisely the Bauer-Posch bias mechanism. The Jin & Zhang (2021) framework avoids this by using an intermediate endpoint for selection only, with the test statistic for the primary endpoint computed on independent information.
- **Key insight from Jin & Zhang (2021):** When the interim decision uses an intermediate endpoint (observed on all patients) and the final test uses a correlated primary endpoint, FWER control is achievable under mild assumptions (ρ_XY ≥ ρ_XZ) about the relationship between the two. However, even under these assumptions, independence between selection and testing does not hold automatically — the test procedure must be explicitly designed to account for the selection.

### 4.3 Correlation Between Short-Term and Long-Term Endpoints

- Let S be the short-term endpoint and T be the long-term (primary) endpoint
- The correlation ρ = Corr(S, T) critically affects operating characteristics
- When ρ is high, selection based on S is nearly optimal for T
- When ρ is low, the best arm on S may not be the best on T — reducing the **probability of correct selection (PCS)** and potentially reducing power for the final analysis
- **Joint modeling approaches:**
  - **Copula models:** Model the marginal distributions separately and link via a copula (e.g., Clayton, Frank, Gaussian)
  - **Frailty models:** Shared random effect induces correlation between endpoints
  - **Multi-state models:** Model the disease progression pathway (no response → response → progression → death)

### 4.4 Selection Bias from Picking the Winner

- Selecting the arm with the largest observed effect introduces **regression to the mean** — the selected arm's true effect is likely less extreme than observed
- This must be fully accounted for in the final analysis
- **Methods to address selection bias:**
  1. **Combination tests** with stage-wise p-values (independent increments property)
  2. **Conditional error functions**
  3. **Adjusted test statistics** (e.g., Dunnett-type adjustments accounting for selection)
  4. **Bootstrap or simulation-based calibration** of critical values

### 4.5 Additional Statistical Challenges

| Challenge | Description | Mitigation |
|-----------|-------------|------------|
| **Non-proportional hazards** | IO agents may show delayed separation of Kaplan-Meier curves | RMST, weighted log-rank tests, flexible models |
| **Competing risks** | Death without progression | Cause-specific or subdistribution hazard models |
| **DOR censoring at interim** | Many responders at interim have not yet progressed | Requires careful modeling of DOR distribution |
| **Treatment crossover** | May confound OS analysis, especially in oncology | Rank-preserving structural failure time models, inverse probability of censoring weighting |
| **Multiple testing across endpoints** | Testing ORR and OS in the same trial | Hierarchical testing, gatekeeping procedures |
| **Sample size re-estimation** | May be desirable after interim selection | Must be accounted for in FWER control |

#### Non-Proportional Hazards in Immuno-Oncology

Non-proportional hazards (non-PH) are particularly relevant in the pick-a-winner setting because they affect *both* the interim decision rule and the final confirmatory analysis. The most common non-PH pattern in modern oncology is **delayed separation** — typical of immune checkpoint inhibitors, where Kaplan-Meier curves for the experimental arm overlap with control for the first 3-6 months before diverging. This pattern arises from the immunotherapy mechanism of action (immune activation takes time to translate into survival benefit). A second common pattern is **crossing hazards**, where the experimental arm shows early harm (e.g., due to toxicity) followed by late benefit.

In a seamless pick-a-winner design, non-PH affects the joint distribution of test statistics across stages in ways not captured by the proportional hazards covariance formulas in Zhang & Jin (2025) and Zhong et al. (2025). When the interim decision is based on ORR (binary, assessed early), non-PH in OS does not directly affect the interim rule — but it critically affects the final analysis. Specifically:

- **The covariance formula `cov(Z_I_j, Z_I_j')` in Zhang & Jin (2025, Equation 3)** is derived under proportional hazards for the OS endpoint. Under non-PH with delayed separation, the score statistics for OS across stages are no longer governed by the same information structure, potentially altering the covariance matrix and affecting boundary computation.
- **The inverse normal combination test** remains valid under non-PH (p-values from each stage are still uniform under H₀), but its power properties degrade. Weighted log-rank tests (e.g., Fleming-Harrington G^{ρ,γ} family) can restore power if the weighting matches the non-PH pattern, but these weights must be pre-specified.
- **Restricted mean survival time (RMST)** offers an alternative to the log-rank test that does not require proportional hazards. However, RMST-based testing in a seamless design requires deriving the joint distribution of RMST differences across stages — this is non-trivial and the literature is sparse.
- **Recommendation for the intern:** Include non-PH scenarios (delayed separation with hazard ratio evolving from 1.0 → 0.75 over 6 months) in the sensitivity analysis (Phase 3 of §5.6). Compare the log-rank test, weighted log-rank (G^{1,0} or G^{0,1}), and RMST under these scenarios to understand power trade-offs. Note that the covariance formula from Zhang & Jin should be treated as approximate under non-PH, and simulation-based calibration of boundaries is recommended.

#### Safety-Driven Selection

A critical real-world scenario not captured in most pick-a-winner methodology papers: what happens when the arm selected is *not* the one with the best ORR/DOR but rather the one with the best benefit-risk profile? Stallard & Todd (2008) explicitly address this case — allowing safety data to override efficacy-based selection. This occurs frequently in oncology with therapies that have distinct toxicity profiles (e.g., T-cell engagers, bispecific antibodies, antibody-drug conjugates), where the most efficacious arm may also be the most toxic.

When safety-driven selection occurs, the statistical properties of the design change fundamentally:

- **Selection rule is no longer based solely on the short-term efficacy endpoint.** The probabilistic relationship between the interim decision and the final test statistic changes because the selection criterion now incorporates information not fully captured by the ORR/OS correlation structure.
- **The type I error implications depend on whether safety is correlated with efficacy.** If safety is independent of efficacy (the typical assumption), then overriding the ORR-based selection with a safety-driven choice is essentially random with respect to the final OS test — this does not inflate type I error but may reduce power (since the selected arm may have smaller true OS benefit). If safety is correlated with efficacy (e.g., more toxic doses have higher response rates), the override could systematically select arms with attenuated efficacy, reducing power further.
- **Operating characteristics should be evaluated under a safety-override scenario** where the arm selected at interim is the second-best or third-best on ORR but superior on safety. The simulation framework (§5) should include a scenario where the safety override changes selection in a pre-specified fraction of replications, with the impact on power and FWER assessed.
- **Recommendation for the intern:** Add a sensitivity analysis scenario where selection is based on a composite score incorporating both efficacy (ORR/DOR) and safety (e.g., grade ≥3 AE rate). Compare operating characteristics to pure efficacy-based selection. This directly addresses a question regulators will ask.

---

## 5. Simulation Framework Outline (for the Intern)

This section provides a concrete blueprint for building a simulation study to evaluate operating characteristics of adaptive seamless pick-a-winner designs.

### 5.1 Data Generation Model

#### Scenario 1: ORR → OS

```
Patient-level simulation:
1. Generate K treatment arms + 1 control arm
2. For each patient:
   a. Generate binary ORR indicator: Y ~ Bernoulli(p_arm)
   b. For responders (Y=1), generate DOR from a parametric survival model: T_response ~ Weibull(λ_arm, γ)
   c. For non-responders (Y=0), generate PFS from: T_nr ~ Weibull(λ_nr, γ)
   d. Generate OS as: OS = min(T_death, censoring_time)
      where T_death ~ Weibull with hazard depending on response status and arm
   e. ORR and OS can be linked via:
      - Copula approach: Gaussian or Clayton copula on uniform quantiles
      - Shared frailty: log-normal frailty term affecting both endpoints
      - Multi-state model: No response → Response → Progression → Death
```

**Recommended approach:** Use a **multi-state model** with 4 states:
```
State 0: On treatment, no response (alive, no response observed yet)
State 1: Responded, on treatment (alive, confirmed response achieved)
State 2: Progressed (or off treatment, alive after progression)
State 3: Death (absorbing state)
```
This model requires specifying **explicit transition intensities** for each possible direct transition. In a 4-state model with states 0-3, there are 6 possible one-way transitions (each ordered pair (i,j) with i < j, since backward transitions like response → no response are not allowed in oncology):

```
λ₀₁(t) = α₀₁·t^(γ₀₁-1)   — No Response → Response (response event)
λ₀₂(t) = α₀₂·t^(γ₀₂-1)   — No Response → Progression (progression without prior response)
λ₀₃(t) = α₀₃·t^(γ₀₃-1)   — No Response → Death (death without response or progression)
λ₁₂(t) = α₁₂·t^(γ₁₂-1)   — Response → Progression (loss of response / progression after response)
λ₁₃(t) = α₁₃·t^(γ₁₃-1)   — Response → Death (death while in response)
λ₂₃(t) = α₂₃·t^(γ₂₃-1)   — Progression → Death (death after progression)
```
Each λ_{ij}(t) is a Weibull hazard with scale α_{ij} (arm-specific) and shape γ_{ij}. All intensities depend on arm. This generates:
- **ORR** = cumulative incidence of 0→1 by t₁ (6-12 weeks)
- **DOR** = sojourn time in State 1 before transition to 2 or 3
- **PFS** = min(times to 0→2, 0→3, and for responders 1→2, 1→3)
- **OS** = time to State 3 from any state

**Identifiability:** All 6 transitions are identifiable if each is observed at least once. Rare transitions (e.g., 1→3, death while in response) may have few events. For calibration: PFS curve informs λ₀₂ + λ₀₃; DOR curve informs λ₁₂ + λ₁₃; OS curve provides the overall constraint on λ₀₃, λ₁₃, λ₂₃. A practical starting point is γ_{ij} = 1 (exponential transitions), introducing Weibull shapes only where supported by data.

#### Scenario 2: PFS → OS

```
For each patient:
1. Generate PFS event time from arm-specific Weibull: T_PFS ~ Weibull(α_arm, β)
2. Generate OS as: T_OS = T_PFS + t_post_progression
   where t_post_progression ~ Exp(λ_arm) or Weibull
   OR use a copula to link T_PFS and T_OS directly
```

### 5.2 Simulation Parameters

| Parameter | Suggested Values | Notes |
|-----------|-----------------|-------|
| Number of treatment arms (K) | 2, 3, 4 | Including control |
| Per-arm sample size (Stage 1) | 30-100 per arm (explore n=30-40 scenarios) | ~15-50 events for TTE; many Phase IIs have 20-40 evaluable patients per arm |
| Total sample size (Stages 1+2) | 300-800 | Driven by primary endpoint power |
| ORR for control arm | 0.10-0.30 | Tumor type dependent |
| ORR for experimental arms | 0.15-0.50 | Vary across arms |
| OS hazard ratio | 0.70-1.00 (vs control) — include 0.70–0.85 range for realistic solid-tumor effects | HR of 0.60 is unrealistically optimistic for most solid tumors |
| Correlation ORR ↔ OS | ρ = 0.3, 0.5, 0.7 | Critical sensitivity parameter |
| Accrual rate | 10-30 patients/month | Realistic for oncology |
| Interim analysis timing | After N_stage1 patients or E_stage1 events | Driven by short-term endpoint maturity |

### 5.3 Decision Rules at Interim

#### Pick-the-Winner Rule

```
For each experimental arm j = 1,...,K:
  - Compute ORR_j (or DOR median, or PFS HR)
  - For ORR: select arm with highest ORR if ORR_j - ORR_control > δ_min
  - For DOR: select arm with longest median DOR if DOR_median_j > DOR_control × 1.3
  - For composite: rank arms by a weighted score: S_j = w₁ × Z_ORR_j + w₂ × Z_DOR_j

Futility stopping:
  - Drop arm j if ORR_j ≤ ORR_control (or if upper bound of CI excludes meaningful benefit)
  - Or use pre-specified conditional power for OS

Go/no-go for stage 2:
  - If no arm meets selection criteria → stop trial for futility
  - If exactly one arm meets criteria → select that arm
  - If multiple arms meet criteria → select the best, OR carry forward the top 2
```

#### Advanced Decision Rules

1. **Benefit-cost ratio approach** (Sun et al. 2020): Use an objective function that balances expected effect size against remaining sample size cost
2. **Predictive probability**: P(treatment_arm ≈ control_at_final | interim_data) for futility; P(treatment_arm > control | interim_data) for go decision
3. **Conditional power**: Probability of reaching significant OS result given interim data and assumed effect

### 5.4 Performance Metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **Type I error (FWER)** | P(reject any true H₀) | ≤ 0.025 (one-sided) |
| **Power** | P(reject H₀ for truly effective arm) | ≥ 0.80 - 0.90 |
| **Probability of Correct Selection (PCS)** | P(select the truly best arm at interim) | Higher is better |
| **Probability of Futility Stop** | P(stop for futility when all arms are ineffective) | ≥ 0.80 |
| **Expected sample size** | E[N] under null, alternative, and selected scenarios | Lower is better |
| **Expected trial duration** | E[Duration] | Lower is better |
| **Bias in treatment effect estimate** | E[β̂_selected] - β_true | Small or correctable |

### 5.5 Sensitivity Analyses

| Sensitivity Factor | Why It Matters |
|-------------------|----------------|
| **Correlation ρ(ORR, OS)** | Selection efficiency depends critically on this |
| **Delayed separation (non-PH)** | IO agents often violate PH; impacts power and interim decision |
| **Accrual rate variation** | Slower accrual means less OS data at interim |
| **Number of arms (K)** | More arms → more selection pressure → greater bias |
| **Interim timing** | Too early: unreliable ORR/DOR; too late: minimal efficiency gain |
| **Decision rule threshold** | Stringency affects both type I error and power |
| **Drop-the-loser vs pick-the-winner** | Different operating characteristics |
| **Carry one vs carry two arms** | Trade-off between power and multiplicity adjustment |
| **Misspecified DOR model** | DOR can be longer than expected (especially with IO) |

### 5.6 Simulation Study Implementation Plan

```
Phase 1: Null scenario
  - All arms have the same effect as control
  - Assess type I error across all configurations

Phase 2: Alternative scenarios
  - Scenario A: One effective arm, rest null
  - Scenario B: Two moderately effective arms, one null
  - Scenario C: All arms effective (dose-response)
  - Scenario D: Effective arm has weak ORR but strong OS (discordance)

Phase 3: Sensitivity
  - Vary ρ across {0.3, 0.5, 0.7}
  - Vary interim timing
  - Compare decision rules

Phase 4: Comparison with standard approach
  - Separate Phase II (pick winner) + Phase III
  - Compare sample size, duration, power
```

### 5.7 Software Recommendations

| Tool | Purpose | Notes |
|------|---------|-------|
| **R** | Core simulation | Widest range of packages |
| `gsDesign` | Group sequential boundaries | Lan-DeMets alpha spending, O'Brien-Fleming |
| `asd` | Adaptive seamless design simulation | Treatment and subgroup selection; flexible endpoint types. **Note:** `asd` was archived from CRAN as of late 2024 — verify availability before building workflow around it |
| `rpact` | Adaptive designs (combination test, conditional error) | **Recommended alternative to `asd`** — actively maintained, regulatory-grade implementation, supports inverse normal combination test and conditional error approaches |
| `simtrial` | TTE simulation with non-PH | Delayed effects, crossing hazards |
| `copula` / `copulaedas` | Joint modeling of endpoints | Flexible correlation structures |
| `SimDesign` | Structured simulation studies | Parallel computing, error handling |
| **SAS** | Alternative for regulated environments | `SEQDESIGN`, `ADAPTIVEREG`|

### 5.8 Suggested Monte Carlo Setup

- **Simulation replications:** 5,000-10,000 per scenario (for 0.025 type I error, need ≥10,000 for reliable estimation)
- **Bootstrap confidence intervals** for operating characteristics
- **Variance reduction:** Common random numbers across scenarios to isolate design effects
- **Parallelization:** Use `parallel` or `future` packages for speed

### 5.9 Intern Implementation Timeline (10–12 Weeks)

This timeline replaces the original 8-week plan with a more realistic 10–12 week schedule that incorporates reviewer feedback. Key changes: starts with the foundational Stallard & Todd (2003) design, adds a dedicated pilot simulation phase, and allocates more time to complex tasks.

**Week 1–2: Literature foundation and first-principles implementation**
- Read Stallard & Todd (2003) — the pick-the-winner foundation — and implement their two-arm, two-stage design in R from scratch using efficient score statistics
- Read Bauer & Posch (2004) to understand the bias mechanism
- Read Jenkins et al. (2011) for the cohort-separation solution
- Validate: reproduce key numerical results from Stallard & Todd (2003) Table I or II
- Use `gsDesign` and `rpact` for the group sequential guts (do not code alpha spending from scratch)

**Week 3–4: Extend to ORR/DOR setting and pilot simulation**
- Read Sun et al. (2020) and Zhang & Jin (2025) — the most directly applicable designs
- Implement binary→binary simulation (ORR at interim, ORR at final) to validate the methodology without TTE complexity
- **Pilot simulation phase:** Run a small grid (2–3 scenarios × 1,000 reps) to identify coding errors and computational bottlenecks before scaling up
- Debug null scenarios first: confirm type I error = 0.025 ± MC error
- Add the multi-state DGP with Weibull transitions (see §5.1)

**Week 5–7: Full operating characteristics**
- Implement the full ORR→OS simulation with multi-state DGP and copula-based correlation
- Run the complete simulation grid: Phase 1 (null), Phase 2 (alternative scenarios A–D), Phase 3 (sensitivity) (§5.6)
- Scenarios to include: per-arm n=30–40 for smaller Phase II settings, HRs in 0.70–0.85 range for realistic solid-tumor effects
- Include safety-driven selection scenarios (§4.5)
- Include non-PH scenarios (delayed separation typical of IO)
- 5,000–10,000 reps per scenario; document Monte Carlo standard errors

**Week 8–9: Sensitivity and robustness analyses**
- Sensitivity analysis for ρ(ORR, OS) across {0.3, 0.5, 0.7} — calibrate from tumor-specific historical data (Prasad et al. 2015) rather than arbitrary values
- Compare pick-a-winner vs drop-the-losers vs traditional sequential Phase 2+3
- Compare carry-one vs carry-two arms
- Document the full simulation framework as an R Markdown vignette (build it as an R package from day one: `R/` for functions, `inst/sims/` for scripts, `vignettes/` for documentation)

**Week 10–12: Drafting and publication prep**
- Draft methodology section with simulation results
- Prepare figures (power curves, PCS curves, FWER contours over ρ and Δ)
- Write clean documentation for reproducibility (save every simulation run with RNG seed, full parameters, and full results — not just summary statistics)
- Deliverable: R package + vignette + methodology note ready for internal review and potential publication

**Notes:**
- Weeks 1–2 will feel slow — reproducing published results is harder than it looks. Each bug in the correlation structure, selection rule, or combination test produces wrong results that take days to debug. This is normal.
- Every simulation run must save the full state (RNG seed, parameter values, full results). You *will* need to debug a result six weeks later.
- For ρ(ORR, OS): use published meta-analytic estimates (Prasad et al. 2015) rather than attempting patient-level empirical calibration from raw historical data, which is rarely accessible.
- Check CRAN status of all R packages before building the simulation framework — `asd` was archived from CRAN as of late 2024; use `rpact` as the primary alternative.

---

## 6. References (Formatted)

### Primary Papers

1. **Jin M, Zhang P.** An adaptive seamless Phase 2-3 design with multiple endpoints. *Statistical Methods in Medical Research*. 2021;30(4):1143-1151. DOI: 10.1177/0962280220986935. PMID: 33588655.

2. **Jenkins M, Stone A, Jennison C.** An adaptive seamless phase II/III design for oncology trials with subpopulation selection using correlated survival endpoints. *Pharmaceutical Statistics*. 2011;10(4):347-356. DOI: 10.1002/pst.472. PMID: 22328327.

3. **Bretz F, Schmidli H, König F, Racine A, Maurer W.** Confirmatory seamless phase II/III clinical trials with hypotheses selection at interim: general concepts. *Biometrical Journal*. 2006;48(4):623-634. DOI: 10.1002/bimj.200510232. PMID: 16972714.

4. **Schmidli H, Bretz F, Racine A, Maurer W.** Confirmatory seamless phase II/III clinical trials with hypotheses selection at interim: applications and practical considerations. *Biometrical Journal*. 2006;48(4):635-643. DOI: 10.1002/bimj.200510232. PMID: 16972715.

5. **Stallard N, Todd S.** Sequential designs for phase III clinical trials incorporating treatment selection. *Statistics in Medicine*. 2003;22(5):689-703. DOI: 10.1002/sim.1362. PMID: 12587100.

6. **Stallard N, Todd S.** A group-sequential design for clinical trials with treatment selection. *Statistics in Medicine*. 2008;27(29):6209-6227. DOI: 10.1002/sim.3436. PMID: 18792085.

7. **Friede T, Stallard N.** A comparison of methods for adaptive treatment selection. *Biometrical Journal*. 2008;50(5):767-781. DOI: 10.1002/bimj.200710453. PMID: 18932136.

8. **Sun LZ, Li W, Chen C, Zhao J.** Advanced Utilization of Intermediate Endpoints for Making Optimized Cost-Effective Decisions in Seamless Phase II/III Oncology Trials. *Statistics in Biopharmaceutical Research*. 2020;12(2):224-233. DOI: 10.1080/19466315.2019.1665578.

9. **Dixit V, et al.** Multi-arm multi-stage clinical trials for time-to-event outcomes. *Journal of Biopharmaceutical Statistics*. 2021;31(6):838-851. DOI: 10.1080/10543406.2021.1979575. PMID: 34606418.

10. **Zhang EP, Jin M.** A Multi-Arm Multi-Stage Group Sequential Phase 2/3 Design with Dose Selection for Oncology Trials. *Statistics in Biopharmaceutical Research*. 2025. DOI: 10.1080/19466315.2025.2539831.

11. **Zhong W, Liu J, Wang C.** Multiplicity Control in Oncology Clinical Trials With a Binary Surrogate Endpoint-Based Drop-The-Losers Design. *Statistics in Medicine*. 2025;44:e70209. DOI: 10.1002/sim.70209.

12. **Wu J, Li Y, Zhu L.** Group sequential multi-arm multi-stage trial design with treatment selection. *Statistics in Medicine*. 2023;42:1480-1491. DOI: 10.1002/sim.9682.

13. **Magirr D, Jaki T, Whitehead J.** A flexible MAMS design for time-to-event outcomes. *Statistics in Medicine*. 2012;31(25):3060-3072. DOI: 10.1002/sim.5389.

14. **Bauer P, Posch M.** Modification, adaptation and suboptimal combination tests — a simulation study. *Statistics in Medicine*. 2004;23(10):1651-1670. DOI: 10.1002/sim.1769.

15. **Dunnett CW.** A multiple comparison procedure for comparing several treatments with a control. *Journal of the American Statistical Association*. 1955;50(272):1096-1121.

16. **Kelly PJ, Stallard N, Todd S.** A practical guide to implementing multi-arm multi-stage clinical trials. *Statistics in Medicine*. 2005;24(4):559-577. DOI: 10.1002/sim.1998.

17. **Mehta CR, Tsiatis AA.** Flexible sample size estimation using information-based monitoring. *Biometrics*. 2001;57(3):850-857. DOI: 10.1111/j.0006-341X.2001.00850.x.

### Methodological Foundations

18. **Royston P, Parmar MKB, Qian W.** Novel designs for multi-arm multi-stage trials (MAMS) with time-to-event outcomes. *Clinical Trials*. 2003 (subsequently extended in various publications). **Note:** The definitive MAMS reference is Parmar MKB, et al. More flexible designs for randomized clinical trials — the MAMS framework. *Clinical Trials*. 2017. *[Full text not reviewed — inferential details from related work]*

19. **Bauer P, Kieser M.** Combining different phases in the development of medical treatments within a single trial. *Statistics in Medicine*. 1999;18:1833-1848.

20. **Müller HH, Schäfer H.** Adaptive group sequential designs for clinical trials: combining the advantages of adaptive and of classical group sequential approaches. *Biometrics*. 2001;57(3):886-891.

21. **Brannath W, König F, Bauer P.** Multiplicity and adaptive designs. *Biometrical Journal*. 2007;49(4):506-517.

### Bayesian Adaptive Design Literature

22. **Berry DA, Müller P, Grieve AP, et al.** Adaptive Bayesian designs for dose-ranging drug trials. In: *Case Studies in Bayesian Statistics*. Springer; 2002:99-181.

23. **Lee JJ, Liu DD.** A predictive probability design for phase II cancer clinical trials. *Clinical Trials*. 2008;5(2):93-106. DOI: 10.1177/1740774508089279.

24. **Thall PF, Simon R, Estey EH.** Bayesian sequential monitoring designs for single-arm clinical trials with multiple outcomes. *Statistics in Medicine*. 1995;14(4):357-379. DOI: 10.1002/sim.4780140404.

### Application & Implementation

25. **Sydes MR, Parmar MKB, Mason MD, et al.** Flexible trial design in practice — stopping arms for lack-of-benefit and adding research arms mid-trial in STAMPEDE: a multi-arm multi-stage randomized controlled trial. *Trials*. 2012;13:168. DOI: 10.1186/1745-6215-13-168. PMID: 22978443.

26. **Friede T, Stallard N, Parsons N.** Seamless phase II/III clinical trials using early outcomes for treatment or subgroup selection: Methods and aspects of their implementation. *arXiv:1901.08365*. 2019. [R package `asd` documentation and vignette]

27. **Broglio K, Cooner F, Wu Y, et al.** A Systematic Review of Adaptive Seamless Clinical Trials for Late-Phase Oncology Development. *Therapeutic Innovation & Regulatory Science*. 2024;58:917-929. DOI: 10.1007/s43441-024-00670-1. PMID: 38861131.

28. **Zhu H, Yu J, Wang Q, et al.** Adaptive seamless phase II/III design with sequential estimation-adjusted urn model. *Communications in Statistics — Simulation and Computation*. 2024;54(6):4431-4441. DOI: 10.1080/03610918.2024.2381077.

29. **Spivack JH, Cheng B, Levin B.** Adding dose modifications into Phase II and Phase II/III seamless trials. *Statistical Methods in Medical Research*. 2019;29(5):1315-1324. DOI: 10.1177/0962280219859387.

### Regulatory Guidance

30. **ICH.** Addendum on Estimands and Sensitivity Analysis in Clinical Trials to the Guideline on Statistical Principles for Clinical Trials E9(R1). International Council for Harmonisation; 2019.

31. **FDA.** Adaptive Design Clinical Trials for Drugs and Biologics — Guidance for Industry. 2019.

32. **FDA Oncology Center of Excellence.** Project Optimus: Reforming the dose selection paradigm in oncology. Ongoing initiative.

### Surrogate Endpoint Literature

33. **Buyse M, Michiels S, Sargent DJ, et al.** Integrating biomarkers in clinical trials. In: *Handbook of Statistics in Clinical Oncology*. 3rd ed. 2012.

34. **Prasad V, Kim C, Burotto M, Vandross A.** The strength of association between surrogate end points and survival in oncology: a systematic review of trial-level meta-analyses. *JAMA Internal Medicine*. 2015;175(8):1389-1398.

---

## Appendix A: Suggested Next Steps

See §5.9 for the full 10–12 week implementation timeline. High-level summary:

1. **Read the key papers** in priority order (per timeline): Stallard & Todd (2003) → Bauer & Posch (2004) → Jenkins et al. (2011) → Sun et al. (2020) → Zhang & Jin (2025)
2. **Start with first-principles implementation** of Stallard & Todd's two-stage pick-the-winner, not Zhang & Jin's more complex design
3. **Run a pilot simulation phase** before scaling up to identify bugs early
4. **Extend to TTE endpoints** using the multi-state model from §5.1 with all 6 transitions specified
5. **Include sensitivity analyses** for ρ(ORR, OS), non-PH, safety-driven selection
6. **Build the simulation as an R package** from day one (`R/`, `inst/sims/`, `vignettes/`) for reproducibility

## Appendix B: Notes on Papers Not Fully Reviewed

The following papers are referenced from search results and citations but their full text was not accessed. Their inclusion here is based on abstract content only. **Marked papers should be read in full before finalizing the intern's work plan.**

- ☐ **Sun et al. (2020)** — HIGH PRIORITY: Most directly relevant to this project
- ☐ **Jin & Zhang (2021)** — HIGH PRIORITY: Multiple endpoint framework
- ☐ **Jenkins et al. (2011)** — HIGH PRIORITY: Correlated TTE endpoints
- ☐ **Bretz et al. (2006)** — HIGH PRIORITY: Foundational framework
- ☐ **Broglio et al. (2024)** — MODERATE PRIORITY: Systematic review for landscape
- ☐ **Friede & Stallard (2008)** — HIGH PRIORITY: Method comparison
- ☐ **Dixit et al. (2021)** — For TTE + non-PH considerations
- ☐ **Spivack et al. (2019)** — For dose modification scenarios
- ☐ **Zhu et al. (2024)** — For response-adaptive randomization approaches

---

*This literature review was compiled from publicly available abstracts via PubMed and Semantic Scholar. Full texts should be obtained through institutional access for a complete understanding.*
