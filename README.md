# az-snapshot-distribution

Copy and distribute managed disk snapshots across multiple Azure Subscriptions


## 1. Create Snapshot
#### create-MDSnapshot.ps1
A managed disk snapshot is created from data disks that are attached to the source virtual machine. 

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

#### Configuration Option Tags

Configuration options from the original data disk will be recorded as tags on the new snapshot. 

|Tag|Description|
|---|---|
|LUN|Assigned LUN from sourceVM|
|diskSKU|Managed disk SKU|
|diskSizeGB|Managed disk size|
|SourceVM|Source VM Name|


## 2. Copy Snapshot
#### copy-snapshotRemoteSubscription.ps1

Copy a managed disk snapshot between Azure subscriptions.

**Note**: The user running this script needs to have appropriate permissions to create and manage snapshots in the source and target subscriptions. 

### Required Parameters

|Name|Description|
|---|---|
|sourceSubscriptionID| Source Azure Subscription ID|
|targetSubscriptionID| Target remote Azure Subscription ID|
|snapshotRg| Resource Group where source snapshots are located|
|targetResourceGroupName| Remote Resource Group to copy snapshots|


```powershell
# Required Parameters

    [parameter(position=0, mandatory=$true)][string]$sourceSubscriptionID = "",
    [parameter(position=1, mandatory=$true)][string]$targetSubscriptionID = "",
    [parameter(position=2, mandatory=$true)][string]$snapshotRg = "",
    [parameter(position=3, mandatory=$true)][string]$targetResourceGroupName = ""
```

## 3. Attach Snapshot
#### attach-MDSnapshot.ps1

The source snapshot will be used to create a new managed disk (per VM). 
The new disk will be attached to the target VM. 

### Required Parameters
|Name|Description|
|---|---|
|snapshotRGName|Resource Group where snapshots are stored|
|targetVms|Target VM to attach disk|

```powershell
# Required Parameters
param (
    [parameter(position=1, mandatory=$true)][string]$snapshotRGName,
    [parameter(position=2, Mandatory=$true)][string]$targetVms
)
```

Configuration options stored as Tags on the source snapshot will be used to define options for creating and attaching the new disk. 

#### Configuration Option Tags
|Tag|Description|
|---|---|
|LUN|Assigned LUN from sourceVM|
|diskSKU|Managed disk SKU|
|diskSizeGB|Managed disk size|
|SourceVM|Source VM Name|