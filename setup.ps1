#Requires -Version 7.0

<#
.SYNOPSIS
    Hermes Project Setup - Windows PowerShell Version
.DESCRIPTION
    Creates a new Hermes project with standard structure and templates.
.PARAMETER ProjectName
    Name of the project to create. Use "init" to initialize in current directory.
.PARAMETER Help
    Show help message
.EXAMPLE
    .\setup.ps1 my-awesome-project
.EXAMPLE
    hermes-setup my-awesome-project
.EXAMPLE
    hermes-setup init
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectName = "my-project",
    
    [Alias('h')]
    [switch]$Help
)

# Get Hermes home directory
$script:HermesHome = if ($env:HERMES_HOME) { 
    $env:HERMES_HOME 
} 
else { 
    Join-Path $env:LOCALAPPDATA "Hermes" 
}

$script:TemplatesDir = Join-Path $script:HermesHome "templates"
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Show-Help {
    Write-Host ""
    Write-Host "Hermes Project Setup" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: hermes-setup [PROJECT_NAME | init]" -ForegroundColor White
    Write-Host ""
    Write-Host "Arguments:" -ForegroundColor Yellow
    Write-Host "    PROJECT_NAME    Name of the project to create in new directory"
    Write-Host "    init            Initialize Hermes in current directory"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "    hermes-setup my-awesome-project    # Create new directory"
    Write-Host "    cd my-awesome-project"
    Write-Host "    hermes"
    Write-Host ""
    Write-Host "    hermes-setup init                  # Initialize in current directory"
    Write-Host "    hermes"
    Write-Host ""
    Write-Host "This creates:" -ForegroundColor Gray
    Write-Host "    .hermes/            Hermes workspace (gitignored)"
    Write-Host "    .hermes/PROMPT.md   AI instructions"
    Write-Host "    .hermes/tasks/      Task files (created by hermes-prd)"
    Write-Host "    .hermes/logs/       Execution logs"
    Write-Host "    .hermes/docs/       PRD and documentation"
    Write-Host ""
}

function Get-TemplatesPath {
    <#
    .SYNOPSIS
        Finds the templates directory
    #>
    
    # First check Hermes home
    if (Test-Path $script:TemplatesDir) {
        return $script:TemplatesDir
    }
    
    # Check relative to script
    $localTemplates = Join-Path $script:ScriptDir "templates"
    if (Test-Path $localTemplates) {
        return $localTemplates
    }
    
    # Check parent directory (for development)
    $parentTemplates = Join-Path (Split-Path $script:ScriptDir -Parent) "templates"
    if (Test-Path $parentTemplates) {
        return $parentTemplates
    }
    
    return $null
}

