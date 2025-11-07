#!/usr/bin/env Rscript
# =============================================================================
# SafeMapper Real-World Usage Examples
# =============================================================================

cat("SafeMapper - Real-World Usage Examples\n")
cat("========================================\n\n")

library(SafeMapper)

# =============================================================================
# Scenario 1: Processing Large Dataset with Potential Failures
# =============================================================================

cat("\n📊 Scenario 1: Large Dataset Processing with Checkpoint\n")
cat("--------------------------------------------------------\n")

# Simulate a large dataset analysis
process_large_dataset <- function() {
  cat("\nProcessing 200 data points with potential failures...\n")

  s_configure(batch_size = 25, retry_attempts = 2)

  # Simulate data processing function
  process_data <- function(x) {
    # Simulate complex computation
    Sys.sleep(0.01)

    # Simulate very rare failures (1% rate for demo)
    if (runif(1) < 0.01) {
      stop(sprintf("Random failure at item %d", x))
    }

    # Return processed result
    list(
      id = x,
      value = x^2,
      category = sample(c("A", "B", "C"), 1),
      timestamp = Sys.time()
    )
  }

  session_id <- "large_data_processing"

  result <- tryCatch({
    s_map(1:200, process_data, .session_id = session_id)
  }, error = function(e) {
    cat(sprintf("\n⚠ Processing interrupted: %s\n", e$message))
    cat("Progress has been saved. You can resume by running the same code.\n")
    NULL
  })

  if (!is.null(result)) {
    cat(sprintf("\n✓ Successfully processed %d items\n", length(result)))
    return(result)
  }
}

# Run the processing
result1 <- process_large_dataset()

# =============================================================================
# Scenario 2: API Batch Calls with Recovery
# =============================================================================

cat("\n\n🌐 Scenario 2: API Batch Calls with Automatic Recovery\n")
cat("--------------------------------------------------------\n")

simulate_api_calls <- function() {
  cat("\nSimulating 100 API calls with rate limiting...\n")

  s_configure(batch_size = 20, retry_attempts = 3)

  # Simulate API call function
  api_call <- function(id) {
    Sys.sleep(0.02)  # Simulate network delay

    # Simulate very rare API issues (1% chance)
    if (runif(1) < 0.01) {
      stop("API rate limit exceeded")
    }

    # Return API response
    list(
      user_id = id,
      status = "success",
      data = rnorm(1),
      response_time = as.numeric(Sys.time())
    )
  }

  session_id <- "api_batch_calls"

  result <- s_map(1:100, api_call, .session_id = session_id)

  cat(sprintf("\n✓ Completed %d API calls successfully\n", length(result)))
  return(result)
}

result2 <- simulate_api_calls()

# =============================================================================
# Scenario 3: Parallel Data Transformation
# =============================================================================

cat("\n\n⚡ Scenario 3: Parallel Processing with Recovery\n")
cat("------------------------------------------------\n")

parallel_processing_demo <- function() {
  library(future)

  cat("\nRunning parallel computation with automatic checkpointing...\n")

  # Set up parallel backend (2 workers for demo)
  plan(multisession, workers = 2)

  s_configure(batch_size = 15)

  # CPU-intensive function
  complex_calc <- function(x) {
    # Simulate heavy computation
    result <- sum(sapply(1:1000, function(i) sqrt(i * x)))
    Sys.sleep(0.03)
    result
  }

  session_id <- "parallel_computation"

  start_time <- Sys.time()
  result <- s_future_map(1:60, complex_calc, .session_id = session_id)
  end_time <- Sys.time()

  # Reset to sequential
  plan(sequential)

  cat(sprintf("\n✓ Processed %d items in %.2f seconds\n",
             length(result), as.numeric(end_time - start_time)))

  return(result)
}

result3 <- parallel_processing_demo()

# =============================================================================
# Scenario 4: Two-Input Processing (map2)
# =============================================================================

cat("\n\n🔄 Scenario 4: Two-Input Data Merging\n")
cat("--------------------------------------\n")

