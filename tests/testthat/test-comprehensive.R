#!/usr/bin/env Rscript
# =============================================================================
# SafeMapper Comprehensive Test Suite
# =============================================================================

cat("Loading SafeMapper...\n")
library(SafeMapper)

# Test counter
tests_passed <- 0
tests_failed <- 0

test_that <- function(desc, expr) {
  cat(sprintf("\n[TEST] %s\n", desc))
  result <- tryCatch({
    expr
    tests_passed <<- tests_passed + 1
    cat("  ✓ PASSED\n")
    TRUE
  }, error = function(e) {
    tests_failed <<- tests_failed + 1
    cat(sprintf("  ✗ FAILED: %s\n", e$message))
    FALSE
  })
  result
}

cat("\n=== Testing Basic s_map Functions ===\n")

test_that("s_map works with simple vectors", {
  result <- s_map(1:5, function(x) x^2)
  expected <- list(1, 4, 9, 16, 25)
  stopifnot(identical(result, expected))
})

test_that("s_map_chr returns character vector", {
  result <- s_map_chr(1:3, function(x) paste("item", x))
  expected <- c("item 1", "item 2", "item 3")
  stopifnot(identical(result, expected))
})

test_that("s_map_dbl returns numeric vector", {
  result <- s_map_dbl(1:5, function(x) x * 2.5)
  expected <- c(2.5, 5.0, 7.5, 10.0, 12.5)
  stopifnot(all.equal(result, expected))
})

test_that("s_map_int returns integer vector", {
  result <- s_map_int(1:5, function(x) as.integer(x * 2))
  expected <- c(2L, 4L, 6L, 8L, 10L)
  stopifnot(identical(result, expected))
})

test_that("s_map_lgl returns logical vector", {
  result <- s_map_lgl(1:5, function(x) x %% 2 == 0)
  expected <- c(FALSE, TRUE, FALSE, TRUE, FALSE)
  stopifnot(identical(result, expected))
})

cat("\n=== Testing s_map2 Functions ===\n")

test_that("s_map2 works with two vectors", {
  result <- s_map2(1:3, 4:6, function(x, y) x + y)
  # s_map2 returns a list, so we check each element
  stopifnot(length(result) == 3)
  stopifnot(result[[1]] == 5 && result[[2]] == 7 && result[[3]] == 9)
})

test_that("s_map2_dbl returns numeric vector", {
  result <- s_map2_dbl(1:3, 1:3, function(x, y) x * y)
  expected <- c(1, 4, 9)
  stopifnot(identical(result, expected))
})

cat("\n=== Testing Recovery Mechanism ===\n")

test_that("Recovery works after simulated failure", {
  session_id <- paste0("test_recovery_", format(Sys.time(), "%Y%m%d_%H%M%S"))

  # Configure for testing
  s_configure(batch_size = 5, retry_attempts = 1)

  # Create function that fails at specific point
  counter <- 0
  failing_func <- function(x) {
    counter <<- counter + 1
    if (counter == 8) {  # Fail at 8th item
      stop("Simulated failure")
    }
    x^2
  }

  # First run - should fail
  first_result <- tryCatch({
    s_map(1:15, failing_func, .session_id = session_id)
  }, error = function(e) {
    cat("  → First run failed as expected\n")
    NULL
  })

  # Check that session was saved
  sessions <- s_list_sessions()
  stopifnot(session_id %in% sessions$session_id)

  # Second run - should resume
  counter <- 0  # Reset counter
  success_func <- function(x) x^2

  second_result <- s_map(1:15, success_func, .session_id = session_id)
  expected <- as.list((1:15)^2)
  stopifnot(identical(second_result, expected))

  # Clean up
  s_clean_sessions(session_ids = session_id)
})

cat("\n=== Testing walk Functions ===\n")

test_that("s_walk executes side effects", {
  results <- numeric(0)
  invisible_result <- s_walk(1:5, function(x) results <<- c(results, x))
  stopifnot(length(results) == 5)
  # Check values are correct
  stopifnot(all(results == 1:5))
})

test_that("s_walk2 executes side effects with two inputs", {
  results <- numeric(0)
  s_walk2(1:3, 4:6, function(x, y) results <<- c(results, x + y))
  stopifnot(length(results) == 3)
})

cat("\n=== Testing pmap Functions ===\n")

test_that("s_pmap works with multiple arguments", {
  data <- list(a = 1:3, b = 4:6, c = 7:9)
  result <- s_pmap(data, function(a, b, c) a + b + c)
  # Check each result
  stopifnot(length(result) == 3)
  stopifnot(result[[1]] == 12 && result[[2]] == 15 && result[[3]] == 18)
})

