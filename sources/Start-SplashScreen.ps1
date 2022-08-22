<#
    .Synopsis
    Creates a Splash Screen before loading the tool.
    In this part of the script, the modules are being imported and Sessions are being opened.

    .Notes
    Author: Paulo Schwab
    Date: 29-Dec-2021

    .Dependencies
        Install-Module -Name ThreadJob


#>
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll')       | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\System.Windows.Interactivity.dll') | out-null

function Start-SplashScreen{
    $Pwshell.Runspace = $runspace
    $script:handle = $Pwshell.BeginInvoke() 
}

function Close-SplashScreen{
    $hash.window.Dispatcher.Invoke("Normal",[action]{ $hash.window.close() })
    $Pwshell.EndInvoke($handle) | Out-Null
    $runspace.Close() | Out-Null
}

$hash = [hashtable]::Synchronized(@{})

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("hash",$hash) 
    $Pwshell = [PowerShell]::Create()

    $Pwshell.AddScript({
    $xml = [xml]@"
     <Window
	xmlns:Controls="clr-namespace:MahApps.Metro.Controls;assembly=MahApps.Metro"
	xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
	xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
	x:Name="WindowSplash" Title="SplashScreen" WindowStyle="None" WindowStartupLocation="CenterScreen"
	Background="#008ac9" ShowInTaskbar ="true" 
	Width="600" Height="350" ResizeMode = "NoResize" >
	
	<Grid>
		<Grid.RowDefinitions>
            <RowDefinition Height="70"/>
            <RowDefinition/>
        </Grid.RowDefinitions>
		
		<Grid Grid.Row="0" x:Name="Header" >	
			<StackPanel Orientation="Horizontal" HorizontalAlignment="Left" VerticalAlignment="Stretch" Margin="20,10,0,0">       
				<Image x:Name="Logo" RenderOptions.BitmapScalingMode="Fant" HorizontalAlignment="Left" Margin="0,0,0,0" Width="60" Height="60" VerticalAlignment="Top" /> 
			    <Label Content="Access Management Tools" Margin="5,0,0,0" Foreground="White" Height="50"  FontSize="30"/>
			</StackPanel> 
		</Grid>
        <Grid Grid.Row="1" >
		 	<StackPanel Orientation="Vertical" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="5,5,5,5">
				<Label x:Name="LoadingLabel" Content="Loading Modules" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="24" Margin = "0,0,0,0" />
				<Controls:MetroProgressBar IsIndeterminate="True" Foreground="White" HorizontalAlignment="Center" Width="350" Height="20"/>
			</StackPanel>	
        </Grid>
	</Grid>
		
</Window> 
"@
 
    $reader = New-Object System.Xml.XmlNodeReader $xml
    $hash.window = [Windows.Markup.XamlReader]::Load($reader)
    $hash.LoadingLabel = $hash.window.FindName("LoadingLabel")
    $hash.Logo = $hash.window.FindName("Logo")
    $hash.Logo.Source=".\resources\HuismanHLogo.png"
    #$hash.LoadingLabel.Content= "Loading Modules"
    $hash.window.ShowDialog() 
    
}) | Out-Null

Start-SplashScreen

try {
    if(-not(Get-Module ActiveDirectory)){
        Import-Module activedirectory
    }
    
    $ActiveSessions = Get-PSSession
    
    if (!($ActiveSessions.ComputerName -contains "outlook.office365.com")){
        <#TODO
        $Runspace = [runspacefactory]::CreateRunspace()
        $PowerShell = [powershell]::Create()
        $PowerShell.Runspace = $Runspace
        $Runspace.Open()
        $PowerShell.AddScript({Connect-ExchangeOnline})
        $PowerShell.BeginInvoke()
        #>
        Connect-ExchangeOnline -ErrorAction Stop
    }

    if (!($ActiveSessions.ComputerName -contains "nl-sch01-ex50.hsle.local")){
        $LocalExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://NL-SCH01-EX50.hsle.local/Powershell -Authentication Kerberos -ErrorAction Stop

        Import-PSSession $LocalExchangeSession -CommandName Enable-RemoteMailbox,Set-RemoteMailbox
    }


}
catch [System.Management.Automation.Remoting.PSRemotingTransportException]{
    $result = [System.Windows.Forms.MessageBox]::Show("User $($env:USERNAME) doesn't have permissions to connect to Exchange Online.`nUse another account?","Error",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Error)
    if ($result -eq "Yes"){
        $credential = Get-Credential
        $LocalExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://NL-SCH01-EX50.hsle.local/Powershell -Credential $credential -Authentication Kerberos -ErrorAction Stop
        Import-PSSession $LocalExchangeSession -CommandName Enable-RemoteMailbox,Set-RemoteMailbox
    }
}
catch {
    [System.Windows.Forms.MessageBox]::Show($error[0].Exception.Message,"Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
}

Close-SplashScreen