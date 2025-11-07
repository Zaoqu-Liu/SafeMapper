#!/usr/bin/env Rscript
# =============================================================================
# SafeMapper Deep Validation - 深度验证测试
# =============================================================================

library(SafeMapper)

cat("\n╔══════════════════════════════════════════════════════════════╗\n")
cat("║        SafeMapper Deep Validation Test Suite                ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n")

passed <- 0
failed <- 0

test <- function(name, code) {
  cat(sprintf("\n[TEST] %s\n", name))
  result <- tryCatch({
    code
    passed <<- passed + 1
    cat("  ✓ PASSED\n")
    TRUE
  }, error = function(e) {
    failed <<- failed + 1
    cat(sprintf("  ✗ FAILED: %s\n", e$message))
    FALSE
  })
}

# =============================================================================
# 1. 边界条件测试
# =============================================================================

cat("\n\n【1】边界条件测试\n")
cat(paste0(rep("─", 60), collapse = ""), "\n")

test("单元素向量", {
  result <- s_map(5, ~ .x * 2)
  stopifnot(length(result) == 1)
  stopifnot(result[[1]] == 10)
})

test("大型向量 (10000 元素)", {
  s_configure(batch_size = 500)
  result <- s_map(1:10000, ~ .x %% 100)
  stopifnot(length(result) == 10000)
})

test("空输入错误处理", {
  result <- tryCatch(s_map(c(), ~ .x), error = function(e) "error")
  stopifnot(result == "error")
})

test("NULL 值处理", {
  result <- s_map(1:5, function(x) if (x == 3) NULL else x)
  stopifnot(length(result) == 5)
  stopifnot(is.null(result[[3]]))
})

test("NA 值处理", {
  result <- s_map(c(1, NA, 3), function(x) if (is.na(x)) 0 else x)
  stopifnot(result[[2]] == 0)
})

# =============================================================================
# 2. 类型转换测试
# =============================================================================

cat("\n\n【2】类型转换测试\n")
cat(paste0(rep("─", 60), collapse = ""), "\n")

test("s_map_chr 字符转换", {
  result <- s_map_chr(1:5, ~ paste0("item_", .x))
  stopifnot(is.character(result))
  stopifnot(length(result) == 5)
  stopifnot(result[1] == "item_1")
})

test("s_map_dbl 数值转换", {
  result <- s_map_dbl(1:5, ~ .x * 1.5)
  stopifnot(is.numeric(result))
  stopifnot(all.equal(result, seq(1.5, 7.5, by = 1.5)))
})

test("s_map_int 整数转换", {
  result <- s_map_int(1:5, ~ as.integer(.x * 2))
  stopifnot(is.integer(result))
  stopifnot(identical(result, c(2L, 4L, 6L, 8L, 10L)))
})

test("s_map_lgl 逻辑转换", {
  result <- s_map_lgl(1:10, ~ .x > 5)
  stopifnot(is.logical(result))
  stopifnot(sum(result) == 5)
})

test("s_map_dfr 数据框行绑定", {
  result <- s_map_dfr(1:5, function(x) {
    data.frame(id = x, value = x^2)
  })
  stopifnot(is.data.frame(result))
  stopifnot(nrow(result) == 5)
  stopifnot(all(result$value == (1:5)^2))
})

test("s_map_dfc 数据框列绑定", {
  result <- s_map_dfc(1:3, function(x) {
    setNames(data.frame(x^2), paste0("col", x))
  })
  stopifnot(is.data.frame(result))
  stopifnot(ncol(result) == 3)
})

# =============================================================================
# 3. 恢复机制深度测试
# =============================================================================

cat("\n\n【3】恢复机制深度测试\n")
cat(paste0(rep("─", 60), collapse = ""), "\n")

