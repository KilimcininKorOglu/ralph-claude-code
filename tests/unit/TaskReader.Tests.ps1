<#
.SYNOPSIS
    Unit tests for TaskReader.ps1 module
#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$lib = Join-Path (Split-Path -Parent (Split-Path -Parent $here)) "lib"
. "$lib\TaskReader.ps1"

function New-TestTasksDirectory {
    param([string]$BasePath)
    
    $hermesDir = Join-Path $BasePath ".hermes"
    $tasksDir = Join-Path $hermesDir "tasks"
    New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null
    
    $featureContent = @"
# Feature 1: User Registration

**Feature ID:** F001
**Feature Name:** User Registration
**Priority:** P1 - Critical
**Status:** IN_PROGRESS
**Target Version:** 1.0.0
**Estimated Duration:** 5 days

## Overview

User registration functionality.

## Tasks

### T001: Registration Form UI

**Status:** NOT_STARTED
**Priority:** P1
**Estimated Effort:** 1 day

#### Description
Create the registration form with email and password fields.

#### Technical Details
Use React Hook Form for validation.

#### Files to Touch
- src/components/RegisterForm.tsx (new)
- src/styles/register.css (new)

#### Dependencies
- None

#### Success Criteria
- [ ] Form renders correctly
- [ ] Validation works
- [ ] Responsive design

---

### T002: API Integration

**Status:** NOT_STARTED
**Priority:** P2
**Estimated Effort:** 2 days

#### Description
Connect form to backend API.

#### Files to Touch
- src/api/auth.ts (update)

#### Dependencies
- T001

#### Success Criteria
- [ ] API calls work
- [ ] Error handling

---

### T003: Email Verification

**Status:** COMPLETED
**Priority:** P2
**Estimated Effort:** 1 day

#### Description
Send verification email after registration.

#### Dependencies
- T001
- T002

#### Success Criteria
- [x] Email sent
- [x] Link works

"@
    Set-Content -Path (Join-Path $tasksDir "001-user-registration.md") -Value $featureContent -Encoding UTF8
    
    return $BasePath
}

