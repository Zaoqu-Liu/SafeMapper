test_that("s_map works identically to purrr::map", {
  # Basic functionality
  input <- 1:5
  func <- function(x) x^2

  expect_equal(s_map(input, func), purrr::map(input, func))
})

test_that("s_map_chr works identically to purrr::map_chr", {
  input <- 1:3
  func <- function(x) paste("item", x)

  expect_equal(s_map_chr(input, func), purrr::map_chr(input, func))
})

test_that("configuration works correctly", {
  old_config <- s_configure(batch_size = 25)

  expect_equal(.safemapper_sessions$config$batch_size, 25L)

  # Reset
  s_configure(batch_size = 50L)
})

test_that("session management functions work", {
  # Test session listing (should not error)
  expect_silent(s_list_sessions())

  # Test session stats (should not error)
  expect_silent(s_session_stats())
})

test_that("empty input handling", {
  expect_warning(result <- s_map(c(), function(x) x))
  expect_equal(length(result), 0)
})
