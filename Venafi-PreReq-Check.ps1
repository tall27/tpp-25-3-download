<#
//
// Copyright (c) 2025 Venafi, Inc.  All rights reserved.
//
// Venafi, Inc. hereby grants you limited permission to use and modify this software during only the period in which you
// hold a valid license from Venafi, Inc. to use the Venafi Trust Protection Platform, on condition that (a) such use or
// modification is for your sole internal business use, and (b) you hereby assign to Venafi, Inc. all rights in any
// modifications of this software that you may create (and agree to take all such actions as may be necessary and desirable
// to perfect such assignment), except that you (i) shall retain any Background Intellectual Property that you may
// incorporate into any such modifications and (ii) hereby agree to grant Venafi, Inc., a perpetual, worldwide, royalty
// free license to use, copy, modify, reproduce, distribute such modifications, including, without limitation, any
// Background Intellectual Property incorporated into such modifications. For the purposes of this paragraph, “Background
// Intellectual Property” means any intellectual property developed by you independently of this software (or any
// modifications thereof). You may not copy, reproduce or distribute this software (or any modifications thereof) without
// the prior written consent of Venafi, Inc. (which may be by email). Without limiting the foregoing, the above copyright
// notice, this paragraph and the following paragraph must appear in all copies, modifications, reproductions, and
// distributions of this software.
// IN NO EVENT SHALL VENAFI, INC., ITS DIRECTORS, OFFICERS, EMPLOYEES, AGENTS, OR AFFILIATES BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS
// SOFTWARE OR ITS DOCUMENTATION, IF ANY, EVEN IF VENAFI, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
// VENAFI, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF
// MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. THIS SOFTWARE, ALONG WITH ITS DOCUMENTATION, IF ANY, IS PROVIDED
// "AS IS". VENAFI, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, OR UPDATES FOR THE SOFTWARE OR ITS
// DOCUMENTATION, IF ANY.
//
Author: Chris Lyttle (chris.lyttle@cyberark.com) and Nelson Buya (nelson.buya@cyberark.com)
Version 4.1
#>

<#
.SYNOPSIS
  Script to check if the Venafi Trust Protection Platform Prerequisites are installed