test("中断后完美恢复", {
  session_id <- sprintf("recovery_test_%d", as.integer(Sys.time()))
  s_configure(batch_size = 10, retry_attempts = 1)

  # 第一次运行 - 故意在第25个元素失败
  counter <- 0
  fail_func <- function(x) {
    counter <<- counter + 1
    if (counter == 25) stop("Intentional failure")
    x * 2
  }

  first_run <- tryCatch({
    s_map(1:50, fail_func, .session_id = session_id)
  }, error = function(e) NULL)

  # 验证进度被保存
  sessions <- s_list_sessions()
  stopifnot(session_id %in% sessions$session_id)
  session_info <- sessions[sessions$session_id == session_id, ]

  cat(sprintf("    保存进度: %d/%d 项\n",
             session_info$items_completed, session_info$total_items))

  # 第二次运行 - 使用正常函数恢复
  counter <- 0
  success_func <- function(x) x * 2

  second_run <- s_map(1:50, success_func, .session_id = session_id)

  stopifnot(length(second_run) == 50)
  stopifnot(all(unlist(second_run) == (1:50) * 2))

  # 清理
  s_clean_sessions(session_ids = session_id)
})

test("多次中断恢复", {
  session_id <- sprintf("multi_recovery_%d", as.integer(Sys.time()))
  s_configure(batch_size = 5)

  # 模拟多次失败和恢复
  for (attempt in 1:3) {
    counter <- 0
    result <- tryCatch({
      s_map(1:20, function(x) {
        counter <<- counter + 1
        if (counter == 7 * attempt && attempt < 3) {
          stop("Planned failure")
        }
        x
      }, .session_id = session_id)
    }, error = function(e) NULL)

    if (!is.null(result)) break
  }

  stopifnot(!is.null(result))
  stopifnot(length(result) == 20)

  s_clean_sessions(session_ids = session_id)
})

# =============================================================================
# 4. 并行处理测试
# =============================================================================

cat("\n\n【4】并行处理测试\n")
cat(paste0(rep("─", 60), collapse = ""), "\n")

test("s_future_map 顺序执行", {
  library(future)
  plan(sequential)

  result <- s_future_map(1:20, ~ .x^2)
  expected <- as.list((1:20)^2)

  stopifnot(length(result) == 20)
  stopifnot(all(unlist(result) == unlist(expected)))
})

test("s_future_map 多进程执行", {
  library(future)
  plan(multisession, workers = 2)

  result <- s_future_map(1:30, function(x) {
    Sys.sleep(0.01)
    x * 3
  })

  plan(sequential)

  stopifnot(length(result) == 30)
  stopifnot(all(unlist(result) == (1:30) * 3))
})

test("s_future_map2 并行处理", {
  library(future)
  plan(multisession, workers = 2)

  result <- s_future_map2(1:20, 21:40, `+`)

  plan(sequential)

  stopifnot(length(result) == 20)
  expected_vals <- (1:20) + (21:40)
  stopifnot(all(unlist(result) == expected_vals))
})

# =============================================================================
# 5. pmap 和 walk 函数测试
# =============================================================================

cat("\n\n【5】pmap 和 walk 函数测试\n")
cat(paste0(rep("─", 60), collapse = ""), "\n")

test("s_pmap 多参数处理", {
  data <- list(
    x = 1:10,
    y = 11:20,
    z = 21:30
  )

  result <- s_pmap(data, function(x, y, z) x + y + z)

  stopifnot(length(result) == 10)
  expected <- (1:10) + (11:20) + (21:30)
  stopifnot(all(unlist(result) == expected))
})

test("s_pmap 复杂数据结构", {
  data <- list(
    a = c("A", "B", "C"),
    b = 1:3,
    c = c(TRUE, FALSE, TRUE)
  )

  result <- s_pmap(data, function(a, b, c) {
    list(letter = a, number = b, flag = c)
  })

  stopifnot(length(result) == 3)
  stopifnot(result[[1]]$letter == "A")
  stopifnot(result[[2]]$number == 2)
})

