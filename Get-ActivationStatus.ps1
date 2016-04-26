function Get-ActivationStatus {
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[string[]]$Computer=($Env:COMPUTERNAME),
		[System.Management.Automation.CredentialAttribute()]$Credential
    )
	
	begin {}
	
    process {
		foreach ($ComputerName in $Computer) {
			if (test-connection -ComputerName $Computer -count 1 -quiet) {
				try {
					$wpa = Get-WmiObject SoftwareLicensingProduct -Credential $Credential -ComputerName $ComputerName `
					-Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" `
					-Property LicenseStatus -ErrorAction Stop
				} catch {
					$status = New-Object ComponentModel.Win32Exception ($_.Exception.ErrorCode)
					$wpa = $null
				}
			}
			$Result = New-Object psobject -Property @{
				ComputerName = $ComputerName;
				Status = [string]::Empty;
			}
			if ($wpa) {
				:outer foreach($item in $wpa) {
					switch ($item.LicenseStatus) {
						0 {$Result.Status = "Unlicensed"}
						1 {$Result.Status = "Licensed"; break outer}
						2 {$Result.Status = "Out-Of-Box Grace Period"; break outer}
						3 {$Result.Status = "Out-Of-Tolerance Grace Period"; break outer}
						4 {$Result.Status = "Non-Genuine Grace Period"; break outer}
						5 {$Result.Status = "Notification"; break outer}
						6 {$Result.Status = "Extended Grace"; break outer}
						default {$Result.Status = "Unknown value"}
					}
				}
			} else {
				$Result.Status = $status.Message
			}
			Write-Output $Result	
		}
    }
	
	end {}
}