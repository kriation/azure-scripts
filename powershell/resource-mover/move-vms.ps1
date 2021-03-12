# Define variables for script
$SourceSubscription = ""
$SourceResourceGroupName = ""

$TargetSubscriptionId = ""
$TargetResourceGroupName = ""

$ListOfVMs = ""

# Set Source Subscription
Select-AzSubscription -Subscription $SourceSubscription
ForEach( $VMName in $ListOfVMs)
{
    # Get VM Details
    $VM = Get-AzVM -ResourceGroupName $SourceResourceGroupName -Name $VMName -Status
    $VMObject = Get-AzVM -ResourceGroupName $SourceResourceGroupName -Name $VMName
    $Disks = Get-AzVM -ResourceGroupName $SourceResourceGroupName -Name $VMName -Status | Select-Object -ExpandProperty Disks

    # Stop VM in preparation
    Stop-AzVM -Force -ResourceGroupName $SourceResourceGroupName -Name $VMName

    # Get VM Disk objects
    $VMOSDiskName = $Disks | Where-Object Name -NotLike '*Data*'
    $VMDataDisks = $Disks | Where-Object Name -Like '*Data*'

    # Detach data disk from VM
    if( $VMDataDisks.count -gt 0 )
    {
        ForEach($VMDataDisk in $VMDataDisks)
        {
            Remove-AzVMDataDisk -VM $VMObject -DataDiskNames $VMDataDisk.Name
            Update-AzVM -ResourceGroupName $sourceResourceGroupName -VM $VMObject
            # Move the data disk to the new destination
            $DataDiskObject = Get-AzResource -Name $VMDataDisk.Name -ResourceGroupName $SourceResourceGroupName
            Move-AzResource -Force -DestinationResourceGroupName $TargetResourceGroupName -DestinationSubscriptionId $TargetSubscriptionId -ResourceId $DataDiskObject.ResourceId
        }
    }

    # Get OSDisk Object
    $VMOSDisk = Get-AzDisk -ResourceGroupName $SourceResourceGroupName -Name $VMOSDiskName.Name

    # Build snapshot Configuration of OS Disk
    $OSDiskSnapshotConfig = New-AzSnapshotConfig -SkuName $VMOSDisk.Sku.Name -OsType $VMOSDisk.OsType -DiskSizeGB $VMOSDisk.DiskSizeGB -Location $VMOSDisk.location -CreateOption copy -SourceUri $VMOSDisk.Id

    # Define snapshot name
    $OSSnapshotName = "snapshot-"+$VM.Name

    # Create snapshot using the above configuration
    $OSDiskSnapshot = New-AzSnapshot -ResourceGroupName $VMOSDisk.ResourceGroupName -SnapshotName $OSSnapshotName -Snapshot $OSDiskSnapshotConfig

    # Create disk configuration
    $OSDiskConfig = New-AzDiskConfig -SkuName $VMOSDisk.Sku.Name -OsType $VMOSDisk.OsType -DiskSizeGB $VMOSDisk.DiskSizeGB -Location $VMOSDisk.location -CreateOption copy -SourceUri $OSDiskSnapshot.Id

    # Create name for OS disk copy
    $OSDiskCopyName = "osdisk-"+$VMObject.Location+"-"+$VMOSDisk.Name

    # Create copy of OS disk
    $OSDiskCopy = New-AzDisk -ResourceGroupName $VMOSDisk.ResourceGroupName -DiskName $OSDiskCopyName -Disk $OSDiskConfig

    # Move the disk to the new destination
    Move-AzResource -Force -DestinationResourceGroupName $TargetResourceGroupName -DestinationSubscriptionId $TargetSubscriptionId -ResourceId $OSDiskCopy.Id
}
