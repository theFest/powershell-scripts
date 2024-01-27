Function Start-ARPSpoofing {
    <#
    .SYNOPSIS
    Starts ARP spoofing by simulating ARP packets between specified IPs on a chosen network interface.

    .DESCRIPTION
    This function launches a graphical ARP spoofing tool to simulate ARP packets between a specified target IP and gateway IP on a selected network interface.

    .PARAMETER TargetIP
    Specifies the IP address of the target machine.
    .PARAMETER GatewayIP
    IP address of the gateway/router.
    .PARAMETER Interface
    Network interface to use for ARP spoofing.
    .PARAMETER PacketCount
    Number of ARP packets to simulate, default is 100.

    .EXAMPLE
    Start-ARPSpoofing -TargetIP "192.168.1.2" -GatewayIP "192.168.1.1" -Interface "Ethernet" -PacketCount 200

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TargetIP,

        [Parameter(Mandatory = $false)]
        [string]$GatewayIP,

        [Parameter(Mandatory = $false)]
        [string]$Interface,

        [Parameter(Mandatory = $false)]
        [int]$PacketCount = 100
    )
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $Form = New-Object System.Windows.Forms.Form
        $Form.Text = "ARP Spoofing Tool"
        $Form.Size = New-Object System.Drawing.Size(400, 300)
        $Form.StartPosition = "CenterScreen"
        $Form.BackColor = "#2B2B2B"
        $Form.ForeColor = "#FFFFFF"
        $LabelInterface = New-Object System.Windows.Forms.Label
        $LabelInterface.Text = "Select Network Interface:"
        $LabelInterface.Location = New-Object System.Drawing.Point(10, 20)
        $LabelInterface.ForeColor = "#FFFFFF"
        $Form.Controls.Add($LabelInterface)
        $DropdownInterface = New-Object System.Windows.Forms.ComboBox
        $DropdownInterface.Location = New-Object System.Drawing.Point(200, 20)
        $DropdownInterface.Size = New-Object System.Drawing.Size(150, 20)
        $DropdownInterface.Items.AddRange((Get-NetworkInterfaces))
        $DropdownInterface.SelectedIndex = 0
        $DropdownInterface.BackColor = "#464646"
        $DropdownInterface.ForeColor = "#FFFFFF"
        $Form.Controls.Add($DropdownInterface)
        $LabelTargetIP = New-Object System.Windows.Forms.Label
        $LabelTargetIP.Text = "Target IP:"
        $LabelTargetIP.Location = New-Object System.Drawing.Point(10, 50)
        $LabelTargetIP.ForeColor = "#FFFFFF"
        $Form.Controls.Add($LabelTargetIP)
        $TextBoxTargetIP = New-Object System.Windows.Forms.TextBox
        $TextBoxTargetIP.Location = New-Object System.Drawing.Point(200, 50)
        $TextBoxTargetIP.Size = New-Object System.Drawing.Size(150, 20)
        $TextBoxTargetIP.BackColor = "#464646"
        $TextBoxTargetIP.ForeColor = "#FFFFFF"
        $Form.Controls.Add($TextBoxTargetIP)
        $LabelGatewayIP = New-Object System.Windows.Forms.Label
        $LabelGatewayIP.Text = "Gateway IP:"
        $LabelGatewayIP.Location = New-Object System.Drawing.Point(10, 80)
        $LabelGatewayIP.ForeColor = "#FFFFFF"
        $Form.Controls.Add($LabelGatewayIP)
        $TextBoxGatewayIP = New-Object System.Windows.Forms.TextBox
        $TextBoxGatewayIP.Location = New-Object System.Drawing.Point(200, 80)
        $TextBoxGatewayIP.Size = New-Object System.Drawing.Size(150, 20)
        $TextBoxGatewayIP.BackColor = "#464646"
        $TextBoxGatewayIP.ForeColor = "#FFFFFF"
        $Form.Controls.Add($TextBoxGatewayIP)
        $LabelPacketCount = New-Object System.Windows.Forms.Label
        $LabelPacketCount.Text = "Packets Sent:"
        $LabelPacketCount.Location = New-Object System.Drawing.Point(10, 110)
        $LabelPacketCount.ForeColor = "#FFFFFF"
        $Form.Controls.Add($LabelPacketCount)
        $LabelPacketCountDisplay = New-Object System.Windows.Forms.Label
        $LabelPacketCountDisplay.Text = "0"
        $LabelPacketCountDisplay.Location = New-Object System.Drawing.Point(200, 110)
        $LabelPacketCountDisplay.ForeColor = "#FFFFFF"
        $Form.Controls.Add($LabelPacketCountDisplay)
        $ButtonStart = New-Object System.Windows.Forms.Button
        $ButtonStart.Location = New-Object System.Drawing.Point(50, 150)
        $ButtonStart.Size = New-Object System.Drawing.Size(120, 30)
        $ButtonStart.Text = "Start ARP Spoofing"
        $ButtonStart.BackColor = "#007ACC"
        $ButtonStart.ForeColor = "#FFFFFF"
        $ButtonStart.Add_Click({
                try {
                    $SelectedInterface = $DropdownInterface.SelectedItem
                    $TargetIP = $TextBoxTargetIP.Text
                    $GatewayIP = $TextBoxGatewayIP.Text
                    if (-not [string]::IsNullOrEmpty($SelectedInterface) -and
                        -not [string]::IsNullOrEmpty($TargetIP) -and
                        -not [string]::IsNullOrEmpty($GatewayIP)) {
                        $PacketCount = [int]$LabelPacketCountDisplay.Text
                        ## ARP Spoofing logic here
                        ## Simulate ARP packets sent to $TargetIP and $GatewayIP on interface $SelectedInterface
                        $LabelPacketCountDisplay.Text = ($PacketCount + 100).ToString()
                    }
                    else {
                        Write-Warning -Message "Please fill in all the required fields!"
                    }
                }
                catch {
                    Write-Error -Message "Error occurred during ARP Spoofing: $_"
                }
            })
        $Form.Controls.Add($ButtonStart)
        $ButtonStop = New-Object System.Windows.Forms.Button
        $ButtonStop.Location = New-Object System.Drawing.Point(200, 150)
        $ButtonStop.Size = New-Object System.Drawing.Size(120, 30)
        $ButtonStop.Text = "Stop ARP Spoofing"
        $ButtonStop.BackColor = "#FF4500"
        $ButtonStop.ForeColor = "#FFFFFF"
        $ButtonStop.Add_Click({
                try {
                    ## Cleanup ARP cache entries here
                    Write-Host "Stopping ARP Spoofing"
                    $LabelPacketCountDisplay.Text = "0"
                }
                catch {
                    Write-Error "Error occurred during cleanup: $_"
                }
            })
        $Form.Controls.Add($ButtonStop)
        $Form.ShowDialog()
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
}
