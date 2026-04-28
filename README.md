# vmronly: VM-Restricted Access to Microsoft Fabric

A secure R package that provides VM-locked access to Microsoft Fabric Lakehouse for authorized researchers. This package enforces strict security controls including VM-only execution, Windows-based authentication, per-user table permissions, and controlled data downloads.

## Features

- 🔒 **VM-Only Execution**: Package only runs on approved UZIMA research VMs
- 🔐 **Windows Authentication**: Uses interactive browser-based Microsoft sign-in
- 👥 **User Permissions**: Fine-grained access control per user and per table
- 📊 **Audit Logging**: Complete access log for compliance and monitoring
- ⬇️ **Controlled Downloads**: Admin-controlled download permissions
- 🛡️ **Admin Functions**: User management and system monitoring tools

## Installation

### From GitHub (Recommended)

```r
# Install the package from GitHub
if (!require("remotes")) install.packages("remotes")
remotes::install_github("AKU-CDIO/vm_r_package_only_access")

# Load the package
library(vmronly)
```

### From Local Source

```r
# Install from local directory
if (!require("devtools")) install.packages("devtools")
devtools::install("path/to/vm_r_package_only_access")

# Load the package
library(vmronly)
```

### Prerequisites

Before installing, ensure you have:

```r
# Required system components
- R 4.0 or higher
- Windows operating system
- ODBC Driver 18 for SQL Server
- Microsoft Fabric workspace access

# Required R packages (installed automatically)
install.packages(c("DBI", "odbc", "cli", "jsonlite", "openssl", 
                   "dplyr", "rlang", "lubridate", "httr"))
```

---

## 🚀 Quick Start Guide

### For Researchers

Here's a complete example of a typical research workflow:

```r
# --- Step 1: Load the package ---
library(vmronly)

# --- Step 2: Connect to Fabric Lakehouse ---
# This will open a browser window for Microsoft sign-in
# Use your @aku.edu account
con <- vmronly_connect()
#> ℹ Windows session: researcher1
#> ℹ A browser window will open for Microsoft sign-in...
#> ℹ Sign in with your @aku.edu account to continue.
#> ✔ Connected to Fabric Lakehouse.

# --- Step 3: Explore available tables ---
# List all tables you have access to
tables <- vmronly_tables(con)
#> ℹ Query executed with user permissions.
#> Available Tables:
#> • patients
#> • visits
#> • lab_results

# --- Step 4: Get table information ---
# Get detailed information about a specific table
patient_info <- vmronly_table(con, "patients")
#> ℹ Table: patients
#> ℹ Rows: 15000
#> Columns:
#> • patient_id (integer)
#> • name (varchar(100))
#> • age (integer)
#> • gender (varchar(10))
#> • admission_date (datetime)

# --- Step 5: Query data ---
# Run SQL queries with automatic permission checking
df_patients <- vmronly_query(con, "
  SELECT TOP 100 
    patient_id, name, age, gender, admission_date
  FROM patients 
  WHERE age > 18
  ORDER BY admission_date DESC
")
#> ℹ Query executed with user permissions.
#> ✔ Query returned 87 rows.

# --- Step 6: Download data (if permitted) ---
# Download data to local file (if you have download permissions)
if (TRUE) {  # Check if you have download permission
  data <- vmronly_download(
    con, 
    table_name = "patients", 
    limit = 1000,
    output_file = "patient_data.csv"
  )
  #> ℹ Downloading up to 1000 rows from 'patients'...
  #> ✔ Data saved to: patient_data.csv
  #> ✔ Downloaded 1000 rows from 'patients'.
}

# --- Step 7: Disconnect ---
# Always disconnect when done
vmronly_disconnect(con)
#> ✔ Disconnected from Fabric Lakehouse.
```

### For Administrators

Complete setup and management workflow:

