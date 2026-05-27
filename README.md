# CyberArk Certificate Manager Offline Installation Files

This repository provides the offline installation package and prerequisite files needed before installing CyberArk Certificate Manager Self-Hosted Edition on a Windows Server 2022 or Windows Server 2025 machine.

Use this repository when the target server has limited or no internet access and the required installation files need to be downloaded ahead of time, copied to the server, and installed locally.

## Prerequisite Documentation

Before installing CyberArk Certificate Manager Self-Hosted Edition, review the official documentation and confirm that the target machine meets the required operating system, hardware, software, and platform requirements.

- [CyberArk Certificate Manager documentation](https://docs.venafi.com/)
- [System requirements for Trust Protection Foundation components](https://docs.venafi.com/Docs/current/TopNav/Content/Install/r-install-SysReq-ALLVenProducts.php)

## Downloads

Download the files directly from the latest release assets:

| File | Description |
| --- | --- |
| [`MicrosoftEdgeWebView2RuntimeInstallerX64.exe`](https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/MicrosoftEdgeWebView2RuntimeInstallerX64.exe) | Microsoft Edge WebView2 Runtime offline installer |
| [`MicrosoftEdgeWebview2Setup.exe`](https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/MicrosoftEdgeWebview2Setup.exe) | Microsoft Edge WebView2 setup bootstrapper |
| [`rewrite_amd64_en-US.msi`](https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/rewrite_amd64_en-US.msi) | Microsoft IIS URL Rewrite module |
| [`BaseConfiguration.exe`](https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/BaseConfiguration.exe) | Base configuration utility |
| [`Venafi-PreReq-Check.ps1`](https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/Venafi-PreReq-Check.ps1) | Prerequisite validation script |
| [`Trust.Protection.Platform_25.3_1778857190122.zip`](https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/Trust.Protection.Platform_25.3_1778857190122.zip) | CyberArk Certificate Manager / Trust Protection Platform 25.3 installation package |

## Suggested Offline Installation Flow

1. Download all release assets from a machine with internet access.
2. Copy the files to the target Windows Server 2022 or Windows Server 2025 machine.
3. Install the required prerequisites.
4. Run the prerequisite validation script.
5. Start the CyberArk Certificate Manager Self-Hosted Edition installation from the TPP ZIP package.

## PowerShell Example

The following example creates `C:\Install\TPP-25.3`, downloads the required files, extracts the TPP installation ZIP, installs prerequisites, and runs the prerequisite validation script.

```powershell
$InstallPath = "C:\Install\TPP-25.3"
$ExtractPath = Join-Path $InstallPath "Extracted"

New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null

$Downloads = @{
    "MicrosoftEdgeWebView2RuntimeInstallerX64.exe" = "https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
    "MicrosoftEdgeWebview2Setup.exe" = "https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/MicrosoftEdgeWebview2Setup.exe"
    "rewrite_amd64_en-US.msi" = "https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/rewrite_amd64_en-US.msi"
    "BaseConfiguration.exe" = "https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/BaseConfiguration.exe"
    "Venafi-PreReq-Check.ps1" = "https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/Venafi-PreReq-Check.ps1"
    "Trust.Protection.Platform_25.3_1778857190122.zip" = "https://github.com/tall27/tpp-25-3-download/releases/download/v25.3/Trust.Protection.Platform_25.3_1778857190122.zip"
}

foreach ($File in $Downloads.GetEnumerator()) {
    $Destination = Join-Path $InstallPath $File.Key
    Write-Host "Downloading $($File.Key)..."
    Invoke-WebRequest -Uri $File.Value -OutFile $Destination
}

Set-Location $InstallPath

Write-Host "Extracting CyberArk Certificate Manager installation package..."
Expand-Archive -Path ".\Trust.Protection.Platform_25.3_1778857190122.zip" -DestinationPath $ExtractPath -Force

Write-Host "Installing Microsoft Edge WebView2 Runtime..."
Start-Process -FilePath ".\MicrosoftEdgeWebView2RuntimeInstallerX64.exe" -ArgumentList "/silent", "/install" -Wait

Write-Host "Installing IIS URL Rewrite module..."
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", ".\rewrite_amd64_en-US.msi", "/qn", "/norestart" -Wait

Write-Host "Running CyberArk Certificate Manager prerequisite check..."
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& ".\Venafi-PreReq-Check.ps1"

Write-Host "Prerequisite installation and validation steps completed."
Write-Host "You can now run the CyberArk Certificate Manager installer from $ExtractPath."
```

## Notes

- Run the PowerShell session as Administrator.
- Review your CyberArk Certificate Manager installation documentation before starting the TPP installer.
- The prerequisite script validates readiness; it does not replace the official product installation guide.
- If the target server is fully offline, download these files from another machine first and transfer them using your approved internal process.