.DESCRIPTION
  This script is designed to check for the following prerequisites before installing
  the Venafi Trust Protection Platform;
  a) Microsoft Windows Server 2016, 2019, 2022, or 2025
  b) .NET Framework 4.8 or 4.8.1 (Required with and after TPP version 23.3)
  c) Universal C Runtime Update only on 2012R2 (Upgrades only)
  d) TPP Required Server Roles & Features
  e) Microsoft URL Rewrite Module 2.1
  f) Powershell version is <= 5.1
  g) Connect to SQL server with DBO Account to gather information about Venafi Trust Protection Platform DB, roles and availability groups
  h) If server requires a reboot
  i) If DB Owner and Operational accounts are configured for Log on as a Service or Batch Job and Operational account is a local administrator
  j) Visual Studio C++ Redistributable 2015-2022 (x64 & x86) - Required for TPP version 24.1 or later
  k) Microsoft Edge WebView2 Runtime - Required for TPP version 25.3 or later

  NOTE: The 'Version' parameter is now required to run the script. Example '-Version 25.3'

  There is an optional parameter 'Install' that will install the following (if not already present);
  a) All missing Roles and Features
  b) If .NET is an insufficient version, .NET Framework 4.8. Offline installs will look for the files in the current directory location.
  c) Visual Studio C++ Redistributable 2015-2022 (x64 & x86). Offline installs will look for the files in the current directory location.
  d) URL Rewrite Module for IIS v2.1. Offline installs will look for the files in the current directory location.
  e) Microsoft Edge WebView2 Runtime. Offline installs will look for the files in the current directory location.
  f) If used with the Rights parameter set, installs 'RSAT-AD-PowerShell' to check for local administrators.

  There is an optional parameter 'RemoveDefaultIIS' that will check for and remove the IIS 'Default Web Site'

  Checking the SQL connection:
  This uses the PS module 'dbatools' which will be downloaded from the PS Gallery if not installed.
  If there is no internet connection to the PS Gallery, the script will stop. To avoid this, preinstall DBA Tools manually.
  a) When not using any of the SQL or SQLOnly parameter set, the script will not check the SQL server connection.
  b) The parameter 'SQLOnly' only runs SQL checks and no other prerequisite tests.
  c) Alternatively, using any other 'SQL' parameter set parameters adds SQL Checks to the other checks.
  d) SQL Checks do _NOT_ require the sysadmin role on SQL, only the db_owner role. The script will automatically check the connection and SQL credential.
  e) The parameters 'SQLFQDN' (SQL server name) and 'Database' (database name) are mandatory if using the SQL or SQLOnly parameter sets.
  f) The SQL authentication account must use the 'username@domain.com' format for Winauth or 'username' format for SQLauth.
  g) The SQL port and/or instance information will be automatically discovered by scanning the SQL server in the same way that SSMS does.

  Checking local system rights:
  This uses the PS Module 'UserRights' which must exist in the same directory as this script (UserRights.psm1).
  There must be two account names supplied as an array. For example -Accounts 'DBOAcct','OpAcct'
  a) The parameter 'Accounts' is mandatory for the Rights parameter set.
  b) Checks for the ActiveDirectory module and if used with the 'Install' parameter will install 'RSAT-AD-PowerShell'.
  c) Checks the local 'Administrators' group and AD for each account supplied with the 'Accounts' parameter.
  d) Prompts as to which of the two accounts is the DB Owner or Operational account.
  e) Matches each account supplied with the 'Accounts' parameter to 'Log on as a Service' or 'Log on as a Batch Job'.
  f) When used with optional parameter 'AddAccounts', adds each account to either 'Log on as a Service ' or 'Log on as a Batch Job'.
  See the Windows permissions for database service accounts(https://docs.venafi.com/Docs/current/TopNav/Content/Install/r-install-windows-auth-requirements-tpp.php)
  page for details on these accounts.

.PARAMETER SQLOnly
  (Required) SQLOnly parameter set
  Only run SQL checks. Installs DBA tools if missing.
.PARAMETER SQLFQDN
  (Required) SQL & SQLOnly parameter set
  FQDN of the SQL server.
.PARAMETER Database
  (Required) SQL & SQLOnly parameter set
  Database name on the SQL server.
.PARAMETER Install
  (Optional) If feature is not installed, install it and all applicable management tools.
  Will also download & install items if missing. Also installs AD tools for Rights parameter set.
.PARAMETER NonIIS
  (Optional) Only install non-IIS features required by the Venafi Trust Protection Platform installer. Allows for a box without IIS.
  Can be combined with the install switch. If used 'Default Web Site' is not removed.
.PARAMETER Accounts
  (Required) Rights parameter set
  Name(s) of accounts to check for 'Log on as a Service ' and 'Log on as a Batch Job'.
  This must be two accounts (e.g. 'DBOAcct','OpAcct') and can be 'Accountname' or 'DOMAIN\AccountName' or 'AccountName@domain.com'.
  The domain will be stripped by the script.
.PARAMETER AddAccounts
  (Optional) Rights parameter set
  Adds each of the above accounts to 'Log on as a Service ' and 'Log on as a Batch Job'.
  Will prompt as to if the account is DB Owner, or Operational Account. Adds Operational to local Administrators if missing.
.PARAMETER Version
  (Required) The version number of TPP that is to be installed. Used for checking packages and .NET Framework version.
.PARAMETER RemoveDefaultIIS
  (Optional) Remove IIS "Default Web Site" as recommended by Venafi best practice.
  Can be combined with the install switch.

.EXAMPLE
  PS C:> .\Venafi-PreReq-Check.ps1 -Version 25.3
  Checking WIN-VM632JL1TRV for 64-bit PowerShell
  You are running 64-bit PowerShell

  Checking WIN-VM632JL1TRV for Server OS version
  Microsoft Windows Server 2019 is supported

  Checking WIN-VM632JL1TRV for Universal C Runtime Update
  Universal C Runtime Update not needed on 2016, 2019, 2022 and 2025

  Checking WIN-VM632JL1TRV for Microsoft Edge WebView2.
  Microsoft Edge WebView2 Runtime not detected on WIN-VM632JL1TRV

  Checking All Roles Installed
  Checking WIN-VM632JL1TRV for required Roles and Features
  Feature .NET Framework 4.7 is installed on server WIN-VM632JL1TRV
  Feature .NET Framework 4.7 Features is installed on server WIN-VM632JL1TRV
  ...
  Web Server is not installed on server WIN-VM632JL1TRV, rerun with install switch
  Web Server (IIS) is not installed on server WIN-VM632JL1TRV, rerun with install switch

  Checking WIN-VM632JL1TRV for ReWrite Module
  WARNING: No IIS Installed, unable to check or install Rewrite module.

  Checking WIN-VM632JL1TRV for Default IIS Site
  WARNING: No IIS Installed, unable to check or remove Default Web Site

  Checking WIN-VM632JL1TRV for Visual Studio C++ Redistributables
  Visual Studio C++ Redistributable x86 and x64 are installed on WIN-VM632JL1TRV

  Checking WIN-VM632JL1TRV for required .NET Frameworks
  You have .NET Framework version 4.8 Installed on Microsoft Windows Server 2019 Datacenter
  You have the correct .NET Framework to install the Trust Protection Platform

  Checking to see if a reboot is required
  Reboot check on WIN-VM632JL1TRV found reboot is not needed
  Successfully removed PowerShell modules
.EXAMPLE
  PS C:> .\Venafi-PreReq-Check.ps1 -Version 25.3 -SQLOnly -SQLFQDN 'WIN-VM632JL1TRV.domain.com' -Database 'TrustForce'
  NuGet Installed
  Install DBA Tools
  Checking SQL requires installing the DBA Tools package, enter Yes to agree or no to abort installation
  [Y] Yes - Agree  [N] No - Abort  [?] Help (default is "Y"):
  Installing DBA Tools modules

  Select SQL Server username type
  Enter SQL Server username choice
  [W] Windows (Domain\user)  [S] SQL Server Account  [?] Help (default is "W"):
  Using Windows account venafi-sqlown@domain.com

  ==========================SQL Server Information=================================
  SQL Server FQDN: WIN-VM632JL1TRV.domain.com:51309
  SQL Instance: WIN-VM632JL1TRV\SQLEXPRESS
  SQL Port: 51309
  SQL Version: SQL 2019
  Edition: Express Edition (64-bit)
  SQL Product Level: RTM
  SQL Server OS: Windows Server 2019 Standard
  SQL Server Processors: 4
  SQL Server Memory: 16.00 GB
  SQL Server Availability Group Databases: Availability Group not configured
  SQL Server Availability Group Listeners: No Availability Group Listeners
  =================================================================================

  =======================SQL Database User Information=============================
  UserName       :  DOMAIN\venafi-sqlops
  Login          :  DOMAIN\venafi-sqlops
  Database Name  :  TrustForce
  Server Role    :  db_datareader

  UserName       :  DOMAIN\venafi-sqlops
  Login          :  DOMAIN\venafi-sqlops
  Database Name  :  TrustForce
  Server Role    :  db_datawriter

  UserName       :  dbo
  Login          :  DOMAIN\venafi-sqlown
  Database Name  :  TrustForce
  Server Role    :  db_owner
  =================================================================================
  Successfully removed PowerShell modules
.EXAMPLE
  PS C:\p> .\Venafi-PreReq-Check.ps1 -Version 25.3 -Accounts 'venafi-sqlown','venafi-sqlops'
  Checking WIN-VM632JL1TRV for 64-bit PowerShell
  You are running 64-bit PowerShell

  Checking WIN-VM632JL1TRV for Server OS version
  Microsoft Windows Server 2019 is supported

  Checking WIN-VM632JL1TRV for Universal C Runtime Update
  Universal C Runtime Update not needed on 2016, 2019, 2022 and 2025

  Checking WIN-VM632JL1TRV for Microsoft Edge WebView2.
  Microsoft Edge WebView2 Runtime is installed on WIN-VM632JL1TRV

  Checking All Roles Installed
  Checking WIN-VM632JL1TRV for required Roles and Features
  Feature .NET Extensibility 4.7 is installed on server WIN-VM632JL1TRV
  Feature .NET Framework 4.7 is installed on server WIN-VM632JL1TRV
  ...
  Feature Web Server is installed on server WIN-VM632JL1TRV
  Feature Web Server (IIS) is installed on server WIN-VM632JL1TRV

  Checking WIN-VM632JL1TRV for ReWrite Module
  ReWrite module is installed

  Checking WIN-VM632JL1TRV for Default IIS Site
  Default Web Site is not present

  Checking WIN-VM632JL1TRV for Visual Studio C++ Redistributables
  Visual Studio C++ Redistributable x86 and x64 are installed on WIN-VM632JL1TRV

  Checking WIN-VM632JL1TRV for required .NET Frameworks
  You have .NET Framework version 4.8 Installed on Microsoft Windows Server 2019 Datacenter
  You have the correct .NET Framework to install the Trust Protection Platform

  Checking to see if a reboot is required
  Reboot check on WIN-VM632JL1TRV found reboot is not needed

  Select if Accounts are Log On as a Service/Batch Job
  Is the venafi-sqlown account the DB Owner, or Operational Account
  [D] DB Owner Account  [O] Operational Account  [?] Help (default is "D"):
  Checking venafi-sqlown is the DB Owner Account
  Checking venafi-sqlops is the Operational Account
  venafi-sqlown is the DB Owner Account and has correct Log on as a Service rights (Non-Administrator)
  venafi-sqlops is the Operational Account and has correct Log on as a Service rights, Batch Job rights and is a Local Administrator
  Successfully removed PowerShell modules
#>
#########################################################################################
# Parameters for script
#########################################################################################
[CmdletBinding(DefaultParameterSetName = "IISCheck")]
  param(
    [Parameter(Mandatory, HelpMessage = "TPP Major and Minor Version, eg. 25.3")]
    [version]$Version,
    [Parameter(Mandatory, HelpMessage = "Only run SQL check", ParameterSetName = "SQLOnly")]
    [switch]$SQLOnly,
    [Parameter(Mandatory, HelpMessage = "Computer name of SQL server", ParameterSetName = "SQL")]
    [Parameter(Mandatory, HelpMessage = "Computer name of SQL server", ParameterSetName = "SQLOnly")]
    [string]$SQLFQDN,
    [Parameter(Mandatory, HelpMessage = "Database name on SQL server", ParameterSetName = "SQL")]
    [Parameter(Mandatory, HelpMessage = "Database name on SQL server", ParameterSetName = "SQLOnly")]
    [string]$Database,
    [Parameter(HelpMessage = "Install missing packages", ParameterSetName = "IISCheck")]
    [Parameter(HelpMessage = "Install missing packages", ParameterSetName = "NoIIS")]
    [Parameter(HelpMessage = "Install missing packages", ParameterSetName = "SQL")]
    [Parameter(HelpMessage = "Install missing packages", ParameterSetName = "Rights")]
    [switch]$Install,
    [Parameter(HelpMessage = "Non-IIS Server Role", ParameterSetName = "NoIIS")]
    [Parameter(HelpMessage = "Non-IIS Server Role", ParameterSetName = "SQL")]
    [Parameter(HelpMessage = "Non-IIS Server Role", ParameterSetName = "Rights")]
    [switch]$NonIIS,
    [Parameter(Mandatory, HelpMessage = "Name of accounts to check rights", ParameterSetName = "Rights")]
    [string[]]$Accounts,
    [Parameter(HelpMessage = "Add above accounts to security rights", ParameterSetName = "Rights")]
    [switch]$AddAccounts,
    [Parameter(HelpMessage = "Remove Default Web Site", ParameterSetName = "IISCheck")]
    [Parameter(HelpMessage = "Remove Default Web Site", ParameterSetName = "SQL")]
    [Parameter(HelpMessage = "Remove Default Web Site", ParameterSetName = "Rights")]
    [switch]$RemoveDefaultIIS
  )

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#########################################################################################
# 		CHECK POWERSHELL SESSION
#########################################################################################
#These two handy statements check if using PS5.1 and running in an Administrative session
#requires -version 5.1
#requires -RunAsAdministrator
function Get-PS64 {
  #Check if running 64-bit PowerShell
  Write-Host "Checking $($env:COMPUTERNAME) for 64-bit PowerShell" -ForegroundColor Cyan
		If ( [IntPtr]::size * 8 -eq 64 ) {
    Write-Host "You are running 64-bit PowerShell `n" -ForegroundColor Green
		}
  else {
    Write-Error "Please run 64-bit Powershell `n"  -Category 'NotImplemented' -ErrorAction Stop
		}
  }

#########################################################################################
# Functions used for script
#########################################################################################
function Get-OSSupported {
  [CmdletBinding()]
    Param(
      [CmdletBinding()]
      [Parameter(ValueFromPipeline=$true)]
      [string]$ServerOSVersion
    )

  Process {
    if (!$ServerOSVersion) {
      $script:ServerOS = Get-CimInstance -ClassName Win32_OperatingSystem -Filter "caption like '%Windows Server%'"
    } else {
      $script:ServerOS = New-Object psobject
      Add-Member -InputObject $script:ServerOS -MemberType NoteProperty -Name "Caption" -Value $ServerOSVersion
      Add-Member -InputObject $script:ServerOS -MemberType NoteProperty -Name "CSName" -Value $env:COMPUTERNAME
    }
    $script:ComputerName = $script:ServerOS.CSName
    $Caption = $script:ServerOS.Caption
		Write-Host "Checking $($script:ComputerName) for Server OS version" -ForegroundColor Cyan
		if ($Caption -match '2019') {
      Write-Host "Microsoft Windows Server 2019 is supported `n" -ForegroundColor Green
      $script:OSVersion = "2019"
		}
    elseif (($Caption -match "2012 R2") -and ([version]$Version -le [version]"24.1")) {
      Write-Host "Microsoft Windows Server 2012 R2 is supported for upgrades only`n" -ForegroundColor Green
      $script:OSVersion = "2012R2"
		}
    elseif ($Caption -match "2016") {
      Write-Host "Microsoft Windows Server 2016 is supported `n" -ForegroundColor Green
      $script:OSVersion = "2016"
    }
    elseif ($Caption -match "2022") {
      Write-Host "Microsoft Windows Server 2022 is supported `n" -ForegroundColor Green
      $script:OSVersion = "2022"
    }
    elseif ($Caption -match "2025") {
      Write-Host "Microsoft Windows Server 2025 is supported `n" -ForegroundColor Green
      $script:OSVersion = "2025"
		}
    else {
      Write-Error "Unsupported server. This script must be run on a supported server `n" -ErrorAction Stop
		}
  }
}
function Get-Features {
  [CmdletBinding()]
  Param (
    [Parameter(Position = 0, HelpMessage = "Non-IIS Server Role")]
    [switch] $NonIIS,
    [Parameter(Position = 1, HelpMessage = "Install IIS Server Features")]
    [switch] $Install
  )

  Begin {
    Import-Module ServerManager
    $InstallResult = @()
    $InstallObj = @()
    if ($NonIIS) {
      Write-Host "Checking Non-IIS Roles Installed" -ForegroundColor Magenta
      $RequiredFeature = @(
        'NET-Framework-45-Features', 'NET-Framework-45-Core', 'NET-WCF-Services45', 'NET-WCF-TCP-PortSharing45'
      )
    }
    else {
      if ($script:OSVersion -eq "2012R2") {
        Write-Host "Checking All Roles Installed" -ForegroundColor Magenta
        $RequiredFeature = @(
          'Web-Server', 'Web-WebServer', 'Web-Common-Http', 'Web-Default-Doc', 'Web-Dir-Browsing', 'Web-Http-Errors',
          'Web-Static-Content', 'Web-Health', 'Web-Http-Logging', 'Web-Log-Libraries', 'Web-Request-Monitor',
          'Web-Http-Tracing', 'Web-Performance', 'Web-Stat-Compression', 'Web-Security', 'Web-Filtering', 'Web-App-Dev',
          'Web-Net-Ext45', 'Web-ASP', 'Web-Asp-Net45', 'Web-ISAPI-Ext', 'Web-ISAPI-Filter',
          'Web-Mgmt-Tools', 'Web-Mgmt-Console', 'NET-Framework-45-Features', 'NET-Framework-45-Core',
          'NET-Framework-45-ASPNET', 'NET-WCF-Services45', 'NET-WCF-TCP-PortSharing45'
        )
      }
      else {
        Write-Host "Checking All Roles Installed" -ForegroundColor Magenta
        $RequiredFeature = @(
          'Web-Server', 'Web-WebServer', 'Web-Common-Http', 'Web-Default-Doc', 'Web-Dir-Browsing', 'Web-Http-Errors',
          'Web-Static-Content', 'Web-Health', 'Web-Http-Logging', 'Web-Log-Libraries', 'Web-Request-Monitor',
          'Web-Http-Tracing', 'Web-Performance', 'Web-Stat-Compression', 'Web-Security', 'Web-Filtering', 'Web-App-Dev',
          'Web-Net-Ext45', 'Web-Asp-Net45', 'Web-ISAPI-Ext', 'Web-ISAPI-Filter',
          'Web-Mgmt-Tools', 'Web-Mgmt-Console', 'NET-Framework-45-Features', 'NET-Framework-45-Core',
          'NET-Framework-45-ASPNET', 'NET-WCF-Services45', 'NET-WCF-TCP-PortSharing45'
        )
      }
    }
    if (!$script:connectcheck) {
      $global:ProgressPreference = "SilentlyContinue"
      $script:connectcheck = (Test-NetConnection -ComputerName "download.microsoft.com").PingSucceeded
      $global:ProgressPreference = "Continue"
    }
  }

  Process {
    try {
      Write-Host "Checking $($script:ComputerName) for required Roles and Features" -ForegroundColor Cyan
      $Caption = $script:ServerOS.Caption
      if (($Install) -and ($Caption -notmatch "2012 R2")) {
        # check registry to make sure Windows update isn't disabled (not available in Windows 2012 R2)
        $AUProperties = Get-RegistryValue -RegKey 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        $WUProperties = Get-RegistryValue -RegKey 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
        if ($AUProperties.NoAutoUpdate) {
          $AUEnabled = $AUProperties.NoAutoUpdate
        }
        else {
          $AUEnabled = 0
        }
        switch ($AUEnabled) {
          1 { $AUEnabled = 'Disabled' }
          0 { $AUEnabled = 'Enabled' }
        }
        Write-Host "Automatic Update - $($AUEnabled)" -ForegroundColor Green
        if ($AUProperties.UseWUServer) {
          $WUEnabled = $AUProperties.UseWUServer
        }
        else {
          $WUEnabled = 0
        }
        switch ($WUEnabled) {
          1 { $WUEnabled = 'WSUS' }
          0 { $WUEnabled = 'Windows Update' }
        }
        Write-Host "WSUS Server Configured to - $($WUEnabled)" -ForegroundColor Green
        if ($WUProperties.DisableWindowsUpdateAccess) {
          $UAEnabled = $WUProperties.DisableWindowsUpdateAccess
        }
        else {
          $UAEnabled = 0
        }
        switch ($UAEnabled) {
          1 { $UAEnabled = 'Disabled' }
          0 { $UAEnabled = 'Enabled' }
        }
        Write-Host "Access to Windows Update - $($UAEnabled)" -ForegroundColor Green
        if ($script:connectcheck -eq $true) {
          Write-Host "Microsoft connection verified" -ForegroundColor Yellow
          if (($WUEnabled -eq 'Windows Update') -and ($AUEnabled -eq 'Enabled') -and ($UAEnabled -eq 'Enabled')) {
            Write-Host "This will take a while if downloading the packages from Windows Update" -ForegroundColor Yellow
          }
          else {
            Write-Host "This host is set to use WSUS, installing packages may fail" -ForegroundColor Yellow
          }
        }
        else {
          Write-Host "No external connection to Microsoft, 'Removed' packages will NOT be installed." -ForegroundColor Red
        }
      }
      $Checked = Get-WindowsFeature -Name $RequiredFeature
      foreach ($Check in $Checked) {
        $CheckObj = [PSCustomObject] @{
          Name = $Check.Name
          DisplayName = $Check.DisplayName
          InstallState = $Check.InstallState
        }
        $InstallResult += $CheckObj
      }
      $InstallResult = ($InstallResult | Sort-Object -Property InstallState -Descending)

      # Run Feature checks
      foreach ($Feature in $InstallResult) {
        $FeatureName = $Feature.Name
        $CheckObj = [PSCustomObject] @{
          Name = $FeatureName
          DisplayName = $Feature.DisplayName
          InstallState = $null
        }
        if (($Install) -and ($script:connectcheck -eq $true) -and ($Feature.InstallState -ne "Installed")) {
          $Installed = Install-WindowsFeature $FeatureName -ErrorAction SilentlyContinue
          if ($Installed.Success -eq $true){
            $CheckObj.InstallState = "Installed"
            Write-Verbose "$($Feature.DisplayName) was installed"
          } else {
            $CheckObj.InstallState = $Feature.InstallState
            Write-Verbose "$($Feature.DisplayName) unable to be installed"
          }
        } elseif (($Install) -and ($script:connectcheck -eq $false) -and ($Feature.InstallState -eq "Removed")) {
            $CheckObj.InstallState = $Feature.InstallState
            Write-Warning "$($Feature.DisplayName) unable to be installed, no connection"
        } elseif (($Install) -and ($script:connectcheck -eq $false) -and ($Feature.InstallState -eq "Available")) {
          $Installed = Install-WindowsFeature $FeatureName -ErrorAction SilentlyContinue
          if ($Installed.Success -eq $true){
            $CheckObj.InstallState = "Installed"
            Write-Verbose "$($Feature.DisplayName) was installed"
          } else {
            $CheckObj.InstallState = $Feature.InstallState
            Write-Verbose "$($Feature.DisplayName) unable to be installed"
          }
        } else {
            $CheckObj.InstallState = $Feature.InstallState
        }
        $InstallObj += $CheckObj
      }

      $FeatureStatus = ($InstallObj | Sort-Object -Property @{Expression = "InstallState"; Descending = $true },
      @{Expression = "DisplayName"; Descending = $false })

    }
    catch {
      $PSCmdlet.ThrowTerminatingError($_)
    }
  }

  End {
    foreach ($Feature in $FeatureStatus) {
      if ($Feature.InstallState -eq "Installed") {
        Write-Host "Feature $($Feature.DisplayName) is installed on server $($script:ComputerName)" -ForegroundColor Green
      }
      else {
        Write-Host "$($Feature.DisplayName) is not installed on server $($script:ComputerName), rerun with install switch" -ForegroundColor Yellow
      }
    }
    Write-Host ""
    $script:VenafiFeatureCheck = $FeatureStatus | Select-Object "Name", "DisplayName", "InstallState"
  }
}
function Get-Rewrite {
  [CmdletBinding()]
    Param (
      [Parameter()]
      [switch]$Install
    )

  Begin {
    Import-Module ServerManager
    if (Get-Module -ListAvailable | Where-Object {$_.Name -eq 'webadministration'}) {
      Import-Module WebAdministration
      $WebAdminModule = $true
    } else {
      $WebAdminModule = $false
    }
    $Check = @()
    $rewriteurl = 'https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi'
    $testhash = "8F41A67FA49110155969DCCFF265B8623A66448F"
    $msi = 'rewrite_amd64_en-US.msi'
  }

  Process {
    try {
      if ($script:VenafiFeatureCheck | Where-Object { $_.Name -eq 'Web-Server' -and $_.InstallState -eq 'Installed' }) {
        $InstCheck = [PSCustomObject] @{
          Installed = $true
        }
        $Check = $InstCheck
      } elseif ((Get-CimInstance -ClassName Win32_OperatingSystem).caption -match "Server") {
        $Check = [PSCustomObject] @{
          Installed = $false
        }
        $Check.Installed = (Get-WindowsFeature -Name Web-Server).Installed
      } else {
        Write-Error "Not Supported" -ErrorAction Stop
      }
      Write-Host "Checking $($script:ComputerName) for ReWrite Module" -ForegroundColor Cyan
      if (($Check.Installed -eq $true) -and ($WebAdminModule -eq $true) -and (!$NonIIS)) {
        $RWModule = (Get-WebGlobalModule "ReWriteModule" -ErrorAction SilentlyContinue)
        if ($null -ne $RWModule) {
          $RWfile = $RWModule.image | Select-Object -Unique
          $RWdll = ([System.Environment]::ExpandEnvironmentVariables($RWfile)).Replace('\','\\')
          [version]$RWVersion = (Get-CimInstance -ClassName Cim_DataFile -Filter "Name='$RWdll'").Version
        }

        if ([version]$RWVersion -ge [version]"7.1.1980.0") {
          Write-Host "ReWrite module is installed`n" -ForegroundColor Green
        } elseif ($Install) {
          $MsiCheck = Test-Path -Path $msi
          if ((!$script:connectcheck) -and ($MsiCheck -eq $false)) {
            $global:ProgressPreference = "SilentlyContinue"
            $script:connectcheck = (Test-NetConnection -ComputerName "download.microsoft.com").PingSucceeded
            $global:ProgressPreference = "Continue"
          }
          if ($MsiCheck -eq $true) {
            Write-Host "Installing required IIS Rewrite Module 2.1 on $($script:ComputerName)`n" -ForegroundColor Magenta
            $rewritehash = (Get-FileHash $msi -Algorithm SHA1).Hash
            if ($testhash -eq $rewritehash) {
              Start-Process msiexec.exe -ArgumentList "/i $msi /quiet /norestart" -Wait -WorkingDirectory $pwd | Out-Null
              Write-Host "IIS ReWrite Module 2.1 is now installed on $($script:ComputerName)`n" -ForegroundColor Green
            } else {
              Write-Error "File hash is inconsistent! Cannot install."
            }
          } elseif ($script:connectcheck -eq $true) {
            Write-Host "Downloading and Installing IIS ReWrite Module 2.1 on $($script:ComputerName)`n" -ForegroundColor Magenta
            Invoke-WebRequest -Uri $rewriteurl -OutFile $msi
            $rewritehash = (Get-FileHash $msi -Algorithm SHA1).Hash
            if ($testhash -eq $rewritehash) {
              Start-Process msiexec.exe -ArgumentList "/i $msi /quiet /norestart" -Wait -WorkingDirectory $pwd | Out-Null
              Write-Host "IIS ReWrite Module 2.1 is now installed on $($script:ComputerName)`n" -ForegroundColor Green
            } else {
              Write-Error "File hash is inconsistent! Cannot install."
            }
          } else {
            Write-Error "IIS ReWrite Module 2.1 was not installed on server $($script:ComputerName).`n" -ErrorAction Stop
          }
        } else {
          Write-Host "IIS ReWrite Module 2.1 insufficient version or not detected on $($script:ComputerName)`n" -ForegroundColor Yellow
        }
      } elseif (($Check.Installed -eq $false) -or ($WebAdminModule -eq $false)) {
        Write-Warning "No IIS Installed, unable to check or install Rewrite module.`n"
        Write-Host ""
      }
    }
    catch {
      $PSCmdlet.ThrowTerminatingError($_)
    }
  }
  end {}
}
function Get-UCRTUpdate {
  [CmdletBinding()]
    Param ()

  Begin {
    $KBVersion = @()
    if ($script:ServerOS) {
      $Caption = $script:ServerOS.Caption
    } else {
      $Caption = (Get-CimInstance -ClassName Win32_OperatingSystem -Filter "caption like '%Windows Server%'").Caption
    }
  }

  Process {
    Write-Host "Checking $($script:ComputerName) for Universal C Runtime Update" -ForegroundColor Cyan
    if ($Caption -match "2012 R2") {
      $KBdll = ([System.Environment]::ExpandEnvironmentVariables("%SystemRoot%\System32\ucrtbase.dll")).Replace('\','\\')
      $KBVersion = (Get-CimInstance -ClassName Cim_DataFile -Filter "Name='$KBdll'")
      if ([version]$KBVersion.Version -gt [version]"10.0.10240.16389") {
        Write-Host "Universal C Runtime Update is installed `n" -ForegroundColor Green
      } else {
        Write-Warning "Universal C Runtime Update not installed on server $($script:ComputerName)."
        Write-Warning "Windows Update must be run to retrieve Universal C Runtime Update."
        Write-Host ""
      }
    } else {
      Write-Host "Universal C Runtime Update not needed on 2016, 2019, 2022 and 2025 `n" -ForegroundColor Green
    }
  }
}
function Get-IISSites {
  [CmdletBinding()]
    Param (
      [Parameter()]
      [switch]$RemoveDefault
    )

  Begin {
    Import-Module ServerManager
    if (Get-Module -ListAvailable | Where-Object {$_.Name -eq 'iisadministration'}) {
      Import-Module IISAdministration
      $WebAdminModule = "IISAdministration"
    } elseif (Get-Module -ListAvailable | Where-Object {$_.Name -eq 'webadministration'}) {
      Import-Module WebAdministration
      $WebAdminModule = "WebAdministration"
    }
  }

  Process {
    Write-Host "Checking $($script:ComputerName) for Default IIS Site" -ForegroundColor Cyan
    if ($script:VenafiFeatureCheck | Where-Object { $_.Name -eq 'Web-Server' -and $_.InstallState -eq 'Installed' }) {
      $InstCheck = [PSCustomObject] @{
        ComputerName = $($script:ComputerName)
        Installed = $true
      }
      $IISCheck = $InstCheck
    } elseif ((Get-CimInstance -ClassName Win32_OperatingSystem).caption -match "Server") {
      $IISCheck = [PSCustomObject] @{
        ComputerName = $($script:ComputerName)
        Installed = $false
      }
      $IISCheck.installed = (Get-WindowsFeature -Name Web-Server).Installed
    } else {
      Write-Error "Not Supported" -ErrorAction Stop
    }

    if ($IISCheck.Installed -eq $true) {
      if ($WebAdminModule -eq "IISAdministration") {
        $GetSite = Get-IISSite -ErrorAction SilentlyContinue
        if ($GetSite.Name -eq 'Default Web Site') {
          Stop-IISSite -Name 'Default Web Site' -Confirm:$false
        }
      } elseif ($WebAdminModule -eq "WebAdministration") {
        $GetSite = Get-WebSite -ErrorAction SilentlyContinue
        if ($GetSite.Name -eq 'Default Web Site') {
          Stop-WebSite -Name 'Default Web Site' -ErrorAction SilentlyContinue
        }
      } else {
        Write-Error "No administration tools installed!" -ErrorAction Stop
      }
      if (($RemoveDefault) -and ($GetSite.Name -contains "Default Web Site") -and ($WebAdminModule -eq "IISAdministration") -and (!$NonIIS)) {
        Remove-IISSite -Name 'Default Web Site' -Confirm:$false
        Write-Host "Default Web Site was removed`n" -ForegroundColor Green
      } elseif (($RemoveDefault) -and ($GetSite.Name -contains "Default Web Site") -and ($WebAdminModule -eq "WebAdministration") -and (!$NonIIS)) {
        Remove-WebSite -Name 'Default Web Site' -Confirm:$false
        Write-Host "Default Web Site was removed`n" -ForegroundColor Green
      } elseif (($GetSite.Name  -contains "Default Web Site") -and (!$NonIIS)) {
        Write-Warning "Default Web Site Present, removal recommended"
        Write-Host ""
      } elseif ($NonIIS) {
        Write-Warning "Non IIS install requested but IIS is installed!"
        Write-Host ""
      } else {
        Write-Host "Default Web Site is not present`n" -ForegroundColor Green
      }
    } else {
      Write-Warning "No IIS Installed, unable to check or remove Default Web Site"
      Write-Host ""
    }
  }
}
function Get-dotNET {
  [CmdletBinding()]
    Param (
      [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
      [switch]$Install
    )

  Begin {
    $ndp48Offline = 'ndp48-x86-x64-allos-enu.exe'
    $ndp48Web = 'ndp48-web.exe'
    $ndp48WebUrl = 'https://go.microsoft.com/fwlink/?LinkId=2085155'
    $testhash = '4181398AA1FD5190155AC3A388434E5F7EA0B667','CA87B70910F131B625D140FFBFD1C232EA27AB71'
    $dotNet4Registry = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'
  }

  Process {
    try {
      Write-Host "Checking $($script:ComputerName) for required .NET Frameworks" -ForegroundColor Cyan
      $OS = $script:ServerOS.Caption
      Get-RegistryValue -RegKey $dotNet4Registry -ValueName 'Release' | Out-Null
        foreach ($item in $script:RegKeys) {
          $Release = $item.Value
          Switch ($Release) {
            378389 { [version]$NetFrameworkVersion = "4.5" }
            378675 { [version]$NetFrameworkVersion = "4.5.1" }
            378758 { [version]$NetFrameworkVersion = "4.5.1" }
            379893 { [version]$NetFrameworkVersion = "4.5.2" }
            393295 { [version]$NetFrameworkVersion = "4.6" }
            393297 { [version]$NetFrameworkVersion = "4.6" }
            394254 { [version]$NetFrameworkVersion = "4.6.1" }
            394271 { [version]$NetFrameworkVersion = "4.6.1" }
            394802 { [version]$NetFrameworkVersion = "4.6.2" }
            394806 { [version]$NetFrameworkVersion = "4.6.2" }
            460798 { [version]$NetFrameworkVersion = "4.7" }
            460805 { [version]$NetFrameworkVersion = "4.7" }
            461308 { [version]$NetFrameworkVersion = "4.7.1" }
            461310 { [version]$NetFrameworkVersion = "4.7.1" }
            461808 { [version]$NetFrameworkVersion = "4.7.2" }
            461814 { [version]$NetFrameworkVersion = "4.7.2" }
            528040 { [version]$NetFrameworkVersion = "4.8" }
            528049 { [version]$NetFrameworkVersion = "4.8" }
            528372 { [version]$NetFrameworkVersion = "4.8" }
            528449 { [version]$NetFrameworkVersion = "4.8" }
            533320 { [version]$NetFrameworkVersion = "4.8.1" }
            533325 { [version]$NetFrameworkVersion = "4.8.1" }
            Default { [version]$NetFrameworkVersion = "1.0.0" }
          }
        }
      Write-Host "You have .NET Framework version $([version]$NetFrameworkVersion) Installed on $($OS)" -ForegroundColor Green
      if ([version]$Version -lt [version]"23.3") {
        Write-Error "Venafi Trust Protection Platform Version $($Version) is no longer officially supported`n" -ErrorAction Stop
      }
      elseif ($NetFrameworkVersion -ge [version]"4.8") {
        Write-Host "You have the correct .NET Framework to install the Trust Protection Platform`n" -ForegroundColor Green
      }
      elseif ((!$Install) -and ([version]$NetFrameworkVersion -lt "4.8")) {
        Write-Error "You do not have the .NET Framework version 4.8 installed, rerun with the install switch" -ErrorAction Continue
      }
      elseif ($Install) {
        $Installed = $false
        $ndp48OffCheck = Test-Path -Path $ndp48Offline
        if ((!$script:connectcheck) -and ($ndp48OffCheck -eq $false)) {
          $global:ProgressPreference = "SilentlyContinue"
          $script:connectcheck = (Test-NetConnection -ComputerName "go.microsoft.com").PingSucceeded
          $global:ProgressPreference = "Continue"
        }
        if ($ndp48OffCheck -eq $true) {
          $ndp48Offhash = (Get-FileHash $ndp48Offline -Algorithm SHA1).Hash
          if ($testhash -contains $ndp48Offhash) {
            Write-Host "Installing .Net Framework version 4.8 Offline runtime on $($script:ComputerName)" -ForegroundColor Magenta
            Start-Process -FilePath $ndp48Offline -ArgumentList "/norestart","/q" -Wait -WorkingDirectory $pwd | Out-Null
            Write-Warning "This installation REQUIRES a reboot."
            Write-Host ".Net Framework version 4.8 Offline runtime is now installed on $($script:ComputerName)`n" -ForegroundColor Green
            $Installed = $true
          } else {
            Write-Error "File hash is inconsistent! Cannot install." -ErrorAction Stop
          }
        } elseif ($script:connectcheck -eq $true) {
          Write-Host "Downloading and Installing .Net Framework version 4.8 Web runtime on $($script:ComputerName)`n" -ForegroundColor Magenta
          Invoke-WebRequest -Uri $ndp48WebUrl -OutFile $ndp48Web
          $ndp48Webhash = (Get-FileHash $ndp48Web -Algorithm SHA1).Hash
          if ($testhash -contains $ndp48Webhash) {
            Start-Process -FilePath $ndp48Web -ArgumentList "/norestart","/q" -Wait -WorkingDirectory $pwd | Out-Null
            Write-Warning "This installation REQUIRES a reboot."
            Write-Host ".Net Framework version 4.8 Web runtime is now installed on $($script:ComputerName)`n" -ForegroundColor Green
            $Installed = $true
          } else {
            Write-Error "File hash is inconsistent! Cannot install." -ErrorAction Stop
          }
        } else {
          Write-Error ".Net Framework version 4.8 was not installed on $($script:ComputerName)`n" -ErrorAction Stop
        }
        if ($Installed -eq $true) {
          $yes = New-Object System.Management.Automation.Host.ChoiceDescription  '&Yes - Agree'
          $no = New-Object System.Management.Automation.Host.ChoiceDescription '&No - Abort'
          $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
          $title = 'Reboot Required'
          $message = "The .Net Framework version 4.8 was installed, enter 'Yes' to reboot or 'No' to continue checks (may cause errors)."
          $Install48 = $host.ui.PromptForChoice($title, $message, $options, 0)
          Switch ($Install48) {
            0 { $InstallReboot = "Yes" }
            1 { $InstallReboot = "No" }
          }
          if ($InstallReboot -eq "Yes") {
            Start-Sleep -Seconds 10 ; Restart-Computer -Force
          }
          else {
            Write-Host "Reboot for .Net Framework version 4.8 installation was aborted on $($script:ComputerName)`n" -ForegroundColor Yellow
          }
        }
      }
      else {
        Write-Host ".Net Framework version 4.8 not detected on $($script:ComputerName)`n" -ForegroundColor Yellow
      }
    } catch {
      $PSCmdlet.ThrowTerminatingError($_)
    }
  }
}
function Get-RegistryValue {
  [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
      [string]$RegKey,
      [Parameter(Mandatory=$false)]
      [string[]]$ValueName
    )

  Begin {
    $Hives = @{
      HKLM = [uint32]2147483650
      HKCR = [uint32]2147483648
      HKCU = [uint32]2147483649
    }
    $parms =  @{
      Namespace ="root\default"
      ClassName = 'StdRegProv'
      Verbose = $false
    }
  }

  Process {
    $Key = ($RegKey -split ":")[1] -replace '^\\'
    [uint32]$Hive = $Hives[ ($RegKey -split ":")[0] ]
    Write-Verbose "Querying $Hive':'$Key"
    $RegTypes = @{
      1 =  @{ method = 'GetStringValue'; result = "sValue" ; type = 'REG_SZ' }
      2 =  @{ method = 'GetExpandedStringValue'; result = "sValue" ; type = 'REG_EXPAND_SZ' }
      3 =  @{ method = 'GetBinaryValue' ; result = 'uValue' ; type = 'REG_BINARY' }
      4 =  @{ method = 'GetDWORDValue'; result = 'uValue' ; type = 'REG_DWORD' }
      7 =  @{ method = 'GetMultiStringValue'; result = 'sValue' ; type = 'REG_MULTI_SZ' }
      11 = @{ method = 'GetQWORDValue'; result = 'uValue' ; type = 'REG_QWORD' }
    }
    $result = (Invoke-CimMethod -MethodName "EnumValues" @parms -Arguments @{ hDefKey = $Hive;sSubKeyName = $Key })
    $resultParms = @()
    foreach ($r in $result) {
      if ($r.sNames.Count -gt 0) {
        0..($r.sNames.Count -1) | ForEach-Object  {
          if ($ValueName -and ($ValueName -notcontains $r.sNames[$PSItem])) {
            $script:NoValue = $true
            return
          }
          $obj = Invoke-CimMethod @parms -MethodName $RegTypes[$r.Types[$PSItem]].method -Arguments @{
            hDefKey = $Hive; sSubKeyName = $key; sValueName = $r.sNames[$PSItem]
          }
          $newresult = [PSCustomObject] @{
            Method = $RegTypes[$r.Types[$PSItem]].method
            Type = $RegTypes[$r.Types[$PSItem]].type
            Key = $r.sNames[$PSItem]
            Value = $obj.($RegTypes[$r.Types[$PSItem]].result)
          }
          $resultParms += $newresult
        }
        if (($NoValue) -and (!$obj)) {
          $newresult = [PSCustomObject] @{
            Method = $null
            Type = $null
            Key = $null
            Value = "Not Present"
          }
          $resultParms += $newresult
        }
    } else {
        $newresult = [PSCustomObject] @{
          Method = $null
          Type = $null
          Key = $null
          Value = "Not Present"
        }
        $resultParms += $newresult
      }
    }
  }

  End {
    $script:RegKeys = $resultParms | Select-Object "Method", "Type", "Key", "Value"
    Write-Output $script:RegKeys
  }
}
function Get-PendingReboot {
  [CmdletBinding()]
    Param (
      [Parameter(ValueFromPipeline=$true)]
      [string]$ComputerName = $env:COMPUTERNAME
  )

  Begin {
    $CBSRebootPendingKey = 'HKLM:Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
    $CBSRebootInProgressKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress'
    $CBSPackagesPendingKey = 'HKLM:Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending'
    $WindowsUpdateRebootRequiredKey = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    $WindowsUpdatePostRebootReportingdKey =  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting'
    $FileRenamePendingKey = 'HKLM:SYSTEM\CurrentControlSet\Control\Session Manager'
    $RebootPending = @()
  }

  Process {
    Write-Host "Checking to see if a reboot is required" -ForegroundColor Cyan
    #CBSRebootPending - The Key will not exist unless there is a pending operation.
    if (Get-Item -Path $CBSRebootPendingKey -ErrorAction Ignore) {
      $CBSRUpdate = $true
    } else {
      $CBSRUpdate = $false
    }

    #CBSRebootInProgress - The Key will not exist unless there is a pending operation.
    if (Get-Item -Path $CBSRebootInProgressKey -ErrorAction Ignore) {
      $CBSIUpdate = $true
    } else {
      $CBSIUpdate = $false
    }

    #CBSPackagesPending - The Key will not exist unless there is a pending operation.
    if (Get-Item -Path $CBSPackagesPendingKey -ErrorAction Ignore) {
      $CBSPUpdate = $true
    } else {
      $CBSPUpdate = $false
    }

    #WindowsUpdateRebootRequired - The Key will not exist unless there is a pending operation.
    if (Get-Item -Path $WindowsUpdateRebootRequiredKey -ErrorAction Ignore) {
      $WinRUpdate = $true
    } else {
      $WinRUpdate = $false
    }

    #WindowsUpdatePostRebootReporting - The Key will not exist unless there is a pending operation.
    if (Get-Item -Path $WindowsUpdatePostRebootReportingdKey -ErrorAction Ignore) {
      $WinPUpdate = $true
    } else {
      $WinPUpdate = $false
    }

    #PendingFileRenameOperations - The Key will not exist unless there is a pending operation.
    Get-RegistryValue -RegKey $FileRenamePendingKey -ValueName 'PendingFileRenameOperations' | Out-Null
    $FileRenamecheck1 = @()
    $FileRenamecheck1 = $script:RegKeys
    if ($FileRenamecheck1.Value -ne "Not Present") {
      $FileUpdate1 = $true
    } else {
      $FileUpdate1 = $false
    }

    #PendingFileRenameOperations2 - The Key will not exist unless there is a pending operation.
    Get-RegistryValue -RegKey $FileRenamePendingKey -ValueName 'PendingFileRenameOperations2' | Out-Null
    $FileRenamecheck2 = @()
    $FileRenamecheck2 = $script:RegKeys
    if ($FileRenamecheck2.Value -ne "Not Present") {
      $FileUpdate2 = $true
    } else {
      $FileUpdate2 = $false
    }

    $RebootCheck = [PSCustomObject] @{
      CBSRebootPending = $CBSRUpdate
      CBSRebootInProgress = $CBSIUpdate
      CBSPackagesPending = $CBSPUpdate
      WindowsUpdateRebootRequired = $WinRUpdate
      WindowsUpdatePostRebootReporting = $WinPUpdate
      PendingFileRename1 = $FileUpdate1
      PendingFileRename2 = $FileUpdate2
    }
    $RebootPending = $RebootCheck
}

  End {
    if ($RebootPending | Where-Object { $_.CBSRebootPending -eq $true -or $_.CBSRebootInProgress -eq $true -or $_.CBSPackagesPending -eq $true -or
      $_.WindowsUpdateRebootRequired -eq $true -or $_.WindowsUpdatePostRebootReporting -eq $true -or
      $_.PendingFileRename1 -eq $true -or $_.PendingFileRename2 -eq $true }) {
      Write-Warning "Reboot check on $($ComputerName) found reboot is needed"
    } else {
      Write-Host "Reboot check on $($ComputerName) found reboot is not needed" -ForegroundColor Green
    }
  }
}

function Get-VCRedist {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$false)]
    [switch]$Install
  )

  begin {
    $x86Url = 'https://aka.ms/vs/17/release/vc_redist.x86.exe'
    $x64Url = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
    $regKey = 'HKLM:SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes'
    $testhash = 'C14A4B9A374D3EBD3F032A51B356DC8054D98E5A','FB3A9B4B4FBCE99628F6FAB2E320D3AD2F570A73'
  }

  process {
    Write-Host "Checking $($script:ComputerName) for Visual Studio C++ Redistributables" -ForegroundColor Cyan

    # Check if the x86 and x64 redistributables are installed
    $x86Installed = Get-ItemProperty -Path $($regKey + "\x86") -ErrorAction SilentlyContinue
    $x64Installed = Get-ItemProperty $($regKey + "\x64") -ErrorAction SilentlyContinue

    if (($x86Installed.Major -eq 14 -and $x86Installed.Minor -ge 30) -and ($x64Installed.Major -eq 14 -and $x64Installed.Minor -ge 30)) {
      Write-Host "Visual Studio C++ Redistributable x86 and x64 are installed on $($script:ComputerName)`n" -ForegroundColor Green
    } elseif ($Install) {
      $x86File = 'vc_redist.x86.exe'
      $x86Check = Test-Path -Path $x86File
      $x64File = 'vc_redist.x64.exe'
      $x64Check = Test-Path -Path $x64File
      if ((!$script:connectcheck) -and (($x86Check -eq $false) -or ($x64Check -eq $false))) {
        $global:ProgressPreference = "SilentlyContinue"
        $script:connectcheck = (Test-NetConnection -ComputerName "aka.ms").PingSucceeded
        $global:ProgressPreference = "Continue"
      }
      if (($x86Check -eq $true) -or ($x64Check -eq $true)){
        Write-Host "Installing Visual Studio C++ Redistributable x86 and x64 on $($script:ComputerName)`n" -ForegroundColor Magenta
        if ($x86Check -eq $true) {
          $x86hash = (Get-FileHash $x86File -Algorithm SHA1).Hash
          if ($testhash -contains $x86hash) {
            Start-Process -FilePath $x86File -ArgumentList "/install","/quiet","/norestart" -Wait -WorkingDirectory $pwd | Out-Null
            Write-Host "Visual Studio C++ Redistributable x86 is now installed on $($script:ComputerName)`n" -ForegroundColor Green
          } else {
            Write-Error "File hash is inconsistent! Cannot install." -ErrorAction Stop
          }
        }
        if ($x64Check -eq $true) {
          $x64hash = (Get-FileHash $x64File -Algorithm SHA1).Hash
          if ($testhash -contains $x64hash) {
            Start-Process -FilePath $x64File -ArgumentList "/install","/quiet","/norestart" -Wait -WorkingDirectory $pwd | Out-Null
            Write-Host "Visual Studio C++ Redistributable x64 is now installed on $($script:ComputerName)`n" -ForegroundColor Green
          } else {
            Write-Error "File hash is inconsistent! Cannot install." -ErrorAction Stop
          }
        }
        Write-Warning "This installation REQUIRES a reboot"
      } elseif ($script:connectcheck -eq $true) {
        Write-Host "Installing Visual Studio C++ Redistributable x86 and x64 on $($script:ComputerName)`n" -ForegroundColor Magenta
        Invoke-WebRequest -Uri $x86Url -OutFile $x86File
        Invoke-WebRequest -Uri $x64Url -OutFile $x64File
        $x86hash = (Get-FileHash $x86File -Algorithm SHA1).Hash
        if ($testhash -contains $x86hash) {
          Start-Process $x86File -ArgumentList "/install","/quiet","/norestart" -Wait -WorkingDirectory $pwd | Out-Null
        } else {
          Write-Error "File hash is inconsistent! Cannot install." -ErrorAction Stop
        }
        $x64hash = (Get-FileHash $x64File -Algorithm SHA1).Hash
        if ($testhash -contains $x64hash) {
          Start-Process $x64File -ArgumentList "/install","/quiet","/norestart" -Wait -WorkingDirectory $pwd | Out-Null
        } else {
          Write-Error "File hash is inconsistent! Cannot install." -ErrorAction Stop
        }
        Write-Warning "This installation REQUIRES a reboot"
        Write-Host "Visual Studio C++ Redistributable x86 and x64 are now installed on $($script:ComputerName)`n" -ForegroundColor Green
      } else {
        Write-Error "Visual Studio C++ Redistributable x86 and/or x64 were not installed on $($script:ComputerName)`n" -ErrorAction Stop
      }
    } else {
      Write-Host "Visual Studio C++ Redistributable x86 and/or x64 are not detected on $($script:ComputerName)`n" -ForegroundColor Yellow
    }
  }

  end {}
}
function Get-WebView2 {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$false)]
    [switch]$Install
  )

  begin {
    $WebView2Url = 'https://go.microsoft.com/fwlink/p/?LinkId=2124703'
    $MachineRegKey = 'HKLM:SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
    $UserRegKey = 'HKCU:Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
    $testhash = 'CA492B165E139B48FD39A45479DC28DAD8838B81','331CAA8FD3168CE4CCA33FBA823ACECC379AC917'
    $StandAlone = "MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
    $Bootstrap = "MicrosoftEdgeWebview2Setup.exe"
  }

  process {
    Write-Host "Checking $($script:ComputerName) for Microsoft Edge WebView2." -ForegroundColor Cyan

    # Check for Microsoft Edge WebView2. The Key will not exist unless it is installed
    Get-RegistryValue -RegKey $MachineRegKey -ValueName 'pv' | Out-Null
    $MachineCheck = @()
    $MachineCheck = $script:RegKeys
    if (($MachineCheck.Value -eq "0.0.0.0") -or ([string]::IsNullOrEmpty($MachineCheck.Value)) -or ($MachineCheck.Value -eq "Not Present")) {
      $MachineUpdate = $false
    } else {
      $MachineUpdate = $true
    }
    Get-RegistryValue -RegKey $UserRegKey -ValueName 'pv' | Out-Null
    $UserCheck = @()
    $UserCheck = $script:RegKeys
    if (($UserCheck.Value -eq "0.0.0.0") -or ([string]::IsNullOrEmpty($UserCheck.Value)) -or ($UserCheck.Value -eq "Not Present")) {
      $UserUpdate = $false
    } else {
      $UserUpdate = $true
    }

    if (($MachineUpdate -eq $true) -or  ($UserUpdate -eq $true)) {
      Write-Host "Microsoft Edge WebView2 Runtime is installed on $($script:ComputerName)`n" -ForegroundColor Green
    } elseif ($Install) {
      $StandAloneCheck = Test-Path -Path $StandAlone
      if ((!$script:connectcheck) -and ($StandAloneCheck -eq $false)) {
        $global:ProgressPreference = "SilentlyContinue"
        $script:connectcheck = (Test-NetConnection -ComputerName "go.microsoft.com").PingSucceeded
        $global:ProgressPreference = "Continue"
      }
      if ($StandAloneCheck -eq $true) {
        $SAhash = (Get-FileHash $StandAlone -Algorithm SHA1).Hash
        if ($testhash -contains $SAhash) {
          Write-Host "Installing Microsoft Edge WebView2 Runtime Standalone on $($script:ComputerName)`n" -ForegroundColor Magenta
          Start-Process -FilePath $StandAlone -ArgumentList "/silent","/install" -Wait -WorkingDirectory $pwd | Out-Null
          Get-RegistryValue -RegKey $MachineRegKey -ValueName 'pv' | Out-Null
          Write-Host "Microsoft Edge WebView2 Runtime version $($script:RegKeys.Value) is now installed on $($script:ComputerName)`n" -ForegroundColor Green
        } else {
          Write-Error "File hash is inconsistent! Cannot install." -ErrorAction Stop
        }
      } elseif ($script:connectcheck -eq $true) {
        Write-Host "Downloading and Installing Microsoft Edge WebView2 Runtime Bootstrapper on $($script:ComputerName)`n" -ForegroundColor Magenta
        Invoke-WebRequest -Uri $WebView2Url -OutFile $Bootstrap
        $Boothash = (Get-FileHash $Bootstrap -Algorithm SHA1).Hash
        if ($testhash -contains $Boothash) {
          Start-Process -FilePath $Bootstrap -ArgumentList "/silent","/install" -Wait -WorkingDirectory $pwd | Out-Null
          Get-RegistryValue -RegKey $MachineRegKey -ValueName 'pv' | Out-Null
          Write-Host "Microsoft Edge WebView2 Runtime version $($script:RegKeys.Value) is now installed on $($script:ComputerName)`n" -ForegroundColor Green
        } else {
          Write-Error "File hash is inconsistent! Cannot install." -ErrorAction Stop
        }
      } else {
        Write-Error "Microsoft Edge WebView2 Runtime was not installed on $($script:ComputerName)`n" -ErrorAction Stop
      }
    } else {
      Write-Host "Microsoft Edge WebView2 Runtime not detected on $($script:ComputerName)`n" -ForegroundColor Yellow
    }
  }

  end {}

}

