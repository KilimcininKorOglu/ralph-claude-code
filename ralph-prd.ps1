<#
.SYNOPSIS
    Ralph PRD Parser - Convert PRD to task-plan format
.DESCRIPTION
    Reads a PRD file and uses AI to generate task files in task-plan format
.EXAMPLE
    ralph-prd docs/PRD.md
    ralph-prd docs/PRD.md -AI claude
    ralph-prd docs/PRD.md -AI droid -DryRun
    ralph-prd -List
#>

param(
    [Parameter(Position = 0)]
    [string]$PrdFile,
    
    [ValidateSet("claude", "droid", "aider", "auto")]
    [string]$AI = "auto",
    
    [switch]$List,
    
    [switch]$DryRun,
    
    [string]$OutputDir = "tasks",
    
    [int]$Timeout = 1200,
    
    [int]$MaxRetries = 10
)

$ErrorActionPreference = "Stop"

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import AIProvider module
. "$scriptDir\lib\AIProvider.ps1"

# Get prompt template path
$promptTemplatePath = "$scriptDir\lib\prompts\prd-parser.md"

function Show-Usage {
    Write-Host ""
    Write-Host "Ralph PRD Parser" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  ralph-prd <prd-file> [-AI <provider>] [-DryRun] [-OutputDir <dir>]"
    Write-Host "  ralph-prd -List"
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  <prd-file>     Path to PRD markdown file"
    Write-Host "  -AI            AI provider: claude, droid, aider, auto (default: auto)"
    Write-Host "  -DryRun        Show what would be created without writing files"
    Write-Host "  -OutputDir     Output directory (default: tasks)"
    Write-Host "  -Timeout       AI timeout in seconds (default: 1200)"
    Write-Host "  -MaxRetries    Max retry attempts (default: 10)"
    Write-Host "  -List          List available AI providers"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  ralph-prd docs/PRD.md"
    Write-Host "  ralph-prd docs/PRD.md -AI claude"
    Write-Host "  ralph-prd docs/PRD.md -DryRun"
    Write-Host ""
}

function Write-FilePreview {
    param(
        [array]$Files
    )
    
    Write-Host ""
    Write-Host "Files to create:" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($file in $Files) {
        $lines = ($file.Content -split "`n").Count
        Write-Host "  [+] $($file.FileName)" -ForegroundColor Green -NoNewline
        Write-Host " ($lines lines)" -ForegroundColor Gray
    }
    
    Write-Host ""
}

function Write-TaskFiles {
    param(
        [array]$Files,
        [string]$OutputDir
    )
    
    # Create output directory if not exists
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Host "[OK] Created directory: $OutputDir" -ForegroundColor Green
    }
    
    $created = @()
    
    foreach ($file in $Files) {
        # Extract just filename from path like "tasks/001-feature.md"
        $fileName = Split-Path -Leaf $file.FileName
        $filePath = Join-Path $OutputDir $fileName
        
        # Write file
        $file.Content | Out-File -FilePath $filePath -Encoding UTF8 -Force
        
        # Extract stats
        $featureMatch = [regex]::Match($file.Content, "Feature ID:\s*(F\d+)")
        $taskMatches = [regex]::Matches($file.Content, "### (T\d+):")
        
        $featureId = if ($featureMatch.Success) { $featureMatch.Groups[1].Value } else { "-" }
        $taskRange = if ($taskMatches.Count -gt 0) { 
            $first = $taskMatches[0].Groups[1].Value
            $last = $taskMatches[$taskMatches.Count - 1].Groups[1].Value
            "$first-$last"
        }
        else { "" }
        
        $created += @{
            FileName  = $fileName
            FeatureId = $featureId
            TaskRange = $taskRange
        }
        
        if ($taskRange) {
            Write-Host "[OK] Created: $fileName ($featureId, $taskRange)" -ForegroundColor Green
        }
        else {
            Write-Host "[OK] Created: $fileName" -ForegroundColor Green
        }
    }
    
    return $created
}

