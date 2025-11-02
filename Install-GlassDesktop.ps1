<#
.SYNOPSIS
    Automates the installation and configuration of Windows 11 Glass Desktop effects.

.DESCRIPTION
    This script installs and configures three tools to create a beautiful glass/translucent Windows 11 desktop:
    - MicaForEveryone: Applies Acrylic effects to application windows
    - TranslucentTB: Makes the taskbar translucent with Acrylic effect
    - ExplorerBlurMica: Adds Acrylic blur to File Explorer

.NOTES
    Requires Administrator privileges
    Requires Windows 10 (build 18362+) or Windows 11

.EXAMPLE
    .\Install-GlassDesktop.ps1
    Runs installation automatically (default behavior)

.EXAMPLE
    .\Install-GlassDesktop.ps1 -Help
    Displays usage information

.EXAMPLE
    .\Install-GlassDesktop.ps1 -Uninstall
    Removes all glass desktop components
#>

#Requires -RunAsAdministrator

param(
    [Parameter(HelpMessage="Display usage information")]
    [switch]$Help,

    [Parameter(HelpMessage="Uninstall all glass desktop components")]
    [switch]$Uninstall
)

# Global variables
$Script:ExplorerBlurMicaPath = "C:\Program Files\ExplorerBlurMica"
$Script:ExplorerBlurMicaUrl = "https://github.com/Maplespe/ExplorerBlurMica/releases/download/2.0.1/Release_x64.zip"
$Script:VCRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$Script:MicaForEveryoneUrl = "https://github.com/MicaForEveryone/MicaForEveryone/releases/download/2.0.5.0/bundle.msixbundle"
$Script:TranslucentTBUrl = "https://github.com/TranslucentTB/TranslucentTB/releases/download/2025.1/bundle.msixbundle"

function Test-Prerequisites {
    <#
    .SYNOPSIS
        Checks system prerequisites for glass desktop installation.
    #>
    Write-Host "`n=== Checking Prerequisites ===" -ForegroundColor Cyan

    # Check Windows version
    $os = Get-CimInstance Win32_OperatingSystem
    $build = [int]$os.BuildNumber

    Write-Host "Windows Version: $($os.Caption) (Build $build)" -ForegroundColor Gray

    if ($build -lt 18362) {
        Write-Host "ERROR: Windows 10 build 18362 or higher is required!" -ForegroundColor Red
        return $false
    }

    if ($build -ge 22000) {
        Write-Host "Windows 11 detected - Full Mica/Acrylic support available" -ForegroundColor Green
    } else {
        Write-Host "Windows 10 detected - Limited effect support" -ForegroundColor Yellow
    }

    return $true
}

function Install-VCRedist {
    <#
    .SYNOPSIS
        Checks for and installs Visual C++ Redistributables if missing.
    #>
    Write-Host "`n=== Checking Visual C++ Redistributables ===" -ForegroundColor Cyan

    # Check if VC++ Redistribut is already installed
    $vcInstalled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" -ErrorAction SilentlyContinue

    if ($vcInstalled -and $vcInstalled.Installed -eq 1) {
        Write-Host "Visual C++ Redistributables already installed" -ForegroundColor Green
        return $true
    }

    Write-Host "Visual C++ Redistributables not found. Installing..." -ForegroundColor Yellow

    try {
        $vcPath = "$env:TEMP\vc_redist.x64.exe"

        Write-Host "Downloading VC++ Redistributables..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $Script:VCRedistUrl -OutFile $vcPath -UseBasicParsing

        Write-Host "Installing VC++ Redistributables (this may take a minute)..." -ForegroundColor Gray
        $process = Start-Process -FilePath $vcPath -ArgumentList "/install /quiet /norestart" -Wait -PassThru

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Host "VC++ Redistributables installed successfully!" -ForegroundColor Green
            Remove-Item $vcPath -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Host "WARNING: VC++ installation returned exit code $($process.ExitCode)" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "ERROR: Failed to install VC++ Redistributables: $_" -ForegroundColor Red
        Write-Host "Please install manually from: $Script:VCRedistUrl" -ForegroundColor Yellow
        return $false
    }
}

