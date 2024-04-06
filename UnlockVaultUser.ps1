#Unlocking user account using ps in vault

try
{  
    #VALIDATE IF CUSTOM LOG FILE FOR THIS POWERSHELL CODE EXISTS, IF NOT CREATE A TXT FILE
	$logFileName = "LogUnlockAccCyaAPI.txt"
	$logFilePath = "."
	$logFilePathName = ".\" + $logFileName
	$currentTimeStamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss-ms"
	if (!(Test-Path $logFilePathName))
	{
	    New-Item -path . -name $logFileName -type "file" -value "--- CUSTOM LOG FILE"
		Add-Content -path $logFilePathName -value "`r`n============================================="
	    Add-Content -path $logFilePathName -value "-- RECORD EVENT $currentTimeStamp"
		Add-Content -path $logFilePathName -value "============================================="		
	}
	else
	{
		Add-Content -path $logFilePathName -value "`r`n============================================="
	    Add-Content -path $logFilePathName -value "-- RECORD EVENT $currentTimeStamp"
		Add-Content -path $logFilePathName -value "============================================="
	}
	
	#GCC HELPDESK TO ENTER THEIR CREDENTIALS TO LOGIN INTO CYBERARK WITH RADIUS AUTHENTICATION
	$uid = Read-Host 'Enter Your Username: '
	$passwordEncrypted = Read-Host 'Enter Password: ' -AsSecureString
	$plainPwd = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordEncrypted))
	Add-Content -path $logFilePathName -value "Credentials entered successfully"

	#GET TOKEN FROM CYBERARK VAULT USING LOGON API
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $body = "{`n	`"username`": `"$uid`",`n	`"password`": `"$plainPwd`",`n	`"concurrentSession`": `"true`"`n}"
	Add-Type -AssemblyName PresentationCore,PresentationFramework
	$msgBody = "Please note that you will be prompted for RADIUS authentication (MicroSoft Authenticator / SMS Token) to complete your login into CyberArk."
	[System.Windows.MessageBox]::Show($msgBody)
    $token = Invoke-RestMethod 'baseurl/API/auth/RADIUS/Logon' -Method 'POST' -Headers $headers -Body $body
	$token | ConvertTo-Json
    Add-Content -path $logFilePathName -value "AccessToken created successfully"
	
	
	#GCC HELPDESK TO PROVIDE USERNAME OF THE ACCOUNT TO BE UNLOCKED
	$searchUser = Read-Host 'Enter Username to Unlock Account (enter username): '
	
	#GET USERID CORRESPONDING TO USERNAME FROM CYBERARK
	$headersGetUserID = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
	$headersGetUserID.Add("Authorization",$token)
	$headersGetUserID.Add("Content-Type", "application/json")
    $baseUrl = "baseurl/api/Users?filter=userType&search="
    $url = $baseurl + $searchUser	
    Add-Content -path $logFilePathName -value "URL = $url"
    $responseGetUser = Invoke-RestMethod -uri $url -Method 'GET' -Headers $headersGetUserID
	$responseGetUser | ConvertTo-Json
	
	#VALIDATE RESPONSE - HOW MANY USERS WERE RETURNED FROM SEARCH
	$responseCount = $responseGetUser.Users.Count
	Add-Content -path $logFilePathName -value "Count of User ID Fetched = $responseCount"
	if($responseCount -eq 1) #PROCEED ONLY IF 1 USER IS FOUND
	{
		$responseUserID = $responseGetUser.Users.id
		Add-Content -path $logFilePathName -value "User ID Fetched = $responseUserID"
		
		$responseUserName = $responseGetUser.Users.username
		Add-Content -path $logFilePathName -value "Username Fetched = $responseUserName"
		
		
		#CHECK ACCOUNT STATUS IF IT'S SUSPENDED OR NOT
		$headersGetUserStatus = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
		$headersGetUserStatus.Add("Authorization",$token)
		$headersGetUserStatus.Add("Content-Type", "application/json")
		$baseUrlGetUserStatus = "baseurl/api/Users/"
		$urlGetUserStatus = $baseUrlGetUserStatus + $responseUserID
		Add-Content -path $logFilePathName -value "GET USER DETAILS URL = $urlGetUserStatus"
		$responseGetUserStatus = Invoke-RestMethod -uri $urlGetUserStatus -Method 'GET' -Headers $headersGetUserStatus
		$responseGetUserStatus | ConvertTo-Json
		$responseUserSuspended = $responseGetUserStatus.suspended
		
			if($responseUserSuspended.ToString() -eq "False")
			{
				#DISPLAY MESSAGE THAT USER IS ALREADY ACTIVE IN CYBERARK
				Add-Content -path $logFilePathName -value "User is not locked in CyberArk."
				Add-Type -AssemblyName PresentationCore,PresentationFramework
				$msgBody = "User is not locked in CyberArk."
				[System.Windows.MessageBox]::Show($msgBody)
			}
			else 
			{
				#ACTIVATE USER IN CYBERARK
				$headersActivateUser = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
				$headersActivateUser.Add("Authorization",$token)
				$headersActivateUser.Add("Content-Type", "application/json")
				$baseUrlActivate = "baseurl/api/Users/"
				$urlActivate = $baseUrlActivate + $responseUserID + "/Activate"
				Add-Content -path $logFilePathName -value "ACTIVATE ACCOUNT URL = $urlActivate"
				$responseActivateUser = Invoke-RestMethod -uri $urlActivate -Method 'POST' -Headers $headersActivateUser
				$responseActivateUser | ConvertTo-Json
				Add-Content -path $logFilePathName -value "Activate User Response = $responseActivateUser"	
			}		
	}
	elseif($responseCount -eq 0)
	{
		#DISPLAY MESSAGE IF NO USER WITH THIS USERNAME IF FOUND IN CYBERARK
		Add-Content -path $logFilePathName -value "User Not Found"
		Add-Type -AssemblyName PresentationCore,PresentationFramework
		$msgBody = "User Not Found"
		[System.Windows.MessageBox]::Show($msgBody)
	}
	else
	{
		#DISPLAY MESSAGE IF USER SEARCH FAILED
		Add-Content -path $logFilePathName -value "User Search Failed. Please try again."
		Add-Type -AssemblyName PresentationCore,PresentationFramework
		$msgBody = "User Search Failed. Please try again."
		[System.Windows.MessageBox]::Show($msgBody)
	}
}
catch
{
Add-Content -path $logFilePathName -value "FAILURE MESSAGE: "
Add-Content -path $logFilePathName -value $_

Add-Type -AssemblyName PresentationCore,PresentationFramework
$msgBody = $_
[System.Windows.MessageBox]::Show($msgBody)
}