# Define connection variables
$server = "192.168.0.230"
$database = "UPCN_REPORTES"
$username = "consultas"
$password = "Csua2018"
$outputDir = "C:\Repos\reportes-sql\"  # Path to your local Git repository folder

# Load SQL Server SMO (SQL Server Management Objects)
Import-Module SqlServer

# Create a connection to the SQL Server
$connectionString = "Server=$server;Database=$database;User Id=$username;Password=$password;"
$connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$connection.ConnectionString = $connectionString
$serverInstance = New-Object Microsoft.SqlServer.Management.Smo.Server $connection
$databaseInstance = $serverInstance.Databases[$database]

# Ensure output directories for Views and Functions exist
$viewOutputDir = Join-Path $outputDir "Views"
$functionOutputDir = Join-Path $outputDir "Functions"
if (-not (Test-Path $viewOutputDir)) {
    New-Item -ItemType Directory -Force -Path $viewOutputDir
}
if (-not (Test-Path $functionOutputDir)) {
    New-Item -ItemType Directory -Force -Path $functionOutputDir
}

# Export Views
$databaseInstance.Views | Where-Object { $_.IsSystemObject -eq $false } | ForEach-Object {
    $script = $_.Script()
    $script | Out-File "$viewOutputDir\$($_.Name).sql"
    Write-Host "Exported view: $($_.Name)"
}

# Export Table-Valued Functions
$databaseInstance.UserDefinedFunctions | Where-Object { $_.FunctionType -eq "Table" } | ForEach-Object {
    $script = $_.Script()
    $script | Out-File "$functionOutputDir\$($_.Name).sql"
    Write-Host "Exported function: $($_.Name)"
}

Set-Location $outputDir

# Stage the changes (new or modified .sql files)
git add .

# Commit the changes with a timestamped message
$commitMessage = "Actualizado - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m $commitMessage

# Push the changes to the remote repository
git push origin main  # Replace 'main' with the appropriate branch name