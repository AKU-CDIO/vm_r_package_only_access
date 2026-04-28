# admin.R — Administrative functions for package management

#' View access log
#'
#' @param n Maximum number of recent entries to show (default: 50)
#' @param user Optional filter for specific user
#' @param action Optional filter for specific action
#'
#' @export
#' @examples
#' \dontrun{
#' vmronly_log()
#' vmronly_log(user = "researcher1")
#' vmronly_log(action = "CONNECT")
#' }
vmronly_log <- function(n = 50, user = NULL, action = NULL) {
  assert_vm()
  
  current_user <- get_windows_user()
  perms <- load_permissions()
  
  # Check admin permission
  if (!isTRUE(perms$admins[[current_user]])) {
    cli::cli_abort("Only administrators can view access logs.")
  }
  
  if (!file.exists(VMRONLY_LOG_FILE)) {
    cli::cli_alert_info("No access log found.")
    return(invisible(NULL))
  }
  
  # Read log file
  log_lines <- readLines(VMRONLY_LOG_FILE)
  log_entries <- lapply(log_lines, function(line) {
    tryCatch({
      jsonlite::fromJSON(line)
    }, error = function(e) NULL)
  })
  log_entries <- log_entries[!sapply(log_entries, is.null)]
  
  # Filter entries
  if (!is.null(user)) {
    log_entries <- log_entries[sapply(log_entries, function(x) x$user == user)]
  }
  
  if (!is.null(action)) {
    log_entries <- log_entries[sapply(log_entries, function(x) x$action == action)]
  }
  
  # Sort by timestamp (newest first)
  timestamps <- sapply(log_entries, function(x) as.POSIXct(x$timestamp))
  log_entries <- log_entries[order(timestamps, decreasing = TRUE)]
  
  # Limit results
  if (length(log_entries) > n) {
    log_entries <- log_entries[seq_len(n)]
  }
  
  # Display results
  if (length(log_entries) == 0) {
    cli::cli_alert_info("No log entries match the criteria.")
  } else {
    cli::cli_h2("Recent Access Log")
    for (entry in log_entries) {
      status_color <- if (entry$status == "SUCCESS") "green" else "red"
      cli::cli_li("{entry$timestamp} - {entry$user} - {entry$action} - ")
      cli::cli_span("{entry$details}", .style = list(color = status_color))
    }
  }
  
  invisible(log_entries)
}

#' Show package status and configuration
#'
#' @export
#' @examples
#' \dontrun{
#' vmronly_status()
#' }
vmronly_status <- function() {
  assert_vm()
  
  cli::cli_h1("VM-Restricted Package Status")
  
  # System info
  cli::cli_h2("System Information")
  cli::cli_li("Hostname: {Sys.info()['nodename']}")
  cli::cli_li("User: {get_windows_user()}")
  cli::cli_li("R Version: {R.version.string}")
  cli::cli_li("Platform: {.Platform$OS.type}")
  
  # Package files
  cli::cli_h2("Configuration Files")
  cli::cli_li("Config path: {VMRONLY_CONFIG_PATH}")
  cli::cli_li("Credentials file: {ifelse(file.exists(VMRONLY_CRED_FILE), 'EXISTS', 'MISSING')}")
  cli::cli_li("Permissions file: {ifelse(file.exists(VMRONLY_PERM_FILE), 'EXISTS', 'MISSING')}")
  cli::cli_li("Log file: {ifelse(file.exists(VMRONLY_LOG_FILE), 'EXISTS', 'MISSING')}")
  
  # User permissions
  tryCatch({
    current_user <- get_windows_user()
    perms <- load_permissions()
    user_perms <- get_user_permissions(current_user)
    
    cli::cli_h2("Your Permissions")
    cli::cli_li("User: {current_user}")
    cli::cli_li("Admin: {user_perms$is_admin}")
    
    if (!user_perms$is_admin) {
      cli::cli_li("Tables: {paste(user_perms$tables, collapse = ', ')}")
      cli::cli_li("Can download: {user_perms$can_download}")
    }
    
  }, error = function(e) {
    cli::cli_alert_warning("Could not load permissions: {e$message}")
  })
  
  # Database connection status
  tryCatch({
    if (file.exists(VMRONLY_CRED_FILE)) {
      creds <- load_credentials()
      cli::cli_h2("Database Configuration")
      cli::cli_li("Server: {creds$server}")
      cli::cli_li("Database: {creds$database}")
      cli::cli_li("Configured by: {creds$stored_by}")
      cli::cli_li("Configured at: {creds$stored_at}")
    }
  }, error = function(e) {
    cli::cli_alert_warning("Could not load database configuration: {e$message}")
  })
  
  invisible(NULL)
}

