# Uncertainty Design and Optimization (CEE) Project 1.C – Trading Algorithm

This repository contains an optimized several files for a trading algorithm designed to tune parameters for a strategy– maximizing robust returns over a 200-day period. The strategy combines **momentum** and **mean-reversion** signals using a set of tunable design variables. Performance is evaluated using a simulation-based optimization process, with built-in drawdown protection and parameter robustness analysis.

---

## System Overview (some of the .m-files from MATLAB are kept private).

- **Objective**: minimize objective function (- portfolio value) in a constrained optimization problem 
- **Approach**: Trade stocks based on mathematical Q-score, WMA crossover, and z-score spreads  
- **Strategy Features**:
  - Momentum-based quality score (Q-score)
  - Dynamic thresholds for buy/sell decision
  - Trend confirmation via weighted moving average (WMA)
  - Mean-reversion signal from pairs trading (z-score)
  - Risk-managed position sizing and cash allocation
 ![variables](https://github.com/user-attachments/assets/7f371788-9963-43ac-af6d-b6e326b35fb8)

---

## Design Variables

| Variable | Meaning                      | Range       |
|----------|------------------------------|-------------|
| `N`      | Smoothing window (WMA)       | 5–100       |
| `q1`     | Weight on price velocity     | -1 to 1     |
| `q2`     | Weight on acceleration       | -1 to 1     |
| `q3`     | Weight on volatility         | 0 to 1      |
| `fc`     | Fraction of cash to invest   | 0.01–0.99   |
| `B`      | Buy threshold (Q-score)      | 0.001–0.1   |
| `S`      | Sell threshold (Q-score)     | -0.1 to 0   |
| `W`      | WMA crossover window         | 4–30        |

---

## Objective Function

**Goal**: Maximize  
```
Vₜ = Cₜ + Σ_s pₜ,s · Mₜ,s
```
Where:  
- `Cₜ`: cash at day `t`  
- `pₜ,s`: price of stock `s` at day `t`  
- `Mₜ,s`: shares of stock `s` held at day `t`
![activity_performance](https://github.com/user-attachments/assets/50d288a4-a5f2-479d-9c0d-2a6261677545)

**Alternatives Considered**: Sharpe ratio, max drawdown

---

## Constraints & Uncertainty

- No short-selling: `M_d,s ≥ 0`
- Can only buy if: `Σ_s p_d,s · M_d,s ≤ fc · C_d`
- Safety mechanism: liquidate if drawdown exceeds 12% and dynamically re-tighten quality thresholds
- Uncertainty from historical price volatility and return noise
![drawdown_risk](https://github.com/user-attachments/assets/29655265-e68b-4fcd-875f-5e8698436dba)

---

## Trading Logic & Signal Construction

1. **Q-score** = `q1·velocity + q2·acceleration + q3·volatility`
2. **Buy**: if Q-score > B and price > WMA
3. **Sell**: if Q-score < S or price < WMA
4. Optional: Enter trades based on z-score divergence (pairs trading)
![dynamic_thresholds](https://github.com/user-attachments/assets/1e479f52-db25-493a-8324-22079e497702)

---

## Optimization & Results

- **Algorithm**: ORSopt (global search)
- **Best Return**: `$2411.43` (141% gain from $1000 initial)
- **Optimal Parameters**:
  ```
  N = 27, q1 = -0.62, q2 = -0.38, q3 = 0.31
  fc = 0.70, B = 0.042, S = -0.009, W = 4.6
  ```
- **Sensitivity Analysis**:
  - Performance is highly sensitive to `N`, `W`, and `q1`, which were determined during stochastic parameter perturbation
  - Gaussian filtering is used to smooth noisy response surfaces

---

## Robustness Analysis

- Heatmaps generated to analyze Q2/Q3 vs. portfolio value
- Gaussian smoothing reveals stable regions with strong returns
- Emphasizes robust optima over overfit peaks
![qsurfaceplot](https://github.com/user-attachments/assets/aeca0669-0919-4b90-a17b-de57ddc00829)
![qplotsmoothed](https://github.com/user-attachments/assets/947cd786-adbf-45de-850a-c2ff1061f297)

---

## System Constants

- **Initial Cash**: `$1000`
- **Transaction Cost**: `$~2 per trade`

---

## Summary

This trading strategy is built to **balance return and risk** through a blend of statistical signals and robust optimization. The algorithm's modular structure allows for flexible integration of new signals or constraints. See figures for detailed results and sensitivity surfaces.
