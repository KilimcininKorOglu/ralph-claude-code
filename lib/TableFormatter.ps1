# TableFormatter.ps1 - ASCII Table Formatting Module

# Table characters
$script:TableChars = @{
    TopLeft     = [char]0x250C  # ┌
    TopRight    = [char]0x2510  # ┐
    BottomLeft  = [char]0x2514  # └
    BottomRight = [char]0x2518  # ┘
    Horizontal  = [char]0x2500  # ─
    Vertical    = [char]0x2502  # │
    Cross       = [char]0x253C  # ┼
    TLeft       = [char]0x251C  # ├
    TRight      = [char]0x2524  # ┤
    TTop        = [char]0x252C  # ┬
    TBottom     = [char]0x2534  # ┴
}

function Get-StatusColor {
    <#
    .SYNOPSIS
        Returns color for task status
    #>
    param([string]$Status)
    
    switch ($Status) {
        "COMPLETED"   { "Green" }
        "IN_PROGRESS" { "Yellow" }
        "NOT_STARTED" { "Gray" }
        "BLOCKED"     { "Red" }
        default       { "White" }
    }
}

function Format-TableRow {
    <#
    .SYNOPSIS
        Formats a single table row
    #>
    param(
        [array]$Values,
        [array]$Widths
    )
    
    $v = $script:TableChars.Vertical
    $cells = @()
    
    for ($i = 0; $i -lt $Values.Count; $i++) {
        $val = $Values[$i].ToString()
        $width = $Widths[$i]
        
        if ($val.Length -gt $width) {
            $val = $val.Substring(0, $width - 3) + "..."
        }
        
        $cells += " " + $val.PadRight($width) + " "
    }
    
    return $v + ($cells -join $v) + $v
}

function Format-TableSeparator {
    <#
    .SYNOPSIS
        Formats a table separator line
    #>
    param(
        [array]$Widths,
        [string]$Type = "Middle"  # Top, Middle, Bottom
    )
    
    $h = $script:TableChars.Horizontal
    
    switch ($Type) {
        "Top" {
            $left = $script:TableChars.TopLeft
            $right = $script:TableChars.TopRight
            $mid = $script:TableChars.TTop
        }
        "Middle" {
            $left = $script:TableChars.TLeft
            $right = $script:TableChars.TRight
            $mid = $script:TableChars.Cross
        }
        "Bottom" {
            $left = $script:TableChars.BottomLeft
            $right = $script:TableChars.BottomRight
            $mid = $script:TableChars.TBottom
        }
    }
    
    $segments = @()
    foreach ($w in $Widths) {
        $segments += ($h.ToString() * ($w + 2))
    }
    
    return $left + ($segments -join $mid) + $right
}

function Format-TaskTable {
    <#
    .SYNOPSIS
        Formats tasks as ASCII table
    .PARAMETER Tasks
        Array of task objects
    .PARAMETER ShowFeature
        Include feature column
    #>
    param(
        [array]$Tasks,
        [switch]$ShowFeature = $true
    )
    
    if (-not $Tasks -or $Tasks.Count -eq 0) {
        return "No tasks found."
    }
    
    # Define columns and widths
    $columns = @(
        @{ Name = "Task ID"; Width = 8; Property = "TaskId" }
        @{ Name = "Task Name"; Width = 35; Property = "Name" }
        @{ Name = "Status"; Width = 12; Property = "Status" }
        @{ Name = "Priority"; Width = 8; Property = "Priority" }
    )
    
    if ($ShowFeature) {
        $columns += @{ Name = "Feature"; Width = 8; Property = "FeatureId" }
    }
    
    $widths = $columns | ForEach-Object { $_.Width }
    $headers = $columns | ForEach-Object { $_.Name }
    
    $output = @()
    
    # Top border
    $output += Format-TableSeparator -Widths $widths -Type "Top"
    
    # Header row
    $output += Format-TableRow -Values $headers -Widths $widths
    
    # Header separator
    $output += Format-TableSeparator -Widths $widths -Type "Middle"
    
    # Data rows
    foreach ($task in $Tasks) {
        $values = @()
        foreach ($col in $columns) {
            $val = $task[$col.Property]
            if ($null -eq $val) { $val = "" }
            $values += $val
        }
        
        $row = Format-TableRow -Values $values -Widths $widths
        $output += $row
    }
    
    # Bottom border
    $output += Format-TableSeparator -Widths $widths -Type "Bottom"
    
    return $output
}

function Write-TaskTable {
    <#
    .SYNOPSIS
        Writes task table with colors
    #>
    param(
        [array]$Tasks,
        [switch]$ShowFeature = $true
    )
    
    if (-not $Tasks -or $Tasks.Count -eq 0) {
        Write-Host "No tasks found." -ForegroundColor Yellow
        return
    }
    
    # Define columns and widths
    $columns = @(
        @{ Name = "Task ID"; Width = 8; Property = "TaskId" }
        @{ Name = "Task Name"; Width = 35; Property = "Name" }
        @{ Name = "Status"; Width = 12; Property = "Status" }
        @{ Name = "Priority"; Width = 8; Property = "Priority" }
    )
    
    if ($ShowFeature) {
        $columns += @{ Name = "Feature"; Width = 8; Property = "FeatureId" }
    }
    
    $widths = $columns | ForEach-Object { $_.Width }
    $headers = $columns | ForEach-Object { $_.Name }
    
    # Top border
    Write-Host (Format-TableSeparator -Widths $widths -Type "Top") -ForegroundColor Cyan
    
    # Header row
    Write-Host (Format-TableRow -Values $headers -Widths $widths) -ForegroundColor Cyan
    
    # Header separator
    Write-Host (Format-TableSeparator -Widths $widths -Type "Middle") -ForegroundColor Cyan
    
    # Data rows with colors
    foreach ($task in $Tasks) {
        $v = $script:TableChars.Vertical
        $statusColor = Get-StatusColor -Status $task.Status
        
        # Build row manually for coloring
        Write-Host $v -ForegroundColor Cyan -NoNewline
        
        for ($i = 0; $i -lt $columns.Count; $i++) {
            $col = $columns[$i]
            $val = $task[$col.Property]
            if ($null -eq $val) { $val = "" }
            $val = $val.ToString()
            $width = $col.Width
            
            if ($val.Length -gt $width) {
                $val = $val.Substring(0, $width - 3) + "..."
            }
            
            $cell = " " + $val.PadRight($width) + " "
            
            # Color status column
            if ($col.Property -eq "Status") {
                Write-Host $cell -ForegroundColor $statusColor -NoNewline
            }
            else {
                Write-Host $cell -ForegroundColor White -NoNewline
            }
            
            Write-Host $v -ForegroundColor Cyan -NoNewline
        }
        Write-Host ""
    }
    
    # Bottom border
    Write-Host (Format-TableSeparator -Widths $widths -Type "Bottom") -ForegroundColor Cyan
}

