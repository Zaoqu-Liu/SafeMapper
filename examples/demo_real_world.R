#!/usr/bin/env Rscript
# =============================================================================
# SafeMapper Usage Examples
# Author: Zaoqu Liu <liuzaoqu@163.com>
# =============================================================================

library(SafeMapper)

cat("SafeMapper Usage Examples\n")
cat(strrep("=", 60), "\n\n")

# -----------------------------------------------------------------------------
# Example 1: Basic Usage with Automatic Recovery
# -----------------------------------------------------------------------------

cat("Example 1: Basic Usage\n")
cat(strrep("-", 40), "\n")

result <- s_map(1:100, function(x) x^2)
cat("Processed", length(result), "items\n\n")

# -----------------------------------------------------------------------------
# Example 2: Simulated Failure and Recovery
# -----------------------------------------------------------------------------

cat("Example 2: Recovery Mechanism\n")
cat(strrep("-", 40), "\n")

s_configure(batch_size = 10, retry_attempts = 1)
session_id <- "recovery_demo"

# First run - will fail at item 25
counter <- 0
fail_fn <- function(x) {
  counter <<- counter + 1
  if (counter == 25) stop("Simulated failure")
  x^2
}

result <- tryCatch({
  s_map(1:50, fail_fn, .session_id = session_id)
}, error = function(e) {
  cat("First run failed at item 25 (expected)\n")
  NULL
})

# Second run - resumes from checkpoint
success_fn <- function(x) x^2
result <- s_map(1:50, success_fn, .session_id = session_id)
cat("Second run completed:", length(result), "items\n")

# Cleanup
s_clean_sessions(session_ids = session_id)
cat("\n")

# -----------------------------------------------------------------------------
# Example 3: Type-Specific Variants
# -----------------------------------------------------------------------------

cat("Example 3: Type-Specific Functions\n")
cat(strrep("-", 40), "\n")

chars <- s_map_chr(1:5, function(x) paste("item", x))
cat("s_map_chr:", paste(chars, collapse = ", "), "\n")

nums <- s_map_dbl(1:5, function(x) x * 1.5)
cat("s_map_dbl:", paste(nums, collapse = ", "), "\n")

df <- s_map_dfr(1:3, function(x) data.frame(id = x, value = x^2))
cat("s_map_dfr: ", nrow(df), " rows, ", ncol(df), " columns\n\n", sep = "")

# -----------------------------------------------------------------------------
# Example 4: Multiple Input Functions
# -----------------------------------------------------------------------------

cat("Example 4: Multiple Inputs\n")
cat(strrep("-", 40), "\n")

result_map2 <- s_map2(1:5, 6:10, function(a, b) a + b)
cat("s_map2 result:", paste(unlist(result_map2), collapse = ", "), "\n")

data <- list(x = 1:3, y = 4:6, z = 7:9)
result_pmap <- s_pmap(data, function(x, y, z) x + y + z)
cat("s_pmap result:", paste(unlist(result_pmap), collapse = ", "), "\n\n")

# -----------------------------------------------------------------------------
# Example 5: Parallel Processing (if furrr available)
# -----------------------------------------------------------------------------

if (requireNamespace("furrr", quietly = TRUE) && 
    requireNamespace("future", quietly = TRUE)) {
  
  cat("Example 5: Parallel Processing\n")
  cat(strrep("-", 40), "\n")
  
  library(future)
  plan(multisession, workers = 2)
  
  s_configure(batch_size = 20)
  
  result <- s_future_map(1:50, function(x) {
    Sys.sleep(0.01)
    x^2
  })
  
  plan(sequential)
  cat("Parallel processing completed:", length(result), "items\n\n")
}

# -----------------------------------------------------------------------------
# Example 6: Error Handling
# -----------------------------------------------------------------------------

cat("Example 6: Error Handling\n")
cat(strrep("-", 40), "\n")

safe_log <- s_safely(log)
r1 <- safe_log(10)
r2 <- safe_log("invalid")
cat("s_safely: log(10) =", round(r1$result, 3), ", log('invalid') error captured\n")

possible_log <- s_possibly(log, otherwise = NA)
cat("s_possibly: log(-1) =", possible_log(-1), "\n\n")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

cat(strrep("=", 60), "\n")
cat("Examples completed.\n")
