# utils.R — Security and utility functions

# Package constants
VMRONLY_CONFIG_PATH <- "~/.vmronly"
VMRONLY_CRED_FILE   <- file.path(VMRONLY_CONFIG_PATH, "credentials.rds")
VMRONLY_PERM_FILE   <- file.path(VMRONLY_CONFIG_PATH, "permissions.json")
VMRONLY_LOG_FILE    <- file.path(VMRONLY_CONFIG_PATH, "access.log")

#' Assert that code is running on the approved VM
#' @keywords internal
assert_vm <- function() {
  # Get current machine info
  hostname <- Sys.info()["nodename"]
  user <- Sys.info()["user"]
  
  # Check if we're on the approved VM (you can customize these values)
  approved_hostnames <- c("UZIMA-VM-01", "UZIMA-VM-02", "UZIMA-RESEARCH-VM")
  approved_users <- c("admindsvm", "researcher1", "researcher2")
  
  if (!hostname %in% approved_hostnames) {
    cli::cli_abort(c(
      "x" = "This package can only run on approved UZIMA research VMs.",
      "i" = "Current hostname: {hostname}",
      "i" = "Contact your administrator for access."
    ))
  }
  
  invisible(TRUE)
}

#' Get current Windows user
#' @keywords internal
get_windows_user <- function() {
  if (.Platform$OS.type == "windows") {
    # Try multiple methods to get Windows user
    user <- Sys.getenv("USERNAME")
    if (user == "") {
      user <- Sys.getenv("USER")
    }
    if (user == "") {
      user <- Sys.info()["user"]
    }
    return(user)
  } else {
    cli::cli_abort("This package is designed for Windows VMs only.")
  }
}

#' Get machine-specific encryption key
#' @keywords internal
get_machine_key <- function() {
  # Create a machine-specific key using hostname and user
  machine_info <- paste0(
    Sys.info()["nodename"], 
    Sys.info()["user"],
    Sys.info()["release"]
  )
  openssl::sha256(machine_info)
}

#' Encrypt string with machine key
#' @keywords internal
encrypt_string <- function(text, key) {
  openssl::aes_cbc_encrypt(
    data = charToRaw(text),
    key = key,
    iv = raw(16)  # Zero IV for simplicity (in production, use random IV)
  )
}

#' Decrypt string with machine key
#' @keywords internal
decrypt_string <- function(encrypted, key) {
  rawToChar(openssl::aes_cbc_decrypt(
    data = encrypted,
    key = key,
    iv = raw(16)  # Zero IV for simplicity (in production, use random IV)
  ))
}

#' Log access attempts
#' @keywords internal
log_access <- function(user, action, details, status = "SUCCESS") {
  log_entry <- list(
    timestamp = as.character(Sys.time()),
    user = user,
    action = action,
    details = details,
    status = status
  )
  
  # Create log directory if needed
  dir.create(dirname(VMRONLY_LOG_FILE), recursive = TRUE, showWarnings = FALSE)
  
  # Append to log file
  log_line <- jsonlite::toJSON(log_entry, auto_unbox = TRUE)
  cat(log_line, "\n", file = VMRONLY_LOG_FILE, append = TRUE)
  
  invisible(log_entry)
}

#' Initialize the VM-Restricted package (admin setup)
#'
#' Creates the necessary configuration files and sets up initial permissions.
#' This should only be run once by the VM administrator.
#'
#' @export
#' @examples
#' \dontrun{
#' vmronly_init()
#' }
vmronly_init <- function() {
  assert_vm()
  
  current_user <- get_windows_user()
  
  # Create config directory
  dir.create(VMRONLY_CONFIG_PATH, recursive = TRUE, showWarnings = FALSE)
  
  # Initialize default permissions
  default_perms <- list(
    admins = list(
      "admindsvm" = TRUE
    ),
    users = list(
      "researcher1" = list(
        tables = c("patients", "visits", "lab_results"),
        can_download = TRUE
      ),
      "researcher2" = list(
        tables = c("patients", "medications"),
        can_download = FALSE
      )
    ),
    created_at = as.character(Sys.time()),
    created_by = current_user
  )
  
  # Save permissions
  jsonlite::write_json(default_perms, VMRONLY_PERM_FILE, pretty = TRUE, auto_unbox = TRUE)
  
  cli::cli_alert_success("VM-Restricted package initialized.")
  cli::cli_alert_info("Default permissions created for demo users.")
  cli::cli_alert_info("Edit {VMRONLY_PERM_FILE} to customize user permissions.")
  
  log_access(current_user, "INIT", "Package initialization", "SUCCESS")
  
  invisible(default_perms)
}