function Get-FilteredTasks {
    <#
    .SYNOPSIS
        Gets tasks with optional filtering
    #>
    param(
        [string]$StatusFilter = "",
        [string]$FeatureFilter = "",
        [string]$PriorityFilter = "",
        [string]$BasePath = "."
    )
    
    $allTasks = @(Get-AllTasks -BasePath $BasePath)
    $result = [System.Collections.ArrayList]::new()
    
    foreach ($task in $allTasks) {
        $include = $true
        
        if ($StatusFilter -and $StatusFilter -ne "" -and $task.Status -ne $StatusFilter) {
            $include = $false
        }
        
        if ($include -and $FeatureFilter -and $FeatureFilter -ne "" -and $task.FeatureId -ne $FeatureFilter) {
            $include = $false
        }
        
        if ($include -and $PriorityFilter -and $PriorityFilter -ne "" -and $task.Priority -ne $PriorityFilter) {
            $include = $false
        }
        
        if ($include) {
            [void]$result.Add($task)
        }
    }
    
    return ,$result.ToArray()
}

function Write-TaskSummary {
    <#
    .SYNOPSIS
        Writes task summary statistics
    #>
    param([string]$BasePath = ".")
    
    $progress = Get-TaskProgress -BasePath $BasePath
    
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor White
    Write-Host "  Total: $($progress.Total) tasks" -ForegroundColor White
    
    # Count by status
    $allTasks = Get-AllTasks -BasePath $BasePath
    $completed = @($allTasks | Where-Object { $_.Status -eq "COMPLETED" }).Count
    $inProgress = @($allTasks | Where-Object { $_.Status -eq "IN_PROGRESS" }).Count
    $notStarted = @($allTasks | Where-Object { $_.Status -eq "NOT_STARTED" }).Count
    $blocked = @($allTasks | Where-Object { $_.Status -eq "BLOCKED" }).Count
    
    $total = $progress.Total
    if ($total -eq 0) { $total = 1 }
    
    Write-Host "  COMPLETED:    $completed ($([Math]::Round($completed / $total * 100))%)" -ForegroundColor Green
    Write-Host "  IN_PROGRESS:  $inProgress ($([Math]::Round($inProgress / $total * 100))%)" -ForegroundColor Yellow
    Write-Host "  NOT_STARTED:  $notStarted ($([Math]::Round($notStarted / $total * 100))%)" -ForegroundColor Gray
    Write-Host "  BLOCKED:      $blocked ($([Math]::Round($blocked / $total * 100))%)" -ForegroundColor Red
    
    # Progress bar
    Write-Host ""
    $bar = Get-ProgressBar -Percentage $progress.Percentage -Width 25
    Write-Host "Progress: $bar $($progress.Percentage)%" -ForegroundColor White
}

function Show-EnhancedTaskStatus {
    <#
    .SYNOPSIS
        Shows enhanced task status with table and filtering
    #>
    param(
        [string]$StatusFilter = "",
        [string]$FeatureFilter = "",
        [string]$PriorityFilter = "",
        [string]$BasePath = "."
    )
    
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "  TASK STATUS" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
    
    # Show active filters
    $filters = @()
    if ($StatusFilter) { $filters += "Status: $StatusFilter" }
    if ($FeatureFilter) { $filters += "Feature: $FeatureFilter" }
    if ($PriorityFilter) { $filters += "Priority: $PriorityFilter" }
    
    if ($filters.Count -gt 0) {
        Write-Host "Filters: $($filters -join ', ')" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Get tasks
    $tasks = Get-FilteredTasks -StatusFilter $StatusFilter -FeatureFilter $FeatureFilter `
        -PriorityFilter $PriorityFilter -BasePath $BasePath
    
    # Write table
    Write-TaskTable -Tasks $tasks -ShowFeature:(-not $FeatureFilter)
    
    # Summary (only if no filter or just feature filter)
    if (-not $StatusFilter) {
        Write-TaskSummary -BasePath $BasePath
    }
    else {
        Write-Host ""
        Write-Host "$($tasks.Count) task(s) found." -ForegroundColor White
    }
    
    # Next task
    if (-not $StatusFilter -and -not $FeatureFilter -and -not $PriorityFilter) {
        $nextTask = Get-NextTask -BasePath $BasePath
        if ($nextTask) {
            Write-Host ""
            Write-Host "Next Task: $($nextTask.TaskId) - $($nextTask.Name)" -ForegroundColor Cyan
        }
    }
    
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}
