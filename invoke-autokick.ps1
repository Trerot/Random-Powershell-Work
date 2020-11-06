<# autokick disconnected sessions when load reaches set threshold.
command runs every X seconds and runs until terminated.
this is designed to be run as a job on problem servers with offline resournce hoggs.#>

# logfile location, if logfile not created. create a new one.
$Logfile = "C:\Logs\$(Get-ChildItem env:computername)-kicklog.log"
if (-not Test-Path $logs) {
    New-Item -Path $Logfile -ItemType File -Force
}
#Sleeptime in seconds
$SleepTime = 10
#CPU and ram threshold
$CPUThreshold = 40
$RAMThreshold = 70
# Custom functions are here
function Get-CPUPercentage {
    $Global:CPUloadPercentage = (Get-CimInstance -Class win32_processor |
        Measure-Object -Property LoadPercentage -Average).average  
}
function Get-RAMPercentage {
    $FreeMemory = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
    $TotalMemory = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize
    $Global:UsedMemoryPercent = (100 / $TotalMemory) * ($TotalMemory - $FreeMemory)
    $Global:UsedMemoryPercentRound = [math]::round($Global:UsedMemoryPercent)
}
function Get-Sessions {
    $QuerySession = query session
    $starters = New-Object psobject -Property @{
        "SessionName" = 0
        "UserName"    = 0
        "ID"          = 0
        "State"       = 0
        "Type"        = 0
        "Device"      = 0
    }
    foreach ($result in $QuerySession) {
        if ($result.trim().substring(0, $result.trim().indexof(" ")) -eq "SESSIONNAME") {
            $starters.UserName = $result.indexof("USERNAME")
            $starters.ID = $result.indexof("ID")
            $starters.State = $result.indexof("STATE")
            $starters.Type = $result.indexof("TYPE")
            $starters.Device = $result.indexof("DEVICE")
            continue
        }

        New-Object psobject -Property @{
            "SessionName" = $result.trim().substring(0, $result.trim().indexof(" ")).trim(">")
            "Username"    = $result.Substring($starters.Username, $result.IndexOf(" ", $starters.Username) - $starters.Username)
            "ID"          = $result.Substring($result.IndexOf(" ", $starters.Username), $starters.ID - $result.IndexOf(" ", $starters.Username) + 2).trim()
            "State"       = $result.Substring($starters.State, $result.IndexOf(" ", $starters.State) - $starters.State).trim()
            "Type"        = $result.Substring($starters.Type, $starters.Device - $starters.Type).trim()
            "Device"      = $result.Substring($starters.Device).trim()
        }
    }
}
while ($true) {
    Get-CPUPercentage; Get-RAMPercentage
    switch ($CPUloadPercentage -or $UsedMemoryPercent) {
        { $CPUloadPercentage -gt $CPUThreshold -or $UsedMemoryPercent -gt $RAMThreshold } { 
            "CPU or RAM threshold reached"
            "RAM usage is $UsedMemoryPercentRound%"
            "CPU usage is $CPUloadPercentage%"
            # 
            "Commencing the kickening"
            # get DC sessions with the get-sessions function
            $IncludeStates = '^(Disc)$'
            $DisconnectedSessions = Get-Sessions |
            Where-Object { $_.State -match $IncludeStates -and $_.UserName -ne "" }
            # kick all Disconnected users.
            foreach ($session in $DisconnectedSessions) {
                logoff $session.ID 
            }
            #writing kick time, users RAM and CPU useage to logfile.
            Add-Content -Path $Logfile -Value (
                -join
                ("`n$(Get-Date)`n",
                    "CPU reached $CPUloadPercentage% and RAM reached $UsedMemoryPercentRound%`n",
                    "following disconnected users where kicked"
                ),
                $($DisconnectedSessions.ID)
            
            "Sleeping for $SleepTime seconds and checking again"
            Start-Sleep -Seconds $SleepTime
            # getting RAM and CPU percent
            Get-CPUPercentage; Get-RAMPercentage
        }
        Default {
            "I sleep for $Sleeptime seconds and try again"
            Start-Sleep -Seconds $SleepTime
            # getting CPU and RAM percentage
            Get-CPUPercentage; Get-RAMPercentage
        }
    }
}
Add-Content -Path $Logfile -Value (
    $string = -join
    (            "$(Get-Date)`n",
        "CPU reached $CPUloadPercentage and RAM reached $UsedMemoryPercentRound`n",
        "following disconnected users where kicked",
        "$($something.ID)"
    )
)