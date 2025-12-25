<#
.SYNOPSIS
    Unit tests for GitBranchManager.ps1 module
#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$lib = Join-Path (Split-Path -Parent (Split-Path -Parent $here)) "lib"
. "$lib\GitBranchManager.ps1"

Describe "GitBranchManager Module" {
    Context "Get-FeatureBranchName" {
        It "Creates correct branch name" {
            $name = Get-FeatureBranchName -FeatureId "F001" -FeatureName "User Registration"
            $name | Should Be "feature/F001-user-registration"
        }
        
        It "Sanitizes special characters" {
            $name = Get-FeatureBranchName -FeatureId "F002" -FeatureName "Email & Password Reset"
            $name | Should Match "^feature/F002-"
            $name | Should Not Match "&"
        }
        
        It "Truncates long names" {
            $longName = "This is a very long feature name that exceeds thirty characters"
            $name = Get-FeatureBranchName -FeatureId "F003" -FeatureName $longName
            ($name.Length -le 50) | Should Be $true
        }
        
        It "Handles unicode characters" {
            $name = Get-FeatureBranchName -FeatureId "F004" -FeatureName "User Kayit Formu"
            $name | Should Match "^feature/F004-"
        }
    }
    
    Context "Get-MainBranch" {
        It "Returns main or master" {
            $main = Get-MainBranch
            ($main -eq "main" -or $main -eq "master") | Should Be $true
        }
    }
    
    Context "Test-GitRepository" {
        It "Returns true in git repository" {
            if (Test-Path ".git") {
                Test-GitRepository | Should Be $true
            } else {
                Set-TestInconclusive "Not in a git repository"
            }
        }
    }
    
    Context "Get-CurrentBranch" {
        It "Returns branch name" {
            if (Test-Path ".git") {
                $branch = Get-CurrentBranch
                $branch | Should Not BeNullOrEmpty
            } else {
                Set-TestInconclusive "Not in a git repository"
            }
        }
    }
    
    Context "Test-WorkingTreeClean" {
        It "Returns boolean" {
            if (Test-Path ".git") {
                $clean = Test-WorkingTreeClean
                ($clean -eq $true -or $clean -eq $false) | Should Be $true
            } else {
                Set-TestInconclusive "Not in a git repository"
            }
        }
    }
    
    Context "Test-StagedChanges" {
        It "Returns boolean" {
            if (Test-Path ".git") {
                $staged = Test-StagedChanges
                ($staged -eq $true -or $staged -eq $false) | Should Be $true
            } else {
                Set-TestInconclusive "Not in a git repository"
            }
        }
    }
    
    Context "Get-CommitsSinceMain" {
        It "Returns integer" {
            if (Test-Path ".git") {
                $count = Get-CommitsSinceMain
                $count.GetType().Name | Should Be "Int32"
            } else {
                Set-TestInconclusive "Not in a git repository"
            }
        }
    }
    
    Context "Test-BranchExists" {
        It "Returns true for current branch" {
            if (Test-Path ".git") {
                $current = Get-CurrentBranch
                Test-BranchExists -Name $current | Should Be $true
            } else {
                Set-TestInconclusive "Not in a git repository"
            }
        }
        
        It "Returns false for nonexistent branch" {
            if (Test-Path ".git") {
                Test-BranchExists -Name "nonexistent-branch-xyz" | Should Be $false
            } else {
                Set-TestInconclusive "Not in a git repository"
            }
        }
    }
    
    Context "Test-MergeInProgress" {
        It "Returns false when no merge in progress" {
            if (Test-Path ".git") {
                Test-MergeInProgress | Should Be $false
            } else {
                Set-TestInconclusive "Not in a git repository"
            }
        }
    }
}
