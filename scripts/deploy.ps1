param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev","qa","prd")]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [string]$Application,

    [Parameter(Mandatory=$true)]
    [string]$Version
)

try {
    $RootPath = Split-Path -Parent $PSScriptRoot
    $ConfigFile = Join-Path $RootPath "config\$Environment.json"
    $MqscPath = Join-Path $RootPath "applications\$Application\$Version\mqsc"

    if (!(Test-Path $ConfigFile)) {
        throw "Config file not found: $ConfigFile"
    }

    if (!(Test-Path $MqscPath)) {
        throw "MQSC path not found: $MqscPath"
    }

    $Config = Get-Content $ConfigFile | ConvertFrom-Json
    $QueueManager = $Config.queueManager

    Write-Host "========================================="
    Write-Host "MQ Deployment"
    Write-Host "Environment : $($Config.environment)"
    Write-Host "QueueManager: $QueueManager"
    Write-Host "Application : $Application"
    Write-Host "Version     : $Version"
    Write-Host "MQSC Path   : $MqscPath"
    Write-Host "========================================="

    $MqscFiles = Get-ChildItem $MqscPath -Filter "*.mqsc" | Sort-Object Name

    if ($MqscFiles.Count -eq 0) {
        throw "No MQSC files found."
    }

    foreach ($File in $MqscFiles) {
        Write-Host ""
        Write-Host "Executing $($File.Name)..."

        cmd.exe /c "runmqsc $QueueManager < `"$($File.FullName)`""

        if ($LASTEXITCODE -ne 0) {
            throw "Failed executing $($File.Name)"
        }

        Write-Host "SUCCESS: $($File.Name)"
    }

    Write-Host ""
    Write-Host "Deployment completed successfully."
    exit 0
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}