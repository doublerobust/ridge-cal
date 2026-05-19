# NN-Cal Extension: Neural Network Calibration of External Prognostic Scores

**Research plan for extending Ridge-Cal with flexible calibration**

---

## 1. Motivation

The current Ridge-Cal assumes a *linear* calibration model: $\hat{S}^{(cal)} = \beta_1 \hat{S}^{(ext)} + \beta_\mathcal{C}^T W_\mathcal{C}$. This is sufficient when:

- The external score captures most non-linear structure
- Miscalibration is approximately linear in the calibration covariates
- No interactions among calibration covariates matter for the correction

These assumptions may fail when the external model is misspecified in complex ways, e.g., when a covariate has a non-linear or threshold effect in the trial population, or when two calibration covariates interact in their effect on prognosis.

A more flexible calibration using a small neural network with a bottleneck layer addresses these cases directly. It also makes the LoRA analogy literal (not just conceptual), strengthening the paper's framing.

---

## 2. Non-Linear Data Generation

### 2.1 Extending the Current DGP

Current: $\lambda(t \mid W) = \lambda_0(t) \exp(\beta^T W + \beta_{trt} A)$

Extension: add non-linear effects in the calibration covariates

$$\lambda(t \mid W) = \lambda_0(t) \exp\!\big(\underbrace{\beta^T W}_{\text{linear}} + \underbrace{f(W_\mathcal{C})}_{\text{non-linear correction}} + \beta_{trt} A\big)$$

where $f$ introduces:

| Non-linearity | Example | Clinical Rationale |
|:--------------|:--------|:-------------------|
| **Threshold effect** | $f(\text{CRP}) = 0.5 \cdot I(\text{CRP} > 1.5)$ | Biomarker effect only above clinical threshold |
| **Interaction** | $f(\text{sex, CRP}) = 0.3 \cdot \text{sex} \cdot \text{CRP}$ | CRP effect differs by sex (realistic in inflammation) |
| **U-shaped** | $f(\text{age}) = 0.4 \cdot (\text{age} - 0.5)^2$ | Worse prognosis at extremes of age |
| **Saturation** | $f(\text{LDH}) = 0.6 \cdot \tanh(\text{LDH} / 2)$ | LDH effect plateaus at high values |

The external model $\hat{S}^{(ext)}$ is still **trained on a Cox PH** (linear), so it completely misses these non-linearities. This creates a realistic scenario where:

- Under linear shift: linear ridge calibration works fine
- Under non-linear shift: neural calibration should outperform linear ridge

### 2.2 Scenarios

| ID | Scenario | Non-linearity | Expected result |
|:--:|:---------|:-------------|:----------------|
| NL-1 | Threshold CRP | CRP effect only > 1.5 SD | NN cal > linear cal |
| NL-2 | Sex × CRP interaction | CRP slope differs by sex | NN cal > linear cal |
| NL-3 | U-shaped age | Quadratic age effect | NN cal > linear cal |
| NL-4 | Combined | All three + linear shift | NN cal >> linear cal |
| NL-5 | No shift (linear) | None (current Scenario 1) | linear cal ≈ NN cal |
| NL-6 | Linear shift only | Current Scenario 3 | linear cal ≈ NN cal |

Scenarios NL-5 and NL-6 verify that NN calibration doesn't *hurt* when the simpler model is sufficient.

---

## 3. Neural Network Calibration Architecture

### 3.1 Model Design

```
Input layer (c + 1 neurons)        S_ext, sex, marker_x, CRP, albumin, LDH
        │
    [Fully connected + ReLU]
        │
  Hidden layer (h neurons)          h = 8 (or 2×LoRA rank)
        │
    [Fully connected + ReLU]
        │
  Bottleneck layer (r neurons)      r = 4 (LoRA rank hyperparameter)
        │
    [Fully connected + linear]
        │
Output layer (1 neuron)             S_cal (calibrated score)
```

### 3.2 Loss Function

$$\mathcal{L} = -\ell_{Cox}(\hat{S}^{(cal)}; \mathcal{D}_{trial}) + \lambda \sum_{l=1}^{L} ||W^{(l)}||_F^2$$

where:
- $\ell_{Cox}$ is the Cox partial log-likelihood using $\hat{S}^{(cal)}$ as the single predictor
- $\lambda$ penalizes all network weights (ridge/Frobenius norm)
- $\ell_1$ / dropout / batch norm deliberately excluded (would complicate the Type I error argument)

### 3.3 LoRA Connection

The bottleneck layer makes the analogy exact:
- **Pre-trained model:** external score $\hat{S}^{(ext)}$
- **Fine-tuning module:** small NN that maps $(\hat{S}^{(ext)}, W_\mathcal{C}) \to \hat{S}^{(cal)}$
- **Low-rank constraint:** bottleneck width $r$ limits the update's rank
- **Regularization:** ridge penalty $\lambda$ on all weights (equivalent to weight decay)
- **Rank selection:** cross-validated over $r \in \{2, 4, 8\}$, analogous to LoRA rank selection