function Install-MSIXPackage {
    <#
    .SYNOPSIS
        Downloads and installs an MSIX bundle package.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Url
    )

    try {
        $msixPath = "$env:TEMP\$Name.msixbundle"

        Write-Host "Downloading $Name from GitHub..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $Url -OutFile $msixPath -UseBasicParsing

        Write-Host "Installing $Name..." -ForegroundColor Gray
        Add-AppxPackage -Path $msixPath -ErrorAction Stop

        Write-Host "$Name installed successfully via MSIX!" -ForegroundColor Green
        Remove-Item $msixPath -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        Write-Host "ERROR: Failed to install $Name via MSIX: $_" -ForegroundColor Red
        return $false
    }
}

function Start-MSIXApp {
    <#
    .SYNOPSIS
        Launches an installed MSIX application and configures it for startup.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$AppName,

        [Parameter(Mandatory=$true)]
        [string]$PackageFamilyName
    )

    try {
        Write-Host "Launching $AppName..." -ForegroundColor Gray

        # Get the installed package
        $package = Get-AppxPackage | Where-Object { $_.Name -like "*$PackageFamilyName*" } | Select-Object -First 1

        if (-not $package) {
            Write-Host "WARNING: Could not find installed package for $AppName" -ForegroundColor Yellow
            return $false
        }

        # Get the Application ID
        $manifest = Get-AppxPackageManifest $package
        $appId = $manifest.Package.Applications.Application.Id

        if (-not $appId) {
            Write-Host "WARNING: Could not find Application ID for $AppName" -ForegroundColor Yellow
            return $false
        }

        # Launch the app using shell protocol
        $appUserModelId = "$($package.PackageFamilyName)!$appId"
        Start-Process "shell:AppsFolder\$appUserModelId"

        Write-Host "$AppName launched successfully!" -ForegroundColor Green

        # Add to startup using Task Scheduler for reliability
        $taskName = "GlassDesktop_$AppName"
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

        if (-not $existingTask) {
            Write-Host "Configuring $AppName to start at login..." -ForegroundColor Gray
            $action = New-ScheduledTaskAction -Execute "explorer.exe" -Argument "shell:AppsFolder\$appUserModelId"
            $trigger = New-ScheduledTaskTrigger -AtLogon
            $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0

            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
            Write-Host "$AppName will now start automatically at login" -ForegroundColor Green
        }

        return $true
    } catch {
        Write-Host "WARNING: Could not launch $AppName: $_" -ForegroundColor Yellow
        Write-Host "You can launch it manually from the Start Menu" -ForegroundColor Gray
        return $false
    }
}

function Install-WinGetIfMissing {
    <#
    .SYNOPSIS
        Ensures WinGet is installed on the system.
    #>
    Write-Host "`n=== Checking for WinGet ===" -ForegroundColor Cyan

    try {
        $winget = Get-Command winget -ErrorAction Stop
        Write-Host "WinGet found: $($winget.Source)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "WinGet not found. Installing..." -ForegroundColor Yellow

        try {
            # Install App Installer from Microsoft Store (includes WinGet)
            Write-Host "Installing Microsoft App Installer (this may take a moment)..." -ForegroundColor Gray
            $appInstallerUrl = "https://aka.ms/getwinget"
            Start-Process "ms-windows-store://pdp/?productid=9nblggh4nns1"
            Write-Host "Please install 'App Installer' from the Microsoft Store window that just opened." -ForegroundColor Yellow
            Write-Host "Press Enter once installation is complete..." -ForegroundColor Yellow
            Read-Host

            # Verify installation
            $winget = Get-Command winget -ErrorAction Stop
            Write-Host "WinGet successfully installed!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "ERROR: Failed to install WinGet. Please install manually from Microsoft Store." -ForegroundColor Red
            return $false
        }
    }
}

