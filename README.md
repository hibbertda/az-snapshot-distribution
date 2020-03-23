# az-snapshot-distribution
Copy and distribute managed disk snapshots across multiple Azure Subscriptions


## 1. Create Snapshot
#### create-MDSnapshot.ps1
A managed disk snapshot is created from data disks that are attached to the source virtal machine. 

### Required Parameters

|Name|Description|
|---|---|
|SourceVM| Virtual Machine source for data disks to snapshot|
|snapshotRG| Resource Group to store snapshots|


```powershell
# Required Parameters
param (
    # Default
    [parameter(position=0, mandatory=$true)][string]$sourceVm,
    [parameter(position=1, mandatory=$true)][string]$snapshotRG,
)
```


## 2. Copy Snapshot
#### copy-snapshotRemoteSubscription.ps1

### Required Parameters

|Name|Description|
|---|---|
|sourceSubscriptionID| Source Azure Subscription ID|
|targetSubscriptionID| Target remote Azure Subscription ID|
|snapshotRg| Resource Group where source snapshots are located|
|targetResourceGroupName| Remote Resouce Group to copy snapshots|


```powershell
# Required Parameters

    [parameter(position=0, mandatory=$true)][string]$sourceSubscriptionID = "",
    [parameter(position=1, mandatory=$true)][string]$targetSubscriptionID = "",
    [parameter(position=2, mandatory=$true)][string]$snapshotRg = "",
    [parameter(position=3, mandatory=$true)][string]$targetResourceGroupName = ""
```