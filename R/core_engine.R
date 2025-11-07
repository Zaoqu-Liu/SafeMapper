# =============================================================================
# Core Execution Engine (Simplified & Optimized)
# =============================================================================

#' Core Safe Execution Engine
#'
#' Simplified execution engine with progress tracking and smart error handling.
#'
#' @keywords internal
.safe_execute <- function(data, func, session_id, mode, output_type,
                          .options = NULL, .env_globals = parent.frame(),
                          .progress = FALSE, ...) {
  # 1. Validate and initialize
  .validate_inputs(data)
  config <- .safemapper_sessions$config
  total_items <- length(data[[1]])

  # 2. Setup session
  session_id <- session_id %||% .generate_session_id(mode)
  checkpoint <- .init_checkpoint(session_id, data, mode, config)

  # 3. Check if already completed
  if (checkpoint$start_idx > total_items) {
    .cleanup_checkpoint(checkpoint$file)
    return(.format_output(checkpoint$results, output_type))
  }

  # 4. Process batches with progress
  results <- .process_batches(
    data = data,
    func = func,
    mode = mode,
    checkpoint = checkpoint,
    config = config,
    total_items = total_items,
    .options = .options,
    .env_globals = .env_globals,
    .progress = .progress,
    ...
  )

  # 5. Cleanup and return
  .cleanup_checkpoint(checkpoint$file)
  message(sprintf("Completed %d items", total_items))

  return(.format_output(results, output_type))
}

#' Validate Inputs
#' @keywords internal
.validate_inputs <- function(data) {
  if (length(data) == 0 || length(data[[1]]) == 0) {
    stop("Input data cannot be empty", call. = FALSE)
  }

  if (length(data) > 1) {
    lengths <- vapply(data, length, integer(1))
    if (!all(lengths == lengths[1])) {
      stop("All input vectors must have the same length", call. = FALSE)
    }
  }
}

