Function AudioControl {
    <#
    .SYNOPSIS
    Adjust sound volume or mute with a timespan.
    
    .DESCRIPTION
    With this simple function you can adjust sound volume and mute sound with ability of using a loop.
    
    .PARAMETER Volume
    NotMandatory - declare volume you want to persist throughout a loop.   
    .PARAMETER Seconds
    NotMandatory - optional to add seconds.    
    .PARAMETER Minutes
    NotMandatory - optional to add minutes.   
    .PARAMETER Hours
    NotMandatory - optional to add hours.   
    .PARAMETER Days
    NotMandatory - optional to add days.   
    .PARAMETER Interval
    NotMandatory - declare interval between sound correction.   
    .PARAMETER Mute
    NotMandatory choose this switch to mute sound.
    
    .EXAMPLE
    AudioControl -Volume 0.2 -Seconds 60 -Interval 5 (0.2 is 20%, 0.5 is 50%...)
    
    .NOTES
    v1 (for other audio controls, use Nirsoft tool or AudioDeviceCmdlets)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [double]$Volume,

        [Parameter(Mandatory = $false)]
        [int]$Seconds,

        [Parameter(Mandatory = $false)]
        [int]$Minutes,

        [Parameter(Mandatory = $false)]
        [int]$Hours,

        [Parameter(Mandatory = $false)]
        [int]$Days,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [int]$Interval = 1,

        [Parameter(Mandatory = $false)]
        [switch]$Mute
    )
    BEGIN {
        $StartTime = Get-Date
        Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume
{
   // f(), g(), ... are unused COM method slots. Define these if you care
   int f(); int g(); int h(); int i();
   int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
   int j();
   int GetMasterVolumeLevelScalar(out float pfLevel);
   int k(); int l(); int m(); int n();
   int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
   int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice
{
   int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator
{
   int f(); // Unused
   int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
public class Audio
{
   static IAudioEndpointVolume Vol()
   {
       var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
       IMMDevice dev = null;
       Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
       IAudioEndpointVolume epv = null;
       var epvid = typeof(IAudioEndpointVolume).GUID;
       Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
       return epv;
   }
   public static float Volume
   {
       get { float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v; }
       set { Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty)); }
   }
   public static bool Mute
   {
       get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
       set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
   }
}
'@
    }
    PROCESS {
        $TimeOut = New-TimeSpan -Seconds:$Seconds -Minutes:$Minutes -Hours:$Hours -Days:$Days
        $EndTime = (Get-Date).Add($TimeOut) 
        do {
            if ($Volume) {
                [Audio]::Volume = $Volume
            }
            if ($Mute.IsPresent) {
                [Audio]::Mute = $true
            }
            Start-Sleep -Seconds $Interval
        } until ((Get-Date) -gt $EndTime)
    }
    END {
        #Get-CimInstance -ClassName Win32_SoundDevice | Select-Object -Property Name, Status
        Write-Output "Total duration: $((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")"
    }
}