function Install-MicaForEveryone {
    <#
    .SYNOPSIS
        Installs and configures MicaForEveryone with Acrylic effects.
    #>
    Write-Host "`n=== Installing MicaForEveryone ===" -ForegroundColor Cyan

    try {
        # Try WinGet first (fast if it works)
        Write-Host "Attempting installation via WinGet..." -ForegroundColor Gray
        $output = winget install --id=MicaForEveryone.MicaForEveryone -e --accept-package-agreements --accept-source-agreements 2>&1

        if ($LASTEXITCODE -eq 0 -or $output -like "*Successfully installed*") {
            Write-Host "MicaForEveryone installed successfully via WinGet!" -ForegroundColor Green
            Start-Sleep -Seconds 3
        } else {
            # WinGet failed, use MSIX fallback
            Write-Host "WinGet failed. Trying direct MSIX installation..." -ForegroundColor Yellow
            $installed = Install-MSIXPackage -Name "MicaForEveryone" -Url $Script:MicaForEveryoneUrl

            if (-not $installed) {
                throw "Failed to install via both WinGet and MSIX"
            }
            Start-Sleep -Seconds 2
        }

        # Create Acrylic configuration
        Write-Host "Configuring Acrylic effects..." -ForegroundColor Gray
        $configPath = "$env:LOCALAPPDATA\Mica For Everyone"

        if (-not (Test-Path $configPath)) {
            New-Item -ItemType Directory -Path $configPath -Force | Out-Null
        }

        $configFile = Join-Path $configPath "config.xcl"
        # Build config content line by line to avoid parser issues
        $configLines = @(
            '# MicaForEveryone Configuration - Acrylic Effects'
            '# Auto-generated by Install-GlassDesktop.ps1'
            ''
            'Global: "" {'
            '    TitleBarColor = Dark'
            '    BackdropPreference = Acrylic'
            '}'
            ''
            '# File Explorer gets Acrylic effect'
            'Class: "CabinetWClass" {'
            '    BackdropPreference = Acrylic'
            '    TitleBarColor = System'
            '}'
            ''
            '# Notepad'
            'Process: "notepad" {'
            '    BackdropPreference = Acrylic'
            '    TitleBarColor = System'
            '}'
        )

        $configLines | Out-File -FilePath $configFile -Encoding UTF8 -Force
        Write-Host "Configuration file created: $configFile" -ForegroundColor Green

        # Launch the application and configure startup
        Write-Host "`nStarting MicaForEveryone..." -ForegroundColor Cyan
        Start-MSIXApp -AppName "MicaForEveryone" -PackageFamilyName "MicaForEveryone"

        return $true
    } catch {
        Write-Host "ERROR: Failed to install MicaForEveryone: $_" -ForegroundColor Red
        return $false
    }
}

function Install-TranslucentTB {
    <#
    .SYNOPSIS
        Installs TranslucentTB for Acrylic taskbar effects.
    #>
    Write-Host "`n=== Installing TranslucentTB ===" -ForegroundColor Cyan

    try {
        # Try WinGet first (fast if it works)
        Write-Host "Attempting installation via WinGet..." -ForegroundColor Gray
        $output = winget install --id=CharlesMilette.TranslucentTB -e --accept-package-agreements --accept-source-agreements 2>&1

        if ($LASTEXITCODE -eq 0 -or $output -like "*Successfully installed*") {
            Write-Host "TranslucentTB installed successfully via WinGet!" -ForegroundColor Green
            Start-Sleep -Seconds 3
        } else {
            # WinGet failed, use MSIX fallback
            Write-Host "WinGet failed. Trying direct MSIX installation..." -ForegroundColor Yellow
            $installed = Install-MSIXPackage -Name "TranslucentTB" -Url $Script:TranslucentTBUrl

            if (-not $installed) {
                throw "Failed to install via both WinGet and MSIX"
            }
            Start-Sleep -Seconds 2
        }

        Write-Host "TranslucentTB will use Acrylic effect by default." -ForegroundColor Gray
        Write-Host "You can customize settings by right-clicking its system tray icon." -ForegroundColor Gray

        # Launch the application and configure startup
        Write-Host "`nStarting TranslucentTB..." -ForegroundColor Cyan
        Start-MSIXApp -AppName "TranslucentTB" -PackageFamilyName "TranslucentTB"

        return $true
    } catch {
        Write-Host "ERROR: Failed to install TranslucentTB: $_" -ForegroundColor Red
        return $false
    }
}