```r
# --- Step 1: Initialize the package (run once) ---
library(vmronly)

# Initialize the package configuration
vmronly_init()
#> ✔ VM-Restricted package initialized.
#> ℹ Default permissions created for demo users.
#> ℹ Edit ~/.vmronly/permissions.json to customize user permissions.

# --- Step 2: Store Fabric server configuration ---
# This should be done by the VM administrator
vmronly_store_credentials(
  server = "fis5abc.datawarehouse.fabric.microsoft.com",
  database = "uzima_research_db"
)
#> ✔ Fabric server config stored securely.
#> ℹ Server:   fis5abc.datawarehouse.fabric.microsoft.com
#> ℹ Database: uzima_research_db
#> ℹ Note: No password stored — researchers log in interactively via browser.

# --- Step 3: Add users to the system ---
# Add a senior researcher with full access
vmronly_add_user(
  user = "dr_smith",
  tables = c("patients", "visits", "lab_results", "medications", "procedures"),
  can_download = TRUE
)
#> ✔ User 'dr_smith' added to permissions system.
#> ℹ Tables: patients, visits, lab_results, medications, procedures
#> ℹ Can download: TRUE

# Add a junior researcher with limited access
vmronly_add_user(
  user = "junior_researcher1",
  tables = c("patients", "visits"),
  can_download = FALSE
)
#> ✔ User 'junior_researcher1' added to permissions system.
#> ℹ Tables: patients, visits
#> ℹ Can download: FALSE

# --- Step 4: Manage users ---
# List all users in the system
vmronly_list_users()
#> VM-Restricted Users
#> 
#> Administrators
#> • admindsvm (Admin)
#> 
#> Regular Users
#> • dr_smith
#>   • Tables: patients, visits, lab_results, medications, procedures
#>   • Can download: TRUE
#> • junior_researcher1
#>   • Tables: patients, visits
#>   • Can download: FALSE

# Deactivate a user when needed
vmronly_deactivate_user("former_researcher")
#> ✔ User 'former_researcher' deactivated from permissions system.

# --- Step 5: Monitor system usage ---
# View recent access logs
vmronly_log(n = 20)
#> Recent Access Log
#> • 2026-04-29 02:00:15 - dr_smith - CONNECT - SUCCESS
#> • 2026-04-29 02:01:23 - dr_smith - QUERY - Returned 87 rows - SUCCESS
#> • 2026-04-29 02:02:45 - junior_researcher1 - CONNECT - SUCCESS
#> • 2026-04-29 02:03:12 - junior_researcher1 - QUERY - Returned 150 rows - SUCCESS

# Check system status
vmronly_status()
#> VM-Restricted Package Status
#> 
#> System Information
#> • Hostname: UZIMA-VM-01
#> • User: admindsvm
#> • R Version: R version 4.3.2 (2023-10-31)
#> • Platform: windows
#> 
#> Configuration Files
#> • Config path: ~/.vmronly
#> • Credentials file: EXISTS
#> • Permissions file: EXISTS
#> • Log file: EXISTS
#> 
#> Database Configuration
#> • Server: fis5abc.datawarehouse.fabric.microsoft.com
#> • Database: uzima_research_db
#> • Configured by: admindsvm
#> • Configured at: 2026-04-29 01:45:00

# --- Step 6: Run system diagnostics ---
# Test all package functionality
vmronly_test()
#> VM-Restricted Package Tests
#> ✔ VM validation: PASS
#> ✔ User detection: PASS (admindsvm)
#> ✔ Config file (credentials): EXISTS
#> ✔ Config file (permissions): EXISTS
#> ✔ Config file (log): EXISTS
#> ✔ Permissions loading: PASS
#> ✔ Credentials loading: PASS
#> 
#> Test Summary
#> ℹ Tests passed: 7/7
#> ✔ All tests passed! Package is ready to use.
```

---

## 📚 Advanced Usage Examples

### Research Workflow Example

Here's a complete research analysis workflow:

