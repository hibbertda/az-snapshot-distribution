# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave –Scope Process

# Connect Az PowerShell using Automation Run-AS account
$connection = Get-AutomationConnection -Name AzureRunAsConnection
while(!($connectionResult) -And ($logonAttempt -le 10))
{
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult =    Connect-AzAccount `
                               -ServicePrincipal `
                               -Tenant $connection.TenantID `
                               -ApplicationId $connection.ApplicationID `
                               -CertificateThumbprint $connection.CertificateThumbprint

    Start-Sleep -Seconds 30
}

## Get Automation Account Variables
# Max snapshot cut off in Days
[int]$maxShapshotAge = Get-AutomationVariable -Name 'snapshot_retentionDays'

# Resource Group where snapshots are stored
[string]$shapshotResourceGroup = Get-AzResourceGroup -name $(Get-AutomationVariable -Name 'snapshot_resourceGroup')

# Compute max date for snapshot retention
$cutOffDate = (get-date).addDays(-$maxShapshotAge)
Write-verbose -Message "Snapshot retention cut off date: $cutOffDate"

# Query for snapshots
$shapshots = get-azSnapshot -ResourceGroupName $shapshotResourceGroup.Name

# Check snapshot age and take action
$shapshots | foreach-object {
    if ($($_.timecreated.addDays(-30)) -lt $maxShapshotAge){

        Write-verbose -Message "Removing Snapshot: $($_.name)" -nonewline

        remove-azsnapshot `
            -name $_.name `
            -force
    }
    else {
        Write-verbose -Message "Retaining Snapshot: $($_.name)"
    }
}