Describe "TaskReader Module" {
    
    Context "Test-TasksDirectoryExists" {
        It "Returns true when tasks directory exists" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            Test-TasksDirectoryExists -BasePath $testDir | Should Be $true
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Returns false when tasks directory does not exist" {
            Test-TasksDirectoryExists -BasePath "C:\nonexistent-path-xyz" | Should Be $false
        }
    }
    
    Context "Get-FeatureFiles" {
        It "Returns feature files from tasks directory" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $files = Get-FeatureFiles -BasePath $testDir
            $files.Count | Should Be 1
            $files[0].Name | Should Be "001-user-registration.md"
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Returns empty array for nonexistent directory" {
            $files = Get-FeatureFiles -BasePath "C:\nonexistent-path-xyz"
            $files | Should BeNullOrEmpty
        }
    }
    
    Context "Read-FeatureFile" {
        It "Parses feature ID correctly" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            $tasksDir = Join-Path $testDir ".hermes\tasks"
            
            $feature = Read-FeatureFile -FilePath (Join-Path $tasksDir "001-user-registration.md")
            $feature.FeatureId | Should Be "F001"
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Parses feature name correctly" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            $tasksDir = Join-Path $testDir ".hermes\tasks"
            
            $feature = Read-FeatureFile -FilePath (Join-Path $tasksDir "001-user-registration.md")
            $feature.FeatureName | Should Be "User Registration"
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Parses feature status correctly" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            $tasksDir = Join-Path $testDir ".hermes\tasks"
            
            $feature = Read-FeatureFile -FilePath (Join-Path $tasksDir "001-user-registration.md")
            $feature.Status | Should Be "IN_PROGRESS"
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Parses tasks correctly" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            $tasksDir = Join-Path $testDir ".hermes\tasks"
            
            $feature = Read-FeatureFile -FilePath (Join-Path $tasksDir "001-user-registration.md")
            $feature.Tasks.Count | Should Be 3
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
    }
    
    Context "Get-AllTasks" {
        It "Returns all tasks from all feature files" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $tasks = Get-AllTasks -BasePath $testDir
            $tasks.Count | Should Be 3
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Tasks have correct IDs" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $tasks = Get-AllTasks -BasePath $testDir
            $tasks[0].TaskId | Should Be "T001"
            $tasks[1].TaskId | Should Be "T002"
            $tasks[2].TaskId | Should Be "T003"
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
    }
    
    Context "Get-TaskById" {
        It "Returns task by ID" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $task = Get-TaskById -TaskId "T001" -BasePath $testDir
            $task.TaskId | Should Be "T001"
            $task.Name | Should Match "Registration Form"
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Returns null for nonexistent task" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $task = Get-TaskById -TaskId "T999" -BasePath $testDir
            $task | Should BeNullOrEmpty
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
    }
    
    Context "Get-TasksByStatus" {
        It "Returns NOT_STARTED tasks" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $tasks = Get-TasksByStatus -Status "NOT_STARTED" -BasePath $testDir
            $tasks.Count | Should Be 2
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Returns COMPLETED tasks" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $tasks = Get-TasksByStatus -Status "COMPLETED" -BasePath $testDir
            $tasks.Count | Should Be 1
            $tasks[0].TaskId | Should Be "T003"
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
    }
    
    Context "Test-TaskDependenciesMet" {
        It "Returns true for task with no dependencies" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $task = Get-TaskById -TaskId "T001" -BasePath $testDir
            Test-TaskDependenciesMet -Task $task -BasePath $testDir | Should Be $true
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Returns false for task with unmet dependencies" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $task = Get-TaskById -TaskId "T002" -BasePath $testDir
            Test-TaskDependenciesMet -Task $task -BasePath $testDir | Should Be $false
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
    }
    
    Context "Get-NextTask" {
        It "Returns first available task" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $task = Get-NextTask -BasePath $testDir
            $task.TaskId | Should Be "T001"
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Returns null when all tasks completed" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            $tasksDir = Join-Path $testDir ".hermes\tasks"
            New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null
            
            $content = @"
# Feature 1: Done

**Feature ID:** F001
**Status:** COMPLETED

### T001: Done Task

**Status:** COMPLETED
"@
            Set-Content -Path (Join-Path $tasksDir "001-done.md") -Value $content -Encoding UTF8
            
            $task = Get-NextTask -BasePath $testDir
            $task | Should BeNullOrEmpty
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
    }
    
    Context "Get-TaskProgress" {
        It "Returns correct total count" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $progress = Get-TaskProgress -BasePath $testDir
            $progress.Total | Should Be 3
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Returns correct completed count" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $progress = Get-TaskProgress -BasePath $testDir
            $progress.Completed | Should Be 1
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Returns correct not started count" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $progress = Get-TaskProgress -BasePath $testDir
            $progress.NotStarted | Should Be 2
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Calculates percentage correctly" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $progress = Get-TaskProgress -BasePath $testDir
            ($progress.Percentage -ge 33) | Should Be $true
            ($progress.Percentage -le 34) | Should Be $true
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
    }
    
    Context "Get-FeatureProgress" {
        It "Returns correct progress for feature" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $progress = Get-FeatureProgress -FeatureId "F001" -BasePath $testDir
            $progress.Total | Should Be 3
            $progress.Completed | Should Be 1
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "IsComplete is false when tasks remain" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $progress = Get-FeatureProgress -FeatureId "F001" -BasePath $testDir
            $progress.IsComplete | Should Be $false
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
    }
    
    Context "Task Parsing Details" {
        It "Parses files to touch correctly" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $task = Get-TaskById -TaskId "T001" -BasePath $testDir
            ($task.FilesToTouch.Count -ge 2) | Should Be $true
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Parses dependencies correctly" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $task = Get-TaskById -TaskId "T002" -BasePath $testDir
            ($task.Dependencies -contains "T001") | Should Be $true
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
        
        It "Parses success criteria correctly" {
            $testDir = Join-Path $env:TEMP "hermes-tr-test-$(Get-Random)"
            New-TestTasksDirectory -BasePath $testDir
            
            $task = Get-TaskById -TaskId "T001" -BasePath $testDir
            ($task.SuccessCriteria.Count -ge 2) | Should Be $true
            
            Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
        }
    }
}
