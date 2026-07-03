# Taiwan Fertility Rate Forecasting

Examining how women's higher-education attainment and marriage rates relate to Taiwan's total fertility rate (TFR), and forecasting where TFR is headed, using correlation analysis, simple linear regression, and ETS time-series smoothing in R.

## Overview

Taiwan's TFR was 0.865 births per woman in 2023 — well below the 2.1 replacement threshold and among the lowest in the world. This project asks whether two commonly cited societal drivers, women's participation in higher education and the marriage rate, show a measurable statistical relationship with the decline, and builds a short-term forecast of where TFR is trending.

This started as a group project (Team: Nikolas Perez Linggi [lead], Hsin Yi Peng, Sophia Lee, Julia Hung, Dominick Ortega); this repository is an independent R reproduction of the shared analysis, written and run end-to-end by Hsin Yi Peng.

## Dataset

`data/taiwan_fertility_data.csv` — 27 rows (1997–2023), sourced from Taiwan's Ministry of the Interior Statistical Yearbook.

| Column | Description |
|---|---|
| `year` | Calendar year |
| `marriage_rate` | Share of the population age 15+ that is married |
| `womens_edu_rate` | Share of women ages 18–40 with higher-education attainment |
| `childbearing_age_share` | Share of the female population that is of childbearing age (18–49) |
| `tfr` | Total fertility rate (births per woman) — target variable |

## Repository structure

```
.
├── analysis/
│   └── taiwan_fertility_analysis.R   # full pipeline: correlation -> regression -> ETS forecast -> diagnostics
├── data/
│   └── taiwan_fertility_data.csv
├── outputs/                          # generated on run: regression & forecast plots (PNG)
└── README.md
```

## Methodology

1. **Correlation check** — `marriage_rate` and `womens_edu_rate` are themselves highly correlated (r = -0.95, R² = 0.89), so a multiple regression of TFR on both together is unstable (multicollinearity). Each predictor is instead isolated into its own simple linear regression.
2. **Simple linear regression** — `tfr ~ marriage_rate` and `tfr ~ edu_rate`, evaluated on coefficient significance and adjusted R².
3. **Time-series forecasting** — TFR converted to an annual time series and fit with exponential smoothing (ETS, additive error + damped trend, matching the original model selection for this series), forecast 10 years out.
4. **Residual diagnostics** — Ljung-Box test for residual independence, Shapiro-Wilk test for normality, and a residuals-over-time plot to check for constant variance.

## How to run

```bash
git clone <this-repo-url>
cd taiwan-fertility-rate-forecasting
Rscript analysis/taiwan_fertility_analysis.R
```

Requires R (≥ 4.0) with packages: `forecast`, `tseries` — the script installs any that are missing on first run. Plots are written to `outputs/`.

## Results

**Regression**

| Model | Coefficient | Adjusted R² | p-value |
|---|---|---|---|
| `tfr ~ marriage_rate` | 6.25 (higher marriage rate → higher TFR) | 0.72 | < 0.001 |
| `tfr ~ edu_rate` | -0.66 (higher women's education rate → lower TFR) | 0.56 | < 0.001 |

Both relationships are statistically significant and in the expected direction: TFR rises with the marriage rate and falls as women's higher-education attainment rises. The marriage-rate model explains more of the variance (R² 0.72 vs. 0.56), suggesting nuptiality is the stronger single predictor of the two over this period — though with only two predictors and strong collinearity between them, neither model isolates a clean causal effect on its own.

<p>
  <img src="outputs/plot_tfr_vs_marriage_rate.png" alt="TFR vs. marriage rate" width="49%">
  <img src="outputs/plot_tfr_vs_edu_rate.png" alt="TFR vs. women's education rate" width="49%">
</p>

**Forecast (ETS, damped trend)**

MAPE (training set): ~6.5%. Ljung-Box (p = 0.66) fails to reject independence of residuals; Shapiro-Wilk (p = 0.11) fails to reject normality — both support the model's assumptions holding reasonably well. The 10-year forecast projects TFR continuing its gradual decline before the damped trend flattens it out, consistent with a low-fertility regime rather than a rebound.

![ETS 10-year forecast](outputs/plot_ets_forecast.png)

**Residual diagnostics**

<p>
  <img src="outputs/plot_residuals_over_time.png" alt="Residuals over time" width="49%">
  <img src="outputs/plot_residual_histogram.png" alt="Histogram of residuals" width="49%">
</p>

## License

[MIT](LICENSE)
