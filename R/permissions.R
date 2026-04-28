# permissions.R — User permission management

#' Load user permissions from config file
#' @keywords internal
load_permissions <- function() {
  if (!file.exists(VMRONLY_PERM_FILE)) {
    cli::cli_abort(c(
      "x" = "Permissions file not found.",
      "i" = "Run {.fn vmronly_init} to create default permissions.",
      "i" = "Or contact your administrator."
    ))
  }
  
  jsonlite::read_json(VMRONLY_PERM_FILE, simplifyVector = TRUE)
}

#' Get permissions for a specific user
#' @keywords internal
get_user_permissions <- function(user) {
  perms <- load_permissions()
  
  # Check if user is admin
  if (isTRUE(perms$admins[[user]])) {
    return(list(
      is_admin = TRUE,
      tables = "all",
      can_download = TRUE
    ))
  }
  
  # Check if user exists
  if (is.null(perms$users[[user]])) {
    cli::cli_abort(c(
      "x" = "User '{user}' is not registered in the permissions system.",
      "i" = "Contact your administrator to be added to the allowed users list."
    ))
  }
  
  # Return user permissions
  user_perms <- perms$users[[user]]
  user_perms$is_admin <- FALSE
  user_perms
}

#' Add a new user to the permissions system
#'
#' @param user Windows username (without domain)
#' @param tables Character vector of tables this user can access
#' @param can_download Logical - whether user can download data
#'
#' @export
#' @examples
#' \dontrun{
#' vmronly_add_user("researcher3", c("patients", "visits"), TRUE)
#' }
vmronly_add_user <- function(user, tables, can_download = FALSE) {
  assert_vm()
  
  current_user <- get_windows_user()
  perms <- load_permissions()
  
  # Check if current user is admin
  if (!isTRUE(perms$admins[[current_user]])) {
    cli::cli_abort("Only administrators can add users.")
  }
  
  # Add or update user
  perms$users[[user]] <- list(
    tables = tables,
    can_download = can_download,
    added_at = as.character(Sys.time()),
    added_by = current_user
  )
  
  # Save updated permissions
  jsonlite::write_json(perms, VMRONLY_PERM_FILE, pretty = TRUE, auto_unbox = TRUE)
  
  cli::cli_alert_success("User '{user}' added to permissions system.")
  cli::cli_alert_info("Tables: {paste(tables, collapse = ', ')}")
  cli::cli_alert_info("Can download: {can_download}")
  
  log_access(current_user, "ADD_USER", user, "SUCCESS")
  
  invisible(perms$users[[user]])
}

#' Deactivate a user from the permissions system
#'
#' @param user Windows username to deactivate
#'
#' @export
#' @examples
#' \dontrun{
#' vmronly_deactivate_user("researcher3")
#' }
vmronly_deactivate_user <- function(user) {
  assert_vm()
  
  current_user <- get_windows_user()
  perms <- load_permissions()
  
  # Check if current user is admin
  if (!isTRUE(perms$admins[[current_user]])) {
    cli::cli_abort("Only administrators can deactivate users.")
  }
  
  # Check if user exists
  if (is.null(perms$users[[user]])) {
    cli::cli_alert_warning("User '{user}' not found in permissions system.")
    return(invisible(NULL))
  }
  
  # Remove user
  perms$users[[user]] <- NULL
  
  # Save updated permissions
  jsonlite::write_json(perms, VMRONLY_PERM_FILE, pretty = TRUE, auto_unbox = TRUE)
  
  cli::cli_alert_success("User '{user}' deactivated from permissions system.")
  
  log_access(current_user, "DEACTIVATE_USER", user, "SUCCESS")
  
  invisible(NULL)
}

#' List all users in the permissions system
#'
#' @export
#' @examples
#' \dontrun{
#' vmronly_list_users()
#' }
vmronly_list_users <- function() {
  assert_vm()
  
  perms <- load_permissions()
  
  cli::cli_h1("VM-Restricted Users")
  
  # Admins
  if (length(perms$admins) > 0) {
    cli::cli_h2("Administrators")
    for (admin in names(perms$admins)) {
      cli::cli_li("{admin} (Admin)")
    }
  }
  
  # Regular users
  if (length(perms$users) > 0) {
    cli::cli_h2("Regular Users")
    for (user in names(perms$users)) {
      user_info <- perms$users[[user]]
      cli::cli_li("{user}")
      cli::cli_ul("Tables: {paste(user_info$tables, collapse = ', ')}")
      cli::cli_ul("Can download: {user_info$can_download}")
    }
  }
  
  invisible(perms)
}
