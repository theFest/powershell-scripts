function Set-WindowState {
    <#
    .SYNOPSIS
    Sets the window state of specified processes.

    .DESCRIPTION
    This function sets the window state of specified processes, it can change the visibility or appearance of windows associated with the specified processes.

    .EXAMPLE
    Set-WindowState -InputObject (Get-Process -Name "notepad") -State Minimize

    .NOTES
    v0.2.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Processes whose window state needs to be manipulated")]
        [System.Diagnostics.Process[]]$InputObject,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the desired window state")]
        [ValidateSet(
            "Hide", "ShowNormal", "ShowMinimized", "Maximize", "ShowNoActivate", 
            "Show", "Minimize", "ShowMinNoActive", "ShowNA", "Restore", 
            "ShowDefault", "ForceMinimize"
        )]
        [string]$State = "Show",

        [Parameter(Mandatory = $false, HelpMessage = "Suppress errors if the main window handle is not found")]
        [switch]$SuppressErrors = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Bring the window to the foreground after changing its state")]
        [switch]$SetForegroundWindow = $false
    )
    $WindowStates = @{
        "Hide"            = 0
        "ShowNormal"      = 1
        "ShowMinimized"   = 2
        "Maximize"        = 3
        "ShowNoActivate"  = 4
        "Show"            = 5
        "Minimize"        = 6
        "ShowMinNoActive" = 7
        "ShowNA"          = 8
        "Restore"         = 9
        "ShowDefault"     = 10
        "ForceMinimize"   = 11       
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
                Write-Error -Message "Main Window handle is '0' for process '$($Process.ProcessName)'"
            }
            continue
        }
        $global:MainWindowHandles[$Process.Id] = $Handle
        $Win32ShowWindowAsync::ShowWindowAsync($Handle, $WindowStates[$State]) | Out-Null
        if ($SetForegroundWindow) {
            $Win32ShowWindowAsync::SetForegroundWindow($Handle) | Out-Null
        }
        Write-Verbose -Message "Set Window State '$State' on process '$($Process.ProcessName)' (ID: $($Process.Id))"
    }
}
