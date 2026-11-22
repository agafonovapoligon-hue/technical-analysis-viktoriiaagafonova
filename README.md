# BDA400 Assignment 5 – Technical Analysis using R (Development Phase)

Nine technical-analysis functions, each in its own R script, implemented with base R only
(no packages), following the templates and pseudocode in the assignment brief.

| File | Function | Returns |
|---|---|---|
| `sma.R` | `sma(data, period)` | numeric vector, length `n - period + 1` |
| `ema.R` | `ema(data, period)` | numeric vector, length `n` |
| `macd.R` | `macd(data, short_period, long_period, signal_period)` | list: `macd_line`, `signal_line`, `histogram` |
| `stdev.R` | `stdev(data)` | single number (population SD) |
| `linreg.R` | `linreg(regressionSource, regressionLength, regressionOffset)` | list: `slope`, `intercept`, `predicted_values` |
| `rsi.R` | `rsi(data, period)` | numeric vector, length `n` (first `period` values `NA`) |
| `stoch_rsi.R` | `stoch_rsi(data, period, k_period, d_period)` | list: `k_line`, `d_line` |
| `crossover.R` | `crossover(arr1, arr2)` | character vector: `"Up"`, `"Down"`, `"None"` |
| `crossunder.R` | `crossunder(arr1, arr2)` | character vector: `"None"` first, then `"True"` / `"False"` |
| `run_tests.R` | test suite | prints PASS/FAIL per check |

## How to run

Requires R 4.x. Open a terminal **in this folder** (or `setwd()` to it in RStudio).

Run all tests:

```
Rscript run_tests.R
```

Use a function interactively:

```r
source("sma.R")
sma(c(10, 12, 15, 20, 18, 22, 25, 24, 21), period = 3)
# 12.33 15.67 17.67 20.00 21.67 23.67 23.33
```

`macd.R` loads `ema.R`, and `stoch_rsi.R` loads `rsi.R` and `sma.R`, automatically if those
functions are not already defined, so each script can be sourced on its own.

## Implementation notes

**SMA** – slides a window of `period` points across the data and divides each window's sum
by `period`. Stops with an error if the data is shorter than the period.

**EMA** – multiplier `2 / (period + 1)`. The first EMA value is the first data point; each
later value is `(price - previous EMA) * multiplier + previous EMA`, so recent prices weigh more.

**MACD** – MACD line = short EMA − long EMA; signal line = EMA of the MACD line over
`signal_period`; histogram = MACD line − signal line. Reuses `ema()`.

**Standard deviation** – mean → deviations from the mean → squared → averaged (variance,
divided by *n*) → square root. This is the *population* SD from the brief's formula, so it is
slightly smaller than R's built-in `sd()`, which divides by *n − 1*.

**Linear regression** – least-squares fit of the selected window against index values 1..k:
slope = Σ(x − x̄)(y − ȳ) / Σ(x − x̄)², intercept = ȳ − slope·x̄, predictions = slope·x + intercept.
Validates `regressionLength ≤ n` and `regressionOffset < regressionLength`. The window indices
follow the pseudocode exactly: `start = max(1, n − regressionLength + regressionOffset)`,
`end = min(n, n − regressionOffset)`.

**RSI** – price differences are split into gains and losses (zeros elsewhere). The first
averages are the means of the first `period` gains/losses, then Wilder's smoothing
`avg = (avg·(period − 1) + current) / period` is applied for each point from `period + 1`
onward, and RSI = 100 − 100 / (1 + avg_gain / avg_loss). When there are no losses RSI is 100
(avoids dividing by zero). If the data has `period` points or fewer, every value is `NA`.

**Stochastic RSI** – normalises RSI to 0..1 using its lowest and highest value (ignoring
`NA`s), as the pseudocode specifies. %K = SMA of those values over `k_period`; %D = SMA of %K
over `d_period`. If RSI is flat, normalised values are 0. With the brief's example (10 prices,
RSI period 14) there isn't enough data for any RSI, so %K and %D are all `NA`.

**Crossover** – at each point from the second onward: `"Up"` when arr1 moves from ≤ arr2 to
> arr2, `"Down"` when it moves from ≥ arr2 to < arr2, otherwise `"None"`. Errors if the arrays
differ in length. `NA` comparisons count as no crossover.

**Crossunder** – `"True"` when arr1 moves from ≥ arr2 to < arr2, else `"False"`; the first
element is `"None"` because there is no previous point. Errors if lengths differ.

## Testing

`run_tests.R` runs 39 checks: the examples from the brief, hand-worked values, comparisons
against base R (`sd()`, `lm()`, `stats::filter()`), edge cases (flat data, too little data, only
gains) and the required error messages. All 39 pass on R 4.6.2.
