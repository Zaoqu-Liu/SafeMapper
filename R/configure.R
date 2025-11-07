# =============================================================================
# SafeMapper Configuration Functions
# =============================================================================

# Global session manager
.safemapper_sessions <- new.env(parent = emptyenv())

#' Configure SafeMapper Session
#'
#' Set global configuration for safe mapping operations with automatic recovery.
#' This function allows you to customize batch processing, caching, and retry behavior.
#'
#' @param session_id Character. Unique session identifier for recovery. If NULL,
#'   auto-generated based on timestamp and operation.
#' @param batch_size Integer. Number of items to process per batch before checkpointing.
#'   Smaller values provide more frequent saves but may slow processing.
#' @param cache_dir Character. Directory path for storing checkpoint files.
#' @param retry_attempts Integer. Number of retry attempts for failed batches.
#' @param auto_recover Logical. Whether to automatically resume from checkpoints
#'   when restarting operations.
#'
#' @return Invisible list of current configuration settings.
#'
#' @examples
#' # Basic configuration
#' s_configure()
#'
#' # Custom configuration for large operations
#' s_configure(
#'   batch_size = 100,
#'   cache_dir = "my_cache",
#'   retry_attempts = 5
#' )
#'
#' # Configuration for specific session
#' s_configure(session_id = "data_processing_2024")
#'
#' @export
s_configure <- function(session_id = NULL,
                        batch_size = 50L,
                        cache_dir = ".safe_purrr_cache",
                        retry_attempts = 3L,
                        auto_recover = TRUE) {
  .safemapper_sessions$config <- list(
    session_id = session_id,
    batch_size = as.integer(batch_size),
    cache_dir = cache_dir,
    retry_attempts = as.integer(retry_attempts),
    auto_recover = auto_recover
  )

  # Create cache directory structure
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  checkpoints_dir <- file.path(cache_dir, "checkpoints")
  if (!dir.exists(checkpoints_dir)) {
    dir.create(checkpoints_dir, recursive = TRUE)
  }

  invisible(.safemapper_sessions$config)
}

# Initialize default config
s_configure()
