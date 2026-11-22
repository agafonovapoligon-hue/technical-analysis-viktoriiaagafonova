# Test runner for the Assignment 5 technical indicators.
# Run from this folder:   Rscript run_tests.R
# Checks each function against hand-worked values or an independent base-R calculation.

for (f in c("sma.R", "ema.R", "macd.R", "stdev.R", "linreg.R",
            "rsi.R", "stoch_rsi.R", "crossover.R", "crossunder.R")) {
  source(f)
}

passed <- 0
failed <- 0
check <- function(name, ok) {
  if (isTRUE(ok)) {
    passed <<- passed + 1
    cat(sprintf("[PASS] %s\n", name))
  } else {
    failed <<- failed + 1
    cat(sprintf("[FAIL] %s\n", name))
  }
}
near <- function(a, b, tol = 1e-9) {
  length(a) == length(b) && all(is.na(a) == is.na(b)) &&
    all(abs(a[!is.na(a)] - b[!is.na(b)]) < tol)
}
errors <- function(expr) inherits(try(expr, silent = TRUE), "try-error")

data <- c(10, 12, 15, 20, 18, 22, 25, 24, 21)

# ---- SMA ----
check("sma: assignment example (period 3)",
      near(sma(data, 3), c(37, 47, 53, 60, 65, 71, 70) / 3))
check("sma: period equal to length", near(sma(data, 9), sum(data) / 9))
check("sma: errors when data shorter than period", errors(sma(1:2, 3)))

# ---- EMA ----
e <- ema(data, 3)
check("ema: first value equals first data point", e[1] == 10)
check("ema: second value", near(e[2], 11))
check("ema: third value", near(e[3], 13))
# period 3 -> multiplier 0.5, so EMA[i] = 0.5 * data[i] + 0.5 * EMA[i-1]
check("ema: matches base-R recursive filter",
      near(e, as.numeric(stats::filter(0.5 * data, 0.5, method = "recursive", init = 10))))

# ---- MACD ----
m <- macd(c(100, 105, 110, 115, 120, 125, 130), 3, 5, 2)
mline <- ema(c(100, 105, 110, 115, 120, 125, 130), 3) - ema(c(100, 105, 110, 115, 120, 125, 130), 5)
check("macd: returns macd_line, signal_line, histogram",
      identical(names(m), c("macd_line", "signal_line", "histogram")))
check("macd: macd_line = short EMA - long EMA", near(m$macd_line, mline))
check("macd: signal_line = EMA of macd_line", near(m$signal_line, ema(mline, 2)))
check("macd: histogram = macd - signal", near(m$histogram, m$macd_line - m$signal_line))
check("macd: first value is 0", m$macd_line[1] == 0)

# ---- Standard deviation ----
check("stdev: matches population sd",
      near(stdev(data), sd(data) * sqrt((length(data) - 1) / length(data))))
check("stdev: textbook example = 2", near(stdev(c(2, 4, 4, 4, 5, 5, 7, 9)), 2))
check("stdev: constant data = 0", stdev(c(5, 5, 5)) == 0)

# ---- Linear regression ----
lr <- linreg(c(1, 3, 5, 7, 9), 5, 0)
check("linreg: perfect line slope = 2", near(lr$slope, 2))
check("linreg: perfect line intercept = -1", near(lr$intercept, -1))
check("linreg: predictions reproduce data", near(lr$predicted_values, c(1, 3, 5, 7, 9)))
lr2 <- linreg(data, 5, 0)
# Per the pseudocode, start_index = n - length + offset = 4, so the window is data[4:9]
fit <- coef(lm(y ~ x, data.frame(x = 1:6, y = data[4:9])))
check("linreg: matches lm() on the pseudocode window data[4:9]",
      near(lr2$slope, unname(fit[2])) && near(lr2$intercept, unname(fit[1])))
lr3 <- linreg(data, 5, 2)
check("linreg: offset 2 uses data[6:7] window per pseudocode",
      near(lr3$predicted_values, c(22, 25)))
check("linreg: errors when length > n", errors(linreg(data, 20, 0)))
check("linreg: errors when offset >= length", errors(linreg(data, 5, 5)))

# ---- RSI ----
rd <- c(45, 50, 48, 55, 52, 49, 58, 60, 65, 62)
r <- rsi(rd, 5)
check("rsi: same length as data", length(r) == length(rd))
check("rsi: first 'period' values are NA", all(is.na(r[1:5])) && !any(is.na(r[6:10])))
check("rsi: values within 0..100", all(r[6:10] >= 0 & r[6:10] <= 100))
# hand-worked: gains = 5,0,7,0,0  losses = 0,2,0,3,3 -> avg 2.4 / 1.6
# i = 6 smoothing uses gains[5]=0, losses[5]=3: avg_gain 1.92, avg_loss 1.88
check("rsi: hand-worked value at i = 6", near(r[6], 100 - 100 / (1 + 1.92 / 1.88)))
check("rsi: only gains gives 100", rsi(1:10, 3)[10] == 100)
check("rsi: too little data gives all NA", all(is.na(rsi(c(1, 2, 3), 5))))

# ---- Stochastic RSI ----
s <- stoch_rsi(rd, 14, 3, 3)
check("stoch_rsi: assignment example runs and returns k_line, d_line",
      identical(names(s), c("k_line", "d_line")))
set.seed(1)
prices <- cumsum(rnorm(60)) + 100
s2 <- stoch_rsi(prices, 14, 3, 3)
check("stoch_rsi: k_line length = n - k + 1", length(s2$k_line) == 58)
check("stoch_rsi: d_line length = k length - d + 1", length(s2$d_line) == 56)
kv <- s2$k_line[!is.na(s2$k_line)]
check("stoch_rsi: %K stays within 0..1", all(kv >= 0 & kv <= 1))
check("stoch_rsi: %D is SMA of %K", near(s2$d_line, sma(s2$k_line, 3)))

# ---- Crossover / Crossunder ----
a1 <- c(10, 12, 15, 20, 18, 22, 25, 24, 21)
a2 <- c(18, 20, 22, 18, 15, 12, 10, 11, 13)
check("crossover: assignment example",
      identical(crossover(a1, a2),
                c("None", "None", "None", "Up", "None", "None", "None", "None", "None")))
check("crossover: detects Down", crossover(c(5, 1), c(3, 3))[2] == "Down")
check("crossover: errors on unequal lengths", errors(crossover(1:3, 1:4)))
check("crossunder: assignment example (no cross under)",
      identical(crossunder(a1, a2),
                c("None", rep("False", 8))))
check("crossunder: detects cross under", identical(crossunder(c(5, 1), c(3, 3)), c("None", "True")))
check("crossunder: errors on unequal lengths", errors(crossunder(1:3, 1:4)))

cat(sprintf("\n%d passed, %d failed\n", passed, failed))
if (failed > 0) quit(status = 1)
