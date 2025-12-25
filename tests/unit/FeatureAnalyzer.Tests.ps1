#Requires -Modules Pester

# Load module before tests
. "$PSScriptRoot\..\..\lib\FeatureAnalyzer.ps1"
. "$PSScriptRoot\..\..\lib\AIProvider.ps1"

Describe "FeatureAnalyzer Module" {
    
    Context "Get-HighestFeatureId" {
        It "Should return 0 when no tasks directory" {
            $testDir = Join-Path $TestDrive "no-tasks"
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            
            $result = Get-HighestFeatureId -BasePath $testDir
            $result | Should Be 0
        }
        
        It "Should return 0 when tasks directory is empty" {
            $testDir = Join-Path $TestDrive "empty-tasks"
            $tasksDir = Join-Path $testDir "tasks"
            New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null
            
            $result = Get-HighestFeatureId -BasePath $testDir
            $result | Should Be 0
        }
        
        It "Should find highest Feature ID from files" {
            $testDir = Join-Path $TestDrive "with-tasks"
            $tasksDir = Join-Path $testDir "tasks"
            New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null
            
            # Create test files
            "**Feature ID:** F001" | Set-Content (Join-Path $tasksDir "001-test.md")
            "**Feature ID:** F003" | Set-Content (Join-Path $tasksDir "003-test.md")
            "**Feature ID:** F002" | Set-Content (Join-Path $tasksDir "002-test.md")
            
            $result = Get-HighestFeatureId -BasePath $testDir
            $result | Should Be 3
        }
    }
    
    Context "Get-HighestTaskId" {
        It "Should return 0 when no tasks exist" {
            $testDir = Join-Path $TestDrive "no-task-ids"
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            
            $result = Get-HighestTaskId -BasePath $testDir
            $result | Should Be 0
        }
        
        It "Should find highest Task ID across files" {
            $testDir = Join-Path $TestDrive "with-task-ids"
            $tasksDir = Join-Path $testDir "tasks"
            New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null
            
            $content1 = @"
# Feature 1
### T001: Task 1
### T002: Task 2
"@
            $content2 = @"
# Feature 2
### T003: Task 3
### T005: Task 5
### T004: Task 4
"@
            $content1 | Set-Content (Join-Path $tasksDir "001-test.md")
            $content2 | Set-Content (Join-Path $tasksDir "002-test.md")
            
            $result = Get-HighestTaskId -BasePath $testDir
            $result | Should Be 5
        }
    }
    
    Context "Get-NextIds" {
        It "Should return 1 for empty project" {
            $testDir = Join-Path $TestDrive "new-project"
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            
            $result = Get-NextIds -BasePath $testDir
            $result.NextFeatureId | Should Be 1
            $result.NextTaskId | Should Be 1
            $result.NextFeatureIdPadded | Should Be "001"
            $result.NextTaskIdPadded | Should Be "001"
        }
        
        It "Should continue from existing IDs" {
            $testDir = Join-Path $TestDrive "existing-project"
            $tasksDir = Join-Path $testDir "tasks"
            New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null
            
            $content = @"
**Feature ID:** F002
### T001: Task 1
### T005: Task 5
"@
            $content | Set-Content (Join-Path $tasksDir "002-test.md")
            
            $result = Get-NextIds -BasePath $testDir
            $result.NextFeatureId | Should Be 3
            $result.NextTaskId | Should Be 6
        }
    }
    
    Context "Read-FeatureInput" {
        It "Should read inline text" {
            $result = Read-FeatureInput -InputText "kullanici kayit sistemi"
            $result.Type | Should Be "inline"
            $result.Content | Should Be "kullanici kayit sistemi"
            $result.Path | Should BeNullOrEmpty
        }
        
        It "Should read from file with @ prefix" {
            $testFile = Join-Path $TestDrive "feature.md"
            "Webhook sistemi detaylari" | Set-Content $testFile
            
            $result = Read-FeatureInput -InputText "@$testFile"
            $result.Type | Should Be "file"
            $result.Path | Should Be $testFile
            $result.Content | Should Match "Webhook"
        }
        
        It "Should throw for non-existent file" {
            $errorThrown = $false
            try {
                Read-FeatureInput -InputText "@nonexistent.md"
            }
            catch {
                $errorThrown = $true
            }
            $errorThrown | Should Be $true
        }
    }
    
    Context "ConvertTo-KebabCase" {
        It "Should convert spaces to hyphens" {
            $result = ConvertTo-KebabCase -Text "User Registration System"
            $result | Should Be "user-registration-system"
        }
        
        It "Should handle Turkish characters" {
            $result = ConvertTo-KebabCase -Text "Kullanici Kayit Sistemi"
            $result | Should Be "kullanici-kayit-sistemi"
        }
        
        It "Should remove special characters" {
            $result = ConvertTo-KebabCase -Text "Test: Feature (v1.0)"
            $result | Should Be "test-feature-v1-0"
        }
        
        It "Should collapse multiple hyphens" {
            $result = ConvertTo-KebabCase -Text "Test   Multiple   Spaces"
            $result | Should Be "test-multiple-spaces"
        }
    }
    
    Context "Get-FeatureFileName" {
        It "Should create correct filename format" {
            $result = Get-FeatureFileName -FeatureNumber 1 -FeatureName "User Registration"
            $result | Should Be "001-user-registration.md"
        }
        
        It "Should pad feature number to 3 digits" {
            $result = Get-FeatureFileName -FeatureNumber 25 -FeatureName "Test"
            $result | Should Be "025-test.md"
        }
        
        It "Should truncate long names" {
            $longName = "This is a very long feature name that should be truncated"
            $result = Get-FeatureFileName -FeatureNumber 1 -FeatureName $longName
            $result.Length | Should BeLessThan 50
        }
    }
    
    Context "Parse-FeatureOutput" {
        It "Should parse valid feature output" {
            $output = @"
### FILE: tasks/001-user-registration.md
# Feature 001: User Registration

**Feature ID:** F001
**Feature Name:** User Registration
**Priority:** P2 - High
**Status:** NOT_STARTED

### T001: Form UI

**Estimated Effort:** 1 day

### T002: Validation

**Estimated Effort:** 0.5 days
"@
            
            $result = Parse-FeatureOutput -Output $output
            $result | Should Not BeNullOrEmpty
            $result.FeatureId | Should Be "F001"
            $result.FeatureName | Should Be "User Registration"
            $result.Priority | Should Match "P2"
            $result.TaskCount | Should Be 2
            $result.TaskRange | Should Be "T001-T002"
            $result.TotalEffort | Should Be 1.5
        }
        
        It "Should return null for invalid output" {
            $result = Parse-FeatureOutput -Output "No valid content"
            $result | Should BeNullOrEmpty
        }
    }
}