### 3.4 Implementation

**Option A: R + torch**
```r
library(torch)
nn_cal <- nn_module(
  "NNCal",
  initialize = function(p_input, h = 8, r = 4) {
    self$fc1 <- nn_linear(p_input, h)
    self$fc2 <- nn_linear(h, r)     # bottleneck
    self$fc3 <- nn_linear(r, 1)
  },
  forward = function(x) {
    x %>% nnf_relu(self$fc1(.)) %>%
          nnf_relu(self$fc2(.)) %>%
          self$fc3(.)
  }
)
# Custom loss: Cox PH partial likelihood + ridge penalty
```

**Option B: Python + PyTorch** (for simulation, then port to R)

```python
import torch
class NNCal(torch.nn.Module):
    def __init__(self, p, h=8, r=4):
        super().__init__()
        self.net = torch.nn.Sequential(
            torch.nn.Linear(p, h), torch.nn.ReLU(),
            torch.nn.Linear(h, r), torch.nn.ReLU(),  # bottleneck
            torch.nn.Linear(r, 1)
        )
    def forward(self, x):
        return self.net(x).squeeze()

def cox_loss(S, T, delta):
    # Standard Cox partial likelihood
    # S = predicted scores, sorted by T
    idx = T.argsort(descending=True)
    S_sorted = S[idx]
    delta_sorted = delta[idx]
    log_risk = S_sorted - S_sorted.logcumsumexp()
    return -log_risk[delta_sorted == 1].mean()

def total_loss(S, T, delta, model, lam):
    return cox_loss(S, T, delta) + lam * sum(p.pow(2).sum() for p in model.parameters())
```

Both implementations would be slow for 10K reps. A practical approach: 2,000 reps for NN calibration, same as the linear ridge sensitivity runs.

### 3.5 Optimization Details

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Optimizer | Adam | Standard for small NNs |
| Learning rate | 0.001 | Fixed, no scheduler |
| Epochs | 200 | Sufficient for small network |
| Batch size | Full trial (N=400) | Cox likelihood needs full data |
| λ (ridge) | CV-selected | Same logic as linear ridge |
| r (bottleneck) | CV {2,4,8} | LoRA rank selection |
| h (hidden) | 8 | 2× max rank, small enough |

---

## 4. Expected Results

### 4.1 Hypotheses

1. **Under linear shift:** NN-Cal ≈ Ridge-Cal ≈ Full Model > PROCOVA
2. **Under non-linear shift:** NN-Cal > Ridge-Cal > PROCOVA (gap widens with non-linearity)
3. **Under no shift:** NN-Cal ≈ Ridge-Cal ≈ PROCOVA (no penalty for flexibility)
4. **Type I error:** NN-Cal ≈ nominal (primary analysis preserves validity)
5. **Bias:** NN-Cal < Ridge-Cal under non-linear shift, ≈ Ridge-Cal under linear shift

### 4.2 Visualization Plan

- Power comparison across NL-1 through NL-6: bar chart, 4 methods
- Bias comparison: same structure
- Calibration function: plot $\hat{S}^{(cal)}$ vs true LP for linear vs NN calibration (showing where NN captures non-linearity)
- λ and r selection: distribution across reps

---

## 5. Manuscript Impact

Adding NN calibration would:

1. **Address the reviewer's "not fundamentally novel" concern.** The combination of neural network calibration + ridge penalty + blinded data is genuinely new.

2. **Make the LoRA analogy literal.** The bottleneck IS a low-rank adaptation. The ridge penalty IS weight decay on the fine-tuning network.

3. **Strengthen the simulation section.** Six additional non-linear scenarios would make the evaluation much more comprehensive.

4. **Open a clear future direction.** "Adapter-based calibration" in Section 5.4 stops being speculative — it becomes the extension that's already demonstrated.

### 5.1 Risk Assessment

| Risk | Mitigation |
|:-----|:-----------|
| NN calibration too slow for 10K reps | Run 2K reps for NN scenarios; note sample size |
| NN overfits with N=400 | Ridge penalty + bottleneck + CV select λ and r |
| Results show no advantage | If non-linear DGP is strong enough, NN will capture it — design simulations to ensure signal |
| Reviewer says "why not use a spline basis instead?" | Splines are linear in parameters; NN captures interactions naturally. Could include spline as additional comparator |

---

## 6. Implementation Plan

| Step | What | Time estimate |
|:-----|:-----|:-------------|
| 1 | Write non-linear DGP functions | 30 min |
| 2 | Implement NN calibration in R/torch or Python | 1-2 hours |
| 3 | Validate on a single scenario (NL-1, 100 reps) | 15 min |
| 4 | Run all 6 scenarios (2K reps each) | ~2 hours |
| 5 | Analyze results, produce plots | 30 min |
| 6 | Update manuscript: new §3.2 results, §5.4 extension | 1 hour |
| 7 | Push to GitHub | 5 min |

**Total:** ~5-6 hours of work

---

*Draft for discussion. Ready to implement on your go-ahead.*
