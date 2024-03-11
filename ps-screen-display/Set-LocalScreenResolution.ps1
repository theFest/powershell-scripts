Function Set-LocalScreenResolution {
    <#
    .SYNOPSIS
    Changes the screen resolution of a connected display.

    .DESCRIPTION
    This function allows you to modify the screen resolution of a connected display by specifying the width and height.

    .PARAMETER Width
    Specifies the desired width for the screen resolution.
    .PARAMETER Height
    Specifies the desired height for the screen resolution.

    .EXAMPLE
    Set-LocalScreenResolution -Width 1920 -Height 1080

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias("w")]
        [int]$Width,

        [Parameter(Mandatory = $true, Position = 1)]
        [Alias("h")]
        [int]$Height
    )
    $Code = @"
    using System;
    using System.Runtime.InteropServices;

    public class ScreenResolution
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
        public struct DISPLAY_DEVICE
        {
            public int cb;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
            public string DeviceName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
            public string DeviceString;
            public int StateFlags;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
            public string DeviceID;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
            public string DeviceKey;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct DEVMODE
        {
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
            public string dmDeviceName;
            public short dmSpecVersion;
            public short dmDriverVersion;
            public short dmSize;
            public short dmDriverExtra;
            public int dmFields;
            public short dmOrientation;
            public short dmPaperSize;
            public short dmPaperLength;
            public short dmPaperWidth;
            public short dmScale;
            public short dmCopies;
            public short dmDefaultSource;
            public short dmPrintQuality;
            public short dmColor;
            public short dmDuplex;
            public short dmYResolution;
            public short dmTTOption;
            public short dmCollate;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
            public string dmFormName;
            public short dmLogPixels;
            public short dmBitsPerPel;
            public int dmPelsWidth;
            public int dmPelsHeight;
            public int dmDisplayFlags;
            public int dmDisplayFrequency;
            public int dmICMMethod;
            public int dmICMIntent;
            public int dmMediaType;
            public int dmDitherType;
            public int dmReserved1;
            public int dmReserved2;
            public int dmPanningWidth;
            public int dmPanningHeight;
        }

        [DllImport("user32.dll")]
        public static extern int EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);

        [DllImport("user32.dll")]
        public static extern int EnumDisplaySettingsEx(string lpszDeviceName, int iModeNum, ref DEVMODE lpDevMode, uint dwFlags);

        [DllImport("user32.dll")]
        public static extern int ChangeDisplaySettingsEx(string lpszDeviceName, ref DEVMODE lpDevMode, IntPtr hwnd, uint dwflags, IntPtr lParam);

        public const int ENUM_CURRENT_SETTINGS = -1;

        public static void ListConnectedScreens()
        {
            int deviceIndex = 0;
            while (true)
            {
                DISPLAY_DEVICE d = new DISPLAY_DEVICE();
                d.cb = Marshal.SizeOf(d);

                if (EnumDisplayDevices(null, (uint)deviceIndex, ref d, 0) == 0)
                {
                    break;
                }

                if ((d.StateFlags & 1) != 0) // Check if the display is connected
                {
                    Console.WriteLine("Device " + deviceIndex + ": " + d.DeviceString + " (" + d.DeviceName + ")");
                }

                deviceIndex++;
            }
        }

        public static string ChangeResolution(int width, int height, int deviceIndex)
        {
            DISPLAY_DEVICE d = new DISPLAY_DEVICE();
            d.cb = Marshal.SizeOf(d);

            if (EnumDisplayDevices(null, (uint)deviceIndex, ref d, 0) != 0)
            {
                DEVMODE dm = GetDevMode();
                if (EnumDisplaySettingsEx(d.DeviceName, ENUM_CURRENT_SETTINGS, ref dm, 0) != 0)
                {
                    dm.dmPelsWidth = width;
                    dm.dmPelsHeight = height;

                    int iRet = ChangeDisplaySettingsEx(d.DeviceName, ref dm, IntPtr.Zero, 0, IntPtr.Zero);

                    switch (iRet)
                    {
                        case 0:
                            return "Success";
                        case 1:
                            return "Reboot required for changes to take effect.";
                        default:
                            return "Failed to change the resolution.";
                    }
                }
                else
                {
                    return "Failed to get current display settings.";
                }
            }
            else
            {
                return "Failed to retrieve device information.";
            }
        }

        private static DEVMODE GetDevMode()
        {
            DEVMODE dm = new DEVMODE();
            dm.dmDeviceName = new string(new char[32]);
            dm.dmFormName = new string(new char[32]);
            dm.dmSize = (short)Marshal.SizeOf(dm);
            return dm;
        }
    }
"@
    Add-Type -TypeDefinition $Code
    [ScreenResolution]::ListConnectedScreens()
    $SelectedDeviceIndex = Read-Host "Enter the index of the screen to change resolution"
    [ScreenResolution]::ChangeResolution($Width, $Height, $SelectedDeviceIndex)
}
