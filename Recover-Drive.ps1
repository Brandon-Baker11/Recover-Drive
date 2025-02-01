function Recover-Drive {
    param([String][Parameter(Mandatory=$true,Position=0)] $bitlockerrecoverykey) #This will prompt the tech to enter the BitLocker Recovery key that drive is assigned

    $recoverykey = ConvertTo-SecureString $bitlockerrecoverykey -AsPlainText -Force #Converts the key that was entered into a secure string
    $RDVPassphrase = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "RDVPassphrase" #Gets the item property of the RDVPassphrase registry so we can make necessary changes
    $RDVEnforceUserCert = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "RDVEnforceUserCert"
    $comptuername = Read-Host "Enter the computer name"

    if (!(Test-Connection -ComputerName $comptuername -Quiet)) { #Tests to see if the computer being worked on is reachable
        Write-Host "This computer is unreachable."
    }
    else {
        Invoke-Command -ComputerName $computername -ScriptBlock { 
            if (Test-Path -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE") { #Tests the path exists in registry, if not we have bigger problems on our hands lol
                if ($RDVPassphrase.rdvpassphrase -eq 0){ 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "RDVPassphrase" -Value 1 # Changes value from 0 to 1 if True
                }
                if ($RDVEnforceUserCert.rdvenforceusercert -eq 1) {
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "RDVEnforceUserCert" -Value 0 # Changes value from 1 to 0 if True
                }
            }

            # Here a drive letter is selected with this foreach loop that iterates through the items in $driveletters
            $driveletters = @("D:", "E:", "F:", "G:", "H:", "I:", "J:", "K:")  
            $count = 0
            foreach ($letter in $driveletters) { # Iterating through each item in $driveletters
                if ($count -eq 0) {
                    if (!(Test-Path -Path $letter)) { # If the path with the current $letter doesn't exist, that $letter will be assigned as the $mountpoint to unlock the drive
                        $count += 1
                        $mountpoint = $letter
                    }
                }
            }
            Unlock-BitLocker -MountPoint $mountpoint -RecoveryPassword $recoverykey # Command to unlock the encrypted drive
            $newpw = Read-Host "Provide the new password for the external drive" # This will be the temporary password used to secure the drive
            $newpwsecure = ConvertTo-SecureString $newpw -AsPlainText -Force # Converts the temp password into a secure string
            Add-BitLockerKeyProtector -MountPoint $mountpoint -Password $newpwsecure # Uses $newpwsecure as new key to encrypt drive
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "RDVPassphrase" -Value 0 # 
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "RDVEnforceUserCert" -Value 1
        }
    }
    
    Write-Host $recoverykey
    
    
    
    
    
    
}
