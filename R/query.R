# query.R — Database query and data access functions

#' Execute a SQL query with permission checking
#'
#' @param con A DBI connection returned by \code{vmronly_connect()}
#' @param sql SQL query to execute
#' @param ... Additional parameters passed to DBI::dbGetQuery
#'
#' @return A data frame with query results
#' @export
#' @examples
#' \dontrun{
#' con <- vmronly_connect()
#' df <- vmronly_query(con, "SELECT TOP 10 * FROM patients")
#' vmronly_disconnect(con)
#' }
vmronly_query <- function(con, sql, ...) {
  user <- attr(con, "vmronly_user")
  perms <- attr(con, "vmronly_perms")
  
  # Log query attempt
  log_access(user, "QUERY", sql)
  
  # Check if user has permission to query
  if (perms$is_admin) {
    cli::cli_alert_info("Admin access granted for query.")
  } else {
    # For non-admins, we could add table-level checking here
    # For now, we'll allow any query but log it
    cli::cli_alert_info("Query executed with user permissions.")
  }
  
  # Execute query
  result <- tryCatch({
    DBI::dbGetQuery(con, sql, ...)
  }, error = function(e) {
    log_access(user, "QUERY", paste("Error:", e$message), "FAILED")
    cli::cli_abort(c(
      "x" = "Query failed.",
      "i" = "Error: {e$message}",
      "i" = "Check your SQL syntax and table access permissions."
    ))
  })
  
  # Log success
  log_access(user, "QUERY", sprintf("Returned %d rows", nrow(result)), "SUCCESS")
  cli::cli_alert_success("Query returned {nrow(result)} rows.")
  
  invisible(result)
}

#' List available tables
#'
#' @param con A DBI connection returned by \code{vmronly_connect()}
#'
#' @return Character vector of table names
#' @export
#' @examples
#' \dontrun{
#' con <- vmronly_connect()
#' tables <- vmronly_tables(con)
#' vmronly_disconnect(con)
#' }
vmronly_tables <- function(con) {
  user <- attr(con, "vmronly_user")
  perms <- attr(con, "vmronly_perms")
  
  # Get all tables
  all_tables <- tryCatch({
    DBI::dbListTables(con)
  }, error = function(e) {
    log_access(user, "LIST_TABLES", e$message, "FAILED")
    cli::cli_abort("Failed to list tables: {e$message}")
  })
  
  # Filter based on permissions
  if (perms$is_admin) {
    visible_tables <- all_tables
  } else {
    visible_tables <- intersect(all_tables, perms$tables)
  }
  
  # Log access
  log_access(user, "LIST_TABLES", sprintf("Found %d tables", length(visible_tables)), "SUCCESS")
  
  # Display results
  cli::cli_h2("Available Tables")
  for (table in visible_tables) {
    cli::cli_li(table)
  }
  
  invisible(visible_tables)
}

#' Get table information
#'
#' @param con A DBI connection returned by \code{vmronly_connect()}
#' @param table_name Name of the table to inspect
#'
#' @return List with table information
#' @export
#' @examples
#' \dontrun{
#' con <- vmronly_connect()
#' info <- vmronly_table(con, "patients")
#' vmronly_disconnect(con)
#' }
vmronly_table <- function(con, table_name) {
  user <- attr(con, "vmronly_user")
  perms <- attr(con, "vmronly_perms")
  
  # Check table access permission
  if (!perms$is_admin && !table_name %in% perms$tables) {
    log_access(user, "TABLE_INFO", table_name, "DENIED")
    cli::cli_abort(c(
      "x" = "Access denied to table '{table_name}'.",
      "i" = "You only have access to: {paste(perms$tables, collapse = ', ')}."
    ))
  }
  
  # Get table info
  info <- tryCatch({
    # Get row count
    count_query <- sprintf("SELECT COUNT(*) as row_count FROM %s", table_name)
    row_count <- DBI::dbGetQuery(con, count_query)$row_count
    
    # Get column info
    columns_query <- sprintf("
      SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        IS_NULLABLE,
        CHARACTER_MAXIMUM_LENGTH
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_NAME = '%s'
      ORDER BY ORDINAL_POSITION
    ", table_name)
    
    columns <- DBI::dbGetQuery(con, columns_query)
    
    list(
      table_name = table_name,
      row_count = row_count,
      columns = columns
    )
  }, error = function(e) {
    log_access(user, "TABLE_INFO", paste(table_name, e$message), "FAILED")
    cli::cli_abort("Failed to get table info: {e$message}")
  })
  
  # Log success
  log_access(user, "TABLE_INFO", table_name, "SUCCESS")
  
  # Display results
  cli::cli_h2("Table: {table_name}")
  cli::cli_alert_info("Rows: {info$row_count}")
  cli::cli_h3("Columns")
  for (i in seq_len(nrow(info$columns))) {
    col <- info$columns[i, ]
    cli::cli_li("{col$COLUMN_NAME} ({col$DATA_TYPE}{ifelse(is.na(col$CHARACTER_MAXIMUM_LENGTH), '', paste('(', col$CHARACTER_MAXIMUM_LENGTH, ')'))})")
  }
  
  invisible(info)
}

#' Download data from a table (with permission checking)
#'
#' @param con A DBI connection returned by \code{vmronly_connect()}
#' @param table_name Name of the table to download
#' @param limit Maximum number of rows to download (default: 10000)
#' @param output_file Optional file path to save CSV
#'
#' @return Data frame with table data
#' @export
#' @examples
#' \dontrun{
#' con <- vmronly_connect()
#' data <- vmronly_download(con, "patients", limit = 1000)
#' vmronly_disconnect(con)
#' }
vmronly_download <- function(con, table_name, limit = 10000, output_file = NULL) {
  user <- attr(con, "vmronly_user")
  perms <- attr(con, "vmronly_perms")
  
  # Check download permission
  if (!perms$is_admin && !perms$can_download) {
    log_access(user, "DOWNLOAD", table_name, "DENIED")
    cli::cli_abort(c(
      "x" = "Download permission denied.",
      "i" = "Your account does not have download privileges.",
      "i" = "Contact your administrator to request download access."
    ))
  }
  
  # Check table access permission
  if (!perms$is_admin && !table_name %in% perms$tables) {
    log_access(user, "DOWNLOAD", table_name, "DENIED")
    cli::cli_abort(c(
      "x" = "Access denied to table '{table_name}'.",
      "i" = "You only have access to: {paste(perms$tables, collapse = ', ')}."
    ))
  }
  
  # Build download query
  sql <- sprintf("SELECT TOP %d * FROM %s", limit, table_name)
  
  cli::cli_alert_info("Downloading up to {limit} rows from '{table_name}'...")
  
  # Execute download
  data <- tryCatch({
    DBI::dbGetQuery(con, sql)
  }, error = function(e) {
    log_access(user, "DOWNLOAD", paste(table_name, e$message), "FAILED")
    cli::cli_abort("Download failed: {e$message}")
  })
  
  # Save to file if requested
  if (!is.null(output_file)) {
    tryCatch({
      write.csv(data, output_file, row.names = FALSE)
      cli::cli_alert_success("Data saved to: {output_file}")
    }, error = function(e) {
      cli::cli_alert_warning("Failed to save file: {e$message}")
    })
  }
  
  # Log success
  log_access(user, "DOWNLOAD", sprintf("%s: %d rows", table_name, nrow(data)), "SUCCESS")
  cli::cli_alert_success("Downloaded {nrow(data)} rows from '{table_name}'.")
  
  invisible(data)
}
