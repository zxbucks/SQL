<#
Purpose:
    Export a SQL Server table to Excel.
    Output columns match SELECT * exactly.
    All values are exported as text to avoid scientific notation.

Run manually:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Export_Table_To_Excel.ps1"

SQL Agent:
    Step Type: Operating system (CmdExec)
    Command: powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Export_Table_To_Excel.ps1"
    Success exit code: 0

Requirements:
    Install-Module SqlServer -Scope AllUsers -AllowClobber -Force
    Install-Module ImportExcel -Scope AllUsers -Force
#>

$ErrorActionPreference = "Stop"

# -----------------------------
# Config
# -----------------------------
$ServerInstance = "YourSqlServer\YourInstance"
$Database       = "YourDatabase"
$SchemaName     = "dbo"
$TableName      = "YourTableName"

$OutputFolder   = "\\YourFileServer\YourShare\YourFolder"
$OutputFile     = "Output.xlsx"
$WorksheetName  = "Sheet1"

$ScriptFolder   = "C:\Scripts"
$LogFolder      = Join-Path $ScriptFolder "Logs"

# -----------------------------
# Init
# -----------------------------
function Write-Step {
    param ([string]$Message)
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

if (-not (Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
}

$LogFile = Join-Path $LogFolder ("Export_Log_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$OutputFullPath = Join-Path $OutputFolder $OutputFile

Start-Transcript -Path $LogFile -Force

try {
    Write-Step "Export started."
    Write-Step "Server: $ServerInstance"
    Write-Step "Database: $Database"
    Write-Step "Source: [$SchemaName].[$TableName]"
    Write-Step "Output: $OutputFullPath"

    Import-Module SqlServer -ErrorAction Stop
    Import-Module ImportExcel -ErrorAction Stop

    if (-not (Test-Path $OutputFolder)) {
        throw "Output folder does not exist or cannot be accessed: $OutputFolder"
    }

    $query = @"
SELECT *
FROM [$SchemaName].[$TableName];
"@

    Write-Step "Reading SQL data."

    $data = Invoke-Sqlcmd `
        -ServerInstance $ServerInstance `
        -Database $Database `
        -Query $query `
        -TrustServerCertificate `
        -ErrorAction Stop

    if (-not $data -or $data.Count -eq 0) {
        Write-Step "No rows returned."
        $textData = @()
    }
    else {
        Write-Step "Rows returned: $($data.Count)"

        $sqlColumns = $data[0].Table.Columns | ForEach-Object { $_.ColumnName }
        Write-Step "Columns returned: $($sqlColumns.Count)"

        $textData = foreach ($row in $data) {
            $obj = [ordered]@{}

            foreach ($columnName in $sqlColumns) {
                $value = $row[$columnName]

                if ($null -eq $value -or $value -eq [DBNull]::Value) {
                    $obj[$columnName] = ""
                }
                else {
                    $obj[$columnName] = [string]$value
                }
            }

            [PSCustomObject]$obj
        }
    }

    if (Test-Path $OutputFullPath) {
        Write-Step "Removing old output file."
        Remove-Item $OutputFullPath -Force -ErrorAction Stop
    }

    Write-Step "Exporting to Excel."

    $textData | Export-Excel `
        -Path $OutputFullPath `
        -WorksheetName $WorksheetName `
        -AutoSize `
        -FreezeTopRow `
        -BoldTopRow `
        -NoNumberConversion *

    Write-Step "Export completed successfully."
    Write-Step "File created: $OutputFullPath"

    Stop-Transcript
    exit 0
}
catch {
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Export failed."
    Write-Output $_.Exception.Message
    Write-Output $_

    Stop-Transcript
    exit 1
}
