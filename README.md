# SingleInstance.psm1
This [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/overview) module allows you to prevent multiple instances of the same PowerShell script from running at the same time.

## Cmdlet
The `SingleInstance` module exports the following functions:

- Enter-SingleInstance
- Exit-SingleInstance

### Enter-SingleInstance
Use this function to check if any other instances of the script are running by passing the script ID, such as script's path (`$PSCommandPath`), a GUID, or some other value that only that script would know. If the function detects that no other instances are running, it will create a mutex (named after the script ID), and return `true` to indicate that this is the first instance. The mutex will be held until the script calls the `Exit-SingleInstance` function, but before that any other script that calls `Enter-SingleInstance` will get back `false` and know that there is another instance of the script running. Keep in mind that if the first instance does not release the mutex (e.g. if the script crashes without cleanup), the mutex will be held until the system is rebooted.

#### Syntax
```PowerShell
Enter-SingleInstance `
  [-ScriptId <string>] `
  [<CommonParameters>]
```

#### Arguments
`-ScriptId`

The value uniquely identifying the calling script. If you omit this parameter the module will try to dermine the path to the calling script (.ps1 file) and use this path as the script ID.

`-<CommonParameters>`

Common PowerShell parameters (cmdlet is not using these explicitly).

### Exit-SingleInstance
Use this function to at the end of the processing to release the single-instance mutex.

#### Syntax
```PowerShell
Exit-SingleInstance
```

#### Arguments
`-<CommonParameters>`

Common PowerShell parameters (cmdlet is not using these explicitly).

### Get-ScriptPath
This is a helper function that you may find useful if you want to determine the path of the calling script from a module. The first script in the call stack identified by the extension will be used to determine the script path.

#### Syntax
```PowerShell
Get-ScriptPath `
  [-Extension <string>] `
  [<CommonParameters>]
```

#### Arguments
`-Extension`

Extension by which the calling script will be identified. By default, the '.ps1' extension will be used.

`-<CommonParameters>`

Common PowerShell parameters (cmdlet is not using these explicitly).

### Usage

You can download a copy of the module from the [Github repository](SingleInstance) or install it from the [PowerShell Gallery](https://www.powershellgallery.com/packages/SingleInstance) (see [Examples](#Examples)).

### Examples

#### Example 1
```PowerShell
function LoadModule {
    param(
        [string]
        $ModuleName
    )

    if (!(Get-Module -Name $ModuleName)) {

        if (!(Get-Module -Listavailable -Name $ModuleName)) {
            Install-Module -Name $ModuleName -Force -Scope CurrentUser -ErrorAction Stop
        }

        Import-Module $ModuleName -ErrorAction Stop -Force
    }
}

$modules = @("SingleInstance")
foreach ($module in $modules) {
    try {
        LoadModule -ModuleName $module
    }
    catch {
        throw (New-Object System.Exception "Cannot load module $module.", $_.Exception)
    }
}
```
Downloads the `SingleInstance` module from the [PowerShell Gallery](https://www.powershellgallery.com/packages/SingleInstance) into the PowerShell modules folder for the current user and imports it into the running script.

#### Example 2
```PowerShell
$modulePath = Join-Path (Split-Path -Path $PSCommandPath -Parent) 'SingleInstance.psm1'
Import-Module $modulePath -ErrorAction Stop -Force
```
Imports the `SingleInstance` module from the same directory as the running script.

#### Example 3
```PowerShell
if (!(Enter-SingleInstance)) {
    throw "The script is already running."
}
else {
    try {
        # Do what you need to do.
    }
    finally {
        # Make sure you exit single instance on both success and failure.
        Exit-SingleInstance
    }
}
```
Enforces single-instance script execution.