#this script is to update the user property enableUser to disabled state of multiple users updated in list text file

#User who execute this should use Radius authentication method.
#Update the log file path on log file path and user list path - create the log file ResultsLog and list as text format
#update the API endPoind as required.
#Version 12.2

try
{
    $logFileName = "ResultsLog.txt"
    $logFilePath = "path"
    $logFilePathName = "path" + $logFileName
    $currentTimeStamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss-ms"
 
    if (!(Test-Path $logFilePathName))
    {
        New-Item -Path . -Name $logFileName -Type "file" -Value "--- CUSTOM LOG FILE FOR UpdateAuthTypeForUsers.ps1 FILE ---"
        Add-Content -Path $logFilePathName -Value "`r`n============================================="
        Add-Content -Path $logFilePathName -Value "-- RECORD EVENT $currentTimeStamp"
        Add-Content -Path $logFilePathName -Value "============================================="
    }
    else
    {
        Add-Content -Path $logFilePathName -Value "`r`n============================================="
        Add-Content -Path $logFilePathName -Value "-- RECORD EVENT $currentTimeStamp"
        Add-Content -Path $logFilePathName -Value "============================================="
    }
 
    # Entering credentials to login using RADIUS Authentication
    $uid = Read-Host 'Enter Your Username: '
    $passwordEncrypted = Read-Host 'Enter Password: ' -AsSecureString
    $plainPwd = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordEncrypted))
    Add-Content -Path $logFilePathName -Value "Credentials entered successfully"
 
    # Getting token from Vault using Logon API
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $body = "{`n `"username`": `"$uid`",`n `"password`": `"$plainPwd`",`n `"concurrentSession`": `"true`"`n}"
    Add-Type -AssemblyName PresentationCore, PresentationFramework
    $msgBody = "Please note that you will be prompted for RADIUS authentication (Microsoft Authenticator / SMS Token) to complete your login into CyberArk."
[System.Windows.MessageBox]::Show($msgBody)
$token = Invoke-RestMethod 'baseurl/API/auth/RADIUS/Logon' -Method 'POST' -Headers $headers -Body $body
    $token | ConvertTo-Json
    Add-Content -Path $logFilePathName -Value "AccessToken created successfully"
 
    # User list
    $userIdsFilePath = "inputfile"
 
    # Read user IDs from file
    $userIds = Get-Content $userIdsFilePath
 
    # Loop through each user ID
    foreach ($searchUser in $userIds) {
        try {
            #GET USERID CORRESPONDING TO USERNAME FROM CYBERARK
           $headersGetUserID = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
           $headersGetUserID.Add("Authorization", $token)
           $headersGetUserID.Add("Content-Type", "application/json")
 
$baseUrl = "baseurl/api/Users?filter=userType&search="
            $url = $baseurl + $searchUser
 
            Add-Content -Path $logFilePathName -Value "URL = $url"
 
           $responseGetUser = Invoke-RestMethod -Uri $url -Method 'GET' -Headers $headersGetUserID
           $responseGetUser | ConvertTo-Json

            
 
            # VALIDATE RESPONSE - HOW MANY USERS WERE RETURNED FROM SEARCH
            $responseCount = $responseGetUser.Users.Count
            Add-Content -Path $logFilePathName -Value "Count of User ID Fetched = $responseCount"
 
            if ($responseCount -ge 1) {
                # PROCEED IF AT LEAST 1 USER IS FOUND
$responseUserID = $responseGetUser.Users.id
                Add-Content -Path $logFilePathName -Value "User ID Fetched = $responseUserID"

                $responseUserName = $responseGetUser.Users.username
		Add-Content -path $logFilePathName -value "Username Fetched = $responseUserName"
 
                # UPDATE AUTHENTICATION METHOD TO LDAP
                $headersUpdateAuth = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $headersUpdateAuth.Add("Authorization", $token)
                $headersUpdateAuth.Add("Content-Type", "application/json")
 
$baseUrlUpdateAuth = "baseurl/api/Users/"
                $urlUpdateAuth = $baseUrlUpdateAuth + $responseUserID
                Add-Content -Path $logFilePathName -Value "UPDATE AUTHENTICATION METHOD URL = $urlUpdateAuth"
                #$Authentication="AuthTypePass"
                $updateAuthBody = @{
                "username"=$responseUserName
                  #"authenticationMethod"= "LDAP"
                  "enableUser"=0
                 
                  #"suspended"=1
                  } | ConvertTo-Json

                 # $updateAuthBody = @{
                
                    #$updateAuthBody["authenticationMethod"] = $Authentication
                   # }| ConvertTo-Json
 
                $responseUpdateAuth = Invoke-RestMethod -Uri $urlUpdateAuth -Method 'PUT' -Headers $headersUpdateAuth -Body $updateAuthBody
                $responseUpdateAuth | ConvertTo-Json
                Add-Content -Path $logFilePathName -Value "Update Authentication Method Response = $responseUpdateAuth"
            } else {
                # DISPLAY MESSAGE IF NO USER WITH THIS USERNAME IF FOUND IN CYBERARK
                Add-Content -Path $logFilePathName -Value "User Not Found"
                Add-Type -AssemblyName PresentationCore, PresentationFramework
                $msgBody = "User Not Found"
[System.Windows.MessageBox]::Show($msgBody)
            }
        }
        catch {
            Add-Content -Path $logFilePathName -Value "FAILURE MESSAGE: $_"
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = $_
[System.Windows.MessageBox]::Show($msgBody)
        }
    }
}
catch {
    Add-Content -Path $logFilePathName -Value "FAILURE MESSAGE: $_"
    Add-Type -AssemblyName PresentationCore, PresentationFramework
    $msgBody = $_
[System.Windows.MessageBox]::Show($msgBody)
}

