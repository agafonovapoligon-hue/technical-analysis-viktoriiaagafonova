# Crossover: "Up" where arr1 crosses above arr2, "Down" where it crosses below,
# "None" otherwise (as specified in the assignment pseudocode).
crossover <- function(arr1, arr2) {
  # Check if the length of both arrays is the same
  if (length(arr1) != length(arr2)) {
    stop("Both arrays should have the same length")
  }

  # Initialize a vector to store the crossover signals
  n <- length(arr1)
  crossover_signals <- rep("None", n)

  # Check for crossovers at each data point
  if (n >= 2) {
    for (i in 2:n) {
      if (isTRUE(arr1[i] > arr2[i] && arr1[i - 1] <= arr2[i - 1])) {
        crossover_signals[i] <- "Up"
      } else if (isTRUE(arr1[i] < arr2[i] && arr1[i - 1] >= arr2[i - 1])) {
        crossover_signals[i] <- "Down"
      } else {
        crossover_signals[i] <- "None"
      }
    }
  }

  return(crossover_signals)
}