test("s_walk 副作用执行", {
  accumulator <- numeric(0)
  s_walk(1:10, function(x) {
    accumulator <<- c(accumulator, x^2)
  })

  stopifnot(length(accumulator) == 10)
  stopifnot(all(accumulator == (1:10)^2))
})

test("s_walk2 双输入副作用", {
  results <- character(0)
  s_walk2(letters[1:5], 1:5, function(x, y) {
    results <<- c(results, paste(x, y, sep = ":"))
  })

  stopifnot(length(results) == 5)
  stopifnot(results[1] == "a:1")
})

# =============================================================================
# 6. imap 函数测试
# =============================================================================

cat("\n\n【6】imap 函数测试\n")
cat(paste0(rep("─", 60), collapse = ""), "\n")

test("s_imap 索引访问", {
  result <- s_imap(c("a", "b", "c"), function(val, idx) {
    paste(idx, val, sep = ":")
  })

  stopifnot(length(result) == 3)
  stopifnot(result[[1]] == "1:a")
  stopifnot(result[[3]] == "3:c")
})

test("s_imap_chr 字符返回", {
  result <- s_imap_chr(c("x", "y", "z"), function(val, idx) {
    sprintf("[%d]%s", idx, val)
  })

  stopifnot(is.character(result))
  stopifnot(result[2] == "[2]y")
})

test("s_imap 命名列表", {
  named_list <- list(apple = 5, banana = 3, cherry = 8)
  result <- s_imap(named_list, function(val, name) {
    paste(name, ":", val)
  })

  stopifnot(result[[1]] == "apple : 5")
})

# =============================================================================
# 7. 错误处理函数测试
# =============================================================================

cat("\n\n【7】错误处理函数测试\n")
cat(paste0(rep("─", 60), collapse = ""), "\n")

test("s_safely 错误捕获", {
  safe_log <- s_safely(log)

  r1 <- safe_log(10)
  r2 <- safe_log(-1)
  r3 <- safe_log("invalid")

  stopifnot(!is.null(r1$result))
  stopifnot(is.null(r1$error))
  stopifnot(!is.null(r3$error))
})

test("s_possibly 默认值返回", {
  possible_sqrt <- s_possibly(function(x) {
    if (x < 0) stop("Negative number")
    sqrt(x)
  }, otherwise = NA)

  r1 <- possible_sqrt(9)
  r2 <- possible_sqrt(-4)

  stopifnot(r1 == 3)
  stopifnot(is.na(r2))
})

test("s_quietly 副作用捕获", {
  quiet_print <- s_quietly(function(x) {
    message("Processing: ", x)
    print(x)
    x * 2
  })

  result <- quiet_print(5)

  stopifnot(result$result == 10)
  stopifnot(length(result$messages) > 0)
})

# =============================================================================
# 8. Session 管理测试
# =============================================================================

cat("\n\n【8】Session 管理测试\n")
cat(paste0(rep("─", 60), collapse = ""), "\n")

test("s_configure 配置修改", {
  original <- s_configure()
  s_configure(batch_size = 100, retry_attempts = 5)

  # 通过实际运行验证配置生效
  session_id <- sprintf("config_test_%d", as.integer(Sys.time()))

  # 创建一个会失败的任务来检查 checkpoint
  tryCatch({
    counter <- 0
    s_map(1:150, function(x) {
      counter <<- counter + 1
      if (counter == 101) stop("Test")
      x
    }, .session_id = session_id)
  }, error = function(e) NULL)

  sessions <- s_list_sessions()
  if (session_id %in% sessions$session_id) {
    info <- sessions[sessions$session_id == session_id, ]
    # 批次大小为100，所以应该完成100个
    stopifnot(info$items_completed == 100)
  }

  s_clean_sessions(session_ids = session_id)

  # 恢复原配置
  do.call(s_configure, original)
})