function New-HermesProject {
    <#
    .SYNOPSIS
        Creates a new Hermes project
    #>
    param([string]$Name)
    
    # Check if initializing in current directory
    $initMode = ($Name -eq "init" -or $Name -eq ".")
    
    if ($initMode) {
        $projectPath = Get-Location
        $displayName = Split-Path $projectPath -Leaf
        Write-Host ""
        Write-Host "Hermes Autonomous Agent - Initializing in: $displayName" -ForegroundColor Cyan
        Write-Host ""
    }
    else {
        $displayName = $Name
        Write-Host ""
        Write-Host "Hermes Autonomous Agent - Setting up project: $Name" -ForegroundColor Cyan
        Write-Host ""
    }
    
    # Find templates
    $templatesPath = Get-TemplatesPath
    
    if (-not $templatesPath) {
        Write-Host "[ERROR] Templates not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Expected locations:" -ForegroundColor Yellow
        Write-Host "  - $script:TemplatesDir"
        Write-Host "  - $(Join-Path $script:ScriptDir 'templates')"
        Write-Host ""
        Write-Host "Please run install.ps1 first to install Hermes globally."
        Write-Host ""
        exit 1
    }
    
    Write-Host "Using templates from: $templatesPath" -ForegroundColor Gray
    
    if (-not $initMode) {
        # Check if directory already exists
        if (Test-Path $Name) {
            Write-Host "[ERROR] Directory '$Name' already exists!" -ForegroundColor Red
            Write-Host ""
            Write-Host "Please choose a different name or remove the existing directory."
            Write-Host ""
            exit 1
        }
        
        # Create project directory
        New-Item -ItemType Directory -Path $Name -Force | Out-Null
        Write-Host "[OK] Created directory: $Name" -ForegroundColor Green
        
        # Change to project directory
        Push-Location $Name
    }
    else {
        # Check if .hermes already exists
        if (Test-Path ".hermes") {
            Write-Host "[WARN] .hermes/ already exists in this directory" -ForegroundColor Yellow
            Write-Host ""
            $response = Read-Host "Overwrite existing Hermes configuration? (y/N)"
            if ($response -ne "y" -and $response -ne "Y") {
                Write-Host "Aborted." -ForegroundColor Gray
                exit 0
            }
        }
    }
    
    try {
        # Create .hermes directory structure
        $hermesDir = ".hermes"
        New-Item -ItemType Directory -Path $hermesDir -Force | Out-Null
        
        $directories = @(
            "$hermesDir\tasks",
            "$hermesDir\logs",
            "$hermesDir\docs"
        )
        
        foreach ($dir in $directories) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Write-Host "[OK] Created: .hermes/ directory structure" -ForegroundColor Green
        
        # Copy PROMPT.md template to .hermes/
        $promptSource = Join-Path $templatesPath "PROMPT.md"
        $promptDest = Join-Path $hermesDir "PROMPT.md"
        if (Test-Path $promptSource) {
            Copy-Item -Path $promptSource -Destination $promptDest -Force
            Write-Host "[OK] Created: .hermes/PROMPT.md" -ForegroundColor Green
        }
        else {
            $content = Get-DefaultPromptTemplate -ProjectName $displayName
            $content | Set-Content $promptDest -Encoding UTF8
            Write-Host "[OK] Created: .hermes/PROMPT.md (default template)" -ForegroundColor Green
        }
        
        # Create README.md and .gitignore only for new projects (not init mode)
        if (-not $initMode) {
            # Create README.md in project root
            $readme = Get-ProjectReadme -ProjectName $displayName
            $readme | Set-Content "README.md" -Encoding UTF8
            Write-Host "[OK] Created: README.md" -ForegroundColor Green
            
            # Create .gitignore with .hermes/ excluded
            $gitignore = Get-GitIgnoreContent
            $gitignore | Set-Content ".gitignore" -Encoding UTF8
            Write-Host "[OK] Created: .gitignore" -ForegroundColor Green
        }
        
        # Create project config if ConfigManager is available
        $configManagerPath = Join-Path $script:HermesHome "lib\ConfigManager.ps1"
        if (Test-Path $configManagerPath) {
            . $configManagerPath
            Initialize-ProjectConfig -BasePath "." -Force | Out-Null
            Write-Host "[OK] Created: .hermes/config.json" -ForegroundColor Green
        }
        
        # Initialize git repository (only for new projects)
        if (-not $initMode) {
            try {
                $gitOutput = git init 2>&1
                git add . 2>&1 | Out-Null
                git commit -m "Initial Hermes project setup" 2>&1 | Out-Null
                Write-Host "[OK] Initialized git repository" -ForegroundColor Green
            }
            catch {
                Write-Host "[WARN] Could not initialize git repository" -ForegroundColor Yellow
            }
        }
        else {
            # For init mode, just add .hermes to .gitignore if git exists
            $isGitRepo = Test-Path ".git"
            if ($isGitRepo) {
                # Check if .hermes is already in .gitignore
                $gitignorePath = ".gitignore"
                if (Test-Path $gitignorePath) {
                    $content = Get-Content $gitignorePath -Raw
                    if ($content -notmatch "\.hermes") {
                        Add-Content $gitignorePath "`n# Hermes workspace`n.hermes/"
                        Write-Host "[OK] Added .hermes/ to .gitignore" -ForegroundColor Green
                    }
                }
                else {
                    ".hermes/" | Set-Content $gitignorePath -Encoding UTF8
                    Write-Host "[OK] Created .gitignore with .hermes/" -ForegroundColor Green
                }
            }
        }
        
        # Success message
        Write-Host ""
        if ($initMode) {
            Write-Host "Hermes initialized successfully in current directory!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "  1. Copy your PRD: copy PRD.md .hermes/docs/PRD.md"
            Write-Host "  2. Parse PRD: hermes-prd .hermes/docs/PRD.md"
            Write-Host "  3. Start: hermes"
        }
        else {
            Write-Host "Project '$Name' created successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "  1. cd $Name"
            Write-Host "  2. Copy your PRD: copy PRD.md .hermes/docs/PRD.md"
            Write-Host "  3. Parse PRD: hermes-prd .hermes/docs/PRD.md"
            Write-Host "  4. Start: hermes"
        }
        Write-Host ""
    }
    finally {
        if (-not $initMode) {
            Pop-Location
        }
    }
}

