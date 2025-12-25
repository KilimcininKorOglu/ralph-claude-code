#Requires -Modules Pester

BeforeAll {
    . "$PSScriptRoot\..\..\lib\GitBranchManager.ps1"
}

Describe "GitBranchManager Module" {
    Context "Get-FeatureBranchName" {
        It "Creates correct branch name" {
            $name = Get-FeatureBranchName -FeatureId "F001" -FeatureName "User Registration"
            $name | Should -Be "feature/F001-user-registration"
        }
        
        It "Sanitizes special characters" {
            $name = Get-FeatureBranchName -FeatureId "F002" -FeatureName "Email & Password Reset"
            $name | Should -Match "^feature/F002-"
            $name | Should -Not -Match "&"
        }
        
        It "Truncates long names" {
            $longName = "This is a very long feature name that exceeds thirty characters"
            $name = Get-FeatureBranchName -FeatureId "F003" -FeatureName $longName
            $name.Length | Should -BeLessOrEqual 50
        }
        
        It "Handles unicode characters" {
            $name = Get-FeatureBranchName -FeatureId "F004" -FeatureName "User Kayit Formu"
            $name | Should -Match "^feature/F004-"
        }
    }
    
    Context "Get-MainBranch" {
        It "Returns main or master" {
            $main = Get-MainBranch
            $main | Should -BeIn @("main", "master")
        }
    }
    
    Context "Test-GitRepository" -Skip:(-not (Test-Path ".git")) {
        It "Returns true in git repository" {
            Test-GitRepository | Should -Be $true
        }
    }
    
    Context "Get-CurrentBranch" -Skip:(-not (Test-Path ".git")) {
        It "Returns branch name" {
            $branch = Get-CurrentBranch
            $branch | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Test-WorkingTreeClean" -Skip:(-not (Test-Path ".git")) {
        It "Returns boolean" {
            $clean = Test-WorkingTreeClean
            $clean | Should -BeIn @($true, $false)
        }
    }
    
    Context "Test-StagedChanges" -Skip:(-not (Test-Path ".git")) {
        It "Returns boolean" {
            $staged = Test-StagedChanges
            $staged | Should -BeIn @($true, $false)
        }
    }
    
    Context "Get-CommitsSinceMain" -Skip:(-not (Test-Path ".git")) {
        It "Returns integer" {
            $count = Get-CommitsSinceMain
            $count | Should -BeOfType [int]
        }
    }
    
    Context "Test-BranchExists" -Skip:(-not (Test-Path ".git")) {
        It "Returns true for current branch" {
            $current = Get-CurrentBranch
            Test-BranchExists -Name $current | Should -Be $true
        }
        
        It "Returns false for nonexistent branch" {
            Test-BranchExists -Name "nonexistent-branch-xyz" | Should -Be $false
        }
    }
    
    Context "Test-MergeInProgress" -Skip:(-not (Test-Path ".git")) {
        It "Returns false when no merge in progress" {
            Test-MergeInProgress | Should -Be $false
        }
    }
}
