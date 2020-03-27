<#
.NOTES
    Daniel Hibbert - March 2020
    Version 0.1

    Microsoft Azure - attach-snapshotMD.ps1

    THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
    KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
    PARTICULAR PURPOSE.

.DESCRIPTION

    This script will automate the process of creating a managed disk from a snapshot
    and attaching the new disk to an existing virtual machine.

.PARAMETER sourceVM

    [string] Source resource group name where snapshots are stored

.PARAMETER targetVmName

    [string] Target VM to attach new managed disk

.PARAMETER targetVmResourceGroupName

    [string] Target VM Resource Group Name

.EXAMPLE
       
       attach-snashotMD.ps1 -targetVM VM01 -snapshotRGName rg-snapshotStorage
#>

param (
    [parameter(position=1, mandatory=$true)][string]$snapshotRGName,
    [parameter(position=2, Mandatory=$true)][string]$targetVmName,
    [parameter(position=3, Mandatory=$false)][string]$targetVmResourceGroupName
)

# Query for targetVM configration. [Optional] include VM resource group name
if($targetVmResourceGroupName){
    $vmConfig = Get-AzVM `
        -name $targetVmName `
        -ResourceGroupName $targetVmResourceGroupName
}
else {
    $vmConfig = Get-AzVM -name $targetVmName
}

# Check for valid VM. If not found exit script
if (!$vmConfig.Id){
    Write-error -message "Unable to find target virtual machine. Check the name and try again"
    exit;
}

## Query for existing SnapShots
write-host -ForegroundColor green "## Discovering Available Snapshots ##"
$availableSnapshots = Get-AzSnapshot -ResourceGroupName $snapshotRGName

# Confirm snapshots are found. If (0) exit script
if ($availableSnapshots.count -eq 0){
    Write-Error -Message "No snapshots found."
    exit;
}

# Generate menu to select snapshot
write-host -ForegroundColor yellow "`nMultiple snapshots found.`n"
[int]$listitr =1
$availableSnapshots | ForEach-Object {
    write-host "[$listitr] - "$_.name
    $listitr++
}
[string]$mdResponse = $(Read-Host -Prompt "Select snapshot")-1
$sourceSnapshot = $availableSnapshots[$mdResponse]


#### Create disk from snapshot
## Create new managed disk from snapshot
write-host -ForegroundColor green -NoNewline "## Creating Managed Disk from Snapshot"

# Create managed disk from snapshot (one for each target VM)
try {
    $sourceSnapshot | foreach-object {
        $mdConfig = New-AzDiskConfig `
            -SkuName $_.Tags.diskSKU `
            -Location $vmConfig.Location `
            -CreateOption Copy `
            -SourceResourceId $_.Id `
            -DiskSizeGB $_.tags.diskSizeGB `
            -Tag $_.Tags

        $newMD = New-AzDisk `
            -Disk $mdConfig `
            -ResourceGroupName $vmConfig.ResourceGroupName `
            -DiskName $_.Name 
    }
    write-host -ForegroundColor Yellow "...Completed!"
}
catch {
    Write-Error -Message "Managed Disk creation FAILED`n`n"
    $_
    exit;
}
    
## STEP 3: Attach data disk to target VM
try {
    write-host -ForegroundColor green -NoNewline "## Attach data disk"

    # Check for exiting data disk connected to desired LUN
    foreach ($disk in $($vmConfig.StorageProfile.DataDisks)) {
    # If exists detach data disk
    if ($disk.lun -eq $sourceSnapshot.tags.LUN){
        write-host -foregroundColor Yellow "`n`t!! Found existing disk at LUN $($sourceSnapshot.tags.LUN) !!"

        Remove-AzVMDataDisk -VM $vmConfig -Name $disk.name
        update-AzVM -ResourceGroupName $vmConfig.ResourceGroupname -VM $vmConfig | out-null
    }
}
# attach snapshot disk to target VM
Add-AzVMDataDisk `
    -vm $vmConfig `
    -CreateOption attach `
    -Lun $sourceSnapshot.tags.LUN `
    -ManagedDiskId $newMD.Id `
    -ErrorAction Stop

Update-AzVm `
    -vm $vmConfig `
    -ResourceGroupName $vmConfig.ResourceGroupName `
    -ErrorAction Stop | out-null

    write-host -ForegroundColor Yellow "...Completed!"
}
catch {
    write-error -message "Failed to attach to VM`n`n"
    $_
    exit;
}