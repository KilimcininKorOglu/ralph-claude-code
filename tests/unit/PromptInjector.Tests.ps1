<#
.SYNOPSIS
    Unit tests for PromptInjector.ps1 module
#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$lib = Join-Path (Split-Path -Parent (Split-Path -Parent $here)) "lib"
. "$lib\PromptInjector.ps1"

Describe "PromptInjector Module" {
    BeforeEach {
        $script:testDir = Join-Path $env:TEMP "hermes-prompt-test-$(Get-Random)"
        New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
        
        $promptContent = @"
# Project Instructions

This is the main prompt file.

## Guidelines

Follow best practices.
"@
        Set-Content -Path (Join-Path $script:testDir "PROMPT.md") -Value $promptContent -Encoding UTF8
        
        $script:testTask = @{
            TaskId = "T001"
            Name = "Create Login Form"
            Description = "Build a login form with email and password"
            Priority = "P1"
            FeatureId = "F001"
            FilesToTouch = @("src/Login.tsx", "src/login.css")
            Dependencies = @()
            SuccessCriteria = @("Form renders", "Validation works")
            TechnicalDetails = "Use React Hook Form"
        }
    }
    
    AfterEach {
        Remove-Item -Recurse -Force $script:testDir -ErrorAction SilentlyContinue
    }
    
    Context "Get-PromptPath" {
        It "Returns correct path" {
            $path = Get-PromptPath -BasePath $script:testDir
            $path | Should Be (Join-Path $script:testDir "PROMPT.md")
        }
    }
    
    Context "Test-PromptExists" {
        It "Returns true when PROMPT.md exists" {
            Test-PromptExists -BasePath $script:testDir | Should Be $true
        }
        
        It "Returns false when PROMPT.md does not exist" {
            Test-PromptExists -BasePath "C:\nonexistent" | Should Be $false
        }
    }
    
    Context "Get-TaskPromptSection" {
        It "Generates section with task ID" {
            $section = Get-TaskPromptSection -Task $script:testTask
            $section | Should Match "T001"
        }
        
        It "Includes task name" {
            $section = Get-TaskPromptSection -Task $script:testTask
            $section | Should Match "Create Login Form"
        }
        
        It "Includes files to touch" {
            $section = Get-TaskPromptSection -Task $script:testTask
            $section | Should Match "src/Login.tsx"
        }
        
        It "Includes success criteria" {
            $section = Get-TaskPromptSection -Task $script:testTask
            $section | Should Match "Form renders"
        }
        
        It "Includes HERMES_STATUS example" {
            $section = Get-TaskPromptSection -Task $script:testTask
            $section | Should Match "---HERMES_STATUS---"
        }
        
        It "Has start and end markers" {
            $section = Get-TaskPromptSection -Task $script:testTask
            $section | Should Match "HERMES_TASK_START"
            $section | Should Match "HERMES_TASK_END"
        }
    }
    
    Context "Add-TaskToPrompt" {
        It "Adds task section to PROMPT.md" {
            Add-TaskToPrompt -Task $script:testTask -BasePath $script:testDir | Should Be $true
            
            $content = Get-Content (Join-Path $script:testDir "PROMPT.md") -Raw
            $content | Should Match "HERMES_TASK_START"
            $content | Should Match "T001"
        }
        
        It "Updates existing task section" {
            $newTask = @{
                TaskId = "T002"
                Name = "New Task"
                Description = "Test"
                Priority = "P1"
                FeatureId = "F001"
                FilesToTouch = @()
                Dependencies = @()
                SuccessCriteria = @()
                TechnicalDetails = ""
            }
            
            Add-TaskToPrompt -Task $script:testTask -BasePath $script:testDir
            Remove-TaskFromPrompt -BasePath $script:testDir
            Add-TaskToPrompt -Task $newTask -BasePath $script:testDir | Should Be $true
            
            $content = Get-Content (Join-Path $script:testDir "PROMPT.md") -Raw
            $content | Should Match "T002"
            ([regex]::Matches($content, "HERMES_TASK_START")).Count | Should Be 1
        }
    }
    
    Context "Get-CurrentTaskFromPrompt" {
        It "Returns current task ID" {
            Add-TaskToPrompt -Task $script:testTask -BasePath $script:testDir
            
            $taskId = Get-CurrentTaskFromPrompt -BasePath $script:testDir
            $taskId | Should Not BeNullOrEmpty
        }
    }
    
    Context "Test-TaskSectionExists" {
        It "Returns true when section exists" {
            Add-TaskToPrompt -Task $script:testTask -BasePath $script:testDir
            Test-TaskSectionExists -BasePath $script:testDir | Should Be $true
        }
    }
    
    Context "Remove-TaskFromPrompt" {
        It "Removes task section" {
            Add-TaskToPrompt -Task $script:testTask -BasePath $script:testDir
            Remove-TaskFromPrompt -BasePath $script:testDir | Should Be $true
            
            $content = Get-Content (Join-Path $script:testDir "PROMPT.md") -Raw
            $content | Should Not Match "HERMES_TASK_START"
        }
        
        It "Preserves original content" {
            Add-TaskToPrompt -Task $script:testTask -BasePath $script:testDir
            Remove-TaskFromPrompt -BasePath $script:testDir
            
            $content = Get-Content (Join-Path $script:testDir "PROMPT.md") -Raw
            $content | Should Match "Project Instructions"
        }
    }
    
    Context "Get-MinimalTaskPrompt" {
        It "Generates compact prompt" {
            $minimal = Get-MinimalTaskPrompt -Task $script:testTask
            ($minimal.Length -lt 1000) | Should Be $true
        }
        
        It "Includes task ID and name" {
            $minimal = Get-MinimalTaskPrompt -Task $script:testTask
            $minimal | Should Match "T001"
            $minimal | Should Match "Create Login Form"
        }
    }
    
    Context "Backup-Prompt and Restore-Prompt" {
        It "Creates backup" {
            $backupPath = Backup-Prompt -BasePath $script:testDir
            $backupPath | Should Not BeNullOrEmpty
            Test-Path $backupPath | Should Be $true
        }
        
        It "Restores from backup" {
            $backupPath = Backup-Prompt -BasePath $script:testDir
            
            "Modified content" | Set-Content (Join-Path $script:testDir "PROMPT.md")
            
            Restore-Prompt -BackupPath $backupPath -BasePath $script:testDir | Should Be $true
            
            $content = Get-Content (Join-Path $script:testDir "PROMPT.md") -Raw
            $content | Should Match "Project Instructions"
        }
    }
    
    Context "Get-LatestBackup" {
        It "Returns most recent backup" {
            Backup-Prompt -BasePath $script:testDir
            Start-Sleep -Milliseconds 100
            $latest = Backup-Prompt -BasePath $script:testDir
            
            $found = Get-LatestBackup -BasePath $script:testDir
            $found | Should Be $latest
        }
    }
}