function Get-Summary {
    param(
        [array]$Files
    )
    
    $featureCount = 0
    $taskCount = 0
    $totalEffort = 0
    
    foreach ($file in $Files) {
        if ($file.FileName -notmatch "status") {
            $featureCount++
            
            $taskMatches = [regex]::Matches($file.Content, "### T\d+:")
            $taskCount += $taskMatches.Count
            
            # Extract effort estimates
            $effortMatches = [regex]::Matches($file.Content, "Estimated Effort:\s*([\d.]+)\s*day")
            foreach ($match in $effortMatches) {
                $totalEffort += [double]$match.Groups[1].Value
            }
        }
    }
    
    return @{
        Features = $featureCount
        Tasks    = $taskCount
        Days     = $totalEffort
    }
}

# Main execution

# List mode
if ($List) {
    Write-AIProviderList
    exit 0
}

# Check if PRD file provided
if (-not $PrdFile) {
    Show-Usage
    exit 1
}

# Check if PRD file exists
if (-not (Test-Path $PrdFile)) {
    Write-Error "PRD file not found: $PrdFile"
    exit 1
}

# Check prompt template exists
if (-not (Test-Path $promptTemplatePath)) {
    Write-Error "Prompt template not found: $promptTemplatePath"
    exit 1
}

Write-Host ""
Write-Host "Ralph PRD Parser" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host ""

# Read and check PRD size
Write-Host "[INFO] Reading PRD: $PrdFile" -ForegroundColor Cyan
$prdInfo = Test-PrdSize -PrdFile $PrdFile

# Determine AI provider
if ($AI -eq "auto") {
    $AI = Get-AutoProvider
    if (-not $AI) {
        Write-Error "No AI provider found. Install claude, droid, or aider."
        exit 1
    }
}

# Verify provider is available
if (-not (Test-AIProvider -Provider $AI)) {
    Write-Error "AI provider '$AI' is not installed or not in PATH"
    exit 1
}

Write-Host "[INFO] Using AI: $AI" -ForegroundColor Cyan

# Load prompt template
$promptTemplate = Get-Content $promptTemplatePath -Raw

# Replace placeholder with PRD content
$fullPrompt = $promptTemplate -replace '\{PRD_CONTENT\}', $prdInfo.Content

# Call AI with retry
Write-Host "[INFO] Parsing PRD with $AI..." -ForegroundColor Cyan
Write-Host ""

$result = Invoke-AIWithRetry -Provider $AI `
    -PromptText $fullPrompt `
    -Content $prdInfo.Content `
    -InputFile $PrdFile `
    -MaxRetries $MaxRetries `
    -TimeoutSeconds $Timeout

if (-not $result.Success) {
    Write-Error "Failed to parse PRD: $($result.Error)"
    exit 1
}

Write-Host ""

# DryRun mode
if ($DryRun) {
    Write-FilePreview -Files $result.Files
    
    $summary = Get-Summary -Files $result.Files
    
    Write-Host "Summary (DryRun):" -ForegroundColor Yellow
    Write-Host "  Features: $($summary.Features)"
    Write-Host "  Tasks: $($summary.Tasks)"
    Write-Host "  Estimated: $($summary.Days) days"
    Write-Host ""
    Write-Host "Run without -DryRun to create files." -ForegroundColor Cyan
    exit 0
}

# Write files
$created = Write-TaskFiles -Files $result.Files -OutputDir $OutputDir

Write-Host ""

# Show summary
$summary = Get-Summary -Files $result.Files

Write-Host "Summary:" -ForegroundColor Green
Write-Host "  Features: $($summary.Features)"
Write-Host "  Tasks: $($summary.Tasks)"
Write-Host "  Estimated: $($summary.Days) days"
Write-Host "  Attempts: $($result.Attempts)"
Write-Host ""
Write-Host "Next: Run 'ralph -TaskMode -AutoBranch -AutoCommit' to start" -ForegroundColor Cyan
Write-Host ""