```r
library(vmronly)
library(dplyr)
library(ggplot2)

# Connect to the database
con <- vmronly_connect()

# --- Study 1: Patient Demographics Analysis ---
# Get patient demographics
demographics <- vmronly_query(con, "
  SELECT 
    patient_id,
    age,
    gender,
    admission_date,
    discharge_date
  FROM patients
  WHERE admission_date >= '2023-01-01'
")

# Analyze age distribution
age_stats <- demographics %>%
  summarise(
    mean_age = mean(age, na.rm = TRUE),
    median_age = median(age, na.rm = TRUE),
    sd_age = sd(age, na.rm = TRUE)
  )

print(age_stats)

# --- Study 2: Visit Patterns Analysis ---
# Get visit information
visits <- vmronly_query(con, "
  SELECT 
    v.patient_id,
    v.visit_date,
    v.visit_type,
    p.age,
    p.gender
  FROM visits v
  JOIN patients p ON v.patient_id = p.patient_id
  WHERE v.visit_date >= '2023-01-01'
")

# Analyze visit patterns by gender
visit_analysis <- visits %>%
  group_by(gender, visit_type) %>%
  summarise(
    visit_count = n(),
    avg_age = mean(age, na.rm = TRUE)
  ) %>%
  arrange(desc(visit_count))

print(visit_analysis)

# --- Study 3: Lab Results Analysis ---
# Get lab results for specific patients
lab_results <- vmronly_query(con, "
  SELECT 
    lr.patient_id,
    lr.test_date,
    lr.test_name,
    lr.result_value,
    lr.unit,
    p.age,
    p.gender
  FROM lab_results lr
  JOIN patients p ON lr.patient_id = p.patient_id
  WHERE lr.test_name IN ('CBC', 'Hemoglobin', 'WBC')
    AND lr.test_date >= '2023-01-01'
")

# Create visualization
ggplot(lab_results, aes(x = test_name, y = as.numeric(result_value))) +
  geom_boxplot() +
  facet_wrap(~ gender) +
  theme_minimal() +
  labs(title = "Lab Results by Gender", x = "Test Type", y = "Result Value")

# --- Export Results ---
# Save analysis results (if you have download permission)
if (TRUE) {  # Check permissions
  write.csv(demographics, "patient_demographics_2023.csv", row.names = FALSE)
  write.csv(visit_analysis, "visit_patterns_analysis.csv", row.names = FALSE)
  write.csv(lab_results, "lab_results_2023.csv", row.names = FALSE)
}

# Disconnect
vmronly_disconnect(con)
```

### Data Quality Checks

```r
library(vmronly)

con <- vmronly_connect()

# --- Data Quality Report ---
# Check for missing data
missing_data_report <- vmronly_query(con, "
  SELECT 
    'patients' as table_name,
    COUNT(*) as total_records,
    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) as missing_patient_id,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) as missing_name,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) as missing_age,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) as missing_gender
  FROM patients
  
  UNION ALL
  
  SELECT 
    'visits' as table_name,
    COUNT(*) as total_records,
    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) as missing_patient_id,
    SUM(CASE WHEN visit_date IS NULL THEN 1 ELSE 0 END) as missing_visit_date,
    0 as missing_age,
    0 as missing_gender
  FROM visits
")

print(missing_data_report)

# --- Duplicate Check ---
# Check for duplicate patient records
duplicates <- vmronly_query(con, "
  SELECT 
    patient_id,
    name,
    COUNT(*) as duplicate_count
  FROM patients
  GROUP BY patient_id, name
  HAVING COUNT(*) > 1
")

if (nrow(duplicates) > 0) {
  cat("Found duplicate records:\n")
  print(duplicates)
} else {
  cat("No duplicate patient records found.\n")
}

vmronly_disconnect(con)
```

### Automated Reporting

