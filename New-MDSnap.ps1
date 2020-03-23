[CmdletBinding()]
param (
    [Parameter()]
    [int]$diskSize = 128,                     # Snapshot disk size
    [parameter(Mandatory = $true)]
        [string]$vmName,                      # Virtual Machine Name
    [parameter(Mandatory = $true)]
        [string]$resourceGroupName,           # Disk Snapshot Resource Group Name
    [parameter(Mandatory = $true)]
        [string]$primaryRegion                # Primary Azure Region
)

clear-host

# Test Variables
if ($null -eq $(Get-AzResourceGroup -name $resourceGroupName -ErrorAction SilentlyContinue)) {
    write-host -ForegroundColor red "Unable to find target Resource Group"
    exit;
}

# Query VM configuration
#$vm = Get-Azvm -Name $vmName

# Query for managed disks attached to the VM
$managedDisks = get-azdisk `
    -ResourceGroupName core-management | ? {$_.diskState -ne 'unattached' -and $_.managedby -like "*$vmName"} | select name, ResourceGroupName, Id | sort name

# Select from list of attached managed disks.
write-host -ForegroundColor yellow "Attached Managed Disks"
[int]$listitr =1
$managedDisks | ForEach-Object {
    write-host "[$listitr] - "$_.name
    $listitr++
}
[int]$mdResponse = $(Read-Host -Prompt "Select Managed disk")-1

$mdSnapshotName = $managedDisks[$mdResponse].name + "-snap-" + $(get-date -Format MMddyyyy-mmhhss)

write-host -ForegroundColor yellow "Creating Managed Disk Snapshot - $mdSnapshotName"

# Create Snapshot Configuration
$mdSnapshot = New-AzSnapshotConfig `
    -SourceUri $($managedDisks[$mdResponse].id) `
    -location $primaryRegion `
    -createOption copy `
    -Tag @{
        HBLsourceVM=$vmName
    }

# Create Snapshot
try {
    $mdCreateResult = (
    New-AzSnapshot -Snapshot $mdSnapshot `
        -SnapshotName $mdSnapshotName `
        -ResourceGroupName $resourceGroupName
)
}
catch {
    Write-Host -ForegroundColor red "Snapshot creation failed"    
    write-host -ForegroundColor red $_
}

switch ($mdCreateResult.ProvisioningState) {
    Succeeded {
        write-host -ForegroundColor Green "Disk SnapShot completed succesfully!!!"
    }
}

