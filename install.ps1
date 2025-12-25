#Requires -Version 7.0

<#
.SYNOPSIS
    Ralph for Claude Code - Windows Installation Script
.DESCRIPTION
    Installs Ralph globally on Windows systems.
    Creates commands: ralph, ralph-monitor, ralph-setup, ralph-import
.PARAMETER Uninstall
    Remove Ralph installation
.PARAMETER Help
    Show help message
.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -Uninstall
#>

[CmdletBinding()]
param(
    [switch]$Uninstall,
    
    [Alias('h')]
    [switch]$Help
)

# Configuration
$script:RalphHome = Join-Path $env:LOCALAPPDATA "Ralph"
$script:BinDir = Join-Path $script:RalphHome "bin"
$script:TemplatesDir = Join-Path $script:RalphHome "templates"
$script:LibDir = Join-Path $script:RalphHome "lib"
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Show-Help {
    Write-Host ""
    Write-Host "Ralph for Claude Code - Windows Installation" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\install.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "    -Uninstall    Remove Ralph installation"
    Write-Host "    -Help         Show this help message"
    Write-Host ""
    Write-Host "Installation paths:" -ForegroundColor Yellow
    Write-Host "    Commands:     $script:BinDir"
    Write-Host "    Scripts:      $script:RalphHome"
    Write-Host "    Templates:    $script:TemplatesDir"
    Write-Host ""
}

function Write-Log {
    <#
    .SYNOPSIS
        Logs a message with color
    #>
    param(
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level,
        [string]$Message
    )
    
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
        "SUCCESS" { "Green" }
    }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Dependencies {
    <#
    .SYNOPSIS
        Checks for required dependencies
    #>
    
    Write-Log -Level "INFO" -Message "Checking dependencies..."
    
    $missingDeps = @()
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $missingDeps += "PowerShell 7+ (current: $($PSVersionTable.PSVersion))"
    }
    
    # Check Node.js/npm
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    $npxCmd = Get-Command npx -ErrorAction SilentlyContinue
    if (-not $nodeCmd -and -not $npxCmd) {
        $missingDeps += "Node.js/npm"
    }
    
    # Check Git
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        $missingDeps += "Git"
    }
    
    if ($missingDeps.Count -gt 0) {
        Write-Log -Level "ERROR" -Message "Missing required dependencies:"
        foreach ($dep in $missingDeps) {
            Write-Host "    - $dep" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Please install the missing dependencies:" -ForegroundColor Yellow
        Write-Host "  - Node.js: https://nodejs.org/"
        Write-Host "  - Git: https://git-scm.com/download/win"
        Write-Host "  - PowerShell 7: https://github.com/PowerShell/PowerShell/releases"
        Write-Host ""
        Write-Host "Or install via winget:" -ForegroundColor Cyan
        Write-Host "  winget install Microsoft.PowerShell OpenJS.NodeJS.LTS Git.Git"
        Write-Host ""
        return $false
    }
    
    Write-Log -Level "INFO" -Message "Claude Code CLI will be downloaded when first used."
    Write-Log -Level "SUCCESS" -Message "Dependencies check completed"
    return $true
}

function New-InstallDirs {
    <#
    .SYNOPSIS
        Creates installation directories
    #>
    
    Write-Log -Level "INFO" -Message "Creating installation directories..."
    
    $dirs = @($script:RalphHome, $script:BinDir, $script:TemplatesDir, $script:LibDir)
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    Write-Log -Level "SUCCESS" -Message "Directories created: $script:RalphHome"
}

function Install-Scripts {
    <#
    .SYNOPSIS
        Installs Ralph scripts to Ralph home directory
    #>
    
    Write-Log -Level "INFO" -Message "Installing Ralph scripts..."
    
    # Copy main scripts
    $mainScripts = @(
        "ralph_loop.ps1",
        "ralph_monitor.ps1",
        "setup.ps1",
        "ralph_import.ps1",
        "ralph-prd.ps1"
    )
    
    foreach ($scriptName in $mainScripts) {
        $sourcePath = Join-Path $script:ScriptDir $scriptName
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $script:RalphHome -Force
            Write-Host "    Installed: $scriptName" -ForegroundColor Gray
        }
        else {
            Write-Log -Level "WARN" -Message "Script not found: $scriptName"
        }
    }
    
    # Copy lib folder
    $libSource = Join-Path $script:ScriptDir "lib"
    if (Test-Path $libSource) {
        Copy-Item -Path "$libSource\*" -Destination $script:LibDir -Force -Recurse
        Write-Host "    Installed: lib\*.ps1" -ForegroundColor Gray
    }
    
    # Copy templates
    $templatesSource = Join-Path $script:ScriptDir "templates"
    if (Test-Path $templatesSource) {
        Copy-Item -Path "$templatesSource\*" -Destination $script:TemplatesDir -Force -Recurse
        Write-Host "    Installed: templates\*" -ForegroundColor Gray
    }
    
    Write-Log -Level "SUCCESS" -Message "Ralph scripts installed to $script:RalphHome"
}

