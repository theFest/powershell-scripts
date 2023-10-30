Function Set-WindowState {
    <#
    .SYNOPSIS
    Set window to wanted state.
    
    .DESCRIPTION
    This function sets the state of a window associated with a given process.
    
    .PARAMETER InputObject
    Mandatory - an array of objects representing processes
    .PARAMETER State
    NotMandatory - the state of the window (e.g. 'MINIMIZE', 'MAXIMIZE', etc.).
    .PARAMETER SuppressErrors
    NotMandatory - choose whether or not to suppress error messages.
    .PARAMETER SetForegroundWindow
    NotMandatory - switch to determine whether or not to set the foreground window.
    
    .EXAMPLE
    Set-WindowState -InputObject (Get-Process -Name "notepad") -State "MAXIMIZE" -SetForegroundWindow

    .NOTES
    v0.1.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Diagnostics.Process[]]$InputObject,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet("FORCEMINIMIZE", "HIDE", "MAXIMIZE", "MINIMIZE", "RESTORE",
            "SHOW", "SHOWDEFAULT", "SHOWMAXIMIZED", "SHOWMINIMIZED",
            "SHOWMINNOACTIVE", "SHOWNA", "SHOWNOACTIVATE", "SHOWNORMAL")]
        [string]$State = "SHOW",

        [Parameter(Mandatory = $false)]
        [switch]$SuppressErrors = $false,

        [Parameter(Mandatory = $false)]
        [switch]$SetForegroundWindow = $false
    )
    $WindowStates = @{
        "HIDE"            = 0
        "SHOWNORMAL"      = 1
        "SHOWMINIMIZED"   = 2
        "MAXIMIZE"        = 3
        "SHOWNOACTIVATE"  = 4
        "SHOW"            = 5
        "MINIMIZE"        = 6
        "SHOWMINNOACTIVE" = 7
        "SHOWNA"          = 8
        "RESTORE"         = 9
        "SHOWDEFAULT"     = 10
        "FORCEMINIMIZE"   = 11       
    }
    $Win32ShowWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetForegroundWindow(IntPtr hWnd);
'@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru
    $global:MainWindowHandles = @{ }
    foreach ($Process in $InputObject) {
        $Handle = $Process.MainWindowHandle
        if ($Handle -eq 0 -and $global:MainWindowHandles.ContainsKey($Process.Id)) {
            $Handle = $global:MainWindowHandles[$Process.Id]
        }
        if ($Handle -eq 0) {
            if (-not $SuppressErrors) {
                Write-Error -Message "Main Window handle is '0'"
            }
            continue
        }
        $global:MainWindowHandles[$Process.Id] = $Handle
        $Win32ShowWindowAsync::ShowWindowAsync($Handle, $WindowStates[$State]) | Out-Null
        if ($SetForegroundWindow) {
            $Win32ShowWindowAsync::SetForegroundWindow($Handle) | Out-Null
        }
        Write-Verbose -Message "Set Window State '$State' on '$Handle'"
    }
}