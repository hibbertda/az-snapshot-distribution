
[CmdletBinding()]
param (
    [parameter(position=0, mandatory=$true)][string]$sourceSubscriptionID = "",
    [parameter(position=1, mandatory=$true)][string]$targetSubscriptionID = "",
    [parameter(position=2, mandatory=$true)][string]$snapshotRg = "",
    [parameter(position=3, mandatory=$true)][string]$targetResourceGroupName = ""
)

# Save original Az Context
$orgAzContext = Get-AzContext

# Set Az context to source subscription
Get-AzSubscription -SubscriptionId $sourceSubscriptionID | Set-AzContext

# Query for snapshot
$snapshots = Get-AzSnapshot -ResourceGroupName $snapshotRg

## Copy snapshots to target subscription

# Set Az contect to target subscription
Get-AzSubscription -SubscriptionId $targetSubscriptionID | Set-AzContext

$snapshots | ForEach-Object {
    $snapshotConfig = New-AzSnapshotConfig `
                        -SourceResourceId $_.Id `
                        -Location $_.Location `
                        -CreateOption Copy `
                        -SkuName Standard_LRS `
                        -Tag $_.Tags

    New-AzSnapshot `
        -Snapshot $snapshotConfig `
        -SnapshotName $_.Name `
        -ResourceGroupName $targetResourceGroupName
}

# Reset original Az Context
Set-AzContext -Context $orgAzContext