function Get-DefaultPromptTemplate {
    param([string]$ProjectName)
    
    return @"
# Hermes Development Instructions

## Context
You are Hermes, an autonomous AI development agent working on the $ProjectName project.

## Current Objectives
1. Complete the current task from tasks/*.md
2. Follow the success criteria for each task
3. Run tests after implementation
4. Commit working changes with descriptive messages

## Key Principles
- ONE task per loop - focus on the current task only
- Search the codebase before assuming something isn't implemented
- Write comprehensive tests with clear documentation
- Commit working changes with descriptive messages

## Testing Guidelines
- LIMIT testing to ~20% of your total effort per loop
- PRIORITIZE: Implementation > Documentation > Tests
- Only write tests for NEW functionality you implement
- Focus on CORE functionality first

## Status Reporting

At the end of your response, include this status block:

``````
---HERMES_STATUS---
STATUS: IN_PROGRESS | COMPLETE | BLOCKED
EXIT_SIGNAL: false | true
RECOMMENDATION: <one line summary of what to do next>
---END_HERMES_STATUS---
``````

## File Structure
- tasks/: Task files with feature definitions
- src/: Source code implementation
- docs/: Project documentation

## Current Task
The current task will be injected below by Hermes Task Mode.
"@
}

function Get-ProjectReadme {
    param([string]$ProjectName)
    
    return @"
# $ProjectName

A Hermes-managed project for autonomous AI development.

## Getting Started

1. Create a PRD document (e.g., ``PRD.md``)
2. Run: ``hermes-prd PRD.md``
3. Run: ``hermes -TaskMode -AutoBranch -AutoCommit``

## Hermes Workspace

All Hermes files are stored in ``.hermes/`` folder (gitignored):

- ``.hermes/PROMPT.md`` - AI instructions
- ``.hermes/tasks/`` - Task files
- ``.hermes/logs/`` - Execution logs
- ``.hermes/docs/`` - PRD and documentation
- ``.hermes/config.json`` - Project configuration

## Commands

``````powershell
hermes-prd PRD.md                               # Parse PRD to tasks
hermes -TaskMode -AutoBranch -AutoCommit        # Run Task Mode
hermes -TaskStatus                              # Show task progress
hermes -TaskMode -Autonomous                    # Run without pausing
``````

## Created with Hermes Autonomous Agent

[Hermes](https://github.com/frankbria/hermes-claude-code) - Autonomous AI development loop
"@
}

function Get-GitIgnoreContent {
    return @"
# Hermes folder (AI workspace)
.hermes/

# Node modules (if applicable)
node_modules/

# Python (if applicable)
__pycache__/
*.pyc
.venv/
venv/

# OS files
.DS_Store
Thumbs.db
Desktop.ini

# IDE
.idea/
.vscode/
*.swp
*.swo
*~
"@
}

# Main entry point
if ($Help) {
    Show-Help
    exit 0
}

# Validate project name
if ($ProjectName -match '[<>:"/\\|?*]') {
    Write-Host ""
    Write-Host "[ERROR] Project name contains invalid characters: $ProjectName" -ForegroundColor Red
    Write-Host "        Avoid: < > : `" / \ | ? *"
    Write-Host ""
    exit 1
}

New-HermesProject -Name $ProjectName
