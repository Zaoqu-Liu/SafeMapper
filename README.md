# SafeMapper <img src="https://img.shields.io/badge/R-276DC3?logo=r&logoColor=white" align="right" height="25"/>

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/SafeMapper)](https://CRAN.R-project.org/package=SafeMapper)
[![r-universe](https://zaoqu-liu.r-universe.dev/badges/SafeMapper)](https://zaoqu-liu.r-universe.dev/SafeMapper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**Fault-Tolerant Functional Programming with Automatic Checkpointing**

> *Never lose your computational progress again.*

---

## The Problem

Long-running computations in R are vulnerable to interruptions:

```r
# Processing 10,000 API calls...
result <- purrr::map(urls, fetch_data)
# ❌ Crashes at item 9,847 after 3 hours
# ❌ All progress lost
# ❌ Must restart from scratch
```

**Common failure scenarios:**
- R session crashes or runs out of memory
- Network timeouts during API calls
- System restarts or power failures
- Accidental interruption (Ctrl+C)

## The Solution

SafeMapper provides **drop-in replacements** for `purrr` and `furrr` functions with automatic checkpoint-based recovery:

```r
# Same code, but fault-tolerant
result <- s_map(urls, fetch_data)
# ⚡ Crashes at item 9,847...

# Just re-run the same code:
result <- s_map(urls, fetch_data)
# ✅ "Resuming from checkpoint: 9800/10000 items completed"
# ✅ Continues from where it left off
# ✅ No configuration needed
```

---

## Installation

```r
# From r-universe (recommended)
install.packages("SafeMapper", repos = "https://zaoqu-liu.r-universe.dev")

# From GitHub
devtools::install_github("Zaoqu-Liu/SafeMapper")
```

## Quick Start

```r
library(SafeMapper)

# Replace purrr::map() with s_map() - that's it!
results <- s_map(1:1000, function(x) {
  Sys.sleep(0.1)  # Simulate slow operation
  x^2
})

# If interrupted, just re-run - automatic recovery!
```

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Zero Configuration** | Works out of the box - no setup required |
| **Automatic Recovery** | Detects previous runs and resumes automatically |
| **Drop-in Replacement** | Same API as `purrr` and `furrr` |
| **Transparent Checkpointing** | Progress saved at configurable intervals |
| **Parallel Support** | Full `furrr` compatibility for parallel processing |

---

## Function Reference

### Sequential Processing (purrr replacements)

| SafeMapper | purrr | Returns |
|------------|-------|---------|
| `s_map()` | `map()` | list |
| `s_map_chr()` | `map_chr()` | character |
| `s_map_dbl()` | `map_dbl()` | numeric |
| `s_map_int()` | `map_int()` | integer |
| `s_map_lgl()` | `map_lgl()` | logical |
| `s_map_dfr()` | `map_dfr()` | data.frame (row-bind) |
| `s_map_dfc()` | `map_dfc()` | data.frame (col-bind) |
| `s_map2()` | `map2()` | list (two inputs) |
| `s_pmap()` | `pmap()` | list (multiple inputs) |
| `s_imap()` | `imap()` | list (with index) |
| `s_walk()` | `walk()` | side effects |

### Parallel Processing (furrr replacements)

| SafeMapper | furrr |
|------------|-------|
| `s_future_map()` | `future_map()` |
| `s_future_map2()` | `future_map2()` |
| `s_future_pmap()` | `future_pmap()` |
| `s_future_walk()` | `future_walk()` |
| `s_future_imap()` | `future_imap()` |

*All variants (`_chr`, `_dbl`, `_int`, `_lgl`, `_dfr`, `_dfc`) are supported.*

### Error Handling

| SafeMapper | purrr | Description |
|------------|-------|-------------|
| `s_safely()` | `safely()` | Capture errors |
| `s_possibly()` | `possibly()` | Return default on error |
| `s_quietly()` | `quietly()` | Capture messages/warnings |

---

## Configuration (Optional)

```r
s_configure(
  batch_size = 100,      # Items per checkpoint (default: 100)
  retry_attempts = 3     # Retry failed batches (default: 3)
)

# Clean old checkpoint files
s_clean_sessions(days_old = 7)
```

---

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    First Execution                          │
├─────────────────────────────────────────────────────────────┤
│  Input Data  ──►  Fingerprint  ──►  Process Batches        │
│     [1:1000]       "abc123..."      [1-100] ✓ checkpoint   │
│                                     [101-200] ✓ checkpoint │
│                                     [201-300] ✗ CRASH!     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Re-execution                             │
├─────────────────────────────────────────────────────────────┤
│  Input Data  ──►  Fingerprint  ──►  Find Checkpoint        │
│     [1:1000]       "abc123..."      "200 items completed"  │
│                                                             │
│                    Resume from 201  ──►  Complete!         │
└─────────────────────────────────────────────────────────────┘
```

1. **Fingerprinting**: Each task is identified by a hash of input data characteristics
2. **Checkpointing**: Results are saved to disk at batch intervals
3. **Recovery**: On re-run, matching fingerprints trigger automatic restoration
4. **Cleanup**: Checkpoints are removed after successful completion

---

## Use Cases

- **API Data Collection**: Web scraping, REST API calls with rate limits
- **Bioinformatics**: Processing large genomic datasets
- **Machine Learning**: Batch predictions, cross-validation
- **File Processing**: ETL pipelines, batch transformations
- **Any Long-Running Task**: Where losing progress is costly

---

## Author

**Zaoqu Liu**  
Email: liuzaoqu@163.com  
GitHub: [@Zaoqu-Liu](https://github.com/Zaoqu-Liu)

## License

MIT © 2026 Zaoqu Liu