#########################################################################################
# Main code to run checks
#########################################################################################
try {
  if (!$SQLOnly) {
    Get-PS64
    Get-OSSupported
    Get-UCRTUpdate
    if ([version]$Version -ge [version]"25.3") {
      Get-WebView2 -Install:$Install
    }
    if (($NonIIS.IsPresent) -and ($Install.IsPresent)) {
      Get-Features -NonIIS -Install
      Write-Host "Non IIS install requested. Not installing URL Rewrite module.`n" -ForegroundColor Cyan
    }
    elseif ($Install.IsPresent) {
      Get-Features -Install
      Get-Rewrite -Install
    }
    elseif ($NonIIS.IsPresent) {
      Get-Features -NonIIS
      Write-Host "Non IIS install requested. Not installing URL Rewrite module.`n" -ForegroundColor Cyan
    }
    else {
      Get-Features
      Get-Rewrite
    }
    if (($NonIIS.IsPresent) -and ($RemoveDefaultIIS.IsPresent)) {
      Write-Host "Non IIS install requested. No IIS sites to remove.`n" -ForegroundColor Cyan
    }
    elseif ($NonIIS.IsPresent) {
      Write-Host "Non IIS install requested. No IIS sites to remove.`n" -ForegroundColor Cyan
    }
    elseif ($RemoveDefaultIIS.IsPresent) {
      Get-IISSites -RemoveDefault
    }
    else {
      Get-IISSites
    }
    Get-dotNET -Install:$Install
    if ([version]$Version -ge [version]"24.1") {
        Get-VCRedist -Install:$Install
    }

    # Check-Reboot
    Get-PendingReboot
  }
  if ( $PSCmdlet.ParameterSetName -eq 'Rights' ) {
    if (Test-Path -Path .\UserRights.psm1) {
      #Pull in UserRights module from UserRights.psm1 file
      Import-Module .\UserRights.psm1
    } else {
      Write-Error "Cannot load UserRights module" -ErrorAction Stop
    }
    if (!$script:connectcheck) {
      $global:ProgressPreference = "SilentlyContinue"
      $script:connectcheck = (Test-NetConnection -ComputerName "download.microsoft.com").PingSucceeded
      $global:ProgressPreference = "Continue"
    }
    $Checked = Get-WindowsFeature -Name 'RSAT-AD-PowerShell'
    if ($Checked.InstallState -eq "Installed") {
      Import-Module 'ActiveDirectory' -ErrorAction Stop
      Write-Verbose "ActiveDirectory module is installed on server $($script:ComputerName)"
    } elseif (($Install) -and ($script:connectcheck -eq $true) -and ($Checked.InstallState -ne "Installed")) {
      $Installed = Install-WindowsFeature 'RSAT-AD-PowerShell' -ErrorAction SilentlyContinue
      Write-Verbose "ActiveDirectory module was installed on server $($script:ComputerName)"
      if ($Installed.Success -eq $true){
        Import-Module 'ActiveDirectory' -ErrorAction Stop
      }
    } else {
      Write-Error "ActiveDirectory module is not installed on server $($script:ComputerName), rerun with install switch to check domain groups" -ErrorAction Stop
    }
    $ADModule = Get-Module -ListAvailable | Where-Object {$_.Name -eq 'ActiveDirectory'}
    if ($null -ne $ADModule) {
      $LocalAccts = Get-LocalGroupMember -Group "Administrators"
      $ADGrps = $LocalAccts | Where-Object { ($_.ObjectClass -eq 'Group') }
      $ADUsers = $LocalAccts | Where-Object { $_.ObjectClass -eq 'User' -and $_.PrincipalSource -eq 'ActiveDirectory' }
      if ($null -ne $ADGrps) {
        foreach ($item in $ADGrps.Name.split( "\" )[1]) {
          $ADMembers += (Get-ADGroupMember $item -Recursive).SamAccountName
        }
      }
      if ($null -ne $ADUsers) {
        foreach ($item in $ADUsers.Name.split( "\" )[1]) {
          $ADMembers += $item
        }
      }
      $ADAccts = $ADMembers | Sort-Object -Unique
    }
    $Accthash = @{}
    if ($Accounts.Count -ne 2) {
      Write-Error "Two accounts are required to validate rights configuration" -ErrorAction Stop
    } else {
      $Rawacct = @()
      foreach ($Account in $Accounts) {
        if ($Account -match '\@') {
          Write-Host "Removing domain from username"
          $Acctsplit = $Account.split( "@" )[0]
        } elseif ($Account -match '\\') {
          Write-Host "Removing domain from username"
          $Acctsplit = $Account.split( "\" )[1]
        } else {
          $Acctsplit = $Account
        }
        $Rawacct += $Acctsplit
      }
      $Accounts = $Rawacct
      foreach ($Account in $Accounts) {
        if ($null -ne $Accthash.DBO) {
          $AcctAdd = "Op"
        } elseif ($null -ne $Accthash.Op) {
          $AcctAdd = "DBO"
        } else {
          $DBO = New-Object System.Management.Automation.Host.ChoiceDescription  '&DB Owner Account'
          $Op = New-Object System.Management.Automation.Host.ChoiceDescription '&Operational Account'
          $options = [System.Management.Automation.Host.ChoiceDescription[]]($DBO, $Op)
          $title = "Select if Accounts are Log On as a Service/Batch Job"
          $message = "Is the $($Account) account the DB Owner, or Operational Account"
          $AcctOptions = $host.ui.PromptForChoice($title, $message, $options, 0)
          Switch ($AcctOptions) {
            0 { $AcctAdd = "DBO" }
            1 { $AcctAdd = "Op" }
          }
        }
        if (($AcctAdd -eq "DBO") -and ($AddAccounts)) {
          Write-Host "Checking $($Account) is the DB Owner Account" -ForegroundColor Green
          Write-Host "Granting $($Account) Log on as a Service rights" -ForegroundColor Green
          Grant-UserRight -Account $Account -Right 'SeServiceLogonRight'
          $Accthash.Add( 'DBO',$Account )
        } elseif ($AcctAdd -eq "DBO") {
          Write-Host "Checking $($Account) is the DB Owner Account" -ForegroundColor Green
          $Accthash.Add( 'DBO',$Account )
        }
        if (($AcctAdd -eq "Op") -and ($AddAccounts)) {
          Write-Host "Checking $($Account) is the Operational Account" -ForegroundColor Green
          Write-Host "Granting $($Account) Log on as a Service and Batch Job rights" -ForegroundColor Green
          Grant-UserRight -Account $Account -Right 'SeServiceLogonRight','SeBatchLogonRight'
          $Accthash.Add( 'Op',$Account )
        } elseif ($AcctAdd -eq "Op") {
          Write-Host "Checking $($Account) is the Operational Account" -ForegroundColor Green
          $Accthash.Add( 'Op',$Account )
        }
      }
    }
    $ADMembers = @()
    if (($ADAccts -notcontains $Accthash.Op) -and ($AddAccounts)) {
      Add-LocalGroupMember -Group "Administrators" -Member $Accthash.Op
      Write-Host "$($Accthash.Op) was added to Local Administrators" -ForegroundColor Green
      $ADAccts += $Accthash.Op
    } elseif (($ADAccts -contains $Accthash.Op) -and ($AddAccounts)) {
      Write-Host "$($Accthash.Op) is already a Local Administrator" -ForegroundColor Green
    }
    if ($ADAccts -contains $Accthash.DBO) {
      $Rightshash = Get-UserRightsGrantedToAccount -Account $Accthash.DBO
      if (($Rightshash.Right -contains 'SeServiceLogonRight') -and ($Rightshash.Right -contains 'SeBatchLogonRight')) {
        Write-Warning "$($Accthash.DBO) is the DB Owner Account and has correct Log on as a Service rights, but should be removed from Batch Job rights and as a Local Administrator"
      } elseif ($Rightshash.Right -contains 'SeServiceLogonRight') {
        Write-Warning "$($Accthash.DBO) is the DB Owner Account and has correct Log on as a Service rights, but should be removed as a Local Administrator"
      } elseif ($Rightshash.Right -contains 'SeBatchLogonRight') {
        Write-Warning "$($Accthash.DBO) is the DB Owner Account, needs Log on as a Service rights added, and should be removed from Batch Job rights and as a Local Administrator"
      } else {
        Write-Warning "$($Accthash.DBO) is the DB Owner Account, needs Log on as a Service rights added, and should be removed as a Local Administrator"
      }
    } else {
      $Rightshash = Get-UserRightsGrantedToAccount -Account $Accthash.DBO
      if (($Rightshash.Right -contains 'SeServiceLogonRight') -and ($Rightshash.Right -contains 'SeBatchLogonRight')) {
        Write-Warning "$($Accthash.DBO) is the DB Owner Account and has correct Log on as a Service rights, but should be removed from Batch Job rights"
      } elseif  ($Rightshash.Right -contains 'SeBatchLogonRight') {
        Write-Warning "$($Accthash.DBO) is the DB Owner Account and should be removed from Batch Job rights"
      } elseif ($Rightshash.Right -contains 'SeServiceLogonRight') {
        Write-Host "$($Accthash.DBO) is the DB Owner Account and has correct Log on as a Service rights (Non-Administrator)" -ForegroundColor Green
      } else {
        Write-Warning "$($Accthash.DBO) is the DB Owner Account and needs Log on as a Service rights added"
      }
    }
    if ($ADAccts -contains $Accthash.Op) {
      $Rightshash = Get-UserRightsGrantedToAccount -Account $Accthash.Op
      if (($Rightshash.Right -contains 'SeServiceLogonRight') -and ($Rightshash.Right -contains 'SeBatchLogonRight')) {
        Write-Host "$($Accthash.Op) is the Operational Account and has correct Log on as a Service rights, Batch Job rights and is a Local Administrator" -ForegroundColor Green
      } elseif ($Rightshash.Right -contains 'SeServiceLogonRight') {
        Write-Warning "$($Accthash.Op) is the Operational Account, needs Batch Job rights added, has correct Log on as a Service rights and is a Local Administrator"
      } elseif ($Rightshash.Right -contains 'SeBatchLogonRight') {
        Write-Warning "$($Accthash.Op) is the Operational Account, needs Log on as a Service rights added, has correct Batch Job rights and is a Local Administrator"
      } else {
        Write-Warning "$($Accthash.Op) is the Operational Account, needs Log on as a Service and Batch Job rights added, and is a Local Administrator"
      }
    } else {
      $Rightshash = Get-UserRightsGrantedToAccount -Account $Accthash.Op
      if (($Rightshash.Right -contains 'SeServiceLogonRight') -and ($Rightshash.Right -contains 'SeBatchLogonRight')) {
        Write-Warning "$($Accthash.Op) is the Operational Account and has correct Log on as a Service rights and Batch Job rights but needs to be added as a Local Administrator"
      } elseif  ($Rightshash.Right -contains 'SeBatchLogonRight') {
        Write-Warning "$($Accthash.Op) is the Operational Account, has correct Batch Job rights, needs Log on as a Service rights and Local Administrator rights added"
      } elseif ($Rightshash.Right -contains 'SeServiceLogonRight') {
        Write-Warning "$($Accthash.Op) is the Operational Account, has correct Log on as a Service rights, needs Batch Job rights and Local Administrator rights added"
      } else {
        Write-Warning "$($Accthash.Op) is the Operational Account and needs Log on as a Service, Batch Job and Local Administrator rights added"
      }
    }
  }
  if (( $PSCmdlet.ParameterSetName -eq 'SQL' ) -or ( $PSCmdlet.ParameterSetName -eq 'SQLOnly' )) {
    #Check SQL Server and load DBA Tools
    if (!$script:connectcheck) {
      $global:ProgressPreference = "SilentlyContinue"
      $script:connectcheck = (Test-NetConnection -ComputerName "www.powershellgallery.com" -CommonTCPPort HTTP).TcpTestSucceeded
      $global:ProgressPreference = "Continue"
    }
    if ((Get-PackageProvider).Name -eq 'NuGet') {
      Write-Host "NuGet Installed" -ForegroundColor Green
    }
    else {
      if ($script:connectcheck -eq $false) {
        Write-Error "No internet connection to download required packages!" -ErrorAction Stop
      } else {
        Write-Host "Installing NuGet" -ForegroundColor Yellow
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction silentlycontinue | Out-Null
      }
    }
    Import-PackageProvider -Name NuGet
    Set-PSRepository -InstallationPolicy Trusted -Name PSGallery
    If ((Get-InstalledModule).Name -eq 'dbatools') {
      Write-Host "DBA Tools Installed" -ForegroundColor Green
    }
    else {
      $yes = New-Object System.Management.Automation.Host.ChoiceDescription  '&Yes - Agree'
      $no = New-Object System.Management.Automation.Host.ChoiceDescription '&No - Abort'
      $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
      $title = 'Install DBA Tools'
      $message = 'Checking SQL requires installing the DBA Tools package, enter Yes to agree or no to abort installation'
      $InstallTools = $host.ui.PromptForChoice($title, $message, $options, 0)
      Switch ($InstallTools) {
        0 { $global:InstallDBATools = "Yes" }
        1 { $global:InstallDBATools = "No" }
      }
      if ($InstallDBATools -eq "Yes") {
        if ($script:connectcheck -eq $false) {
          Write-Error "No internet connection to download required packages!" -ErrorAction Stop
        } else {
          Write-Host "Installing DBA Tools module" -ForegroundColor Yellow
          Install-Module dbatools -Confirm:$False -Force -ErrorAction silentlycontinue
        }
      }
      else {
        Write-Error "SQL Checks aborted as DBA Tools installation is required to perform them" -ErrorAction Stop
      }
    }
    Import-Module dbatools -ErrorAction Stop
    $toolsloaded = Get-Module -ListAvailable | Where-Object {$_.Name -eq 'dbatools'}
    $Winauth = New-Object System.Management.Automation.Host.ChoiceDescription  '&Windows (Domain\user)'
    $SQLauth = New-Object System.Management.Automation.Host.ChoiceDescription '&SQL Server Account'
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($Winauth, $SQLauth)
    $title = "Select SQL Server username type"
    $message = "Enter SQL Server username choice"
    $AcctOptions = $host.ui.PromptForChoice($title, $message, $options, 0)
    Switch ($AcctOptions) {
      0 { $AcctAuth = "winauth" }
      1 { $AcctAuth = "sqlauth" }
    }
    $SQLCredential = Get-Credential -Message 'Enter SQL Server username / password.'
    if (($SQLCredential.UserName -match '\@') -or ($SQLCredential.UserName -match '\\') -and ($AcctAuth -eq "winauth")) {
      Write-Host "Using Windows account $($SQLCredential.UserName)" -ForegroundColor Green
    } elseif (($SQLCredential.UserName -notmatch '\@') -or ($SQLCredential.UserName -notmatch '\\') -and ($AcctAuth -eq "winauth")) {
      Write-Warning "Windows account name must use 'username@domain.com' format"
      $SQLCredential = Get-Credential -Message 'Enter SQL Server username / password.'
      Write-Host "Using Windows account $($SQLCredential.UserName)" -ForegroundColor Green
    } elseif (($SQLCredential.UserName -match '\@') -or ($SQLCredential.UserName -match '\\') -and ($AcctAuth -eq "sqlauth")) {
      Write-Warning "SQL Server account name must use 'username' format"
      $SQLCredential = Get-Credential -Message 'Enter SQL Server username / password.'
      Write-Host "Using SQL Server account $($SQLCredential.UserName)" -ForegroundColor Green
    } elseif (($SQLCredential.UserName -notmatch '\@') -or ($SQLCredential.UserName -notmatch '\\') -and ($AcctAuth -eq "sqlauth")) {
      Write-Host "Using SQL Server account $($SQLCredential.UserName)" -ForegroundColor Green
    } else {
      Write-Error "Invalid Username format. Cannot continue." -ErrorAction Stop
    }
    $SQLInstance = Find-DbaInstance -ComputerName $SQLFQDN -SqlCredential $SQLCredential -ScanType Browser, SqlConnect
    $SQLserver = ($SQLFQDN, $SQLInstance.Port -join ":")
    $SQLCMReset = Set-DbaCmConnection -ComputerName $SQLFQDN -ResetCredential -ResetConnectionStatus -DisableBadCredentialCache
    try {
      $SQLTest = Test-DbaConnection -SqlInstance $SQLserver -SqlCredential $SQLCredential -EnableException
    } catch {
      $null = Set-DbatoolsInsecureConnection -SessionOnly
      $SQLTest = Test-DbaConnection -SqlInstance $SQLserver -SqlCredential $SQLCredential
    }
    Write-Verbose $SQLCMReset
    if (($toolsloaded) -and ($SQLTest.ConnectSuccess -eq $true)) {
      $SQLRoleInfo = Get-DBADbRoleMember -SqlInstance $SQLserver -Database $Database -SqlCredential $SQLCredential -IncludeSystemUser
      $svrSQLOS = Get-DbaOperatingSystem -ComputerName $SQLserver
      $svrSQLFQDN = $svrSQLOS.ComputerName,$SQLInstance.Port -join ":"
      try {
        $svrSQLAg = Get-DbaAvailabilityGroup -SqlInstance $SQLserver -SqlCredential $SQLCredential -EnableException
      }
      catch {
        $svrSQLAg = New-Object Object
        $svrSQLAg | Add-Member  -MemberType NoteProperty -Name "AvailabilityDatabases" -Value "Availability Group not configured"
        $svrSQLAg | Add-Member  -MemberType NoteProperty -Name "AvailabilityGroupListeners" -Value "No Availability Group Listeners"
      }
      $svrSQLDbInstance =
      Connect-DbaInstance -SqlInstance $SQLserver -SqlCredential $SQLCredential |
      Select-Object ProductLevel, Edition, Version, Name, DomainInstanceName, NetPort, HostDistribution, Processors, PhysicalMemory,
        @{Name="SQLVersion";Expression={
          if ($_.VersionMajor -eq "11") {
            "SQL 2012"
          } elseif ($_.VersionMajor -eq "12") {
            "SQL 2014"
          } elseif ($_.VersionMajor -eq "13") {
            "SQL 2016"
          } elseif ($_.VersionMajor -eq "14") {
            "SQL 2017"
          } elseif ($_.VersionMajor -eq "15") {
            "SQL 2019"
          } elseif ($_.VersionMajor -eq "16") {
            "SQL 2022"
          } elseif ($_.VersionMajor -lt "11") {
            "SQL 2008R2 or older is not supported"
          } else {
            "unknown"
          }
        }
      }

      write-host "==========================SQL Server Information================================="
      Write-Host "SQL Server FQDN: $($svrSQLFQDN)"
      write-host "SQL Instance: $($svrSQLDbInstance.DomainInstanceName)"
      write-host "SQL Port: $($svrSQLDbInstance.NetPort)"
      write-host "SQL Version: $($svrSQLDbInstance.SQLVersion)"
      write-host "Edition: $($svrSQLDbInstance.Edition)"
      write-host "SQL Product Level: $($svrSQLDbInstance.ProductLevel)"
      if ($null -ne $svrSQLDbInstance.HostDistribution) {
        Write-Host "SQL Server OS: $($svrSQLDbInstance.HostDistribution)"
      } else {
        Write-Host "SQL Server OS: $($svrSQLOS.OSVersion)"
      }
      if ($svrSQLDbInstance.Processors -ge "4") {
        Write-Host "SQL Server Processors: $($svrSQLDbInstance.Processors)"
      } else {
        Write-Host "SQL Server Processors: $($svrSQLDbInstance.Processors) (Recommended Minimum 4 Processing Cores)" -ForegroundColor Yellow
      }
      if ($svrSQLDbInstance.PhysicalMemory -ge "16384") {
        Write-Host "SQL Server Memory: $($svrSQLDbInstance.PhysicalMemory)MB"
      } else {
        Write-Host "SQL Server Memory: $($svrSQLDbInstance.PhysicalMemory)MB (Recommended Minimum 16GB Memory)"  -ForegroundColor Yellow
      }
      write-host "SQL Server Availability Group Databases: $($svrSQLAg.AvailabilityDatabases)"
      write-host "SQL Server Availability Group Listeners: $($svrSQLAg.AvailabilityGroupListeners)"
      write-host "================================================================================="
      if ($SQLRoleInfo) {
        write-host ""
        write-host "=======================SQL Database User Information============================="
        foreach ($RoleInfo in $SQLRoleInfo) {
          write-host    "UserName       :  $($RoleInfo.UserName)"
          write-host    "Login          :  $($RoleInfo.Login)"
          write-host    "Database Name  :  $($RoleInfo.Database)"
          if ($RoleInfo.Role -eq "db_owner") {
            Write-Host    "Server Role    :  $($RoleInfo.Role)" -ForegroundColor Yellow
          }
          else {
            Write-Host    "Server Role    :  $($RoleInfo.Role)"
            write-host ""
          }
        }
        write-host "================================================================================="
      } else {
        Write-Warning "Login failed to the $($SQLserver) SQL Server, unable to get Role or User configuration information"
      }
    }
  }
} catch {
  $PSCmdlet.ThrowTerminatingError($_)
} finally {
  Get-Module | Where-Object { $_.Name -in @('dbatools', 'ActiveDirectory', 'UserRights', 'WebAdministration', 'IISAdministration', 'ServerManager') } | Remove-Module -Force
  Write-Host "Successfully removed PowerShell modules" -ForegroundColor Cyan
}

# SIG # Begin signature block
# MIIhhAYJKoZIhvcNAQcCoIIhdTCCIXECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC8M/DKeMhMyd7U
# pmQqpQdTNFWVUhBc8ESBXUZasibhRqCCGoMwggd8MIIFZKADAgECAhAD8JaetbYh
# gELYx9Duvn5RMA0GCSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBD
# b2RlIFNpZ25pbmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjQwODIxMDAw
# MDAwWhcNMjUwOTEyMjM1OTU5WjCBgzELMAkGA1UEBhMCVVMxDTALBgNVBAgTBFV0
# YWgxFzAVBgNVBAcTDlNhbHQgTGFrZSBDaXR5MRUwEwYDVQQKEwxWZW5hZmksIElu
# Yy4xHjAcBgNVBAsTFVByb2Zlc3Npb25hbCBTZXJ2aWNlczEVMBMGA1UEAxMMVmVu
# YWZpLCBJbmMuMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxungR693
# DIQWU/77slVOdl/qc5leazfxKxl7tkKdNFwCDFrDOAn4/5lIKCl/DZc9RYL5F7Kd
# sdw9Qgi96JWgw0Z29FWcyxYW4xX7IHHhlNzrt/Qc2u+DDk7IZGrMi+OQcGNYxvvG
# HkgZ640nTkX/rPcsctOiYMg57vXUjtYS+u5RfhsJCw3cqCWynTzxKxoQxsTR4NK8
# CW4B/6JYh2V2ni17Bbve074PVKY4Hv+Zmc3F5OHrnfEo51Rv/UcrEdoVvq+Qz5tr
# 89TAd8/QenZ+oomRXG0EmL5UdRn+1Csdk8xoBhHBhgTRmtH+dYwyBSFdWrJ5yTqC
# r198PCe1s4r4eVhrWQdlmI8IWf1uQABq38e/jtLYNJFauurelEN6Fp1bItXuL/Ne
# ncPjOQgmxiufVZ+BYjLYSB4N7vudToDV69B3h8qtVyq0TdAEvyYNcla36li3Ob5K
# qrop+duc37BmHWasgcDXx+Vo6+SyfSaZVNgvw64ihxoVZr/BCkS57zvE/NBnn5rL
# WoVtFWd7tDaoElwCjVbJFNK6RoWCN11aKJKNvUNycb5bR8e3FiuJFZ8rm/4WJvx0
# GNBD53FxKT3fZcZmClb43+C4+s03a6p05X+EIBNDsAlfS44yFy+7t7u8eyM7vmDV
# aVPacOo6yYUPTPxQBENoQeGsecQlWuUQPgcCAwEAAaOCAgMwggH/MB8GA1UdIwQY
# MBaAFGg34Ou2O/hfEYb7/mF7CIhl9E5CMB0GA1UdDgQWBBTTo4VJ8oyO4K/8Z6vN
# vRU44blkbjA+BgNVHSAENzA1MDMGBmeBDAEEATApMCcGCCsGAQUFBwIBFhtodHRw
# Oi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMIG1BgNVHR8Ega0wgaowU6BRoE+GTWh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNI
# QTM4NDIwMjFDQTEuY3JsMFOgUaBPhk1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20v
# RGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0Ex
# LmNybDCBlAYIKwYBBQUHAQEEgYcwgYQwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBcBggrBgEFBQcwAoZQaHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0
# MjAyMUNBMS5jcnQwCQYDVR0TBAIwADANBgkqhkiG9w0BAQsFAAOCAgEAk5iA6e3z
# vlKHWEzVa8GVTb0XfMnSj6UcB8WbKmjFR0FlI33Vy8LvoCyX4TamxGJxmbR/BT6V
# lwPMI4UTQCUS4b3N+yGDUBmqqCLqN0W0OJbun6Y0UscEcWr8RsAY0lp3SFjcUa1c
# ixLsSI/9cQTV+6bIJUScvlXEOYIenjiIO/RTX9y+8/lfgVBYS69bjDUzU/WxcZ3R
# vGZ5sPVko6al7frjz0uL/F/aCbCw2N0eO/sqI4IfWQZ3CVromQjBEzogj7K2OuB3
# V2Gw3IfSvQobmuTtveOhwp/ma+4V46YYx0mQKrDS0jniMGYstoJeFGMhvr9oac0Q
# +wO/PmHBp93m9SfoiUTmKYJMIu9+Jd+8rF6m2/SqRESk1HKD+RgGURt6B38K6dcf
# URJXY/r/wgnH0Xb2yMorFOKGkyX2D5hMs1pzgvL3F3B2/SmH2RORDA45UfOCtWQE
# 6yYnGjZmabCZl4YFWZsoo9pZXXK3b5narfokdh3AEH2RpIEBtWuZYPgqf8X2a5rt
# QrskHMEhY3WHZTZNnncsXSe1cAbPlnDge+byzWYyVc1PtiWE9krTdyJ+TKaTeJTU
# NW73unKsU5JMwA77ASchFEfPtLBLjKJh44vFzYuRJGIXoUK2bdPk3JLmvApx6Ty5
# PP8HdjkQzchgpQHVVQe3KAR1ppN42x/9ESEwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqG
# SIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXH
# JQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMf
# UBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w
# 1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRk
# tFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYb
# qMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUm
# cJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP6
# 5x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzK
# QtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo
# 80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjB
# Jgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXche
# MBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB
# /wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU
# 7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDig
# NqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZI
# hvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd
# 4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiC
# qBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl
# /Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeC
# RK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYT
# gAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/
# a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37
# xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmL
# NriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0
# YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJ
# RyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIG
# vDCCBKSgAwIBAgIQC65mvFq6f5WHxvnpBOMzBDANBgkqhkiG9w0BAQsFADBjMQsw
# CQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRp
# Z2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENB
# MB4XDTI0MDkyNjAwMDAwMFoXDTM1MTEyNTIzNTk1OVowQjELMAkGA1UEBhMCVVMx
# ETAPBgNVBAoTCERpZ2lDZXJ0MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAg
# MjAyNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL5qc5/2lSGrljC6
# W23mWaO16P2RHxjEiDtqmeOlwf0KMCBDEr4IxHRGd7+L660x5XltSVhhK64zi9Ce
# C9B6lUdXM0s71EOcRe8+CEJp+3R2O8oo76EO7o5tLuslxdr9Qq82aKcpA9O//X6Q
# E+AcaU/byaCagLD/GLoUb35SfWHh43rOH3bpLEx7pZ7avVnpUVmPvkxT8c2a2yC0
# WMp8hMu60tZR0ChaV76Nhnj37DEYTX9ReNZ8hIOYe4jl7/r419CvEYVIrH6sN00y
# x49boUuumF9i2T8UuKGn9966fR5X6kgXj3o5WHhHVO+NBikDO0mlUh902wS/Eeh8
# F/UFaRp1z5SnROHwSJ+QQRZ1fisD8UTVDSupWJNstVkiqLq+ISTdEjJKGjVfIcsg
# A4l9cbk8Smlzddh4EfvFrpVNnes4c16Jidj5XiPVdsn5n10jxmGpxoMc6iPkoaDh
# i6JjHd5ibfdp5uzIXp4P0wXkgNs+CO/CacBqU0R4k+8h6gYldp4FCMgrXdKWfM4N
# 0u25OEAuEa3JyidxW48jwBqIJqImd93NRxvd1aepSeNeREXAu2xUDEW8aqzFQDYm
# r9ZONuc2MhTMizchNULpUEoA6Vva7b1XCB+1rxvbKmLqfY/M/SdV6mwWTyeVy5Z/
# JkvMFpnQy5wR14GJcv6dQ4aEKOX5AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMC
# B4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAE
# GTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3Mp
# dpovdYxqII+eyG8wHQYDVR0OBBYEFJ9XLAN3DigVkGalY17uT5IfdqBbMFoGA1Ud
# HwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUF
# BwEBBIGDMIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20w
# WAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZI
# hvcNAQELBQADggIBAD2tHh92mVvjOIQSR9lDkfYR25tOCB3RKE/P09x7gUsmXqt4
# 0ouRl3lj+8QioVYq3igpwrPvBmZdrlWBb0HvqT00nFSXgmUrDKNSQqGTdpjHsPy+
# LaalTW0qVjvUBhcHzBMutB6HzeledbDCzFzUy34VarPnvIWrqVogK0qM8gJhh/+q
# DEAIdO/KkYesLyTVOoJ4eTq7gj9UFAL1UruJKlTnCVaM2UeUUW/8z3fvjxhN6hdT
# 98Vr2FYlCS7Mbb4Hv5swO+aAXxWUm3WpByXtgVQxiBlTVYzqfLDbe9PpBKDBfk+r
# abTFDZXoUke7zPgtd7/fvWTlCs30VAGEsshJmLbJ6ZbQ/xll/HjO9JbNVekBv2Tg
# em+mLptR7yIrpaidRJXrI+UzB6vAlk/8a1u7cIqV0yef4uaZFORNekUgQHTqddms
# PCEIYQP7xGxZBIhdmm4bhYsVA6G2WgNFYagLDBzpmk9104WQzYuVNsxyoVLObhx3
# RugaEGru+SojW4dHPoWrUhftNpFC5H7QEY7MhKRyrBe7ucykW7eaCuWBsBb4HOKR
# FVDcrZgdwaSIqMDiCLg4D+TPVgKx2EgEdeoHNHT9l3ZDBD+XgbF+23/zBjeCtxz+
# dL/9NWR6P2eZRi7zcEO1xwcdcqJsyz/JceENc2Sg8h3KeFUCS7tpFk7CrDqkMYIG
# VzCCBlMCAQEwfTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIElu
# Yy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJT
# QTQwOTYgU0hBMzg0IDIwMjEgQ0ExAhAD8JaetbYhgELYx9Duvn5RMA0GCWCGSAFl
# AwQCAQUAoIGIMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCSqGSIb3DQEJ
# BTEPFw0yNTA3MDIxNTQzNTlaMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEV
# MC8GCSqGSIb3DQEJBDEiBCCybZeM1Cxu39Eq0z+iuNeQnJwBm4akhd1GQQEEYxp8
# dTANBgkqhkiG9w0BAQEFAASCAgAP5UIzsLReYfZNWsIayMMB7c6SR7CvF3zmR+gJ
# MYs1kBziqNbLYsUPurfZ3uTZT/C62tGfEvDOv33xogeKzsnncCbFh1Do9LfoxV8c
# E6L7e0rsRoZx5Pb2Kj9D49DLiZxlXbKgmJ3VOT/GE4uG1dVeki0kHol9VvvUwvt/
# YSDgXgZZ5pDnvUnUjVU+eVv4dZ53gt4lGW9OPc5WCaLHMdFxY6nO8lDiZkTcDrIZ
# GiEHYn++pZ60dz98PpTR+vcZzjSv5hjAkDYH/PFab20Fxr8SHlZDjmw3SMCorVOG
# kWwCDFyJd2NefmltQsYVjlEx7pk2FhuxYxSo0HkDSsHu09v38MGvjkwUiXLzQpaT
# u6NekwSiGEEVp6DvoQCMXKBgH4cT/mptbbVNKw+INHDXWFSOMr2QtsaMsU0f8DRC
# z9p9X1OMH3FzxrfiCHPv+d4qKj/xTVAHi+vppfmkDnzWt4xEFy6FiXve3yIGIX7p
# hOF4uQmIGc0uxLZ4UfTPmZansJ8UCqA/KYk8Wc9mGZ2ZcdPfiSRZuqfIzri37ydj
# SfmlZhpXCQHnZQrsP95ANJyklc/NA43Mx+iJMBD921Bd37TuepBbvFXoBt0mykUk
# qr7YMxr49cpYA7zCo0vDQeE5EdTYW3qXmCCIbx65nFE/KLUT8mx68gQTYA0q1H0u
# kqrNN6GCAyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQg
# VHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAuuZrxa
# un+Vh8b56QTjMwQwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTA3MDIxNTQzNTlaMC8GCSqGSIb3DQEJ
# BDEiBCC4xmDwoGZCeDPuia/XOWhuCeLNZVeQzo4G5KhAqpBx4TANBgkqhkiG9w0B
# AQEFAASCAgCnwdacHo6DAyBSZeO/14m4e+j3RWj22GyYUSAmmwEpbcVZZL4QG0Z2
# +2KI1Y2zLyIA4Q8kg1RXj0rPhtti158blULOXVMAUvJU1ltfnRAdsFlhcKKgkVZj
# vQZjXD/FkrUCDNGJh2+RGyK7pce76T7tQkRWL7Yx3SHLlTjSmphnW325N300YkFv
# jXwlEleSkTd6Cku+5gDNw5mMWME3zWyg7ia5qtypTn8lLS3xe9q7sPUpOgTjfdnC
# zsEueY1iqjSYLpm7JJePSI+et8gxBcIUoKam3olzYXZAsLqsoCFsP09rS0rHEocF
# fdaTla7nVmOAnygeo/UkieYlBWtI5SG4l3q7ZmBERJGg3De774A5RhLPO+tt9SZw
# XejkRv9f0LLXA66L8IiVlxRhB+sL7tmJDWat3hliHGQTKAJ5rvX2L3rZ/FyT/Qr+
# Gl6JgvkbLEjk9HWZeASgYjJL6482JW5/ygy5kk7AmQGqdssCS4Y7r2Q8qQKLabas
# pjDkBwAd5AxRCUtfgCagePo7FvpnfuAcsU0MR8yQCBVJY5HsYo6nEdF7AMUhz04A
# M0imutUhXqEL7luI07qcrIfmS7/9ooyfN+DF0fVJIicqUOvXKRZckjAwu0vZQw25
# RbS5NR+e+YTr3wwJ61BhyA7IdC5Im7yzniOBij99eto3CCcrf6px2w==
# SIG # End signature block
