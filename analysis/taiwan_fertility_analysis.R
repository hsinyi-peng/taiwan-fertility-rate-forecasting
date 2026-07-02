# ===============================
# Taiwan Fertility Rate Forecasting
# Correlation/regression analysis of marriage rate & women's education on TFR,
# plus ETS time-series forecasting of future fertility rates
# ===============================
#
# Run from the project root, e.g.:
#   Rscript analysis/taiwan_fertility_analysis.R
#
# Reads:  data/taiwan_fertility_data.csv
# Writes: outputs/*.png

# --------- 0) Setup ---------
pkg_needed <- c("forecast", "tseries")
pkg_to_install <- pkg_needed[!(pkg_needed %in% installed.packages()[,"Package"])]
if (length(pkg_to_install) > 0) install.packages(pkg_to_install, dependencies = TRUE)

library(forecast)
library(tseries)

dir.create("outputs", showWarnings = FALSE)

# --------- 1) Load Data ---------
df <- read.csv("data/taiwan_fertility_data.csv", stringsAsFactors = FALSE)
names(df) <- c("year", "marriage_rate", "edu_rate", "childbearing_age_share", "tfr")

cat("Rows x Cols:", nrow(df), "x", ncol(df), "\n")
cat("Years covered:", min(df$year), "-", max(df$year), "\n\n")

# --------- 2) Correlation & Multicollinearity Check ---------
# marriage_rate and edu_rate are both strongly related to the passage of time
# in Taiwan over this period, so a multiple regression of tfr on both together
# is unstable (multicollinearity). We check this first, then isolate each
# predictor in its own simple linear regression instead.
corr_vars <- df[, c("marriage_rate", "edu_rate", "tfr")]
corr_mat <- cor(corr_vars)
cat("== Correlation matrix ==\n")
print(round(corr_mat, 4))

r_squared_pairs <- corr_mat^2
cat("\n== Pairwise R-squared (correlation^2) ==\n")
print(round(r_squared_pairs, 4))
cat(sprintf("\nmarriage_rate vs edu_rate share R-squared of %.3f -> multicollinearity if modeled together.\n\n",
            r_squared_pairs["marriage_rate", "edu_rate"]))

# --------- 3) Simple Linear Regressions (isolated predictors) ---------
model_marriage <- lm(tfr ~ marriage_rate, data = df)
model_edu <- lm(tfr ~ edu_rate, data = df)

cat("== TFR ~ marriage_rate ==\n")
print(summary(model_marriage))

cat("\n== TFR ~ edu_rate ==\n")
print(summary(model_edu))

# EDA plot: TFR vs each predictor
png("outputs/plot_tfr_vs_marriage_rate.png", width = 900, height = 600)
plot(df$marriage_rate, df$tfr,
     main = "TFR vs. Marriage Rate (age 15+)",
     xlab = "Marriage rate", ylab = "Total fertility rate (births per woman)",
     pch = 19, col = "steelblue")
abline(model_marriage, col = "firebrick", lwd = 2)
dev.off()

png("outputs/plot_tfr_vs_edu_rate.png", width = 900, height = 600)
plot(df$edu_rate, df$tfr,
     main = "TFR vs. Women's Higher-Education Attainment (ages 18-40)",
     xlab = "Women's education rate", ylab = "Total fertility rate (births per woman)",
     pch = 19, col = "darkorange")
abline(model_edu, col = "firebrick", lwd = 2)
dev.off()

# --------- 4) Time Series Forecasting (Exponential Smoothing) ---------
tfr_ts <- ts(df$tfr, start = min(df$year), frequency = 1)

# Additive error, damped trend, no seasonality (matches the original
# course project's model selection for this series)
ets_model <- ets(tfr_ts, model = "AAN", damped = TRUE)
cat("\n== ETS model summary ==\n")
print(summary(ets_model))

mape_value <- accuracy(ets_model)["Training set", "MAPE"]
cat(sprintf("\nMAPE (training set): %.2f%%\n", mape_value))

ets_forecast <- forecast(ets_model, h = 10)
png("outputs/plot_ets_forecast.png", width = 1000, height = 650)
plot(ets_forecast, main = "TFR Forecast (ETS), 10-Year Horizon",
     xlab = "Year", ylab = "Total fertility rate (births per woman)")
dev.off()

# --------- 5) Residual Diagnostics ---------
resid_vals <- residuals(ets_model)

# Independence: Ljung-Box test (H0: residuals are independent)
lb_test <- Box.test(resid_vals, lag = 10, type = "Ljung-Box")
cat("\n== Ljung-Box test (residual independence) ==\n")
print(lb_test)

# Normality: Shapiro-Wilk test (H0: residuals are normally distributed)
sw_test <- shapiro.test(resid_vals)
cat("\n== Shapiro-Wilk test (residual normality) ==\n")
print(sw_test)

png("outputs/plot_residual_histogram.png", width = 900, height = 600)
hist(resid_vals, main = "Histogram of ETS Residuals", xlab = "Residuals", col = "grey80")
dev.off()

# Constant variance: residuals over time
png("outputs/plot_residuals_over_time.png", width = 900, height = 600)
plot(resid_vals, type = "l", main = "ETS Residuals Over Time",
     xlab = "Year", ylab = "Residuals")
abline(h = 0, col = "firebrick", lty = 2)
dev.off()

cat("\nAll done. Figures saved to outputs/.\n")
