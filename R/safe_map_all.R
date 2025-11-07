# =============================================================================
# Safe Map Functions - All Variants (Factory-Generated)
# =============================================================================

# Declare variables used in factory closures to avoid R CMD check NOTEs
utils::globalVariables(c("transform_function", "bind_function"))

#' Create Safe Map Function Variant
#'
#' Factory function to generate all s_map* variants with minimal code duplication.
#'
#' @keywords internal
.create_safe_map <- function(mode, output_type = "list",
                             transform_fn = NULL, bind_fn = NULL) {
  # Capture parameters in local variables for closure
  transform_function <- transform_fn
  bind_function <- bind_fn

  function(.x, .f, ..., .id = NULL, .session_id = NULL) {
    result <- .safe_execute(
      data = list(.x),
      func = .f,
      session_id = .session_id,
      mode = mode,
      output_type = output_type,
      ...
    )

    # Apply transformation if needed
    if (!is.null(transform_function)) {
      result <- transform_function(result)
    }

    # Apply binding if needed (for dfr/dfc)
    if (!is.null(bind_function)) {
      result <- bind_function(result, .id)
    }

    result
  }
}

#' Create Safe Map2 Function Variant
#' @keywords internal
.create_safe_map2 <- function(mode, output_type = "list",
                              transform_fn = NULL, bind_fn = NULL) {
  # Capture parameters in local variables for closure
  transform_function <- transform_fn
  bind_function <- bind_fn

  function(.x, .y, .f, ..., .id = NULL, .session_id = NULL) {
    result <- .safe_execute(
      data = list(.x, .y),
      func = .f,
      session_id = .session_id,
      mode = mode,
      output_type = output_type,
      ...
    )

    if (!is.null(transform_function)) {
      result <- transform_function(result)
    }

    if (!is.null(bind_function)) {
      result <- bind_function(result, .id)
    }

    result
  }
}

#' Create Safe Future Map Variant
#' @keywords internal
.create_safe_future_map <- function(mode, output_type = "list",
                                    transform_fn = NULL, bind_fn = NULL) {
  # Capture parameters in local variables for closure
  transform_function <- transform_fn
  bind_function <- bind_fn

  function(.x, .f, ..., .options = furrr::furrr_options(),
           .env_globals = parent.frame(), .progress = FALSE,
           .id = NULL, .session_id = NULL) {
    result <- .safe_execute(
      data = list(.x),
      func = .f,
      session_id = .session_id,
      mode = mode,
      output_type = output_type,
      .options = .options,
      .env_globals = .env_globals,
      .progress = .progress,
      ...
    )

    if (!is.null(transform_function)) {
      result <- transform_function(result)
    }

    if (!is.null(bind_function)) {
      result <- bind_function(result, .id)
    }

    result
  }
}

#' Create Safe Future Map2 Variant
#' @keywords internal
.create_safe_future_map2 <- function(mode, output_type = "list",
                                     transform_fn = NULL, bind_fn = NULL) {
  # Capture parameters in local variables for closure
  transform_function <- transform_fn
  bind_function <- bind_fn

  function(.x, .y, .f, ..., .options = furrr::furrr_options(),
           .env_globals = parent.frame(), .progress = FALSE,
           .id = NULL, .session_id = NULL) {
    result <- .safe_execute(
      data = list(.x, .y),
      func = .f,
      session_id = .session_id,
      mode = mode,
      output_type = output_type,
      .options = .options,
      .env_globals = .env_globals,
      .progress = .progress,
      ...
    )

    if (!is.null(transform_function)) {
      result <- transform_function(result)
    }

    if (!is.null(bind_function)) {
      result <- bind_function(result, .id)
    }

    result
  }
}

# =============================================================================
# Generate All s_map* Functions
# =============================================================================

#' Safe Map - Drop-in Replacement for purrr::map with Auto-Recovery
#'
#' @param .x A list or atomic vector to map over.
#' @param .f A function, formula, or vector.
#' @param ... Additional arguments passed to .f.
#' @param .session_id Character. Optional session ID for this operation.
#' @return A list, same as purrr::map.
#' @examples
#' result <- s_map(1:10, ~ .x^2)
#' @export
s_map <- .create_safe_map("map", "list")

#' @rdname s_map
#' @return A character vector.
#' @export
s_map_chr <- .create_safe_map("map", "character", transform_fn = as.character)

#' @rdname s_map
#' @return A double vector.
#' @export
s_map_dbl <- .create_safe_map("map", "double", transform_fn = as.numeric)

#' @rdname s_map
#' @return An integer vector.
#' @export
s_map_int <- .create_safe_map("map", "integer", transform_fn = as.integer)

#' @rdname s_map
#' @return A logical vector.
#' @export
s_map_lgl <- .create_safe_map("map", "logical", transform_fn = as.logical)

#' @rdname s_map
#' @param .id Either a string or NULL for row binding.
#' @return A data frame (row bind).
#' @export
s_map_dfr <- .create_safe_map("map", "list",
  bind_fn = function(x, .id) purrr::list_rbind(x, names_to = .id)
)