cat("\n=== Testing imap Functions ===\n")

test_that("s_imap works with indices", {
  result <- s_imap(c("a", "b", "c"), function(val, idx) paste(idx, val))
  expected <- list("1 a", "2 b", "3 c")
  stopifnot(identical(result, expected))
})

test_that("s_imap_chr returns character vector", {
  result <- s_imap_chr(c("x", "y", "z"), function(val, idx) paste0(idx, ":", val))
  expected <- c("1:x", "2:y", "3:z")
  stopifnot(identical(result, expected))
})

cat("\n=== Testing Error Handling Functions ===\n")

test_that("s_safely captures errors", {
  safe_log <- s_safely(log)
  result1 <- safe_log(10)
  result2 <- safe_log("invalid")

  stopifnot(!is.null(result1$result))
  stopifnot(is.null(result1$error))
  stopifnot(is.null(result2$result))
  stopifnot(!is.null(result2$error))
})

test_that("s_possibly returns default value on error", {
  possible_log <- s_possibly(log, otherwise = NA)
  result1 <- possible_log(10)
  result2 <- possible_log("invalid")

  stopifnot(!is.na(result1))
  stopifnot(is.na(result2))
})

cat("\n=== Testing Session Management ===\n")

test_that("Session management functions work", {
  # List sessions
  sessions <- s_list_sessions()
  stopifnot(is.data.frame(sessions))

  # Session stats
  s_session_stats()

  # Clean old sessions
  s_clean_sessions(older_than_days = 365)
})

cat("\n=== Testing Configuration ===\n")

test_that("Configuration works correctly", {
  old_config <- s_configure(batch_size = 25, retry_attempts = 5)

  # Access config through function call
  s_configure()  # Just ensure it works

  # Reset
  s_configure(batch_size = 50L, retry_attempts = 3L)

  stopifnot(TRUE)  # If we got here, configuration works
})

cat("\n=== Testing Parallel Functions (Future) ===\n")

test_that("s_future_map works with sequential plan", {
  library(future)
  plan(sequential)

  result <- s_future_map(1:10, function(x) x^2)
  expected <- as.list((1:10)^2)
  stopifnot(identical(result, expected))
})

cat("\n=== Testing Edge Cases ===\n")

test_that("Empty input handling", {
  result <- tryCatch({
    s_map(c(), function(x) x)
  }, error = function(e) {
    "error"
  })
  stopifnot(result == "error")
})

test_that("Single item works", {
  result <- s_map(5, function(x) x^2)
  expected <- list(25)
  stopifnot(identical(result, expected))
})

test_that("Formula syntax works", {
  result <- s_map(1:5, ~ .x * 2)
  expected <- list(2, 4, 6, 8, 10)
  stopifnot(identical(result, expected))
})

test_that("Data frame row binding works", {
  result <- s_map_dfr(1:3, function(x) {
    data.frame(id = x, value = x^2)
  })
  stopifnot(nrow(result) == 3)
  stopifnot(ncol(result) == 2)
})

cat("\n=== Testing Real-World Scenario ===\n")

test_that("API-like batch processing with recovery", {
  # Simulate API calls that might fail
  call_count <- 0
  api_simulator <- function(id) {
    call_count <<- call_count + 1
    Sys.sleep(0.01)  # Simulate network delay
    list(id = id, result = id * 100)
  }

  session_id <- paste0("api_test_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  s_configure(batch_size = 10)

  result <- s_map(1:50, api_simulator, .session_id = session_id)

  stopifnot(length(result) == 50)
  stopifnot(result[[1]]$id == 1)
  stopifnot(result[[50]]$result == 5000)

  cat(sprintf("  → Processed 50 API calls in batches\n"))
})

# =============================================================================
# Final Report
# =============================================================================

cat("\n" , paste0(rep("=", 70), collapse = ""), "\n")
cat("TEST SUMMARY\n")
cat(paste0(rep("=", 70), collapse = ""), "\n")
cat(sprintf("Tests Passed: %d\n", tests_passed))
cat(sprintf("Tests Failed: %d\n", tests_failed))
cat(sprintf("Success Rate: %.1f%%\n", 100 * tests_passed / (tests_passed + tests_failed)))
cat(paste0(rep("=", 70), collapse = ""), "\n")

if (tests_failed == 0) {
  cat("\n🎉 All tests passed! SafeMapper is working correctly.\n\n")
} else {
  cat("\n⚠ Some tests failed. Please review the errors above.\n\n")
  quit(status = 1)
}