#' Generate Simple Session ID
#' @keywords internal
.generate_session_id <- function(mode) {
  paste0(mode, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
}

#' Initialize or Resume Checkpoint
#' @keywords internal
.init_checkpoint <- function(session_id, data, mode, config) {
  checkpoint_file <- file.path(
    config$cache_dir, "checkpoints",
    paste0(session_id, ".rds")
  )

  if (file.exists(checkpoint_file) && config$auto_recover) {
    checkpoint_data <- readRDS(checkpoint_file)
    start_idx <- length(checkpoint_data$results) + 1
    message(sprintf(
      "Resuming from item %d/%d", start_idx,
      checkpoint_data$metadata$total_items
    ))
  } else {
    checkpoint_data <- list(
      results = list(),
      metadata = list(
        session_id = session_id,
        total_items = length(data[[1]]),
        mode = mode,
        created = Sys.time()
      )
    )
    start_idx <- 1
  }

  list(
    file = checkpoint_file,
    data = checkpoint_data,
    results = checkpoint_data$results,
    start_idx = start_idx
  )
}

#' Process Batches with Progress Tracking
#' @keywords internal
.process_batches <- function(data, func, mode, checkpoint, config,
                             total_items, .options, .env_globals,
                             .progress, ...) {
  results <- checkpoint$results
  batch_size <- config$batch_size

  for (batch_start in seq(checkpoint$start_idx, total_items, by = batch_size)) {
    batch_end <- min(batch_start + batch_size - 1, total_items)
    batch_indices <- batch_start:batch_end

    # Progress indicator
    pct <- round(100 * batch_start / total_items)
    message(sprintf(
      "[%d%%] Processing items %d-%d of %d",
      pct, batch_start, batch_end, total_items
    ))

    # Execute batch with retry
    batch_results <- .execute_batch_with_retry(
      data = data,
      func = func,
      mode = mode,
      batch_indices = batch_indices,
      config = config,
      .options = .options,
      .env_globals = .env_globals,
      .progress = .progress,
      ...
    )

    # Store results and checkpoint
    results[batch_indices] <- batch_results
    .save_checkpoint(checkpoint$file, results, checkpoint$data$metadata)
  }

  results
}

#' Execute Single Batch with Retry Logic
#' @keywords internal
.execute_batch_with_retry <- function(data, func, mode, batch_indices,
                                      config, .options, .env_globals,
                                      .progress, ...) {
  batch_data <- lapply(data, function(x) x[batch_indices])
  last_error <- NULL

  for (attempt in seq_len(config$retry_attempts)) {
    result <- tryCatch(
      {
        .execute_mode(
          mode, batch_data, func, batch_indices,
          .options, .env_globals, .progress, ...
        )
      },
      error = function(e) {
        last_error <<- e
        NULL
      }
    )

    if (!is.null(result)) {
      return(result)
    }

    # Retry logic
    if (attempt < config$retry_attempts) {
      message(sprintf(
        "  Retry %d/%d: %s", attempt, config$retry_attempts,
        last_error$message
      ))
      Sys.sleep(1)
    }
  }

  stop(sprintf(
    "Batch failed after %d attempts: %s",
    config$retry_attempts, last_error$message
  ), call. = FALSE)
}

#' Execute Specific Mode (Simplified Switch)
#' @keywords internal
.execute_mode <- function(mode, batch_data, func, batch_indices,
                          .options, .env_globals, .progress, ...) {
  # Sequential modes
  if (mode %in% c("map", "walk", "imap")) {
    fn <- switch(mode,
      "map" = purrr::map,
      "walk" = purrr::walk,
      "imap" = purrr::imap
    )
    result <- fn(batch_data[[1]], func, ...)
    if (mode == "walk") {
      return(rep(list(NULL), length(batch_indices)))
    }
    return(result)
  }

  # Two-argument modes
  if (mode %in% c("map2", "walk2")) {
    fn <- switch(mode,
      "map2" = purrr::map2,
      "walk2" = purrr::walk2
    )
    result <- fn(batch_data[[1]], batch_data[[2]], func, ...)
    if (mode == "walk2") {
      return(rep(list(NULL), length(batch_indices)))
    }
    return(result)
  }

  # Multi-argument modes
  if (mode == "pmap") {
    # For pmap, batch_data is already in correct format: list(a=vec, b=vec, c=vec)
    # We just need to pass it directly to purrr::pmap
    return(purrr::pmap(batch_data, func, ...))
  }

  # Future modes
  if (grepl("^future_", mode)) {
    if (is.null(.options)) .options <- furrr::furrr_options()

    base_mode <- sub("^future_", "", mode)

    if (base_mode == "map") {
      return(furrr::future_map(batch_data[[1]], func, ...,
        .options = .options, .env_globals = .env_globals,
        .progress = .progress
      ))
    } else if (base_mode == "map2") {
      return(furrr::future_map2(batch_data[[1]], batch_data[[2]], func, ...,
        .options = .options, .env_globals = .env_globals,
        .progress = .progress
      ))
    } else if (base_mode == "pmap") {
      # For future_pmap, batch_data is already in correct format
      return(furrr::future_pmap(batch_data, func, ...,
        .options = .options, .env_globals = .env_globals,
        .progress = .progress
      ))
    } else if (base_mode == "walk") {
      furrr::future_walk(batch_data[[1]], func, ...,
        .options = .options, .env_globals = .env_globals,
        .progress = .progress
      )
      return(rep(list(NULL), length(batch_indices)))
    } else if (base_mode == "walk2") {
      furrr::future_walk2(batch_data[[1]], batch_data[[2]], func, ...,
        .options = .options, .env_globals = .env_globals,
        .progress = .progress
      )
      return(rep(list(NULL), length(batch_indices)))
    } else if (base_mode == "imap") {
      return(furrr::future_imap(batch_data[[1]], func, ...,
        .options = .options, .env_globals = .env_globals,
        .progress = .progress
      ))
    }
  }

  stop("Unknown mode: ", mode, call. = FALSE)
}

#' Save Checkpoint
#' @keywords internal
.save_checkpoint <- function(file, results, metadata) {
  metadata$last_updated <- Sys.time()
  saveRDS(list(results = results, metadata = metadata), file)
}

#' Cleanup Checkpoint File
#' @keywords internal
.cleanup_checkpoint <- function(file) {
  if (file.exists(file)) file.remove(file)
}

#' Null-coalescing Operator
#'
#' @param x First value
#' @param y Alternative value if x is NULL
#' @return x if not NULL, otherwise y
#' @keywords internal
#' @name null-default
#' @aliases grapes-or-or-grapes
NULL

#' @rdname null-default
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Format Output According to Type
#'
#' Internal function to format results according to the expected output type.
#'
#' @param results List of results from processing
#' @param output_type Expected output type
#' @return Formatted output
#' @keywords internal
.format_output <- function(results, output_type) {
  switch(output_type,
    "list" = results,
    "character" = unlist(results),
    "double" = unlist(results),
    "integer" = unlist(results),
    "logical" = unlist(results),
    "walk" = NULL,
    results
  )
}
