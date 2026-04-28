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

```r
# Install from GitHub
remotes::install_github("AKU-CDIO/vm_r_package_only_access")

# Or install from local source
devtools::install("path/to/vm_r_package_only_access")
```

## Quick Start

### For Researchers

```r
# Load the package
library(vmronly)

# Connect to Fabric (opens browser for Microsoft sign-in)
con <- vmronly_connect()

# List available tables
tables <- vmronly_tables(con)

# Query data
df <- vmronly_query(con, "SELECT TOP 100 * FROM patients")

# Download data (if permitted)
data <- vmronly_download(con, "patients", limit = 1000)

# Disconnect
vmronly_disconnect(con)
```

### For Administrators

```r
# Initialize the package (run once)
vmronly_init()

# Store Fabric server configuration
vmronly_store_credentials(
  server = "your-endpoint.datawarehouse.fabric.microsoft.com",
  database = "your_lakehouse_database"
)

# Add a new user
vmronly_add_user("researcher1", c("patients", "visits", "lab_results"), can_download = TRUE)

# List all users
vmronly_list_users()

# View access logs
vmronly_log()

# Check system status
vmronly_status()
```

## Security Features

### VM Locking
The package only runs on pre-approved VM hostnames. This prevents unauthorized installation and execution.

### User Authentication
- Interactive browser-based Microsoft/Entra ID authentication
- No passwords stored in configuration files
- Windows user session verification

### Permission System
- **Admin users**: Full access to all tables and functions
- **Regular users**: Restricted to specific tables and functions
- **Download control**: Per-user download permissions

### Audit Trail
All access attempts are logged with:
- Timestamp
- User identity
- Action performed
- Success/failure status
- Details of the operation

## Configuration Files

The package stores configuration in `~/.vmronly/`:

- `credentials.rds` - Encrypted server configuration (admin only)
- `permissions.json` - User permissions and access control
- `access.log` - Complete audit log of all activities

## Available Functions

### Connection Functions
- `vmronly_connect()` - Connect to Fabric Lakehouse
- `vmronly_disconnect()` - Disconnect from Fabric

### Data Access Functions
- `vmronly_tables()` - List available tables
- `vmronly_table()` - Get table information
- `vmronly_query()` - Execute SQL queries
- `vmronly_download()` - Download table data

### User Management Functions
- `vmronly_init()` - Initialize package configuration
- `vmronly_add_user()` - Add new user
- `vmronly_deactivate_user()` - Remove user access
- `vmronly_list_users()` - List all users

### Administrative Functions
- `vmronly_store_credentials()` - Store server configuration
- `vmronly_log()` - View access logs
- `vmronly_status()` - Show system status
- `vmronly_test()` - Run package diagnostics

## Requirements

### System Requirements
- Windows operating system
- Approved UZIMA research VM
- R 4.0 or higher

### R Package Dependencies
- `DBI` - Database interface
- `odbc` - ODBC driver interface
- `cli` - Command line interface
- `jsonlite` - JSON handling
- `openssl` - Encryption functions
- `dplyr` - Data manipulation
- `rlang` - Programming utilities
- `lubridate` - Date/time utilities

### External Requirements
- ODBC Driver 18 for SQL Server
- Microsoft Fabric workspace access
- Valid Microsoft/Entra ID account (@aku.edu)

## Troubleshooting

### Common Issues

**"This package can only run on approved UZIMA research VMs"**
- You must be on an approved VM hostname
- Contact your administrator for VM access

**"User is not registered in the permissions system"**
- Ask your administrator to add you to the permissions file
- Verify your Windows username is correct

**"Fabric server config not found"**
- Administrator must run `vmronly_store_credentials()` first
- Check that the configuration files exist

**"Failed to connect to Fabric Lakehouse"**
- Verify your Microsoft account has Fabric access
- Ensure you're signing in with your @aku.edu account
- Check network connectivity to Fabric endpoints

### Diagnostics

Run the built-in diagnostic tool:

```r
vmronly_test()
```

This will check:
- VM validation
- User detection
- Configuration files
- Permissions loading
- Database credentials

## Security Considerations

### Data Protection
- No passwords stored in configuration files
- Machine-specific encryption for sensitive data
- Complete audit trail for compliance

### Access Control
- VM-only execution prevents data exfiltration
- User-specific table permissions
- Admin-controlled download permissions

### Monitoring
- All access attempts logged
- Failed attempts tracked
- User activity monitoring

## License

MIT License - see LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub: https://github.com/AKU-CDIO/vm_r_package_only_access/issues
- Contact the UZIMA Data Team
- Check the access logs for troubleshooting information

## Contributing

This is a security-focused package. Contributions should:
- Maintain security controls
- Follow the existing permission model
- Include comprehensive logging
- Add appropriate tests

---

**Developed by UZIMA Data Team for secure research data access.**
