# =============================================================================
# Debugging and Utility Functions
# =============================================================================

#' Debug a Specific SafeMapper Session
#'
#' Provides detailed diagnostic information about a specific session,
#' including progress, errors, and suggested fixes.
#'
#' @param session_id Character. Session ID to debug.
#'
#' @examples
#' # Debug a failed session
#' s_debug_session("map_20240101_120000_abcd1234")
#'
#' @export
s_debug_session <- function(session_id) {
  config <- .safemapper_sessions$config
  checkpoint_file <- file.path(config$cache_dir, "checkpoints", paste0(session_id, ".rds"))

  if (file.exists(checkpoint_file)) {
    data <- readRDS(checkpoint_file)

    cat("=== Session Debug Info ===\n")
    cat("Session ID:", data$metadata$session_id, "\n")
    cat("Mode:", data$metadata$mode, "\n")
    cat("Total items:", data$metadata$total_items, "\n")
    cat("Completed items:", length(data$results), "\n")
    cat("Progress:", sprintf("%.1f%%", 100 * length(data$results) / data$metadata$total_items), "\n")
    cat("Created:", format(data$metadata$created), "\n")

    if (!is.null(data$metadata$last_updated)) {
      cat("Last updated:", format(data$metadata$last_updated), "\n")
    }

    if (!is.null(data$metadata$failed_at_batch)) {
      cat("Failed at batch:", data$metadata$failed_at_batch, "\n")
    }

    if (!is.null(data$metadata$error_message)) {
      cat("Error message:", data$metadata$error_message, "\n")

      if (grepl("In index:", data$metadata$error_message)) {
        cat("\n=== Suggested Fix ===\n")
        cat("This looks like a worker/globals error. Try:\n")
        cat("1. Add missing functions to globals: globals = c('your_function')\n")
        cat("2. Put all functions inside your mapping function\n")
        cat("3. Use package::function syntax\n")
        cat("4. Test with a smaller dataset first\n")
      } else if (grepl("could not find function", data$metadata$error_message)) {
        cat("\n=== Suggested Fix ===\n")
        cat("Function not found error. Try:\n")
        cat("1. Make sure all required packages are loaded\n")
        cat("2. Define custom functions in the global environment\n")
        cat("3. Use fully qualified function names (package::function)\n")
      }
    } else {
      cat("Status: In progress\n")
    }
  } else {
    cat("Session not found:", session_id, "\n")
  }
}

#' Get SafeMapper Session Statistics
#'
#' Provides summary statistics of all sessions including counts by status,
#' overall completion rates, and timing information.
#'
#' @return Invisible data frame of session information.
#'
#' @examples
#' # Show session statistics
#' s_session_stats()
#'
#' # Capture statistics for further analysis
#' stats <- s_session_stats()
#'
#' @export
s_session_stats <- function() {
  sessions <- s_list_sessions()

  if (nrow(sessions) == 0) {
    cat("No sessions found\n")
    return(invisible(NULL))
  }

  cat("=== SafeMapper Session Statistics ===\n")
  cat("Total sessions:", nrow(sessions), "\n")
  cat("Active sessions:", sum(sessions$status == "in_progress", na.rm = TRUE), "\n")
  cat("Failed sessions:", sum(sessions$status == "failed", na.rm = TRUE), "\n")
  cat("Corrupted sessions:", sum(sessions$status == "corrupted", na.rm = TRUE), "\n")

  if (nrow(sessions) > 0) {
    total_items <- sum(sessions$total_items, na.rm = TRUE)
    completed_items <- sum(sessions$items_completed, na.rm = TRUE)

    cat("Total items processed:", completed_items, "of", total_items, "\n")
    if (total_items > 0) {
      cat("Overall completion rate:", sprintf("%.1f%%", 100 * completed_items / total_items), "\n")
    }

    oldest <- min(sessions$created, na.rm = TRUE)
    newest <- max(sessions$created, na.rm = TRUE)
    cat("Oldest session:", format(oldest), "\n")
    cat("Newest session:", format(newest), "\n")
  }

  invisible(sessions)
}

#' Get SafeMapper Package Version and Information
#'
#' Displays comprehensive information about the SafeMapper package including
#' version, supported functions, and usage tips.
#'
#' @examples
#' # Show package information
#' s_version()
#'
#' @export
s_version <- function() {
  cat("SafeMapper v1.0.0 - Fault-Tolerant Functional Programming\n")
  cat("Author: Zaoqu Liu <liuzaoqu@163.com>\n")
  cat("GitHub: https://github.com/Zaoqu-Liu/SafeMapper\n\n")

  cat("Drop-in replacements for purrr and furrr with automatic recovery:\n\n")

  cat("Core Functions:\n")
  cat("  - s_map(), s_map_chr(), s_map_dbl(), s_map_int(), s_map_lgl()\n")
  cat("  - s_map_dfr(), s_map_dfc()\n")
  cat("  - s_map2(), s_map2_*() variants\n")
  cat("  - s_pmap(), s_imap(), s_imap_chr()\n")
  cat("  - s_walk(), s_walk2()\n\n")

  cat("Parallel Functions (furrr replacements):\n")
  cat("  - s_future_map(), s_future_map_*() variants\n")
  cat("  - s_future_map2(), s_future_map2_*() variants\n")
  cat("  - s_future_pmap(), s_future_imap()\n")
  cat("  - s_future_walk(), s_future_walk2()\n\n")

  cat("Error Handling:\n")
  cat("  - s_safely(), s_possibly(), s_quietly()\n\n")

  cat("Session Management:\n")
  cat("  - s_configure() - Configure batch size, cache directory, retries\n")
  cat("  - s_list_sessions() - View all checkpoint sessions\n")
  cat("  - s_recover_session() - Recover specific session results\n")
  cat("  - s_clean_sessions() - Remove old checkpoint files\n")
  cat("  - s_debug_session() - Debug failed sessions\n")
  cat("  - s_session_stats() - Show session statistics\n\n")

  cat("Key Features:\n")
  cat("  + Automatic checkpointing every N items (configurable)\n")
  cat("  + Seamless recovery from interruptions\n")
  cat("  + Identical API to purrr/furrr functions\n")
  cat("  + Detailed error reporting and debugging\n")
  cat("  + Session management and cleanup tools\n")
  cat("  + Support for both sequential and parallel processing\n\n")

  cat("Quick Start:\n")
  cat("  library(SafeMapper)\n")
  cat("  result <- s_map(1:100, slow_function)  # Automatically saved progress\n")
  cat("  s_list_sessions()                      # View sessions if interrupted\n")
}

# Show version on attach
.onAttach <- function(libname, pkgname) {
  packageStartupMessage("SafeMapper loaded. Use s_version() for details.")
}
