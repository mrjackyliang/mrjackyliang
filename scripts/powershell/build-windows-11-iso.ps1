<#
.SYNOPSIS
    Windows 11 Custom ISO Builder

.DESCRIPTION
    1. Extracts a user-selected Source ISO.
    2. Merges "base" folder (drivers/extras) into the ISO root.
    3. Injects "autounattend.xml" into the boot RAM disk (X:\).
    4. Configures "winpeshl.ini" to force that specific answer file.

.PREREQUISITES
    - Run as Administrator.
    - "oscdimg.exe" MUST be in the "oscdimg\{x64|arm64}" folder.
#>

# ==========================================
# 1. ENVIRONMENT CONFIGURATION
# ==========================================

# Clear the screen.
Clear-Host

# Get the directory where this script is running.
$ProjectDirectory = $PSScriptRoot

# Fallback for PowerShell ISE or if script hasn't been saved yet.
if (-not $ProjectDirectory) {
    $ProjectDirectory = Get-Location
}

# Define the paths to our "Ingredient" folders.
$IsoSourceDirectory     = "$ProjectDirectory\iso_source"
$IsoOutputDirectory     = "$ProjectDirectory\iso_output"
$OscdimgBaseDirectory   = "$ProjectDirectory\oscdimg"
$BaseFolderDirectory    = "$ProjectDirectory\base"
$AnswerFilePath         = "$ProjectDirectory\autounattend.xml"
$TemporaryWorkDirectory = "$ProjectDirectory\temp"

# Define internal paths for temporary workspace.
$ExtractedSourceDirectory = "$TemporaryWorkDirectory\source"
$MountDirectory           = "$TemporaryWorkDirectory\mount"

# Define internal files.
$WimPath = "$ExtractedSourceDirectory\sources\boot.wim"

# ==========================================
# 2. TOOL & PERMISSION CHECKS
# ==========================================

# Check 1: Administrator Privileges.
$IsAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $IsAdministrator) {
    Write-Warning "You must run this script as Administrator."

    return
}

# Check 2: Architecture-aware check for "oscdimg".
$SystemArch = $env:PROCESSOR_ARCHITECTURE
$OscdimgCommand = $null

if ($SystemArch -eq "ARM64") {
    $CandidatePath = "$OscdimgBaseDirectory\arm64\oscdimg.exe"
} else {
    $CandidatePath = "$OscdimgBaseDirectory\x64\oscdimg.exe"
}

if (Test-Path -Path $CandidatePath) {
    $OscdimgCommand = $CandidatePath
}

if (-not $OscdimgCommand) {
    Write-Error "`"oscdimg`" tool not found for architecture: $SystemArch"
    Write-Host "Please ensure the correct executable exists in `"$OscdimgBaseDirectory`"" -ForegroundColor Red

    return
}

# Check 3: Ensure the Answer File exists.
if (-not (Test-Path -Path $AnswerFilePath)) {
    Write-Error "Could not find `"autounattend.xml`" in the project directory."
    Write-Error "Please create one from `"https://schneegans.de/windows/unattend-generator/`"."

    return
}

# Check 4: Ensure ISO source folder exists.
if (-not (Test-Path -Path $IsoSourceDirectory)) {
    New-Item -ItemType Directory -Path $IsoSourceDirectory

    Write-Warning "Created missing `"iso_source`" folder."
    Write-Error "Please put your Windows ISOs inside the `"iso_source`" folder and retry."

    return
}

# Check 5: Redundancy Safety Check.
if (Test-Path -Path "$BaseFolderDirectory\autounattend.xml") {
    Write-Warning "You have an `"autounattend.xml`" inside your `"base`" folder."
    Write-Warning "The script uses the one in the PROJECT ROOT. Please remove the one in `"base`" to avoid confusion."

    $Confirmation = Read-Host "Type `"Y`" to ignore this and continue, or any other key to exit"

    if ($Confirmation.ToUpper() -ne 'Y') {
        return
    }
}

# ==========================================
# 3. USER INTERACTION
# ==========================================

# Find all ISO files in the "iso_source" folder.
$AvailableIsoFiles = Get-ChildItem -Path $IsoSourceDirectory -Filter "*.iso"

if ($AvailableIsoFiles.Count -eq 0) {
    Write-Error "No `".iso`" files were found in `"$IsoSourceDirectory`"."
    
    return
}

# Display the menu.
Write-Host "--- Available ISO Files ---" -ForegroundColor Cyan

