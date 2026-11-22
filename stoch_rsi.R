# Stochastic RSI (StochRSI) function
# Depends on rsi() from rsi.R and sma() from sma.R (loaded automatically if missing).
if (!exists("rsi", mode = "function")) source("rsi.R")
if (!exists("sma", mode = "function")) source("sma.R")

stoch_rsi <- function(data, period, k_period, d_period) {
  # Calculate the RSI
  rsi_values <- rsi(data, period)

  # Calculate the StochRSI (normalise RSI to 0..1 using its lowest/highest value)
  valid <- !is.na(rsi_values)
  k_values <- rep(NA_real_, length(rsi_values))
  if (any(valid)) {
    min_rsi <- min(rsi_values[valid])
    max_rsi <- max(rsi_values[valid])
    if (max_rsi == min_rsi) {
      # Flat RSI: no range to normalise against
      k_values[valid] <- 0
    } else {
      k_values[valid] <- (rsi_values[valid] - min_rsi) / (max_rsi - min_rsi)
    }
  }

  # Calculate the %K line (StochRSI)
  k_line <- sma(k_values, k_period)

  # Calculate the %D line (3-day simple moving average of %K)
  d_line <- sma(k_line, d_period)

  # Return the %K and %D lines as a list
  result <- list(
    k_line = k_line,
    d_line = d_line
  )
  return(result)
}
