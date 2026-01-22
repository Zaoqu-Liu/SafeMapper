# SafeMapper

An R package providing fault-tolerant functional programming with automatic checkpointing and recovery.

## Overview

SafeMapper extends the `purrr` and `furrr` packages by adding transparent checkpoint-based recovery to mapping operations. When a long-running computation is interrupted, SafeMapper automatically resumes from the last successful checkpoint upon re-execution.

The package requires no configuration for basic use. Simply replace `map()` with `s_map()`.

## Installation

From CRAN (recommended):
```r
install.packages("SafeMapper")
```

From r-universe:
```r
install.packages("SafeMapper", repos = "https://zaoqu-liu.r-universe.dev")
```

Development version from GitHub:
```r
devtools::install_github("Zaoqu-Liu/SafeMapper")
```

## Usage

```r
library(SafeMapper)

# Standard usage (identical to purrr::map)
result <- s_map(1:1000, expensive_function)

# If interrupted, re-run the same code to resume
result <- s_map(1:1000, expensive_function)
# Output: "Resuming from item 847/1000"
```

## Exported Functions

### Sequential (purrr replacements)

| Function | Description |
|----------|-------------|
| `s_map()`, `s_map_chr()`, `s_map_dbl()`, `s_map_int()`, `s_map_lgl()` | Apply function to each element |
| `s_map_dfr()`, `s_map_dfc()` | Apply function and bind results |
| `s_map2()`, `s_map2_*()` | Map over two inputs |
| `s_pmap()` | Map over multiple inputs |
| `s_imap()`, `s_imap_chr()` | Map with index |
| `s_walk()`, `s_walk2()` | Apply function for side effects |
| `s_safely()`, `s_possibly()`, `s_quietly()` | Error handling wrappers |

### Parallel (furrr replacements)

| Function | Description |
|----------|-------------|
| `s_future_map()`, `s_future_map_*()` | Parallel map |
| `s_future_map2()`, `s_future_map2_*()` | Parallel map over two inputs |
| `s_future_pmap()` | Parallel map over multiple inputs |
| `s_future_walk()`, `s_future_walk2()` | Parallel side effects |
| `s_future_imap()` | Parallel map with index |

### Configuration

| Function | Description |
|----------|-------------|
| `s_configure()` | Adjust batch size and retry attempts |
| `s_clean_sessions()` | Remove old checkpoint files |

## Configuration (Optional)

```r
s_configure(
  batch_size = 100,     # Items per checkpoint (default: 100)
  retry_attempts = 3    # Retries per batch (default: 3)
)
```

## Implementation

SafeMapper identifies tasks by computing a fingerprint from the input data (length, first element, last element, and type). Checkpoints are stored in the R user cache directory and automatically cleaned after successful completion.

## Author

Zaoqu Liu (<liuzaoqu@163.com>)

## License

MIT
