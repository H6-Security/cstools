# Clear any existing variables
Remove-Variable * -ErrorAction SilentlyContinue

# Default to local machine
$machineName = $env:COMPUTERNAME

# Function to check for gaps in event logs
function CheckEventLogGaps {
    param (
        [string]$logName
    )

    $BoundaryEvents = @()

    Write-Host "Checking ${logName} event log on $machineName..."
    $events = Get-WinEvent -LogName $logName -ComputerName $machineName
    Write-Host "Retrieved event log entries..."

    $RecID0 = $events[0].RecordID
    Write-Host "Starting with record ID: $RecID0"

    foreach ($event in $events) {
        if ($RecID0 -ne $event.RecordID) {
            if ($RecID0 - $event.RecordID -eq 1) {
                $RecID0 = $event.RecordID
            } else {
                $BEvents = New-Object -TypeName psobject
                $BEvents | Add-Member -NotePropertyName before -NotePropertyValue $RecID0
                $BEvents | Add-Member -NotePropertyName after -NotePropertyValue $event.RecordID

                $BEvents | Format-Table

                $BoundaryEvents += $BEvents
                $RecID0 = $event.RecordID
            }
        }
    }

    if ($BoundaryEvents.Count -eq 0) {
        $summaryMessage = "No gaps in the $logName log on $machineName."
    } else {
        $summaryMessage = "${logName} Log Gap Summary on " + $machineName + "`r"
        $summaryMessage += ($BoundaryEvents | Format-Table -HideTableHeaders)
    }

    Clear-Host
    Write-Host $summaryMessage
    Read-Host "Press Enter to continue..."
}

# Function to change to a remote machine
function ChangeToRemoteMachine {
    $newMachineName = Read-Host "Enter the remote machine name"
    if (Test-Connection -ComputerName $newMachineName -Count 1 -Quiet) {
        $machineName = $newMachineName
        Write-Host "Connected to $machineName."
    } else {
        Write-Host "Unable to connect to $newMachineName. Please check the machine name and ensure it's online."
    }
    return $machineName
}

# Function to perform log checks and output each step
function PerformLogChecks {
    Write-Host "Selected an option to check event logs on $machineName."
    Write-Host "Please wait while the program checks the logs..."
    # You can add more descriptive output as needed

    # Call the CheckEventLogGaps function to perform the checks
    CheckEventLogGaps $logName
}

# Function for the intro screen
function ShowIntroScreen {
    Clear-Host
    $isAdmin = IsPowerShellAdmin
    Write-Host "Event Logs Check"
    Write-Host @"
This tool allows you to check if a computer's event logs have been tampered with by a program, malicious script, external attacker, or other automated means. This tool checks the accounting log for gaps in the sequential numbering of events. Typically these logs cannot be written to and are often difficult to decipher. This tool automates that process and lets you know if any gaps were found.

Running in Administrator Mode: $isAdmin
"@

    if (-not $isAdmin) {
        Write-Host "Note: This tool must be run in Administrator mode."
    }

    Read-Host "Press any key to continue..."
}

# Function to check if PowerShell is running as administrator
function IsPowerShellAdmin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    $admin = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $isAdmin = $principal.IsInRole($admin)
    return $isAdmin
}

# Show the intro screen
ShowIntroScreen

# Clear the screen
Clear-Host

# Menu for selecting event logs
while ($true) {
    Write-Host "Event Logs Check for $machineName"
    Write-Host "1. Application"
    Write-Host "2. Setup"
    Write-Host "3. System"
    Write-Host "4. Security"
    if ($machineName -eq $env:COMPUTERNAME) {
        Write-Host "5. Scan a remote computer"
    } else {
        Write-Host "5. Scan local computer"
    }
    Write-Host "6. Exit"

    $choice = Read-Host "Select an option"

    switch ($choice) {
        1 {
            $logName = "Application"
            PerformLogChecks
        }
        2 {
            $logName = "Setup"
            PerformLogChecks
        }
        3 {
            $logName = "System"
            PerformLogChecks
        }
        4 {
            $logName = "Security"
            PerformLogChecks
        }
        5 {
            if ($machineName -eq $env:COMPUTERNAME) {
                $machineName = ChangeToRemoteMachine
            } else {
                $machineName = $env:COMPUTERNAME
            }
        }
        6 {
            Exit
        }
        default { Write-Host "Invalid option. Please select a valid option." }
    }

    # Clear the screen after the choice is processed
    Clear-Host
}
