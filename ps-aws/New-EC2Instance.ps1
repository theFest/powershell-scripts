Function New-EC2Instance {
    <#
    .SYNOPSIS
    Creates a new EC2 instance in AWS with specified configurations.

    .DESCRIPTION
    This function creates a new EC2 instance in the specified AWS region. Ensures that necessary resources like VPC, Internet Gateway, Route Table, and Subnet are created and configured properly before creating the instance. It also sets appropriate tags for the instance.

    .PARAMETER AccessKey
    AWS Access Key ID used to authenticate with AWS.
    .PARAMETER SecretKey
    AWS Secret Access Key corresponding to the provided Access Key ID.
    .PARAMETER KeyPairName
    Name of the Key Pair to associate with the EC2 instance.
    .PARAMETER Region
    AWS region where the EC2 instance will be created.
    .PARAMETER TagKey
    Key of the tag to be applied to the EC2 instance.
    .PARAMETER TagValue
    Value of the tag to be applied to the EC2 instance.

    .EXAMPLE
    New-EC2Instance -AccessKey "your_access_key" -SecretKey "your_secret_key" -KeyPairName "EC2PSKeyPair" -Region "us-east-1" -TagKey "webserver" -TagValue "production" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AccessKey,

        [Parameter(Mandatory = $true)]
        [string]$SecretKey,

        [Parameter(Mandatory = $true)]
        [string]$KeyPairName,

        [Parameter(Mandatory = $true)]
        [string]$Region,

        [Parameter(Mandatory = $true)]
        [string]$TagKey,

        [Parameter(Mandatory = $true)]
        [string]$TagValue
    )
    BEGIN {
        Write-Host "Importing AWS .NetCore module...`n" -ForegroundColor Cyan
        Install-Module -Name AWS.Tools.Common -Force -Verbose
        Get-AWSPowerShellVersion
    }
    PROCESS {
        Write-Verbose -Message "Setting AWS credentials"
        Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs paulprofile 
        Set-AWSCredential -ProfileName paulprofile
        Write-Verbose -Message "Creating TagSpecification for instances..."
        $Tag = @{ Key = $TagKey; Value = $TagValue }
        $Tags = New-Object Amazon.EC2.Model.TagSpecification
        $Tags.ResourceType = "instance"
        $Tags.Tags.Add($Tag)
        Write-Verbose -Message "Checking if VPC already exists..."
        $VPC = Get-EC2Vpc -CidrBlock '10.0.0.0/16' -Region $Region -ErrorAction SilentlyContinue
        if (!$VPC) {
            Write-Verbose -Message "Creating a new VPC"
            $VPC = New-EC2VPC -CidrBlock '10.0.0.0/16' -Region $Region
            Write-Host "VPC created" -ForegroundColor Green
        }
        Write-Verbose -Message "Enable VPC DNS Settings"
        Edit-EC2VPCAttribute -VPCId $VPC.VPCId -EnableDnsSupport $True -Region $Region
        Write-Verbose -Message "Enable DNS Resolution in public for EC2 Instances"
        Edit-EC2VpcAttribute -VPCId $VPC.VPCId -EnableDnsHostnames $True -Region $Region
        Write-Verbose -Message "Checking if Internet Gateway already exists..."
        $InternetGateway = Get-EC2InternetGateway -Region $Region -ErrorAction SilentlyContinue
        if (!$InternetGateway) {
            Write-Verbose -Message "Create and Associate Internet Gateway"
            $InternetGateway = New-EC2InternetGateway -Region $Region
            Add-EC2InternetGateway -InternetGatewayId $InternetGateway.InternetGatewayId -VPCId $VPC.VpcId -Region $Region
            Write-Host "Internet Gateway created and associated with VPC"
        }
        Write-Verbose -Message "Checking if Route Table already exists..."
        $RouteTable = Get-EC2RouteTable -VpcId $VPC.VpcId -Region $Region -ErrorAction SilentlyContinue
        if (!$RouteTable) {
            Write-Verbose -Message "Create a Route Table"
            $RouteTable = New-EC2RouteTable -VpcId $VPC.VpcId -Region $Region
            New-EC2Route -GatewayId $InternetGateway.InternetGatewayId -RouteTableId $RouteTable.RouteTableId -DestinationCidrBlock '0.0.0.0/0' -Region $Region
            Write-Host "Route Table created and associated with VPC."
        }
        Write-Verbose -Message "Checking if Subnet already exists..."
        $Subnet = Get-EC2Subnet -VpcId $VPC.VpcId -CidrBlock '10.0.1.0/24' -Region $Region -ErrorAction SilentlyContinue
        if (!$Subnet) {
            Write-Verbose -Message "Create and Register the subnet"
            $Subnet = New-EC2Subnet -VpcId $VPC.VpcId -CidrBlock '10.0.1.0/24' -Region $Region
            Register-EC2RouteTable -RouteTableId $RouteTable.RouteTableId -SubnetId $Subnet.SubnetId -Region $Region
            Write-Host "Subnet created and associated with VPC."
        }
        Write-Verbose -Message "Get the latest EC2 image"
        $AMI = Get-SSMLatestEC2Image -Path ami-amazon-linux-latest -Region $Region -ImageName 'al2023-ami-kernel-6.1-x86_64'
        Write-Verbose -Message "Checking if the instance already exists..."
        $existingInstance = Get-EC2Instance -Filter @{ Name = 'tag:webserver'; Values = 'production' } -Region $Region -ErrorAction SilentlyContinue
        if (!$existingInstance) {
            Write-Verbose -Message "Create the EC2 Instance"
            New-Ec2Instance -Region $Region -ImageId $AMI -AssociatePublicIp $False -InstanceType 't2.micro' -SubnetId $Subnet.SubnetId -KeyName $KeyPairName -TagSpecification $Tags -name
            Write-Host "EC2 Instance created" -ForegroundColor Green
        }
        else {
            Write-Warning -Message "EC2 Instance with tag 'webserver=production' already exists!"
        }
    }
    END {
        Get-EC2Instance -Region $Region | Format-Table -AutoSize
    }
}
