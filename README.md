<div align="center">

# Optimizing a Rule-Based Trading Strategy

### Stochastic search over a momentum, mean-reversion, and pairs-trading rule set

[![Report](https://img.shields.io/badge/Report-PDF-B31B1B?style=flat-square&logo=adobeacrobatreader&logoColor=white)](Project%201.C%20%E2%80%93%20Stock%20Portfolio%20Optimization%20%E2%80%93%20Felipe%20%26%20Ella%20.pdf)
[![Duke](https://img.shields.io/badge/Duke-CEE%20251L-00539B?style=flat-square)](#about)
[![MATLAB](https://img.shields.io/badge/MATLAB-0076A8?style=flat-square&logo=mathworks&logoColor=white)](#repository-contents)

**Felipe Jaramillo** and **Ella Veysel** · Duke University · Spring 2025

</div>

---

A trading algorithm for 19 stocks over 200 days, starting from $1,000. Each day it scores every stock, decides what to buy and sell, and manages risk; the eight parameters that govern those decisions were tuned with a global stochastic optimizer, then stress-tested for robustness. This work later became the starting point for [Modeling Market Geometry](https://github.com/felipejpenagos/Capstone-Research-Modeling-Market-Geometry).

## Strategy

1. **Quality score.** Each stock gets $Q = q_1 \cdot \text{velocity} + q_2 \cdot \text{acceleration} + q_3 \cdot \text{volatility}$, computed from a smoothed price series.
2. **Trend confirmation.** Buy when $Q$ exceeds the buy threshold $B$ and price is above its weighted moving average; sell when $Q$ falls below $S$ or price drops below the average.
3. **Pairs trading.** A cointegration-style spread between two related stocks generates mean-reversion entries when its z-score diverges.
4. **Risk control.** If drawdown stays above 25% for three consecutive days, the portfolio liquidates and the thresholds tighten before re-entry.

<div align="center">
<img src="https://github.com/user-attachments/assets/7f371788-9963-43ac-af6d-b6e326b35fb8" width="70%" alt="Design variables">
</div>

## Design variables

| Variable | Meaning | Range |
|---|---|---|
| `N` | Smoothing window | 5–100 |
| `q1` | Weight on price velocity | −1 to 1 |
| `q2` | Weight on acceleration | −1 to 1 |
| `q3` | Weight on volatility | 0 to 1 |
| `fc` | Fraction of cash to invest | 0.01–0.99 |
| `B` | Buy threshold | 0.001–0.1 |
| `S` | Sell threshold | −0.1 to 0 |
| `W` | Weighted-moving-average window | 4–30 |

The objective is the negative of terminal portfolio value, $V_T = C_T + \sum_s p_{T,s} M_{T,s}$, with no short selling and purchases capped at $f_c$ of available cash.

## Optimization and results

The parameters were optimized with **ORSopt** (optimized step-size random search), chosen over Nelder-Mead and SQP because the objective landscape is rugged and non-smooth.

| | |
|---|---|
| **Terminal value** | $2,411.43 from $1,000 over the 200-day training window (+141%) |
| **Optimal parameters** | N = 27, q1 = −0.62, q2 = −0.38, q3 = 0.31, fc = 0.70, B = 0.042, S = −0.009, W = 4.6 |
| **Most sensitive** | N, W, and q1 |

<div align="center">
<img src="https://github.com/user-attachments/assets/50d288a4-a5f2-479d-9c0d-2a6261677545" width="49%" alt="Trading activity and portfolio value">
<img src="https://github.com/user-attachments/assets/29655265-e68b-4fcd-875f-5e8698436dba" width="49%" alt="Drawdown over time">
</div>

## Robustness

A sharp optimum on in-sample data is usually an overfit one. To find parameters that hold up, the response surface of portfolio value over pairs of quality weights was mapped and Gaussian-smoothed, which collapses isolated peaks and leaves the broad regions where returns stay high under small perturbations.

<div align="center">
<img src="https://github.com/user-attachments/assets/aeca0669-0919-4b90-a17b-de57ddc00829" width="49%" alt="Raw quality-weight response surface">
<img src="https://github.com/user-attachments/assets/947cd786-adbf-45de-850a-c2ff1061f297" width="49%" alt="Gaussian-smoothed response surface">
</div>

## Repository contents

```
exchange_analysis.m           trading simulation and objective function
run_strategy.m                runs the optimized parameters
quality_surface_plot.m        response surface over quality weights
quality_surface_smoothed.m    Gaussian-smoothed response surface
Result Images/                figures
Project 1.C – Stock … .pdf    full report
```

Some supporting MATLAB files from the course are not included.

## About

Project 1.C for CEE 251L, Uncertainty, Design, and Optimization, taught by Prof. Henri P. Gavin at Duke University.