function Install-ExplorerBlurMica {
    <#
    .SYNOPSIS
        Downloads, installs, and configures ExplorerBlurMica with Acrylic effects.
    #>
    Write-Host "`n=== Installing ExplorerBlurMica ===" -ForegroundColor Cyan

    try {
        # Download the release
        Write-Host "Downloading ExplorerBlurMica from GitHub..." -ForegroundColor Gray
        $zipPath = "$env:TEMP\ExplorerBlurMica.zip"

        Invoke-WebRequest -Uri $Script:ExplorerBlurMicaUrl -OutFile $zipPath -UseBasicParsing
        Write-Host "Downloaded to: $zipPath" -ForegroundColor Gray

        # Create installation directory
        if (-not (Test-Path $Script:ExplorerBlurMicaPath)) {
            New-Item -ItemType Directory -Path $Script:ExplorerBlurMicaPath -Force | Out-Null
        }

        # Extract files
        Write-Host "Extracting files to: $Script:ExplorerBlurMicaPath" -ForegroundColor Gray
        Expand-Archive -Path $zipPath -DestinationPath $Script:ExplorerBlurMicaPath -Force

        # Check if DLL is in a subdirectory and move files if needed
        $dllPath = Join-Path $Script:ExplorerBlurMicaPath "ExplorerBlurMica.dll"
        if (-not (Test-Path $dllPath)) {
            Write-Host "DLL not in root, searching subdirectories..." -ForegroundColor Gray
            $foundDll = Get-ChildItem -Path $Script:ExplorerBlurMicaPath -Filter "ExplorerBlurMica.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

            if ($foundDll) {
                Write-Host "Found DLL in: $($foundDll.DirectoryName)" -ForegroundColor Gray
                # Move all files from subdirectory to root
                Get-ChildItem -Path $foundDll.DirectoryName -File | ForEach-Object {
                    Copy-Item -Path $_.FullName -Destination $Script:ExplorerBlurMicaPath -Force
                    Write-Host "  Moved: $($_.Name)" -ForegroundColor Gray
                }
                # Clean up subdirectory
                Remove-Item -Path $foundDll.DirectoryName -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                # List what we actually got
                Write-Host "ERROR: DLL not found. Extracted files:" -ForegroundColor Red
                Get-ChildItem -Path $Script:ExplorerBlurMicaPath -Recurse | ForEach-Object {
                    Write-Host "  $($_.FullName)" -ForegroundColor Yellow
                }
                throw "ExplorerBlurMica.dll not found in download"
            }
        }

        # Create config.ini with Acrylic effect
        Write-Host "Creating Acrylic configuration..." -ForegroundColor Gray
        $configLines = @(
            '[config]'
            'effect=1'
            'clearAddress=true'
            'clearBarBg=false'
            'clearWinUIBg=true'
            'showLine=true'
            ''
            '[light]'
            'r=255'
            'g=255'
            'b=255'
            'a=128'
            ''
            '[dark]'
            'r=32'
            'g=32'
            'b=32'
            'a=192'
        )

        $configPath = Join-Path $Script:ExplorerBlurMicaPath "config.ini"
        $configLines | Out-File -FilePath $configPath -Encoding UTF8 -Force
        Write-Host "Configuration file created: $configPath" -ForegroundColor Green

        # Install VC++ Redistributables if needed (required for DLL registration)
        Write-Host "Checking Visual C++ Redistributables..." -ForegroundColor Gray
        $vcInstalled = Install-VCRedist
        if (-not $vcInstalled) {
            Write-Host "WARNING: VC++ Redistributables not installed. DLL registration may fail." -ForegroundColor Yellow
        }

        # Register DLL with better error handling
        Write-Host "Registering ExplorerBlurMica DLL..." -ForegroundColor Gray
        # Re-check DLL path after potential move
        $dllPath = Join-Path $Script:ExplorerBlurMicaPath "ExplorerBlurMica.dll"

        if (-not (Test-Path $dllPath)) {
            throw "DLL not found at: $dllPath (this should not happen after move)"
        }

        # Unblock all files in the directory (Windows blocks downloaded files)
        Write-Host "Unblocking downloaded files..." -ForegroundColor Gray
        Get-ChildItem -Path $Script:ExplorerBlurMicaPath -Recurse -File | ForEach-Object {
            Unblock-File -Path $_.FullName -ErrorAction SilentlyContinue
        }

        # Try registration - use /s for silent mode
        try {
            $regArgs = @("/s", "`"$dllPath`"")
            $process = Start-Process -FilePath "regsvr32.exe" -ArgumentList $regArgs -Wait -PassThru -NoNewWindow -ErrorAction Stop

            if ($process.ExitCode -eq 0) {
                Write-Host "DLL registered successfully!" -ForegroundColor Green
            } else {
                Write-Host "WARNING: DLL registration returned exit code: $($process.ExitCode)" -ForegroundColor Yellow
                Write-Host "Note: The DLL has been installed. Effects may appear after restart." -ForegroundColor Yellow
                Write-Host "If effects don't appear, try registering manually:" -ForegroundColor Cyan
                Write-Host "  regsvr32 `"$dllPath`"" -ForegroundColor Cyan
                # Don't throw - continue with installation
            }
        } catch {
            Write-Host "WARNING: Could not register DLL: $_" -ForegroundColor Yellow
            Write-Host "The DLL has been installed. Try registering manually after restart:" -ForegroundColor Cyan
            Write-Host "  regsvr32 `"$dllPath`"" -ForegroundColor Cyan
            # Don't throw - continue with installation
        }

        # Restart Explorer
        Write-Host "Restarting Windows Explorer to apply effects..." -ForegroundColor Yellow
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2

        Write-Host "ExplorerBlurMica installed and configured!" -ForegroundColor Green
        return $true

    } catch {
        Write-Host "ERROR: Failed to install ExplorerBlurMica: $_" -ForegroundColor Red
        return $false
    } finally {
        # Cleanup
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-GlassDesktop {
    <#
    .SYNOPSIS
        Main installation function that orchestrates the entire glass desktop setup.
    #>
    $banner = @(
        '================================================================='
        ''
        '        Windows 11 Glass Desktop Installation'
        ''
        '   This will install and configure:'
        '   - MicaForEveryone (Acrylic window effects)'
        '   - TranslucentTB (Acrylic taskbar)'
        '   - ExplorerBlurMica (Acrylic File Explorer)'
        ''
        '================================================================='
    )
    Write-Host ($banner -join "`n") -ForegroundColor Cyan

    # Track installation results
    $results = @{
        Prerequisites = $false
        WinGet = $false
        MicaForEveryone = $false
        TranslucentTB = $false
        ExplorerBlurMica = $false
    }

    # Check prerequisites
    $results.Prerequisites = Test-Prerequisites
    if (-not $results.Prerequisites) {
        Write-Host "`nInstallation aborted due to failed prerequisites." -ForegroundColor Red
        return
    }

    # Install WinGet if needed
    $results.WinGet = Install-WinGetIfMissing
    if (-not $results.WinGet) {
        Write-Host "`nInstallation aborted: WinGet is required." -ForegroundColor Red
        return
    }

    # Install each component
    $results.MicaForEveryone = Install-MicaForEveryone
    $results.TranslucentTB = Install-TranslucentTB
    $results.ExplorerBlurMica = Install-ExplorerBlurMica

    # Summary
    Write-Host "`n=================================================================" -ForegroundColor Cyan
    Write-Host "              Installation Summary" -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan

    Write-Host "`nComponent Status:" -ForegroundColor White
    Write-Host "  - MicaForEveryone:    $(if($results.MicaForEveryone){'[OK] Installed'}else{'[FAIL] Failed'})" -ForegroundColor $(if($results.MicaForEveryone){'Green'}else{'Red'})
    Write-Host "  - TranslucentTB:      $(if($results.TranslucentTB){'[OK] Installed'}else{'[FAIL] Failed'})" -ForegroundColor $(if($results.TranslucentTB){'Green'}else{'Red'})
    Write-Host "  - ExplorerBlurMica:   $(if($results.ExplorerBlurMica){'[OK] Installed'}else{'[FAIL] Failed'})" -ForegroundColor $(if($results.ExplorerBlurMica){'Green'}else{'Red'})

    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count - 2  # Exclude Prerequisites and WinGet

    if ($successCount -eq 3) {
        Write-Host "`n[SUCCESS] All components installed and running!" -ForegroundColor Green
        Write-Host "`nGlass effects are now active! You should see:" -ForegroundColor Cyan
        Write-Host "  - Translucent taskbar with blur (TranslucentTB)" -ForegroundColor Gray
        Write-Host "  - Acrylic window backgrounds (MicaForEveryone)" -ForegroundColor Gray
        Write-Host "  - Blurred File Explorer (ExplorerBlurMica - may need restart)" -ForegroundColor Gray
        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "  1. Look at your taskbar - it should be translucent now!" -ForegroundColor White
        Write-Host "  2. Open any application window - notice the Acrylic effect" -ForegroundColor White
        Write-Host "  3. If File Explorer blur isn't visible, restart your computer" -ForegroundColor White
        Write-Host "  4. Right-click TranslucentTB tray icon to customize taskbar" -ForegroundColor Gray
        Write-Host "`nBoth apps will start automatically at login." -ForegroundColor Green
        Write-Host "`nTo uninstall, run: .\Install-GlassDesktop.ps1 -Uninstall" -ForegroundColor Yellow
    } else {
        Write-Host "`n[WARNING] Installation completed with some failures." -ForegroundColor Yellow
        Write-Host "Check the error messages above for details." -ForegroundColor Gray
    }
}

function Uninstall-GlassDesktop {
    <#
    .SYNOPSIS
        Removes all glass desktop components and restores default Windows appearance.
    #>
    Write-Host "`n=================================================================" -ForegroundColor Cyan
    Write-Host "        Windows 11 Glass Desktop Uninstallation" -ForegroundColor Cyan
    Write-Host "=================================================================`n" -ForegroundColor Cyan

    $confirmation = Read-Host "Are you sure you want to uninstall all glass desktop components? (yes/no)"

    if ($confirmation -ne "yes") {
        Write-Host "Uninstallation cancelled." -ForegroundColor Yellow
        return
    }

    # Track uninstall results
    $results = @{
        MicaForEveryone = $false
        TranslucentTB = $false
        ExplorerBlurMica = $false
    }

    # Uninstall MicaForEveryone
    Write-Host "`nUninstalling MicaForEveryone..." -ForegroundColor Cyan
    try {
        winget uninstall --id=MicaForEveryone.MicaForEveryone -e --silent
        $results.MicaForEveryone = $true
        Write-Host "MicaForEveryone uninstalled." -ForegroundColor Green
    } catch {
        Write-Host "Failed to uninstall MicaForEveryone: $_" -ForegroundColor Red
    }

    # Uninstall TranslucentTB
    Write-Host "`nUninstalling TranslucentTB..." -ForegroundColor Cyan
    try {
        winget uninstall --id=CharlesMilette.TranslucentTB -e --silent
        $results.TranslucentTB = $true
        Write-Host "TranslucentTB uninstalled." -ForegroundColor Green
    } catch {
        Write-Host "Failed to uninstall TranslucentTB: $_" -ForegroundColor Red
    }

    # Uninstall ExplorerBlurMica
    Write-Host "`nUninstalling ExplorerBlurMica..." -ForegroundColor Cyan
    try {
        $dllPath = Join-Path $Script:ExplorerBlurMicaPath "ExplorerBlurMica.dll"

        if (Test-Path $dllPath) {
            # Unregister DLL
            Write-Host "Unregistering DLL..." -ForegroundColor Gray
            $process = Start-Process -FilePath "regsvr32.exe" -ArgumentList "/u /s `"$dllPath`"" -Wait -PassThru

            if ($process.ExitCode -eq 0) {
                Write-Host "DLL unregistered successfully." -ForegroundColor Green
            }
        }

        # Remove directory
        if (Test-Path $Script:ExplorerBlurMicaPath) {
            Write-Host "Removing installation directory..." -ForegroundColor Gray
            Remove-Item -Path $Script:ExplorerBlurMicaPath -Recurse -Force
        }

        $results.ExplorerBlurMica = $true
        Write-Host "ExplorerBlurMica uninstalled." -ForegroundColor Green

        # Restart Explorer
        Write-Host "Restarting Windows Explorer..." -ForegroundColor Yellow
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2

    } catch {
        Write-Host "Failed to uninstall ExplorerBlurMica: $_" -ForegroundColor Red
    }

    # Summary
    Write-Host "`n=================================================================" -ForegroundColor Cyan
    Write-Host "Uninstallation Summary:" -ForegroundColor White
    Write-Host "  - MicaForEveryone:    $(if($results.MicaForEveryone){'[OK] Removed'}else{'[FAIL] Failed'})" -ForegroundColor $(if($results.MicaForEveryone){'Green'}else{'Red'})
    Write-Host "  - TranslucentTB:      $(if($results.TranslucentTB){'[OK] Removed'}else{'[FAIL] Failed'})" -ForegroundColor $(if($results.TranslucentTB){'Green'}else{'Red'})
    Write-Host "  - ExplorerBlurMica:   $(if($results.ExplorerBlurMica){'[OK] Removed'}else{'[FAIL] Failed'})" -ForegroundColor $(if($results.ExplorerBlurMica){'Green'}else{'Red'})

    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count

    if ($successCount -eq 3) {
        Write-Host "`n[SUCCESS] All components removed successfully!" -ForegroundColor Green
        Write-Host "Your Windows desktop has been restored to default appearance." -ForegroundColor Gray
    } else {
        Write-Host "`n[WARNING] Uninstallation completed with some failures." -ForegroundColor Yellow
    }
}

# Main execution logic
if ($MyInvocation.InvocationName -ne '.') {
    # Script is being run directly (not dot-sourced)

    if ($Help) {
        # Display help information
        $helpText = @(
            '================================================================='
            ''
            '        Windows 11 Glass Desktop Automation Script'
            ''
            '================================================================='
            ''
            'Usage:'
            '  .\Install-GlassDesktop.ps1            # Install (default)'
            '  .\Install-GlassDesktop.ps1 -Help      # Show this help'
            '  .\Install-GlassDesktop.ps1 -Uninstall # Remove all components'
            ''
            'What this script does:'
            '  - Installs MicaForEveryone for Acrylic window effects'
            '  - Installs TranslucentTB for Acrylic taskbar'
            '  - Installs ExplorerBlurMica for Acrylic File Explorer'
            '  - Configures all tools with Acrylic visual effects'
            '  - Provides easy uninstall function'
            ''
            'Requirements:'
            '  - Windows 10 (build 18362+) or Windows 11'
            '  - Administrator privileges'
            '  - Internet connection'
            ''
            'Advanced Usage:'
            '  You can also dot-source this script and call functions directly:'
            '  . .\Install-GlassDesktop.ps1'
            '  Install-GlassDesktop'
            '  Uninstall-GlassDesktop'
            ''
        )
        Write-Host ($helpText -join "`n") -ForegroundColor Cyan
    }
    elseif ($Uninstall) {
        # Run uninstallation
        Uninstall-GlassDesktop
    }
    else {
        # Default: Run installation
        Install-GlassDesktop
    }
}
