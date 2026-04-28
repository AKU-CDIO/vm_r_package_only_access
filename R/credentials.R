# credentials.R — Secure storage of Fabric server config (no password stored)
#
# Since login is interactive (browser), we only need to store the
# server endpoint and database name — NOT any password.

#' Store Fabric server configuration (admin only — run once during setup)
#'
#' Encrypts and saves the Fabric SQL endpoint and database name.
#' No passwords are stored — researchers authenticate interactively via browser.
#'
#' @param server   Fabric SQL endpoint e.g. "xxx.datawarehouse.fabric.microsoft.com"
#' @param database Lakehouse database name e.g. "uzima_db_backup"
#'
#' @export
#' @examples
#' \dontrun{
#' vmronly_store_credentials(
#'   server   = "fis5xxx.datawarehouse.fabric.microsoft.com",
#'   database = "uzima_db_backup"
#' )
#' }
vmronly_store_credentials <- function(server, database) {
  assert_vm()

  current_user <- get_windows_user()

  # Only admin can store credentials
  perms <- load_permissions()
  if (!isTRUE(perms$admins[[current_user]]) && current_user != "admindsvm") {
    cli::cli_abort("Only the VM administrator can store server configuration.")
  }

  config <- list(
    server     = server,
    database   = database,
    stored_at  = as.character(Sys.time()),
    stored_by  = current_user
  )

  key       <- get_machine_key()
  encrypted <- encrypt_string(jsonlite::toJSON(config, auto_unbox = TRUE), key)

  dir.create(VMRONLY_CONFIG_PATH, recursive = TRUE, showWarnings = FALSE)
  saveRDS(encrypted, VMRONLY_CRED_FILE)

  # Lock file to admin only (Windows ACL)
  system(sprintf(
    'powershell -Command "icacls \'%s\' /inheritance:r /grant:r %s:F"',
    VMRONLY_CRED_FILE, current_user
  ))

  cli::cli_alert_success("Fabric server config stored securely.")
  cli::cli_alert_info("Server:   {server}")
  cli::cli_alert_info("Database: {database}")
  cli::cli_alert_info("Note: No password stored — researchers log in interactively via browser.")
  log_access(current_user, "STORE_CONFIG", sprintf("%s / %s", server, database))
}

#' Load Fabric server config
#' @keywords internal
load_credentials <- function() {
  if (!file.exists(VMRONLY_CRED_FILE)) {
    cli::cli_abort(c(
      "x" = "Fabric server config not found.",
      "i" = "Ask your administrator to run {.fn vmronly_store_credentials}."
    ))
  }

  key       <- get_machine_key()
  encrypted <- readRDS(VMRONLY_CRED_FILE)
  config    <- jsonlite::fromJSON(decrypt_string(encrypted, key))
  config
}
