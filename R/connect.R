# connect.R — Fabric connection management

#' Connect to the VM-Restricted Fabric Lakehouse
#'
#' Establishes a secure connection to Microsoft Fabric using interactive
#' browser-based authentication (ActiveDirectoryInteractive). A browser
#' window will open for the researcher to sign in with their own
#' Microsoft / Entra ID account.
#'
#' The researcher's identity is verified against the permissions file
#' AFTER they authenticate — so only registered users can proceed.
#'
#' @return A DBI connection object
#' @export
#' @examples
#' \dontrun{
#' con <- vmronly_connect()
#' df  <- vmronly_query(con, "SELECT * FROM patients")
#' vmronly_disconnect(con)
#' }
vmronly_connect <- function() {
  # 1. VM lock
  assert_vm()

  # 2. Identify Windows user (used for permission lookup)
  windows_user <- get_windows_user()
  cli::cli_alert_info("Windows session: {windows_user}")

  # 3. Check user is registered in permissions before even trying to connect
  get_user_permissions(windows_user)

  # 4. Load server/database config (no stored password needed)
  creds <- load_credentials()

  # 5. Interactive browser login — researcher signs in with their own account
  cli::cli_alert_info("A browser window will open for Microsoft sign-in...")
  cli::cli_alert_info("Sign in with your @aku.edu account to continue.")

  con <- tryCatch({
    DBI::dbConnect(
      odbc::odbc(),
      Driver                 = "ODBC Driver 18 for SQL Server",
      Server                 = creds$server,
      Database               = creds$database,
      Authentication         = "ActiveDirectoryInteractive",
      Encrypt                = "yes",
      TrustServerCertificate = "no",
      Timeout                = 60
    )
  }, error = function(e) {
    log_access(windows_user, "CONNECT", e$message, "FAILED")
    cli::cli_abort(c(
      "x" = "Failed to connect to Fabric Lakehouse.",
      "i" = "Error: {e$message}",
      "i" = "Ensure you signed in with your authorised @aku.edu account.",
      "i" = "Contact your administrator if this persists."
    ))
  })

  # 6. Log success
  log_access(windows_user, "CONNECT", creds$server, "SUCCESS")
  cli::cli_alert_success("Connected to Fabric Lakehouse.")

  # Attach user metadata to connection
  attr(con, "vmronly_user")  <- windows_user
  attr(con, "vmronly_perms") <- get_user_permissions(windows_user)

  con
}

#' Disconnect from Fabric
#'
#' @param con A DBI connection returned by \code{vmronly_connect()}
#' @export
vmronly_disconnect <- function(con) {
  user <- attr(con, "vmronly_user") %||% get_windows_user()
  DBI::dbDisconnect(con)
  log_access(user, "DISCONNECT", "", "SUCCESS")
  cli::cli_alert_success("Disconnected from Fabric Lakehouse.")
  invisible(NULL)
}

# Null coalescing helper
`%||%` <- function(a, b) if (!is.null(a)) a else b