```r
library(vmronly)
library(rmarkdown)

# Generate monthly report
generate_monthly_report <- function(year, month) {
  con <- vmronly_connect()
  
  # Get monthly statistics
  monthly_stats <- vmronly_query(con, sprintf("
    SELECT 
      COUNT(DISTINCT patient_id) as unique_patients,
      COUNT(*) as total_visits,
      AVG(age) as avg_patient_age
    FROM visits v
    JOIN patients p ON v.patient_id = p.patient_id
    WHERE YEAR(v.visit_date) = %d
      AND MONTH(v.visit_date) = %d
  ", year, month))
  
  # Get top procedures
  top_procedures <- vmronly_query(con, sprintf("
    SELECT TOP 10
      procedure_name,
      COUNT(*) as procedure_count
    FROM procedures
    WHERE YEAR(procedure_date) = %d
      AND MONTH(procedure_date) = %d
    GROUP BY procedure_name
    ORDER BY COUNT(*) DESC
  ", year, month))
  
  vmronly_disconnect(con)
  
  # Create report data
  report_data <- list(
    period = sprintf("%d-%02d", year, month),
    stats = monthly_stats,
    procedures = top_procedures
  )
  
  return(report_data)
}

# Generate report for current month
current_year <- as.numeric(format(Sys.Date(), "%Y"))
current_month <- as.numeric(format(Sys.Date(), "%m"))

monthly_report <- generate_monthly_report(current_year, current_month)
print(monthly_report)
```

---

## 🛠️ Troubleshooting & FAQ

### Common Issues and Solutions

#### **Issue: "This package can only run on approved UZIMA research VMs"**

```r
# Check your current hostname
current_hostname <- Sys.info()["nodename"]
cat("Current hostname:", current_hostname, "\n")

# Check approved hostnames
approved_hostnames <- c("UZIMA-VM-01", "UZIMA-VM-02", "UZIMA-RESEARCH-VM")
cat("Approved hostnames:", paste(approved_hostnames, collapse = ", "), "\n")

# If you're not on an approved VM, contact your administrator
```

#### **Issue: "User is not registered in the permissions system"**

```r
# Check your current Windows user
library(vmronly)
current_user <- vmronly:::get_windows_user()
cat("Current Windows user:", current_user, "\n")

# Ask your administrator to add you:
# vmronly_add_user("your_windows_username", c("table1", "table2"), can_download = TRUE)
```

#### **Issue: "Fabric server config not found"**

```r
# Check if configuration files exist
config_files <- c(
  credentials = "~/.vmronly/credentials.rds",
  permissions = "~/.vmronly/permissions.json",
  log = "~/.vmronly/access.log"
)

for (name in names(config_files)) {
  file_path <- path.expand(config_files[[name]])
  if (file.exists(file_path)) {
    cat("✅", name, "file exists\n")
  } else {
    cat("❌", name, "file missing\n")
  }
}

# If credentials file is missing, ask your admin to run:
# vmronly_store_credentials(server = "your-endpoint", database = "your-db")
```

#### **Issue: Connection Problems**

```r
# Test your connection step by step
library(vmronly)

# 1. Test VM validation
tryCatch({
  vmronly:::assert_vm()
  cat("✅ VM validation passed\n")
}, error = function(e) {
  cat("❌ VM validation failed:", e$message, "\n")
})

# 2. Test user detection
tryCatch({
  user <- vmronly:::get_windows_user()
  cat("✅ User detected:", user, "\n")
}, error = function(e) {
  cat("❌ User detection failed:", e$message, "\n")
})

# 3. Test permissions loading
tryCatch({
  perms <- vmronly:::load_permissions()
  cat("✅ Permissions loaded\n")
}, error = function(e) {
  cat("❌ Permissions loading failed:", e$message, "\n")
})

# 4. Test credentials loading
tryCatch({
  creds <- vmronly:::load_credentials()
  cat("✅ Credentials loaded - Server:", creds$server, "\n")
}, error = function(e) {
  cat("❌ Credentials loading failed:", e$message, "\n")
})
```

### Diagnostic Tools

#### **Run Full Diagnostic**

