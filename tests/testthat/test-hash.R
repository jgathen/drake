drake_context("hash")

test_with_dir("available hash algos", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  x <- available_hash_algos()
  expect_true(length(x) > 0)
  expect_true(is.character(x))
})

test_with_dir("illegal hashes", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  x <- drake_plan(a = 1)
  expect_error(
    make(
      x,
      short_hash_algo = "no_such_algo_aslkdjfoiewlk",
      session_info = FALSE
    )
  )
  expect_error(
    make(
      x,
      long_hash_algo = "no_such_algo_aslkdjfoiewlk",
      session_info = FALSE
    )
  )
})

test_with_dir("stress test file hash", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  load_mtcars_example()
  con <- drake_config(my_plan, verbose = FALSE)
  make_imports(con)
  expect_true(is.character(file_hash("'report.Rmd'", config = con, 0)))
  expect_true(is.character(file_hash("'report.Rmd'", config = con, Inf)))
})

test_with_dir("stress test hashing decisions", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  file <- "input.rds"
  expect_true(should_rehash_file(
    filename = file, new_mtime = 0, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    filename = file, new_mtime = 1, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    filename = file, new_mtime = 0, old_mtime = 1, size_cutoff = Inf))
  expect_true(should_rehash_file(
    filename = file, new_mtime = 0, old_mtime = 0, size_cutoff = -1))
  expect_true(should_rehash_file(
    filename = file, new_mtime = 1, old_mtime = 0, size_cutoff = -1))
  expect_true(should_rehash_file(
    filename = file, new_mtime = 0, old_mtime = 1, size_cutoff = -1))
})

test_with_dir("more stress testing of hashing decisions", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  file <- "input.rds"
  saveRDS(1, file = file)
  expect_true(file.exists(file))
  expect_true(should_rehash_file(
    filename = file, new_mtime = 1, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    filename = file, new_mtime = 0, old_mtime = 1, size_cutoff = Inf))
  expect_true(should_rehash_file(
    filename = file, new_mtime = 0, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    filename = file, new_mtime = 1, old_mtime = 0, size_cutoff = -1))
  expect_false(should_rehash_file(
    filename = file, new_mtime = 0, old_mtime = 1, size_cutoff = -1))
  expect_false(should_rehash_file(
    filename = file, new_mtime = 0, old_mtime = 0, size_cutoff = -1))
})
