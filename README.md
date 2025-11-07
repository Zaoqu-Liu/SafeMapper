# SafeMapper 🛡️

<div align="center">

[![R Package](https://img.shields.io/badge/R%20Package-SafeMapper-blue.svg)](https://github.com/Zaoqu-Liu/SafeMapper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-1.0.0-green.svg)](https://github.com/Zaoqu-Liu/SafeMapper)

**Fault-Tolerant and Resumable Functional Programming with Automatic Recovery**

*Never lose your computational progress again!*

</div>

---

## 🎯 What is SafeMapper?

SafeMapper provides **drop-in replacements** for `purrr` and `furrr` mapping functions with built-in **fault tolerance**, **automatic checkpointing**, and **seamless recovery capabilities**. It's designed to solve the critical problem of losing computation progress when long-running operations fail due to network issues, memory errors, system crashes, or other interruptions.

### 🚨 The Problem We Solve

Have you ever experienced these frustrating scenarios?

- ⏰ **Hours of computation lost** when your R session crashes at 95% completion
- 🌐 **API rate limits** causing failures after processing thousands of requests
- 💾 **Memory errors** interrupting large-scale data transformations
- 🔌 **Network timeouts** during web scraping operations
- 🖥️ **System crashes** during overnight batch jobs

**SafeMapper eliminates these pain points completely!**

---

## ✨ Key Features

<table>
<tr>
<td width="50%">

### 🔄 **Automatic Recovery**
- ✅ Seamless resumption from exact failure point
- ✅ No manual intervention required
- ✅ Preserves all completed work

### 🎯 **Drop-in Compatibility**
- ✅ Identical API to `purrr` and `furrr`
- ✅ Simply replace `map` with `s_map`
- ✅ Works with existing code

</td>
<td width="50%">

### ⚡ **Smart Checkpointing**
- ✅ Configurable batch sizes
- ✅ Minimal performance overhead
- ✅ Automatic cleanup on success

### 🔍 **Advanced Debugging**
- ✅ Detailed error reporting
- ✅ Session management tools
- ✅ Progress tracking

</td>
</tr>
</table>

---

## 🚀 Quick Start

### Requirements

- R ≥ 3.5.0
- Required packages: `purrr`, `furrr`, `tools`
- Optional: `testthat` (for testing), `rmarkdown` (for documentation)

### Installation

```r
# Install from GitHub
if (!require(devtools)) install.packages("devtools")
devtools::install_github("Zaoqu-Liu/SafeMapper")

# Load the package
library(SafeMapper)

# Verify installation
s_version()
```

### Basic Usage

```r
# Instead of purrr::map
result <- purrr::map(data, slow_function)

# Use SafeMapper - automatically fault-tolerant!
result <- s_map(data, slow_function)
```

**That's it!** Your computation is now automatically protected against failures.

---

## 📊 Real-World Examples

### 🌐 Example 1: API Calls with Rate Limiting

```r
library(SafeMapper)
library(httr)

# Configure for API operations
s_configure(
  batch_size = 25,           # Save progress every 25 requests
  retry_attempts = 5,        # Retry failed requests
  session_id = "api_batch_2024"
)

# Process 1000 API endpoints safely
urls <- paste0("https://api.example.com/data/", 1:1000)

# This will automatically recover if interrupted!
responses <- s_map(urls, function(url) {
  GET(url, timeout(30))      # 30-second timeout per request
})

# Check progress if needed
s_list_sessions()
```

**What happens if this fails?**
- ✅ Progress is automatically saved every 25 requests
- ✅ On restart, computation resumes from the exact failure point
- ✅ No duplicate API calls or wasted time
- ✅ Detailed session information for debugging

**Real output:**
```
Processing items 1-25 of 1000
Processing items 26-50 of 1000
...
Processing items 826-850 of 1000
Error: API rate limit exceeded

# After restarting:
Resuming session 'api_batch_2024' from item 851
Processing items 851-875 of 1000
```

### 🧠 Example 2: Large-Scale Data Processing

```r
# Process 10,000 complex calculations
large_dataset <- 1:10000

result <- s_map(large_dataset, function(x) {
  # Simulate heavy computation
  complex_analysis <- run_model(x)
  generate_report(complex_analysis)
  return(complex_analysis)
}, .session_id = "big_analysis")
```

### ⚡ Example 3: Parallel Processing with Recovery

```r
library(future)
plan(multisession, workers = 8)

# Configure for parallel operations
s_configure(batch_size = 50, retry_attempts = 3)

# Parallel processing with automatic recovery
results <- s_future_map(1:5000, function(i) {
  Sys.sleep(0.1)  # Simulate computation time
  expensive_computation(i)
}, .session_id = "parallel_job")

plan(sequential)  # Reset to sequential

# Check parallel session statistics
s_session_stats()
```

---

## 🔧 Configuration & Advanced Usage

### Global Configuration

```r
# Customize SafeMapper behavior
s_configure(
  batch_size = 100,                    # Items per checkpoint
  cache_dir = "my_safe_cache",         # Custom cache directory  
  retry_attempts = 3,                  # Retries per batch
  auto_recover = TRUE                  # Auto-resume on restart
)
```

### Session Management

```r
# List all checkpoint sessions
sessions <- s_list_sessions()
print(sessions)

# Recover specific session
recovered_data <- s_recover_session("map_20240101_120000_abcd1234")

# Debug failed sessions
s_debug_session("failed_session_id")

# Clean up old sessions
s_clean_sessions(older_than_days = 7)

# View session statistics
s_session_stats()
```

---

## 🛠️ How Recovery Works

### The Magic Behind the Scenes

```r
# 1. Start a long operation
result <- s_map(1:1000, slow_function)

# 2. If interrupted at item 847...
# Error: System crash / R session terminated

# 3. Restart R and run the SAME code
result <- s_map(1:1000, slow_function)
# ✅ "Resuming session 'map_20240101_120000_abcd1234' from item 848"
# ✅ Only processes remaining 153 items!
```

### Recovery Example with Error Handling

```r
# Simulation: Operation that fails and recovers
problematic_function <- function(x) {
  if (x == 73) stop("Simulated network error")
  return(x^2)
}

# This will fail at item 73
tryCatch({
  result <- s_map(1:100, problematic_function, .session_id = "demo_recovery")
}, error = function(e) {
  cat("Operation failed:", e$message, "\n")
  
  # Check what was completed
  sessions <- s_list_sessions()
  print(sessions[sessions$session_id == "demo_recovery", ])
  
  # Fix the function and resume
  fixed_function <- function(x) {
    if (x == 73) return(NA)  # Handle the error case
    return(x^2)
  }
  
  # Resume with fixed function - starts from item 73!
  result <- s_map(1:100, fixed_function, .session_id = "demo_recovery")
})
```

---

## 📋 Complete Function Reference

### 🎯 Core Map Functions (purrr replacements)
| SafeMapper | purrr Equivalent | Description |
|------------|------------------|-------------|
| `s_map()` | `map()` | Apply function to list/vector |
| `s_map_chr()` | `map_chr()` | Return character vector |
| `s_map_dbl()` | `map_dbl()` | Return numeric vector |
| `s_map_int()` | `map_int()` | Return integer vector |
| `s_map_lgl()` | `map_lgl()` | Return logical vector |
| `s_map_dfr()` | `map_dfr()` | Return data frame (row bind) |
| `s_map_dfc()` | `map_dfc()` | Return data frame (column bind) |

### 🔄 Two-Input Functions (map2 variants)
| SafeMapper | purrr Equivalent | Description |
|------------|------------------|-------------|
| `s_map2()` | `map2()` | Map over two inputs |
| `s_map2_chr()` | `map2_chr()` | Two inputs → character vector |
| `s_map2_dbl()` | `map2_dbl()` | Two inputs → numeric vector |
| `s_map2_int()` | `map2_int()` | Two inputs → integer vector |
| `s_map2_lgl()` | `map2_lgl()` | Two inputs → logical vector |
| `s_map2_dfr()` | `map2_dfr()` | Two inputs → data frame (rows) |
| `s_map2_dfc()` | `map2_dfc()` | Two inputs → data frame (columns) |

### ⚡ Parallel Functions (furrr replacements)
| SafeMapper | furrr Equivalent | Description |
|------------|------------------|-------------|
| `s_future_map()` | `future_map()` | Parallel mapping |
| `s_future_map_chr()` | `future_map_chr()` | Parallel → character vector |
| `s_future_map_dbl()` | `future_map_dbl()` | Parallel → numeric vector |
| `s_future_map2()` | `future_map2()` | Parallel two-input mapping |
| `s_future_pmap()` | `future_pmap()` | Parallel multiple-input mapping |
| `s_future_walk()` | `future_walk()` | Parallel side effects |

### 🔧 Additional Functions
| SafeMapper | Equivalent | Description |
|------------|------------|-------------|
| `s_walk()` | `walk()` | For side effects |
| `s_walk2()` | `walk2()` | Side effects (two inputs) |
| `s_pmap()` | `pmap()` | Multiple-input mapping |
| `s_imap()` | `imap()` | Map with indices |
| `s_safely()` | `safely()` | Error handling wrapper |
| `s_possibly()` | `possibly()` | Default value on error |
| `s_quietly()` | `quietly()` | Capture side effects |

### 🛡️ Session Management
| Function | Description |
|----------|-------------|
| `s_configure()` | Configure global settings |
| `s_list_sessions()` | View all checkpoint sessions |
| `s_recover_session()` | Recover specific session data |
| `s_clean_sessions()` | Remove old checkpoint files |
| `s_debug_session()` | Debug failed sessions |
| `s_session_stats()` | Show session statistics |
| `s_version()` | Package information |

---

## 🎓 Advanced Recovery Scenarios

### Scenario 1: Fixing Function Errors

```r
# Original function has a bug
buggy_analysis <- function(x) {
  if (x %% 100 == 0) stop("Division error")  # Bug at multiples of 100
  return(analyze_data(x))
}

# Start processing
tryCatch({
  results <- s_map(1:500, buggy_analysis, .session_id = "analysis_v1")
}, error = function(e) {
  cat("Failed at item:", e$message, "\n")
})

# Fix the function
fixed_analysis <- function(x) {
  if (x %% 100 == 0) return(analyze_data_special(x))  # Fixed!
  return(analyze_data(x))
}

# Resume with fixed function
results <- s_map(1:500, fixed_analysis, .session_id = "analysis_v1")
# ✅ Continues from where it failed!
```

### Scenario 2: Changing Configuration Mid-Process

```r
# Start with small batches
s_configure(batch_size = 10)
results <- s_map(1:1000, slow_function, .session_id = "adaptive_processing")

# If it's working well, increase batch size for better performance
s_configure(batch_size = 50)
# Recovery will use the new batch size for remaining items
```

### Scenario 3: Manual Session Recovery

```r
# Check what sessions exist
sessions <- s_list_sessions()
print(sessions)

# Recover partial results for analysis
partial_results <- s_recover_session("large_job_20240115_140000")

# Analyze what we have so far
summary(partial_results)

# Decide whether to continue or restart with different parameters
```

---

## 🏆 Why Choose SafeMapper?

### Before SafeMapper 😰
```r
# Traditional approach - all or nothing
result <- map(large_dataset, expensive_function)
# ❌ If it fails at 90%, you lose everything
# ❌ No way to resume
# ❌ Manual error handling required
```

### With SafeMapper 🎉
```r
# SafeMapper approach - bulletproof
result <- s_map(large_dataset, expensive_function)
# ✅ Automatic progress saving
# ✅ Seamless recovery on restart
# ✅ Built-in error handling
# ✅ Detailed progress tracking
```

### Performance Comparison

| Scenario | Without SafeMapper | With SafeMapper |
|----------|-------------------|-----------------|
| **Success case** | ⚡ Fast | ⚡ Fast (minimal overhead) |
| **50% failure** | 🔥 100% loss | ✅ 50% saved, resume from 50% |
| **90% failure** | 😭 100% loss | 🎯 90% saved, resume from 90% |
| **Multiple failures** | 💀 Start over each time | 🔄 Progressive completion |

---

## 🔧 Troubleshooting & Best Practices

### Common Issues and Solutions

#### 1. **"Function not found" in parallel processing**
```r
# ❌ This may fail in parallel
s_future_map(data, my_custom_function)

# ✅ Solution: Include function in globals
s_future_map(data, my_custom_function, 
             .options = furrr_options(globals = c("my_custom_function")))

# ✅ Or use package namespace
s_future_map(data, MyPackage::my_function)
```

#### 2. **Memory issues with large datasets**
```r
# ✅ Use smaller batch sizes for memory-intensive operations
s_configure(batch_size = 10)  # Instead of default 50

# ✅ For very large data, consider chunking
large_data_chunks <- split(huge_dataset, ceiling(seq_len(nrow(huge_dataset))/1000))
results <- s_map(large_data_chunks, process_chunk)
```

#### 3. **Recovering from specific errors**
```r
# Check what went wrong
s_debug_session("failed_session_id")

# Clean up corrupted sessions
s_clean_sessions(status_filter = "corrupted")

# Manual recovery for inspection
partial_results <- s_recover_session("my_session")
summary(partial_results)
```

### Performance Tips

- **Batch size**: Larger batches = fewer checkpoints but more loss if failure occurs
- **Retry attempts**: Set higher for unstable operations (APIs, network calls)
- **Session cleanup**: Regular cleanup prevents disk space issues
- **Parallel processing**: Test with small data first to verify function compatibility

---

## 🤝 Contributing

We welcome contributions! SafeMapper is designed to be the most reliable functional programming package for R.

### Development Setup
```bash
git clone https://github.com/Zaoqu-Liu/SafeMapper.git
cd SafeMapper
R CMD INSTALL .
```

### Priority Areas
- Additional mapping function variants
- Integration with more parallel backends
- Performance optimizations
- Documentation improvements

---

## 📞 Support & Contact

- **Author**: Zaoqu Liu
- **Email**: liuzaoqu@163.com
- **GitHub**: [@Zaoqu-Liu](https://github.com/Zaoqu-Liu)
- **Issues**: [Report bugs or request features](https://github.com/Zaoqu-Liu/SafeMapper/issues)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

### 🛡️ SafeMapper: Because Your Time Is Valuable

*Never lose computational progress again. Start using SafeMapper today!*

[![GitHub stars](https://img.shields.io/github/stars/Zaoqu-Liu/SafeMapper?style=social)](https://github.com/Zaoqu-Liu/SafeMapper)

</div>