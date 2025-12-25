#Requires -Modules Pester

BeforeAll {
    . "$PSScriptRoot\..\..\lib\TaskReader.ps1"
}

Describe "TaskReader Module" {
    BeforeAll {
        # Create test tasks directory
        $script:TestDir = Join-Path $TestDrive "test-project"
        $script:TasksDir = Join-Path $script:TestDir "tasks"
        New-Item -ItemType Directory -Path $script:TasksDir -Force | Out-Null
        
        # Create test feature file
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
- `src/components/RegisterForm.tsx` (new)
- `src/styles/register.css` (new)

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
- `src/api/auth.ts` (update)

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
        
        Set-Content -Path (Join-Path $script:TasksDir "001-user-registration.md") -Value $featureContent -Encoding UTF8
    }
    
    Context "Test-TasksDirectoryExists" {
        It "Returns true when tasks directory exists" {
            Test-TasksDirectoryExists -BasePath $script:TestDir | Should -Be $true
        }
        
        It "Returns false when tasks directory does not exist" {
            Test-TasksDirectoryExists -BasePath "C:\nonexistent" | Should -Be $false
        }
    }
    
    Context "Get-FeatureFiles" {
        It "Returns feature files from tasks directory" {
            $files = Get-FeatureFiles -BasePath $script:TestDir
            $files.Count | Should -Be 1
            $files[0].Name | Should -Be "001-user-registration.md"
        }
        
        It "Returns empty array for nonexistent directory" {
            $files = Get-FeatureFiles -BasePath "C:\nonexistent"
            $files | Should -BeNullOrEmpty
        }
    }
    
    Context "Read-FeatureFile" {
        It "Parses feature ID correctly" {
            $feature = Read-FeatureFile -FilePath (Join-Path $script:TasksDir "001-user-registration.md")
            $feature.FeatureId | Should -Be "F001"
        }
        
        It "Parses feature name correctly" {
            $feature = Read-FeatureFile -FilePath (Join-Path $script:TasksDir "001-user-registration.md")
            $feature.FeatureName | Should -Be "User Registration"
        }
        
        It "Parses feature status correctly" {
            $feature = Read-FeatureFile -FilePath (Join-Path $script:TasksDir "001-user-registration.md")
            $feature.Status | Should -Be "IN_PROGRESS"
        }
        
        It "Parses tasks correctly" {
            $feature = Read-FeatureFile -FilePath (Join-Path $script:TasksDir "001-user-registration.md")
            $feature.Tasks.Count | Should -Be 3
        }
    }
    
    Context "Get-AllTasks" {
        It "Returns all tasks from all feature files" {
            $tasks = Get-AllTasks -BasePath $script:TestDir
            $tasks.Count | Should -Be 3
        }
        
        It "Tasks have correct IDs" {
            $tasks = Get-AllTasks -BasePath $script:TestDir
            $tasks[0].TaskId | Should -Be "T001"
            $tasks[1].TaskId | Should -Be "T002"
            $tasks[2].TaskId | Should -Be "T003"
        }
    }
    
    Context "Get-TaskById" {
        It "Returns task by ID" {
            $task = Get-TaskById -TaskId "T001" -BasePath $script:TestDir
            $task.TaskId | Should -Be "T001"
            $task.Name | Should -Match "Registration Form"
        }
        
        It "Returns null for nonexistent task" {
            $task = Get-TaskById -TaskId "T999" -BasePath $script:TestDir
            $task | Should -BeNullOrEmpty
        }
    }
    
    Context "Get-TasksByStatus" {
        It "Returns NOT_STARTED tasks" {
            $tasks = Get-TasksByStatus -Status "NOT_STARTED" -BasePath $script:TestDir
            $tasks.Count | Should -Be 2
        }
        
        It "Returns COMPLETED tasks" {
            $tasks = Get-TasksByStatus -Status "COMPLETED" -BasePath $script:TestDir
            $tasks.Count | Should -Be 1
            $tasks[0].TaskId | Should -Be "T003"
        }
    }
    
    Context "Test-TaskDependenciesMet" {
        It "Returns true for task with no dependencies" {
            $task = Get-TaskById -TaskId "T001" -BasePath $script:TestDir
            Test-TaskDependenciesMet -Task $task -BasePath $script:TestDir | Should -Be $true
        }
        
        It "Returns false for task with unmet dependencies" {
            $task = Get-TaskById -TaskId "T002" -BasePath $script:TestDir
            Test-TaskDependenciesMet -Task $task -BasePath $script:TestDir | Should -Be $false
        }
    }
    
    Context "Get-NextTask" {
        It "Returns first available task" {
            $task = Get-NextTask -BasePath $script:TestDir
            $task.TaskId | Should -Be "T001"
        }
        
        It "Returns null when all tasks completed" {
            # Create a directory with only completed tasks
            $completedDir = Join-Path $TestDrive "completed-project"
            $completedTasksDir = Join-Path $completedDir "tasks"
            New-Item -ItemType Directory -Path $completedTasksDir -Force | Out-Null
            
            $content = @"
# Feature 1: Done

**Feature ID:** F001
**Status:** COMPLETED

### T001: Done Task

**Status:** COMPLETED
"@
            Set-Content -Path (Join-Path $completedTasksDir "001-done.md") -Value $content -Encoding UTF8
            
            $task = Get-NextTask -BasePath $completedDir
            $task | Should -BeNullOrEmpty
        }
    }
    
    Context "Get-TaskProgress" {
        It "Returns correct total count" {
            $progress = Get-TaskProgress -BasePath $script:TestDir
            $progress.Total | Should -Be 3
        }
        
        It "Returns correct completed count" {
            $progress = Get-TaskProgress -BasePath $script:TestDir
            $progress.Completed | Should -Be 1
        }
        
        It "Returns correct not started count" {
            $progress = Get-TaskProgress -BasePath $script:TestDir
            $progress.NotStarted | Should -Be 2
        }
        
        It "Calculates percentage correctly" {
            $progress = Get-TaskProgress -BasePath $script:TestDir
            $progress.Percentage | Should -BeGreaterOrEqual 33
            $progress.Percentage | Should -BeLessOrEqual 34
        }
    }
    
    Context "Get-FeatureProgress" {
        It "Returns correct progress for feature" {
            $progress = Get-FeatureProgress -FeatureId "F001" -BasePath $script:TestDir
            $progress.Total | Should -Be 3
            $progress.Completed | Should -Be 1
        }
        
        It "IsComplete is false when tasks remain" {
            $progress = Get-FeatureProgress -FeatureId "F001" -BasePath $script:TestDir
            $progress.IsComplete | Should -Be $false
        }
    }
    
    Context "Task Parsing Details" {
        It "Parses files to touch correctly" {
            $task = Get-TaskById -TaskId "T001" -BasePath $script:TestDir
            $task.FilesToTouch.Count | Should -BeGreaterOrEqual 2
            $task.FilesToTouch | Should -Contain "src/components/RegisterForm.tsx"
        }
        
        It "Parses dependencies correctly" {
            $task = Get-TaskById -TaskId "T002" -BasePath $script:TestDir
            $task.Dependencies | Should -Contain "T001"
        }
        
        It "Parses success criteria correctly" {
            $task = Get-TaskById -TaskId "T001" -BasePath $script:TestDir
            $task.SuccessCriteria.Count | Should -BeGreaterOrEqual 2
        }
    }
}