merge_datasets <- function() {
  cat("\nMerging two datasets with different processing requirements...\n")

  # Simulate two datasets
  dataset_a <- 1:50
  dataset_b <- seq(100, 149)

  s_configure(batch_size = 10)

  # Merge function
  merge_func <- function(a, b) {
    Sys.sleep(0.01)
    data.frame(
      source_a = a,
      source_b = b,
      combined = a + b,
      ratio = b / a
    )
  }

  session_id <- "data_merging"
  result <- s_map2_dfr(dataset_a, dataset_b, merge_func,
                       .session_id = session_id)

  cat(sprintf("\n✓ Merged %d rows\n", nrow(result)))
  cat(sprintf("  First row: %d + %d = %d\n",
             result$source_a[1], result$source_b[1], result$combined[1]))
  cat(sprintf("  Last row: %d + %d = %d\n",
             result$source_a[nrow(result)], result$source_b[nrow(result)],
             result$combined[nrow(result)]))

  return(result)
}

result4 <- merge_datasets()

# =============================================================================
# Scenario 5: Error Handling with s_safely
# =============================================================================

cat("\n\n🛡️ Scenario 5: Robust Error Handling\n")
cat("-------------------------------------\n")

robust_processing <- function() {
  cat("\nProcessing data with graceful error handling...\n")

  # Function that may fail
  risky_operation <- function(x) {
    if (x %% 13 == 0) {
      stop(sprintf("Unlucky number: %d", x))
    }
    sqrt(x)
  }

  # Wrap with s_safely
  safe_operation <- s_safely(risky_operation, otherwise = NA)

  # Process with automatic recovery
  result <- s_map(1:50, safe_operation)

  # Extract results and errors
  results <- sapply(result, function(x) x$result)
  errors <- sapply(result, function(x) !is.null(x$error))

  cat(sprintf("\n✓ Processed %d items\n", length(result)))
  cat(sprintf("  Successful: %d\n", sum(!errors)))
  cat(sprintf("  Errors: %d\n", sum(errors)))

  return(list(results = results, error_count = sum(errors)))
}

result5 <- robust_processing()

# =============================================================================
# Scenario 6: Session Management
# =============================================================================

cat("\n\n📋 Scenario 6: Session Management and Cleanup\n")
cat("----------------------------------------------\n")

manage_sessions <- function() {
  cat("\nDemonstrating session management features...\n\n")

  # List all active sessions
  sessions <- s_list_sessions()

  if (nrow(sessions) > 0) {
    cat("Active Sessions:\n")
    for (i in 1:min(5, nrow(sessions))) {
      cat(sprintf("  • %s: %d/%d items (%.1f%% complete)\n",
                 sessions$session_id[i],
                 sessions$items_completed[i],
                 sessions$total_items[i],
                 sessions$completion_rate[i] * 100))
    }

    # Show statistics
    cat("\n")
    s_session_stats()

    # Clean up old sessions
    cat("\nCleaning up completed sessions...\n")
    s_clean_sessions(older_than_days = 0.001)  # Clean recent for demo
  } else {
    cat("No active sessions found.\n")
  }
}

manage_sessions()

# =============================================================================
# Final Summary
# =============================================================================

cat("\n" , paste0(rep("=", 70), collapse = ""), "\n")
cat("DEMONSTRATION COMPLETE\n")
cat(paste0(rep("=", 70), collapse = ""), "\n\n")

cat("SafeMapper successfully handled:\n")
cat("  ✓ Large dataset processing with checkpoints\n")
cat("  ✓ API batch calls with automatic recovery\n")
cat("  ✓ Parallel processing with fault tolerance\n")
cat("  ✓ Two-input data merging\n")
cat("  ✓ Robust error handling\n")
cat("  ✓ Session management and cleanup\n\n")

cat("Key Benefits:\n")
cat("  • Never lose progress due to failures\n")
cat("  • Automatic checkpointing every N items\n")
cat("  • Seamless recovery from interruptions\n")
cat("  • Drop-in replacement for purrr/furrr\n")
cat("  • Minimal performance overhead\n\n")

cat("Package version:\n")
s_version()

cat("\n🎉 All scenarios completed successfully!\n\n")
