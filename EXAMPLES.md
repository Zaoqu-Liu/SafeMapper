# SafeMapper Examples & Use Cases

This document provides detailed examples of SafeMapper usage across different scenarios.

## 📚 Table of Contents

1. [Basic Usage Examples](#basic-usage-examples)
2. [API Integration Examples](#api-integration-examples)
3. [Data Processing Examples](#data-processing-examples)
4. [Parallel Processing Examples](#parallel-processing-examples)
5. [Recovery Scenarios](#recovery-scenarios)
6. [Error Handling Examples](#error-handling-examples)
7. [Session Management Examples](#session-management-examples)

## Basic Usage Examples

### Simple Mathematical Operations

```r
library(SafeMapper)

# Basic mapping with automatic recovery
numbers <- 1:100
squares <- s_map(numbers, function(x) x^2)

# Character operations
words <- c("hello", "world", "safe", "mapper")
uppercase <- s_map_chr(words, toupper)

# Logical operations
test_values <- 1:50
is_even <- s_map_lgl(test_values, function(x) x %% 2 == 0)
```

### Data Frame Operations

```r
# Create sample data
df_list <- list(
  data.frame(a = 1:3, b = 4:6),
  data.frame(a = 7:9, b = 10:12),
  data.frame(a = 13:15, b = 16:18)
)

# Row binding with recovery
combined_rows <- s_map_dfr(df_list, function(df) {
  # Simulate some processing
  df$sum <- df$a + df$b
  return(df)
}, .id = "source")

# Column binding with recovery
list_of_vectors <- list(
  x = 1:5,
  y = 6:10,
  z = 11:15
)
combined_cols <- s_map_dfc(list_of_vectors, function(x) x * 2)
```

## API Integration Examples

### REST API Calls with Rate Limiting

```r
library(httr)
library(jsonlite)

# Configure for API operations
s_configure(
  batch_size = 20,  # Save every 20 API calls
  retry_attempts = 5,
  session_id = "github_api_calls"
)

# Example: GitHub user data
usernames <- c("hadley", "jennybc", "yihui", "rstudio", "tidyverse")

github_data <- s_map(usernames, function(username) {
  url <- paste0("https://api.github.com/users/", username)
  
  response <- GET(url)
  
  if (status_code(response) == 200) {
    user_data <- fromJSON(content(response, "text"))
    return(list(
      login = user_data$login,
      name = user_data$name,
      public_repos = user_data$public_repos,
      followers = user_data$followers
    ))
  } else {
    warning(paste("Failed to fetch data for", username))
    return(NULL)
  }
}, .session_id = "github_users")
```

### Web Scraping with Recovery

```r
library(rvest)

# Configure for web scraping
s_configure(
  batch_size = 10,
  retry_attempts = 3,
  cache_dir = "scraping_cache"
)

# Example URLs to scrape
urls <- paste0("https://example.com/page/", 1:100)

scraped_data <- s_map(urls, function(url) {
  tryCatch({
    page <- read_html(url)
    title <- page %>% html_node("title") %>% html_text()
    return(list(url = url, title = title))
  }, error = function(e) {
    return(list(url = url, title = NA, error = e$message))
  })
}, .session_id = "web_scraping_batch")
```

## Data Processing Examples

### Large Dataset Processing

```r
# Simulate a large dataset
large_data <- data.frame(
  id = 1:10000,
  value = rnorm(10000),
  category = sample(letters[1:5], 10000, replace = TRUE)
)

# Split into chunks for processing
data_chunks <- split(large_data, ceiling(seq_len(nrow(large_data))/1000))

# Process each chunk with recovery
processed_chunks <- s_map(data_chunks, function(chunk) {
  # Simulate complex processing
  result <- chunk %>%
    group_by(category) %>%
    summarise(
      mean_value = mean(value),
      sd_value = sd(value),
      count = n(),
      .groups = "drop"
    )
  
  # Simulate potential failure point
  if (runif(1) < 0.05) {  # 5% chance of failure
    stop("Random processing error")
  }
  
  return(result)
}, .session_id = "large_data_processing")

# Combine results
final_result <- bind_rows(processed_chunks)
```

### File Processing Example

```r
# Get list of CSV files
csv_files <- list.files("data/", pattern = "\\.csv$", full.names = TRUE)

# Process each file with recovery
processed_files <- s_map(csv_files, function(file_path) {
  cat("Processing:", basename(file_path), "\n")
  
  # Read and process file
  data <- read.csv(file_path)
  
  # Perform analysis
  summary_stats <- list(
    file = basename(file_path),
    rows = nrow(data),
    cols = ncol(data),
    numeric_cols = sum(sapply(data, is.numeric)),
    missing_values = sum(is.na(data))
  )
  
  # Simulate potential I/O errors
  if (file.size(file_path) == 0) {
    stop("Empty file detected")
  }
  
  return(summary_stats)
}, .session_id = "file_batch_processing")
```

## Parallel Processing Examples

### CPU-Intensive Parallel Operations

```r
library(future)

# Set up parallel backend
plan(multisession, workers = 4)

# Configure SafeMapper for parallel processing
s_configure(
  batch_size = 25,
  session_id = "parallel_computation"
)

# CPU-intensive function
monte_carlo_pi <- function(n) {
  x <- runif(n, -1, 1)
  y <- runif(n, -1, 1)
  inside_circle <- sum(x^2 + y^2 <= 1)
  return(4 * inside_circle / n)
}

# Run parallel estimation with different sample sizes
sample_sizes <- rep(1000000, 100)  # 100 estimations

pi_estimates <- s_future_map(sample_sizes, monte_carlo_pi,
                           .session_id = "pi_estimation")

# Calculate final estimate
mean_pi <- mean(unlist(pi_estimates))
cat("Estimated π:", mean_pi, "\n")

# Reset to sequential
plan(sequential)
```

### Parallel Data Transformation

```r
library(future)
plan(multisession, workers = 6)

# Large matrix operations
matrices <- replicate(50, matrix(rnorm(1000), 100, 100), simplify = FALSE)

# Parallel matrix operations with recovery
results <- s_future_map(matrices, function(mat) {
  # Complex matrix operations
  eigenvals <- eigen(mat, only.values = TRUE)$values
  determinant <- det(mat)
  trace <- sum(diag(mat))
  
  return(list(
    max_eigenval = max(Re(eigenvals)),
    determinant = determinant,
    trace = trace
  ))
}, .session_id = "matrix_operations")

plan(sequential)
```

## Recovery Scenarios

### Scenario 1: Network Interruption Recovery

```r
# Simulate unreliable network function
unreliable_api_call <- function(id) {
  # Simulate network failures
  if (runif(1) < 0.1) {  # 10% failure rate
    stop("Network timeout")
  }
  
  # Simulate API response
  Sys.sleep(0.1)  # Simulate network delay
  return(paste("Data for ID", id))
}

# Start processing
ids <- 1:500

# This will likely fail partway through
tryCatch({
  results <- s_map(ids, unreliable_api_call, .session_id = "network_batch")
}, error = function(e) {
  cat("Process failed:", e$message, "\n")
  
  # Check progress
  sessions <- s_list_sessions()
  current_session <- sessions[sessions$session_id == "network_batch", ]
  cat("Completed:", current_session$items_completed, "out of", current_session$total_items, "\n")
})

# Create more reliable version
reliable_api_call <- function(id) {
  max_retries <- 3
  for (i in 1:max_retries) {
    tryCatch({
      return(unreliable_api_call(id))
    }, error = function(e) {
      if (i == max_retries) stop(e)
      Sys.sleep(0.5)  # Wait before retry
    })
  }
}

# Resume with improved function
results <- s_map(ids, reliable_api_call, .session_id = "network_batch")
```

### Scenario 2: Memory Error Recovery

```r
# Function that occasionally uses too much memory
memory_intensive_function <- function(x) {
  # Randomly create large objects
  if (x %% 50 == 0) {
    # This might cause memory issues
    large_matrix <- matrix(rnorm(x * 10000), ncol = 100)
    return(sum(large_matrix))
  } else {
    return(x^2)
  }
}

# Process with potential memory issues
data_range <- 1:1000

tryCatch({
  results <- s_map(data_range, memory_intensive_function, 
                  .session_id = "memory_intensive")
}, error = function(e) {
  cat("Memory error occurred:", e$message, "\n")
  
  # Check what was completed
  sessions <- s_list_sessions()
  session_info <- sessions[sessions$session_id == "memory_intensive", ]
  cat("Progress saved at:", session_info$items_completed, "items\n")
})

# Optimized version
optimized_function <- function(x) {
  if (x %% 50 == 0) {
    # Process in smaller chunks to avoid memory issues
    chunk_size <- 1000
    total_sum <- 0
    for (i in seq(1, x * 10000, by = chunk_size)) {
      end_idx <- min(i + chunk_size - 1, x * 10000)
      chunk <- rnorm(end_idx - i + 1)
      total_sum <- total_sum + sum(chunk)
    }
    return(total_sum)
  } else {
    return(x^2)
  }
}

# Resume with optimized function
results <- s_map(data_range, optimized_function, .session_id = "memory_intensive")
```

## Error Handling Examples

### Using Safe Wrappers

```r
# Function that sometimes fails
risky_operation <- function(x) {
  if (x %% 13 == 0) stop("Unlucky number!")
  return(sqrt(x))
}

# Option 1: Use s_safely for detailed error info
safe_operation <- s_safely(risky_operation, otherwise = NA)
results_safe <- s_map(1:50, safe_operation)

# Extract successful results and errors
successes <- map(results_safe, "result")
errors <- map(results_safe, "error")

# Option 2: Use s_possibly for default values
possible_operation <- s_possibly(risky_operation, otherwise = -1)
results_possible <- s_map(1:50, possible_operation)

# Option 3: Use s_quietly to capture all output
quiet_operation <- s_quietly(risky_operation)
results_quiet <- s_map(1:50, quiet_operation)
```

### Custom Error Recovery

```r
# Function with custom error handling
process_with_fallback <- function(x) {
  primary_result <- tryCatch({
    # Primary method
    complex_calculation(x)
  }, error = function(e) {
    # Fallback method
    warning(paste("Primary method failed for", x, "- using fallback"))
    simple_calculation(x)
  })
  
  return(primary_result)
}

# Complex calculation that might fail
complex_calculation <- function(x) {
  if (x > 100) stop("Value too large for complex method")
  return(log(x) * exp(x))
}

# Simple fallback calculation
simple_calculation <- function(x) {
  return(x^2)
}

# Process with automatic fallback
data_points <- 1:150
results <- s_map(data_points, process_with_fallback, 
                .session_id = "fallback_processing")
```

## Session Management Examples

### Advanced Session Monitoring

```r
# Start multiple long-running operations
session_ids <- c("batch_1", "batch_2", "batch_3")

# Launch operations
for (i in 1:3) {
  data <- 1:(100 * i)
  s_map(data, function(x) {
    Sys.sleep(0.01)  # Simulate work
    return(x^2)
  }, .session_id = session_ids[i])
}

# Monitor progress
monitor_sessions <- function() {
  sessions <- s_list_sessions()
  
  for (session_id in session_ids) {
    session_info <- sessions[sessions$session_id == session_id, ]
    if (nrow(session_info) > 0) {
      progress <- session_info$completion_rate * 100
      cat(sprintf("%s: %.1f%% complete\n", session_id, progress))
    }
  }
}

# Check progress periodically
monitor_sessions()
```

### Cleanup and Maintenance

```r
# View all sessions
all_sessions <- s_list_sessions()
cat("Total sessions:", nrow(all_sessions), "\n")

# Clean up old sessions (older than 3 days)
removed_count <- s_clean_sessions(older_than_days = 3)
cat("Removed", removed_count, "old sessions\n")

# Clean up only failed sessions
failed_removed <- s_clean_sessions(status_filter = "failed")
cat("Removed", failed_removed, "failed sessions\n")

# Get detailed statistics
s_session_stats()

# Debug a specific problematic session
if (nrow(all_sessions) > 0) {
  problem_session <- all_sessions$session_id[1]
  s_debug_session(problem_session)
}
```

### Configuration Management

```r
# Save current configuration
current_config <- s_configure()

# Experiment with different settings
s_configure(
  batch_size = 10,
  retry_attempts = 5,
  cache_dir = "experiment_cache"
)

# Run experiment
experiment_data <- 1:100
experiment_results <- s_map(experiment_data, slow_function, 
                           .session_id = "experiment_1")

# Restore original configuration
do.call(s_configure, current_config)

# Verify restoration
restored_config <- s_configure()
identical(current_config, restored_config)
```

---

These examples demonstrate the power and flexibility of SafeMapper across various use cases. The key benefit is that **any of these operations can be interrupted and resumed seamlessly**, making SafeMapper ideal for production environments where reliability is crucial.