```r
library(vmronly)

# Run comprehensive test
vmronly_test()

# Check system status
vmronly_status()

# View recent logs for troubleshooting
vmronly_log(n = 50)
```

#### **Manual Permission Check**

```r
library(vmronly)

# Check your current permissions
current_user <- vmronly:::get_windows_user()
cat("Checking permissions for:", current_user, "\n")

tryCatch({
  user_perms <- vmronly:::get_user_permissions(current_user)
  cat("✅ User permissions found:\n")
  cat("  - Admin:", user_perms$is_admin, "\n")
  cat("  - Tables:", paste(user_perms$tables, collapse = ", "), "\n")
  cat("  - Can download:", user_perms$can_download, "\n")
}, error = function(e) {
  cat("❌ Permission check failed:", e$message, "\n")
})
```

### Performance Tips

#### **Optimize Queries**

```r
# Good: Use specific columns
df <- vmronly_query(con, "
  SELECT patient_id, name, age 
  FROM patients 
  WHERE age > 18
")

# Better: Add LIMIT for large tables
df <- vmronly_query(con, "
  SELECT TOP 1000 patient_id, name, age 
  FROM patients 
  WHERE age > 18
")

# Best: Use indexes and specific date ranges
df <- vmronly_query(con, "
  SELECT patient_id, name, age 
  FROM patients 
  WHERE admission_date >= '2023-01-01'
    AND admission_date < '2024-01-01'
    AND age > 18
")
```

#### **Batch Processing**

```r
# Process large datasets in batches
process_large_dataset <- function(con, table_name, batch_size = 10000) {
  total_rows <- vmronly_query(con, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
  
  for (offset in seq(0, total_rows, batch_size)) {
    batch_query <- sprintf("
      SELECT * FROM %s 
      ORDER BY id 
      OFFSET %d ROWS FETCH NEXT %d ROWS ONLY
    ", table_name, offset, batch_size)
    
    batch_data <- vmronly_query(con, batch_query)
    
    # Process batch_data here
    cat("Processed batch", offset/batch_size + 1, "of", ceiling(total_rows/batch_size), "\n")
  }
}
```

---

## 🔒 Security Best Practices

### For Administrators

```r
# Regular security checks
library(vmronly)

# 1. Review access logs weekly
vmronly_log(n = 100)

# 2. Check user permissions
vmronly_list_users()

# 3. Monitor system health
vmronly_status()

# 4. Run security diagnostics
vmronly_test()
```

### For Researchers

```r
# Secure data handling practices
library(vmronly)

# 1. Always disconnect when done
con <- vmronly_connect()
# ... do your work ...
vmronly_disconnect(con)  # Important!

# 2. Use specific queries instead of SELECT *
# Good:
df <- vmronly_query(con, "SELECT patient_id, age FROM patients WHERE age > 18")

# Avoid:
# df <- vmronly_query(con, "SELECT * FROM patients")

# 3. Download only necessary data
# Good:
data <- vmronly_download(con, "patients", limit = 1000)

# Avoid:
# data <- vmronly_download(con, "patients", limit = 1000000)
```

---

## 📞 Support & Resources

### Getting Help

```r
# 1. Check package version and status
packageVersion("vmronly")
vmronly_status()

# 2. Run diagnostics
vmronly_test()

# 3. Check recent logs
vmronly_log()

# 4. Report issues with system info
system_info <- list(
  r_version = R.version.string,
  package_version = packageVersion("vmronly"),
  hostname = Sys.info()["nodename"],
  user = Sys.info()["user"]
)
```

### Contact Information

- **GitHub Issues**: https://github.com/AKU-CDIO/vm_r_package_only_access/issues
- **UZIMA Data Team**: Contact via internal channels
- **Emergency Support**: Reach out to VM administrators

### Documentation Updates

Check the GitHub repository for the latest documentation and updates.

---

## 📄 License

MIT License - see LICENSE file for details.

---

**Developed by UZIMA Data Team for secure research data access.**

*Last updated: April 2026*