#' @rdname s_map
#' @return A data frame (column bind).
#' @export
s_map_dfc <- .create_safe_map("map", "list", bind_fn = function(x, .id) purrr::list_cbind(x))

# =============================================================================
# Generate All s_map2* Functions
# =============================================================================

#' Safe Map2 - Drop-in Replacement for purrr::map2 with Auto-Recovery
#'
#' @param .x,.y Vectors of the same length.
#' @param .f A function, formula, or vector.
#' @param ... Additional arguments passed to .f.
#' @param .session_id Character. Optional session ID.
#' @return A list.
#' @examples
#' s_map2(1:5, 6:10, `+`)
#' @export
s_map2 <- .create_safe_map2("map2", "list")

#' @rdname s_map2
#' @export
s_map2_chr <- .create_safe_map2("map2", "character", transform_fn = as.character)

#' @rdname s_map2
#' @export
s_map2_dbl <- .create_safe_map2("map2", "double", transform_fn = as.numeric)

#' @rdname s_map2
#' @export
s_map2_int <- .create_safe_map2("map2", "integer", transform_fn = as.integer)

#' @rdname s_map2
#' @export
s_map2_lgl <- .create_safe_map2("map2", "logical", transform_fn = as.logical)

#' @rdname s_map2
#' @param .id Either a string or NULL for row binding.
#' @export
s_map2_dfr <- .create_safe_map2("map2", "list",
  bind_fn = function(x, .id) purrr::list_rbind(x, names_to = .id)
)

#' @rdname s_map2
#' @export
s_map2_dfc <- .create_safe_map2("map2", "list",
  bind_fn = function(x, .id) purrr::list_cbind(x)
)

# =============================================================================
# Generate All s_future_map* Functions
# =============================================================================

#' Safe Future Map - Parallel with Auto-Recovery
#'
#' @param .x A list or atomic vector.
#' @param .f A function, formula, or vector.
#' @param ... Additional arguments passed to .f.
#' @param .options A furrr_options object.
#' @param .env_globals The environment to look for globals.
#' @param .progress A single logical.
#' @param .id Optional name to use for ID column when row binding (dfr/dfc variants).
#' @param .session_id Character. Optional session ID.
#' @return A list.
#' @examples
#' \dontrun{
#' library(future)
#' plan(multisession)
#' s_future_map(1:100, ~ .x^2)
#' }
#' @export
s_future_map <- .create_safe_future_map("future_map", "list")

#' @rdname s_future_map
#' @export
s_future_map_chr <- .create_safe_future_map("future_map", "character",
  transform_fn = as.character
)

#' @rdname s_future_map
#' @export
s_future_map_dbl <- .create_safe_future_map("future_map", "double",
  transform_fn = as.numeric
)

#' @rdname s_future_map
#' @export
s_future_map_int <- .create_safe_future_map("future_map", "integer",
  transform_fn = as.integer
)

#' @rdname s_future_map
#' @export
s_future_map_lgl <- .create_safe_future_map("future_map", "logical",
  transform_fn = as.logical
)

#' @rdname s_future_map
#' @export
s_future_map_dfr <- .create_safe_future_map("future_map", "list",
  bind_fn = function(x, .id) purrr::list_rbind(x, names_to = .id)
)

#' @rdname s_future_map
#' @export
s_future_map_dfc <- .create_safe_future_map("future_map", "list",
  bind_fn = function(x, .id) purrr::list_cbind(x)
)

# =============================================================================
# Generate All s_future_map2* Functions
# =============================================================================

#' Safe Future Map2 - Parallel Two-Input with Auto-Recovery
#'
#' @param .x,.y Vectors of the same length.
#' @param .f A function, formula, or vector.
#' @param ... Additional arguments passed to .f.
#' @param .options A furrr_options object.
#' @param .env_globals The environment to look for globals.
#' @param .progress A single logical.
#' @param .id Optional name to use for ID column when row binding (dfr/dfc variants).
#' @param .session_id Character. Optional session ID.
#' @return A list.
#' @export
s_future_map2 <- .create_safe_future_map2("future_map2", "list")

#' @rdname s_future_map2
#' @export
s_future_map2_chr <- .create_safe_future_map2("future_map2", "character",
  transform_fn = as.character
)

#' @rdname s_future_map2
#' @export
s_future_map2_dbl <- .create_safe_future_map2("future_map2", "double",
  transform_fn = as.numeric
)

#' @rdname s_future_map2
#' @export
s_future_map2_int <- .create_safe_future_map2("future_map2", "integer",
  transform_fn = as.integer
)

#' @rdname s_future_map2
#' @export
s_future_map2_lgl <- .create_safe_future_map2("future_map2", "logical",
  transform_fn = as.logical
)

#' @rdname s_future_map2
#' @export
s_future_map2_dfr <- .create_safe_future_map2("future_map2", "list",
  bind_fn = function(x, .id) purrr::list_rbind(x, names_to = .id)
)

#' @rdname s_future_map2
#' @export
s_future_map2_dfc <- .create_safe_future_map2("future_map2", "list",
  bind_fn = function(x, .id) purrr::list_cbind(x)
)
