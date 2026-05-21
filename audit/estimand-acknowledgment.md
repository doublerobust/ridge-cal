# Estimand Considerations for Ridge-Cal

## Conditional vs. Marginal Estimand in the Ridge-Calibrated Cox Model

### The Issue

The ridge-calibrated Cox model adds a calibrated prognostic score as a covariate to a standard stratified Cox model. This shifts the target estimand:

| Estimator | Conditioning Set | Target Estimand |
|---|---|---|
| Stratified Cox (no covariates) | Randomization strata | Conditional HR \| strata |
| Ridge-cal (stratified Cox + score) | Strata + prognostic score | Conditional HR \| strata, score |
| Unstratified Cox | Nothing (population) | Marginal HR |

Due to the **non-collapsibility** of the hazard ratio (Daniel et al.; Morris et al.), these represent technically distinct estimands under the ICH E9(R1) framework. This is well-documented — the ASA Oncology Estimand Working Group (2025) found that 61.5% of practitioners are unaware that stratified vs. unstratified analyses in non-linear models target different estimands.

### Why the Comparison is Still Valid

The ridge-cal paper's simulation uses a data-generating model with a **constant treatment effect** across all strata and covariate levels (same true HR everywhere). In this setting, both estimators are consistent for the same underlying parameter. The comparison of operating characteristics (bias, coverage, power, Type I error) is therefore **apples-to-apples**.

The estimand distinction becomes practically relevant when there is **treatment effect heterogeneity** — something the current paper does not investigate but acknowledges as a limitation.

### What to Acknowledge in the Paper

**In Methods** (after estimator definitions):

> *We note that the hazard ratio estimand targeted by the ridge-calibrated Cox model is technically distinct from the standard stratified Cox model due to non-collapsibility of the hazard ratio. The standard model estimates a treatment effect conditional on the randomization strata alone, whereas ridge-cal estimates an effect further conditional on the derived prognostic score. Under ICH E9(R1), these represent distinct conditional estimands. However, under the simulation data-generating model with a constant treatment effect across strata and covariate levels, both estimators are consistent for the same underlying parameter, making the comparison of operating characteristics valid.*

**In Discussion / Limitations:**

> *A limitation is that all comparisons assume a constant treatment effect across strata and covariate levels. In settings with treatment effect heterogeneity, the estimands would diverge. The consistency of findings across simulation scenarios suggests the primary conclusions are robust to this distinction, but formal evaluation under heterogeneous effect models is warranted.*

### Recommended Citation

> ASA Oncology Estimand Working Group, Conditional and Marginal Effect Task Force. "Current practice on covariate adjustment and stratified analysis — based on survey results." *BMC Medical Research Methodology* (2025). DOI: 10.1186/s12874-025-02670-7.