for ($Index = 0; $Index -lt $AvailableIsoFiles.Count; $Index += 1) {
    Write-Host "[$Index] $($AvailableIsoFiles[$Index].Name)"
}

# Ask user to pick one.
$UserSelectionIndex = Read-Host "Please select the Source ISO number [0 - $($AvailableIsoFiles.Count - 1)]"

# Validate selection.
if ($UserSelectionIndex -notmatch "^\d+$" -or [int]$UserSelectionIndex -ge $AvailableIsoFiles.Count) {
    Write-Error "Invalid Selection."

    return
}

$SourceIsoFile = $AvailableIsoFiles[[int]$UserSelectionIndex]

# Ask user for output name.
$OutputIsoFileName = Read-Host "Enter a name for the new ISO (e.g., win11_custom)"

if (-not $OutputIsoFileName.EndsWith(".iso")) { 
    $OutputIsoFileName = "$OutputIsoFileName.iso" 
}

# Check if output name has invalid characters.
$InvalidChars = [IO.Path]::GetInvalidFileNameChars()

if ($OutputIsoFileName.IndexOfAny($InvalidChars) -ge 0) {
    Write-Error "Output filename contains invalid characters."

    return
}

# Ensure Output Directory Exists.
if (-not (Test-Path -Path $IsoOutputDirectory)) {
    Write-Host "Creating output folder: $IsoOutputDirectory" -ForegroundColor Yellow

    New-Item -ItemType Directory -Path $IsoOutputDirectory
}

$FinalIsoPath = "$IsoOutputDirectory\$OutputIsoFileName"

# Warns if the file will be overwritten.
if (Test-Path -Path $FinalIsoPath) {
    Write-Warning "File `"$OutputIsoFileName`" already exists and will be overwritten."

    $Confirmation = Read-Host "Press `"Y`" to continue, or any other key to abort"

    if ($Confirmation.ToUpper() -ne 'Y') {
        return
    }
}

# ==========================================
# 4. EXTRACTION & MERGING
# ==========================================
$SourceIsoMounted = $false
$WimMounted = $false

# Clean up old temp files.
if (Test-Path -Path $TemporaryWorkDirectory) { 
    Remove-Item -Path $TemporaryWorkDirectory -Recurse -Force 
}

New-Item -ItemType Directory -Path $ExtractedSourceDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $MountDirectory -Force | Out-Null

