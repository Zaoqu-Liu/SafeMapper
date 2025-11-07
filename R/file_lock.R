# =============================================================================
# File Lock Mechanism - Solve Concurrent Safety Issues
# =============================================================================

#' Acquire File Lock
#' @keywords internal
.acquire_lock <- function(session_id, config, timeout = 60) {
  lock_file <- file.path(
    config$cache_dir, "locks",
    paste0(session_id, ".lock")
  )

  # Create lock directory
  lock_dir <- dirname(lock_file)
  if (!dir.exists(lock_dir)) {
    dir.create(lock_dir, recursive = TRUE)
  }

  # Attempt to acquire lock
  start_time <- Sys.time()
  while (TRUE) {
    # Use atomic nature of file creation
    if (file.create(lock_file, showWarnings = FALSE)) {
      # Write PID and timestamp
      writeLines(
        c(as.character(Sys.getpid()), as.character(Sys.time())),
        lock_file
      )
      return(lock_file)
    }

    # Check if lock is expired (prevent deadlock)
    if (file.exists(lock_file)) {
      lock_info <- tryCatch(readLines(lock_file, warn = FALSE), error = function(e) NULL)
      if (length(lock_info) >= 2) {
        lock_time <- tryCatch(as.POSIXct(lock_info[2]), error = function(e) NULL)
        if (!is.null(lock_time) && difftime(Sys.time(), lock_time, units = "secs") > timeout) {
          warning("Stale lock detected, removing")
          file.remove(lock_file)
          next
        }
      }
    }

    # Timeout
    if (difftime(Sys.time(), start_time, units = "secs") > timeout) {
      stop(sprintf(
        "Could not acquire lock for session '%s' after %d seconds.\nAnother process may be using this session.\nSolutions:\n1. Use a different session_id\n2. Wait for other process to complete\n3. Manually delete: %s",
        session_id, timeout, lock_file
      ), call. = FALSE)
    }

    Sys.sleep(0.1)
  }
}

#' Release File Lock
#' @keywords internal
.release_lock <- function(lock_file) {
  if (!is.null(lock_file) && file.exists(lock_file)) {
    file.remove(lock_file)
  }
}
