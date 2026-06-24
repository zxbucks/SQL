<#
Purpose:
    Export a SQL Server table to an Excel file on a shared folder.

Manual run:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    & "C:\Scripts\Output_SQL_Table_To_Excel.ps1"

SQL Agent job step:
    Type: Operating system (CmdExec)

    Command:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Output_SQL_Table_To_Excel.ps1"

    Advanced:
    Process exit code of a successful command = 0

Notes:
    exit 0 = success
    exit 1 = failure

Requirements:
    PowerShell modules:
        ImportExcel
        SqlServer

    Install if needed:
        Install-Module ImportExcel -Scope AllUsers -Force
        Install-Module SqlServer -Scope AllUsers -AllowClobber -Force

Permissions:
    SQL Agent service account needs:
        - db_datareader on the source database
        - Read/execute access to this .ps1 file
        - Write/delete access to the output shared folder

    Use UNC path, not mapped drive.
#>

$ErrorActionPreference = "Stop"

try {
    function Write-Step {
        param ([string]$Message)

        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Output "[$time] $Message"
    }

    Write-Step "Export script started."

    # -----------------------------
    # Config
    # -----------------------------
    $ServerInstance = "YourSqlServer\YourInstance"
    $Database       = "YourDatabaseName"

    $SchemaName     = "dbo"
    $TableName      = "YourTableName"

    $OutputFolder   = "\\YourFileServer\YourShare\YourFolder"
    $OutputFile     = "Output.xlsx"
    $OutputFullPath = Join-Path $OutputFolder $OutputFile

    $WorksheetName  = "Sheet1"

    Write-Step "Server: $ServerInstance"
    Write-Step "Database: $Database"
    Write-Step "Source table: [$SchemaName].[$TableName]"
    Write-Step "Output file: $OutputFullPath"

    # -----------------------------
    # Load modules
    # -----------------------------
    Write-Step "Loading modules."

    Import-Module SqlServer -ErrorAction Stop
    Import-Module ImportExcel -ErrorAction Stop

    Write-Step "Modules loaded."

    # -----------------------------
    # Validate output folder
    # -----------------------------
    Write-Step "Checking output folder."

    if (-not (Test-Path $OutputFolder)) {
        throw "Output folder does not exist or cannot be accessed: $OutputFolder"
    }

    Write-Step "Output folder is accessible."

    # -----------------------------
    # Query SQL table
    # -----------------------------
    $query = @"
SELECT *
FROM [$SchemaName].[$TableName];
"@

    Write-Step "Reading data from SQL Server."

    $data = Invoke-Sqlcmd `
        -ServerInstance $ServerInstance `
        -Database $Database `
        -Query $query `
        -TrustServerCertificate `
        -ErrorAction Stop

    Write-Step "SQL query completed."

    if (-not $data -or $data.Count -eq 0) {
        Write-Step "No rows returned. Exporting empty result."
    }
    else {
        Write-Step "Rows returned: $($data.Count)"
    }

    # -----------------------------
    # Export to Excel
    # -----------------------------
    Write-Step "Preparing Excel export."

    if (Test-Path $OutputFullPath) {
        Write-Step "Existing output file found. Removing old file."
        Remove-Item $OutputFullPath -Force -ErrorAction Stop
        Write-Step "Old output file removed."
    }

    Write-Step "Exporting to Excel."

    $data | Export-Excel `
        -Path $OutputFullPath `
        -WorksheetName $WorksheetName `
        -AutoSize `
        -FreezeTopRow `
        -BoldTopRow

    Write-Step "Excel export completed."
    Write-Step "File created: $OutputFullPath"
    Write-Step "Export script completed successfully."

    exit 0
}
catch {
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Export script failed."
    Write-Output "Error message:"
    Write-Output $_.Exception.Message

    Write-Output "Full error:"
    Write-Output $_

    exit 1
}
