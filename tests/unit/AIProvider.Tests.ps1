#Requires -Modules Pester

# Load module before tests
. "$PSScriptRoot\..\..\lib\AIProvider.ps1"

Describe "AIProvider Module" {
    
    Context "Split-AIOutput" {
        It "Should parse single file output" {
            $output = "### FILE: tasks/001-auth.md`n# Feature 1: Auth`n`n**Feature ID:** F001`n**Status:** NOT_STARTED"
            
            $result = @(Split-AIOutput -Output $output)
            $result.Count | Should Be 1
            $result[0].FileName | Should Be "tasks/001-auth.md"
            $result[0].Content | Should Match "Feature 1: Auth"
        }
        
        It "Should parse multiple files" {
            $output = @"
### FILE: tasks/001-auth.md
# Feature 1: Auth
**Feature ID:** F001

### FILE: tasks/002-dashboard.md
# Feature 2: Dashboard
**Feature ID:** F002

### FILE: tasks/tasks-status.md
# Task Status Tracker
"@
            
            $result = Split-AIOutput -Output $output
            $result.Count | Should Be 3
            $result[0].FileName | Should Be "tasks/001-auth.md"
            $result[1].FileName | Should Be "tasks/002-dashboard.md"
            $result[2].FileName | Should Be "tasks/tasks-status.md"
        }
        
        It "Should return empty array for invalid output" {
            $output = "No FILE markers here"
            
            $result = Split-AIOutput -Output $output
            $result.Count | Should Be 0
        }
    }
    
    Context "Test-ParsedOutput" {
        It "Should return false for empty files array" {
            $emptyFiles = [System.Collections.ArrayList]@()
            $result = Test-ParsedOutput -Files $emptyFiles
            $result | Should Be $false
        }
        
        It "Should return false when no feature files found" {
            $files = @(
                @{ FileName = "tasks-status.md"; Content = "Status content" }
            )
            
            $result = Test-ParsedOutput -Files $files
            $result | Should Be $false
        }
        
        It "Should return true for valid output" {
            $files = @(
                @{ 
                    FileName = "001-auth.md"
                    Content = "# Feature 1`n**Feature ID:** F001" 
                },
                @{ 
                    FileName = "tasks-status.md"
                    Content = "Status content" 
                }
            )
            
            $result = Test-ParsedOutput -Files $files
            $result | Should Be $true
        }
    }
    
    Context "Test-PrdSize" {
        It "Should return correct size for small file" {
            $testDir = Join-Path $TestDrive "prd-test"
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            
            $smallFile = Join-Path $testDir "small.md"
            "# Small PRD`nSome content" | Set-Content $smallFile
            
            $result = Test-PrdSize -PrdFile $smallFile
            ($result.Size -lt 100) | Should Be $true
            $result.IsLarge | Should Be $false
        }
        
        It "Should detect large files" {
            $testDir = Join-Path $TestDrive "prd-test2"
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            
            $largeFile = Join-Path $testDir "large.md"
            $largeContent = "x" * 250000
            $largeContent | Set-Content $largeFile
            
            $result = Test-PrdSize -PrdFile $largeFile
            ($result.Size -gt 200000) | Should Be $true
            $result.IsLarge | Should Be $true
        }
    }
    
    Context "Get-AutoProvider" {
        It "Should return a provider when at least one is available" {
            # This test depends on actual system availability
            $result = Get-AutoProvider
            # Result could be null if no providers installed
            # In CI, we expect at least one to be available
            if ($result) {
                $result | Should Match "^(claude|droid|aider)$"
            }
        }
    }
    
    Context "Invoke-TaskExecution" {
        It "Should return hashtable with expected keys" {
            # Test with very short timeout to verify return structure
            $result = Invoke-TaskExecution -Provider "claude" -PromptContent "test" -TimeoutSeconds 1
            # Result should be a hashtable with Success, Output, Error keys
            $result | Should Not BeNullOrEmpty
            $result.ContainsKey("Success") | Should Be $true
            $result.ContainsKey("Output") | Should Be $true
            $result.ContainsKey("Error") | Should Be $true
        }
        
        It "Should accept valid provider parameter" {
            # ValidateSet should accept valid providers
            # Test only validates the function exists with correct signature
            $cmd = Get-Command Invoke-TaskExecution -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Parameters.ContainsKey("Provider") | Should Be $true
        }
    }
}