test("s_list_sessions 列表功能", {
  sessions <- s_list_sessions()
  stopifnot(is.data.frame(sessions))
  stopifnot(all(c("session_id", "created", "items_completed",
                 "total_items", "completion_rate", "status") %in% names(sessions)))
})

test("s_clean_sessions 清理功能", {
  # 创建一些测试session
  test_ids <- sprintf("cleanup_test_%d", 1:3)

  for (id in test_ids) {
    tryCatch({
      s_map(1:5, function(x) if (x == 3) stop("test") else x,
           .session_id = id)
    }, error = function(e) NULL)
  }

  # 清理这些sessions
  s_clean_sessions(session_ids = test_ids)

  # 验证已清理
  sessions <- s_list_sessions()
  stopifnot(!any(test_ids %in% sessions$session_id))
})

# =============================================================================
# 9. 性能和稳定性测试
# =============================================================================

cat("\n\n【9】性能和稳定性测试\n")
cat(paste0(rep("─", 60), collapse = ""), "\n")

test("高频小批次处理", {
  s_configure(batch_size = 5)

  start <- Sys.time()
  result <- s_map(1:100, ~ .x * 2)
  elapsed <- as.numeric(Sys.time() - start)

  stopifnot(length(result) == 100)
  cat(sprintf("    性能: 100项/%.2f秒, %.1f项/秒\n",
             elapsed, 100/elapsed))
})

test("大批次处理", {
  s_configure(batch_size = 500)

  start <- Sys.time()
  result <- s_map(1:2000, ~ .x %% 100)
  elapsed <- as.numeric(Sys.time() - start)

  stopifnot(length(result) == 2000)
  cat(sprintf("    性能: 2000项/%.2f秒, %.1f项/秒\n",
             elapsed, 2000/elapsed))
})

test("混合数据类型处理", {
  mixed_data <- list(
    1, "text", TRUE, NULL, NA,
    list(a = 1), data.frame(x = 1:3),
    c(1, 2, 3), factor("a")
  )

  result <- s_map(mixed_data, function(x) {
    list(type = class(x)[1], value = x)
  })

  stopifnot(length(result) == length(mixed_data))
})

# =============================================================================
# 10. 公式语法和高级特性
# =============================================================================

cat("\n\n【10】公式语法和高级特性\n")
cat(paste0(rep("─", 60), collapse = ""), "\n")

test("公式语法 ~ .x", {
  result <- s_map(1:10, ~ .x^2)
  stopifnot(all(unlist(result) == (1:10)^2))
})

test("公式语法双变量 ~ .x + .y", {
  result <- s_map2(1:5, 6:10, ~ .x * .y)
  expected <- (1:5) * (6:10)
  stopifnot(all(unlist(result) == expected))
})

test("匿名函数 \\(x)", {
  result <- s_map(1:5, \(x) x + 100)
  stopifnot(all(unlist(result) == 101:105))
})

test("额外参数传递", {
  add_n <- function(x, n) x + n
  result <- s_map(1:5, add_n, n = 10)
  stopifnot(all(unlist(result) == 11:15))
})

# =============================================================================
# 最终报告
# =============================================================================

cat("\n\n")
cat("╔══════════════════════════════════════════════════════════════╗\n")
cat("║                    VALIDATION REPORT                         ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n")

total <- passed + failed
success_rate <- round(100 * passed / total, 1)

cat(sprintf("\n总测试数: %d\n", total))
cat(sprintf("通过: %d\n", passed))
cat(sprintf("失败: %d\n", failed))
cat(sprintf("成功率: %.1f%%\n", success_rate))

if (failed == 0) {
  cat("\n🎉 所有深度验证测试通过！\n")
  cat("SafeMapper 包经过全面验证，可以安全使用。\n\n")
} else {
  cat("\n⚠ 发现问题，请查看上面的失败测试。\n\n")
  quit(status = 1)
}