#' Test package functionality
#'
#' Performs a series of tests to verify the package is working correctly.
#' This is useful for troubleshooting and validation.
#'
#' @export
#' @examples
#' \dontrun{
#' vmronly_test()
#' }
vmronly_test <- function() {
  assert_vm()
  
  cli::cli_h1("VM-Restricted Package Tests")
  
  tests <- list()
  
  # Test 1: VM validation
  tryCatch({
    assert_vm()
    tests$vm_check <- "PASS"
    cli::cli_alert_success("VM validation: PASS")
  }, error = function(e) {
    tests$vm_check <- "FAIL"
    cli::cli_alert_danger("VM validation: FAIL - {e$message}")
  })
  
  # Test 2: User detection
  tryCatch({
    user <- get_windows_user()
    tests$user_detection <- "PASS"
    cli::cli_alert_success("User detection: PASS ({user})")
  }, error = function(e) {
    tests$user_detection <- "FAIL"
    cli::cli_alert_danger("User detection: FAIL - {e$message}")
  })
  
  # Test 3: Configuration files
  config_files <- list(
    credentials = VMRONLY_CRED_FILE,
    permissions = VMRONLY_PERM_FILE,
    log = VMRONLY_LOG_FILE
  )
  
  for (name in names(config_files)) {
    if (file.exists(config_files[[name]])) {
      tests[[paste0("config_", name)]] <- "PASS"
      cli::cli_alert_success("Config file ({name}): EXISTS")
    } else {
      tests[[paste0("config_", name)]] <- "MISSING"
      cli::cli_alert_warning("Config file ({name}): MISSING")
    }
  }
  
  # Test 4: Permissions loading
  tryCatch({
    if (file.exists(VMRONLY_PERM_FILE)) {
      perms <- load_permissions()
      tests$permissions_load <- "PASS"
      cli::cli_alert_success("Permissions loading: PASS")
    } else {
      tests$permissions_load <- "SKIP"
      cli::cli_alert_info("Permissions loading: SKIP (no permissions file)")
    }
  }, error = function(e) {
    tests$permissions_load <- "FAIL"
    cli::cli_alert_danger("Permissions loading: FAIL - {e$message}")
  })
  
  # Test 5: Database credentials
  tryCatch({
    if (file.exists(VMRONLY_CRED_FILE)) {
      creds <- load_credentials()
      tests$credentials_load <- "PASS"
      cli::cli_alert_success("Credentials loading: PASS")
    } else {
      tests$credentials_load <- "SKIP"
      cli::cli_alert_info("Credentials loading: SKIP (no credentials file)")
    }
  }, error = function(e) {
    tests$credentials_load <- "FAIL"
    cli::cli_alert_danger("Credentials loading: FAIL - {e$message}")
  })
  
  # Summary
  cli::cli_h2("Test Summary")
  pass_count <- sum(tests == "PASS")
  total_count <- length(tests)
  
  cli::cli_alert_info("Tests passed: {pass_count}/{total_count}")
  
  if (pass_count == total_count) {
    cli::cli_alert_success("All tests passed! Package is ready to use.")
  } else {
    cli::cli_alert_warning("Some tests failed. Check the configuration.")
  }
  
  invisible(tests)
}
