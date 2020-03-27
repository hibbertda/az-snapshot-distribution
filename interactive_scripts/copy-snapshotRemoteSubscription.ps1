<#
.NOTES
    Daniel Hibbert - March 2020
    Version 0.1

    Microsoft Azure - copy-snapshotRemoteSubscription

    THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
    KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
    PARTICULAR PURPOSE.

.DESCRIPTION

    This script will automate the process of creating copies of selected managed disk
    snapshots in a remote Azure subscription. 

    The usecase for this script is the ability to copy manage disks from one enclave to another (i.e. Production -> Development)

.PARAMETER sourceSubscriptionID

    [string] [Optional] Azure Subscription ID to find the source managed disk snapshot.

.PARAMETER targetSubscriptionID

    [string] Azure Subscription ID for the remote subscription destination for the managed disk snapshot.

.PARAMETER sourceSnapshotResourceGroupName

    [string] Azure Resource Group where the source managed disk snapshot is located. 

.PARAMETER targetResourceGroupName

    [string] Azure Resource Group where the copied managed disk snapshot will be created in the target remote Azure Subscription. 

.EXAMPLE
       
       copy-snapshotRemoteSubscription -sourceSubscriptionID xxx-xxx-xxx-xxx-xxx -targetSubscriptionID xxx-xxx-xxx-xxx-xxx -sourceSnapshotResourceGroupName rg-snaps -targetResourceGroupName rg-snaps
#>
[CmdletBinding()]
param (
    [parameter(position=3, mandatory=$false)][string]$sourceSubscriptionID = "",
    [parameter(position=0, mandatory=$true)][string]$targetSubscriptionID = "",
    [parameter(position=1, mandatory=$true)][string]$sourceSnapshotResourceGroupName = "",
    [parameter(position=2, mandatory=$true)][string]$targetResourceGroupName = ""
)

# Save original Az Context
$orgAzContext = Get-AzContext | out-null

# If sourceSubscription set, update AzContext
if($sourceSubscriptionID){
    # Set Az context to source subscription
    Get-AzSubscription -SubscriptionId $sourceSubscriptionID | Set-AzContext | out-null
}

# Query for snapshot
$snapshots = Get-AzSnapshot -ResourceGroupName $sourceSnapshotResourceGroupName

## Copy snapshots to target subscription

# Set Az contect to target subscription
Get-AzSubscription -SubscriptionId $targetSubscriptionID | Set-AzContext | out-null
try{
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
            -ResourceGroupName $targetResourceGroupName `
            -ErrorAction Stop
    }
}
catch{
    write-error -message "Failed to create snapshot in remote subscription"
    $_
    exit;
}


# Reset original Az Context
Set-AzContext -Context $orgAzContext | out-null
