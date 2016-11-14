
# Set here the path of your ISO file
$iso = 'C:\ct_windows_server_2016_x64_dvd_9327748.iso'

# Set here the letter of your usb
$usbdiskletter = 'F'

#get disk
$usb =Get-Partition| where DriveLetter -eq "$usbdiskletter"|Get-Disk

# Clean ! will clear your usb!!
$usb| Clear-Disk -RemoveData -Confirm:$true -PassThru
  

 
# Convert GPT
if ($usb.PartitionStyle -eq 'RAW') {
    $usb | Initialize-Disk -PartitionStyle GPT
} else {
    $usb | Set-Disk -PartitionStyle GPT
}

# Create partition primary and format to FAT32
$volume = $usb | New-Partition -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem FAT32



if (Test-Path -Path "$($volume.DriveLetter):\") {

    # Mount iso
    $miso = Mount-DiskImage -ImagePath $iso -StorageType ISO -PassThru

    # Driver letter
    $dl = ($miso | Get-Volume).DriveLetter
}

if (Test-Path -Path "$($dl):\sources\install.wim") {

    # Copy ISO content to USB except install.wim
    & (Get-Command "$($env:systemroot)\system32\robocopy.exe") @(
        "$($dl):\",
        "$($volume.DriveLetter):\"
        ,'/S','/R:0','/Z','/XF','install.wim','/NP'
    )

    # Split install.wim
    & (Get-Command "$($env:systemroot)\system32\dism.exe") @(
        '/split-image',
        "/imagefile:$($dl):\sources\install.wim",
        "/SWMFile:$($volume.DriveLetter):\sources\install.swm",
        '/FileSize:4096'
    )
}

# Eject USB
(New-Object -comObject Shell.Application).NameSpace(17).
ParseName("$($volume.DriveLetter):").InvokeVerb('Eject')

# Dismount ISO
Dismount-DiskImage -ImagePath $iso