function Install-Commands {
    <#
    .SYNOPSIS
        Creates command wrappers in bin directory
    #>
    
    Write-Log -Level "INFO" -Message "Creating command wrappers..."
    
    # ralph.cmd - Main command (for CMD)
    $ralphCmd = @"
@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Ralph\ralph_loop.ps1" %*
"@
    $ralphCmd | Set-Content (Join-Path $script:BinDir "ralph.cmd") -Encoding ASCII
    
    # ralph-monitor.cmd
    $monitorCmd = @"
@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Ralph\ralph_monitor.ps1" %*
"@
    $monitorCmd | Set-Content (Join-Path $script:BinDir "ralph-monitor.cmd") -Encoding ASCII
    
    # ralph-setup.cmd
    $setupCmd = @"
@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Ralph\setup.ps1" %*
"@
    $setupCmd | Set-Content (Join-Path $script:BinDir "ralph-setup.cmd") -Encoding ASCII
    
    # ralph-import.cmd
    $importCmd = @"
@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Ralph\ralph_import.ps1" %*
"@
    $importCmd | Set-Content (Join-Path $script:BinDir "ralph-import.cmd") -Encoding ASCII
    
    # PowerShell wrappers (.ps1) for PowerShell users
    
    # ralph.ps1
    $ralphPs1 = @"
#Requires -Version 7.0
# Ralph for Claude Code - PowerShell Wrapper
`$RalphHome = Join-Path `$env:LOCALAPPDATA "Ralph"
& (Join-Path `$RalphHome "ralph_loop.ps1") @args
"@
    $ralphPs1 | Set-Content (Join-Path $script:BinDir "ralph.ps1") -Encoding UTF8
    
    # ralph-monitor.ps1
    $monitorPs1 = @"
#Requires -Version 7.0
# Ralph Monitor - PowerShell Wrapper
`$RalphHome = Join-Path `$env:LOCALAPPDATA "Ralph"
& (Join-Path `$RalphHome "ralph_monitor.ps1") @args
"@
    $monitorPs1 | Set-Content (Join-Path $script:BinDir "ralph-monitor.ps1") -Encoding UTF8
    
    # ralph-setup.ps1
    $setupPs1 = @"
#Requires -Version 7.0
# Ralph Setup - PowerShell Wrapper
`$RalphHome = Join-Path `$env:LOCALAPPDATA "Ralph"
& (Join-Path `$RalphHome "setup.ps1") @args
"@
    $setupPs1 | Set-Content (Join-Path $script:BinDir "ralph-setup.ps1") -Encoding UTF8
    
    # ralph-import.ps1
    $importPs1 = @"
#Requires -Version 7.0
# Ralph Import - PowerShell Wrapper
`$RalphHome = Join-Path `$env:LOCALAPPDATA "Ralph"
& (Join-Path `$RalphHome "ralph_import.ps1") @args
"@
    $importPs1 | Set-Content (Join-Path $script:BinDir "ralph-import.ps1") -Encoding UTF8
    
    # ralph-prd.cmd
    $prdCmd = @"
@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Ralph\ralph-prd.ps1" %*
"@
    $prdCmd | Set-Content (Join-Path $script:BinDir "ralph-prd.cmd") -Encoding ASCII
    
    # ralph-prd.ps1
    $prdPs1 = @"
#Requires -Version 7.0
# Ralph PRD Parser - PowerShell Wrapper
`$RalphHome = Join-Path `$env:LOCALAPPDATA "Ralph"
& (Join-Path `$RalphHome "ralph-prd.ps1") @args
"@
    $prdPs1 | Set-Content (Join-Path $script:BinDir "ralph-prd.ps1") -Encoding UTF8
    
    Write-Log -Level "SUCCESS" -Message "Command wrappers created in $script:BinDir"
}

function Add-ToPath {
    <#
    .SYNOPSIS
        Adds Ralph bin directory to user PATH
    #>
    
    Write-Log -Level "INFO" -Message "Checking PATH configuration..."
    
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($currentPath -notlike "*$($script:BinDir)*") {
        Write-Log -Level "INFO" -Message "Adding $($script:BinDir) to user PATH..."
        
        # Add to user PATH (permanent)
        $newPath = "$($script:BinDir);$currentPath"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        
        # Also update current session
        $env:PATH = "$($script:BinDir);$env:PATH"
        
        Write-Log -Level "SUCCESS" -Message "PATH updated successfully"
        Write-Host ""
        Write-Host "NOTE: You may need to restart your terminal for PATH changes to take effect." -ForegroundColor Yellow
    }
    else {
        Write-Log -Level "SUCCESS" -Message "$($script:BinDir) is already in PATH"
    }
}

function Remove-FromPath {
    <#
    .SYNOPSIS
        Removes Ralph bin directory from user PATH
    #>
    
    Write-Log -Level "INFO" -Message "Removing from PATH..."
    
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($currentPath -like "*$($script:BinDir)*") {
        $pathParts = $currentPath -split ';' | Where-Object { $_ -ne $script:BinDir -and $_ -ne "" }
        $newPath = $pathParts -join ';'
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Log -Level "SUCCESS" -Message "Removed from PATH"
    }
    else {
        Write-Log -Level "INFO" -Message "Ralph bin directory was not in PATH"
    }
}

function Uninstall-Ralph {
    <#
    .SYNOPSIS
        Removes Ralph installation
    #>
    
    Write-Log -Level "INFO" -Message "Uninstalling Ralph for Claude Code..."
    
    # Remove from PATH
    Remove-FromPath
    
    # Remove installation directory
    if (Test-Path $script:RalphHome) {
        Remove-Item -Path $script:RalphHome -Recurse -Force
        Write-Log -Level "SUCCESS" -Message "Removed $($script:RalphHome)"
    }
    else {
        Write-Log -Level "INFO" -Message "Installation directory not found"
    }
    
    Write-Host ""
    Write-Log -Level "SUCCESS" -Message "Ralph for Claude Code uninstalled successfully"
    Write-Host ""
}

function Install-Ralph {
    <#
    .SYNOPSIS
        Main installation function
    #>
    
    Write-Host ""
    Write-Host "Installing Ralph for Claude Code globally..." -ForegroundColor Cyan
    Write-Host ""
    
    # Check dependencies
    if (-not (Test-Dependencies)) {
        exit 1
    }
    
    # Create directories
    New-InstallDirs
    
    # Install scripts
    Install-Scripts
    
    # Create command wrappers
    Install-Commands
    
    # Update PATH
    Add-ToPath
    
    # Success message
    Write-Host ""
    Write-Log -Level "SUCCESS" -Message "Ralph for Claude Code installed successfully!"
    Write-Host ""
    Write-Host "Global commands available:" -ForegroundColor Cyan
    Write-Host "  ralph -Monitor           Start Ralph with monitoring"
    Write-Host "  ralph -Help              Show Ralph options"
    Write-Host "  ralph-setup my-project   Create new Ralph project"
    Write-Host "  ralph-import prd.md      Convert PRD to Ralph project"
    Write-Host "  ralph-prd prd.md         Parse PRD to task-plan format"
    Write-Host "  ralph-monitor            Manual monitoring dashboard"
    Write-Host ""
    Write-Host "Quick start:" -ForegroundColor Cyan
    Write-Host "  1. ralph-setup my-awesome-project"
    Write-Host "  2. cd my-awesome-project"
    Write-Host "  3. # Edit PROMPT.md with your requirements"
    Write-Host "  4. ralph -Monitor"
    Write-Host ""
    Write-Host "Installation paths:" -ForegroundColor Gray
    Write-Host "  Commands:  $($script:BinDir)"
    Write-Host "  Scripts:   $($script:RalphHome)"
    Write-Host "  Templates: $($script:TemplatesDir)"
    Write-Host ""
}

# Main entry point
if ($Help) {
    Show-Help
    exit 0
}

if ($Uninstall) {
    Uninstall-Ralph
    exit 0
}

Install-Ralph
