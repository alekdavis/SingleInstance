<#
.SYNOPSIS
PowerShell commandlet that enforces a single instance of the running script.

.LINK
https://github.com/alekdavis/SingleInstance
#>

#------------------------[ RUN-TIME REQUIREMENTS ]-------------------------

#Requires -Version 4.0

#---------------------------[ MODULE VARIABLES ]---------------------------

# Mutex to prevent multiple instances from running concurrently.
[System.Threading.Mutex]$Mutex = $null

#---------------------------[ PUBLIC FUNCTIONS ]---------------------------

<#
.SYNOPSIS
Checks if the specified instance of the script is running.

.DESCRIPTION
Use this function to check if the instance of the script is running. The script instance is identified by an arbitrary ID specified by the caller. This cmdlet uses a mutex to detect if the script is running (the mutex must be released before the process exits via the Exit-SingleInstance).

.PARAMETER ScriptID
Id of the script that will be used to identify the script instance. It can be some unique value (such as GUID) that a calling script would know or another identifier, such as  script path ($PSCommandPath).

.EXAMPLE
if (!(Enter-SingleInstance $PSCommandPath) throw "The script is already running."
Checks if the script with the given path is already running and if not, sets a mutex to prevent other calls from entering.

.LINK
https://github.com/alekdavis/SingleInstance
#>
function Enter-SingleInstance {
    [CmdletBinding()]
    param (
        [string]
        $ScriptId = $null
    )
    # Allow module to inherit '-Verbose' flag.
    if (($PSCmdlet) -and (-not $PSBoundParameters.ContainsKey('Verbose'))) {
        $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
    }

    # Allow module to inherit '-Debug' flag.
    if (($PSCmdlet) -and (-not $PSBoundParameters.ContainsKey('Debug'))) {
        $DebugPreference = $PSCmdlet.GetVariableValue('DebugPreference')
    }

    $success = $false

    if (!$ScriptId) {
        $ScriptId = Get-ScriptPath
    }

    if (!$ScriptId) {
        throw "Cannot detect calling script path from module '$PSCommandPath'."
    }

    Write-Verbose "Creating single-instance mutex '$ScriptId'."
    $Script:Mutex = New-Object System.Threading.Mutex($true, $ScriptId, [ref] $success)

    if ($success) {
        return $true
    }

    return $false
}

<#
.SYNOPSIS
Releases single-instance mutex initialized in the Enter-SingleInstance function.

.DESCRIPTION
Use this function to release the single-instance mutex allocated by the Enter-SingleInstance function. If no mutex was allocated, e.g. if Enter-SingleInstance returned false, this function will do nothing.

.EXAMPLE
Exit-SingleInstance
Releases the single-instance mutex.

.LINK
https://github.com/alekdavis/SingleInstance
#>
function Exit-SingleInstance {
    [CmdletBinding()]
    param (
    )

    # Allow module to inherit '-Verbose' flag.
    if (($PSCmdlet) -and (-not $PSBoundParameters.ContainsKey('Verbose'))) {
        $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
    }

    # Allow module to inherit '-Debug' flag.
    if (($PSCmdlet) -and (-not $PSBoundParameters.ContainsKey('Debug'))) {
        $DebugPreference = $PSCmdlet.GetVariableValue('DebugPreference')
    }

    if ($Script:Mutex) {
        Write-Verbose "Releasing single-instance mutex."
        $Mutex.ReleaseMutex()
        $Mutex.Dispose()
        $Mutex = $null
    }
}

<#
.SYNOPSIS
Returns the full path of the first PowerShell script in the call stack.

.DESCRIPTION
Use this function to get the full path of the calling PowerShell script from a PowerShell module.

.PARAMETER Extension
The extension by which the calling script must be identified. The default value is '.ps1'.

.EXAMPLE
$scriptPath = GetScriptPath
Gets the full path of the calling .ps1 script.

.LINK
https://github.com/alekdavis/SingleInstance
#>
function Get-ScriptPath {
    [CmdletBinding()]
    param (
        [string]
        $Extension = '.ps1'
    )

    # Allow module to inherit '-Verbose' flag.
    if (($PSCmdlet) -and (-not $PSBoundParameters.ContainsKey('Verbose'))) {
        $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
    }

    # Allow module to inherit '-Debug' flag.
    if (($PSCmdlet) -and (-not $PSBoundParameters.ContainsKey('Debug'))) {
        $DebugPreference = $PSCmdlet.GetVariableValue('DebugPreference')
    }
        $callstack = Get-PSCallStack

    $i = 0
    $max = 100

    while ($true) {
        if (!$callstack[$i]) {
            Write-Verbose "Cannot detect callstack frame '$i' in 'Get-ScriptPath'."
            return $null
        }

        $path = $callstack[$i].ScriptName

        if ($path) {
            Write-Verbose "Callstack frame '$i': '$path'."
            $ext = [IO.Path]::GetExtension($path)
            if (($ext) -and $ext -eq $Extension) {
                return $path
            }
        }

        $i++

        if ($i -gt $max) {
            Write-Verbose "Exceeded the maximum of '$max' callstack frames in 'Get-ScriptPath'."
            return $null
        }
    }

    return $null
}

Export-ModuleMember -Function *-*