try {
    # Step 1: Mount and Extract.
    Write-Host "`n[Step 1/5] Extracting contents of `"$($SourceIsoFile.Name)`" ..." -ForegroundColor Cyan
    
    $MountedIsoImage = Mount-DiskImage -ImagePath $SourceIsoFile.FullName -PassThru
    $IsoDriveLetter = ($MountedIsoImage | Get-Volume).DriveLetter + ":\"

    $SourceIsoMounted = $true
    
    # Robocopy extraction.
    robocopy "$IsoDriveLetter" "$ExtractedSourceDirectory" /E /NFL /NDL /NJH /NJS | Out-Null
    
    Dismount-DiskImage -ImagePath $SourceIsoFile.FullName | Out-Null

    $SourceIsoMounted = $false
    
    # Clear Read-Only/System attributes inherited from the ISO.
    Write-Host "    -> Unlocking file attributes ..." -ForegroundColor Gray

    Get-ChildItem -Path $ExtractedSourceDirectory -Recurse | ForEach-Object {
        $_.Attributes = 'Normal'
    }

    # Step 2: Merge Base Folder (Overlay).
    if (Test-Path -Path $BaseFolderDirectory) {
        Write-Host "[Step 2/5] Merging `"base`" folder into ISO root ..." -ForegroundColor Cyan

        Copy-Item -Path "$BaseFolderDirectory\*" -Destination $ExtractedSourceDirectory -Recurse -Force
    } else {
        Write-Host "[Step 2/5] No `"base`" folder found. Proceeding with XML injection only." -ForegroundColor Yellow
    }

    # ==========================================
    # 5. BOOT IMAGE MODIFICATION
    # ==========================================
    
    Write-Host "[Step 3/5] Injecting configuration into `"boot.wim`" ..." -ForegroundColor Cyan

    Mount-WindowsImage -ImagePath $WimPath -Index 2 -Path $MountDirectory | Out-Null

    $WimMounted = $true

    # A. Copy "autounattend.xml" to "X:\".
    Write-Host "    -> Placing `"autounattend.xml`" into the boot drive (X:\) ..." -ForegroundColor Gray
    
    Copy-Item -Path $AnswerFilePath -Destination "$MountDirectory\autounattend.xml" -Force

    # B. Create a Helper Batch Script.
    Write-Host "    -> Creating launch script ..." -ForegroundColor Gray

    $LaunchScriptContent = @"
@echo off
title Launcher
echo.
echo ================================
echo  MICROSOFT WINDOWS 11 INSTALLER
echo ================================
echo.
%WINDIR%\system32\wpeinit.exe

echo Launching in 5 seconds ... (Press CTRL+C to Abort)
ping 127.0.0.1 -n 5 > nul

echo Starting Setup ...
X:\setup.exe /unattend:X:\autounattend.xml
"@

    Set-Content -Path "$MountDirectory\Windows\System32\launch.cmd" -Value $LaunchScriptContent -Encoding Ascii

    # C. Update "winpeshl.ini" to run the Batch Script via CMD.
    Write-Host "    -> Configuring `"winpeshl.ini`" ..." -ForegroundColor Gray

    $WinPeshlContent = @"
[LaunchApps]
%WINDIR%\system32\cmd.exe, /c %WINDIR%\system32\launch.cmd
"@
    $WinPeshlPath = "$MountDirectory\Windows\System32\winpeshl.ini"

    Set-Content -Path $WinPeshlPath -Value $WinPeshlContent -Encoding Ascii

    # Unmount and Commit.
    Write-Host "    -> Saving changes ..." -ForegroundColor Gray

    Dismount-WindowsImage -Path $MountDirectory -Save | Out-Null

    $WimMounted = $false

    # ==========================================
    # 6. REBUILDING THE ISO
    # ==========================================
    
    Write-Host "[Step 4/5] Compiling new ISO ..." -ForegroundColor Cyan
    
    # Path validation for boot files.
    $EtfsPath = "$ExtractedSourceDirectory\boot\etfsboot.com"
    $EfiSysPath = "$ExtractedSourceDirectory\efi\microsoft\boot\efisys.bin"

    if (-not (Test-Path $EtfsPath) -or -not (Test-Path $EfiSysPath)) {
        Throw "Boot sectors (etfsboot.com or efisys.bin) missing. ISO structure may be invalid."
    }

    # Boot sectors for BIOS and UEFI.
    $BootArguments = "2#p0,e,b`"$EtfsPath`"#pEF,e,b`"$EfiSysPath`""

    # ISO label.
    $BaseIsoName = [IO.Path]::GetFileNameWithoutExtension($OutputIsoFileName)
    $BaseIsoNameMaxLength = [Math]::Min(32, $BaseIsoName.Length)
    $IsoLabel = $BaseIsoName.Substring(0, $BaseIsoNameMaxLength)
    
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $OscdimgCommand
    $ProcessInfo.Arguments = "-m -o -u2 -udfver102 -l`"$IsoLabel`" -bootdata:$BootArguments `"$ExtractedSourceDirectory`" `"$FinalIsoPath`""
    $ProcessInfo.RedirectStandardOutput = $true
    $ProcessInfo.UseShellExecute = $false
    
    $Process = [System.Diagnostics.Process]::Start($ProcessInfo)
    $Process.WaitForExit()
    $Process.StandardOutput.ReadToEnd() | Out-Null

    # ==========================================
    # 7. CLEANUP
    # ==========================================
    
    Write-Host "[Step 5/5] Cleaning up ..." -ForegroundColor Cyan

    Remove-Item -Path $TemporaryWorkDirectory -Recurse -Force

    Write-Host "`nSUCCESS! Your custom ISO is ready:" -ForegroundColor Green

    Write-Host $FinalIsoPath -ForegroundColor White
} catch {
    Write-Error "`nPROCESS FAILED: $_"
} finally {
    # Fail-Safe Cleanup
    if ($WimMounted) {
        Write-Warning "Performing emergency WIM dismount ..."
        Dismount-WindowsImage -Path $MountDirectory -Discard -ErrorAction SilentlyContinue | Out-Null
    }

    if ($SourceIsoMounted) {
        Write-Warning "Performing emergency Source ISO dismount ..."
        Dismount-DiskImage -ImagePath $SourceIsoFile.FullName -ErrorAction SilentlyContinue | Out-Null
    }

    if (Test-Path -Path $TemporaryWorkDirectory) {
        Remove-Item -Path $TemporaryWorkDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}