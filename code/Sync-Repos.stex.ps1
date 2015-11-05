<# 
Copyright 2015 Stefano Spinucci, mail virgo977virgo at gmail dot com

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. #>

<# 
script che processa un file CSV a scelta dell'utente eseguendo per ogni riga del file Git | Svn | Winmergerev 2015-11-05 04.53
per Git viene chiamato lo script Git-Syncper SVN viene chiamato lo script Svn-Sync
per MIRR viene chiamato lo script Mirr-Sync (che usa WinMerge)

viene definito un file di LOG nella directory MyDocuments che viene passato ad ogni chiamata di Git-Sync e Svn-Sync
il log viene aperto in automatico
    (configura Notepad++ come editor predefinito, e impostalo per aggiornare automaticamente i file
    Settings > Preferences > MISC > File Status Auto-Detection | Update silently)

il contenuto del file CSV (separato da ";") è il seguente :
----x-----x------x------ 
Git | Svn | Mirr | Field 
----x-----x------x------ 
 X  |  X  |  X   | RepoType = Git | Svn | Mirr
 X  |  X  |  X   | WkId = Working Copy ID
 X  |  X  |  X   | WkPath = Working Copy Path
 X  |     |      | BranchName = Branch Name
 X  |     |      | RemoteName = Remote Repository Name
 X  |  X  |  X   | RemoteId = Remote Repository ID
 X  |  X  |  X   | RemotePath = Remote Repository Path
 X  |  X  |  X   | Action = Action to execute (passed to the called script)

il file CSV eseguito è uno tra i seguenti, che si deve trovare nella stessa directory di questo script:
> Sync-Repos-loc.stex.csv
> Sync-Repos-loc+onl.stex.csv
> Sync-Repos-loc+netsh.stex.csv
> Sync-Repos-loc+netsh+onl.stex.csv

per il salvataggio automatico delle password Git installare "Git Credential Manager for Windows" :
https://github.com/Microsoft/Git-Credential-Manager-for-Windows   +   https://github.com/Microsoft/Git-Credential-Manager-for-Windows/releases
         
#>

function Main{    # define LOG FILE $LogFilePath and open it    $MyDocsPath = [Environment]::GetFolderPath("mydocuments")    $date = Get-Date -format "yyyyMMddhhmmss"
    $LogFilePath = $MyDocsPath + '\' + 'Sync-Repos-Log.' + $date + '.log.txt'
    "#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####" >> $LogFilePath
    Invoke-Item $LogFilePath   # open $LogFilePath   

    # ask user if elaboration is Unattended
    $Unattended = read-host "Execution is unattended [True|False <default>]? "
    if (($Unattended -eq $null) -or ($Unattended -eq "")){$Unattended = "False"}

    # ask user the type of Action List to read   (read in $ActionsList and confirm action in $ActionsLConfirm)
    $ActionsList = read-host "Choose the type of action list to read:`n1 = LOCAL <default> `n2 = LOCAL + ONLINE `n3 = LOCAL + NETSHARE `n4 = LOCAL + NETSHARE + ONLINE`n "
    if (($ActionsList -eq $null) -or ($ActionsList -eq "")){$ActionsList = "1"}
    $ActionsLConfirm = read-host "Choose the type of action list to read:`n1 = LOCAL <default> `n2 = LOCAL + ONLINE `n3 = LOCAL + NETSHARE `n4 = LOCAL + NETSHARE + ONLINE`n "
    if (($ActionsLConfirm -eq $null) -or ($ActionsLConfirm -eq "")){$ActionsLConfirm = "1"}
    if ($ActionsList -ne $ActionsLConfirm) {$(throw "Action list type confirmation FAILED")}

    # with $ActionsList set $ActionsLFileName, containing the name of the Action List file to read
    switch ($ActionsList) 
    { 
        # LOCAL
        "1"
            { $ActionsLFileName = "Sync-Repos-loc.stex.csv" }
        # LOCAL + ONLINE
        "2"
            { $ActionsLFileName = "Sync-Repos-loc+onl.stex.csv" }
        # LOCAL + NETSHARE
        "3"
            { $ActionsLFileName = "Sync-Repos-loc+netsh.stex.csv" }
        # LOCAL + NETSHARE + ONLINE
        "4"
            { $ActionsLFileName = "Sync-Repos-loc+netsh+onl.stex.csv" }
        # other >>> ERROR !!!
        default
            { throw "-Action list type ( " + $ActionList + " ) is not valid !!!" }
    }

    # test if $ActionsLFileName exists
    If (!(Test-Path -path $PSScriptRoot'.\'$ActionsLFileName -PathType Leaf))
    {
        throw $PSScriptRoot+'.\'+$ActionsLFileName + " is not valid filename !!!"
    }

    # read the csv file $ActionsLFileName in $FileCsvContent (to be processed below)
    $FileCsvContent = IMPORT-CSV $PSScriptRoot'.\'$ActionsLFileName -Delimiter ";"

    # process the CSV file
    foreach ($row in $FileCsvContent)
    {
        # legge il contenuto del file CSV
        $RepoType = $row.RepoType
        $WkId = $row.WkId
        $BranchName = $row.BranchName
        $RemoteName = $row.RemoteName
        $RemoteId = $row.RemoteId
        $Action = $row.Action

        # ricerca $WkId e $RemoteId
        if ($WkId) { $WkPath = (. SearchDrive -IdOfDriveToSearch $WkId) + $row.WkPath }   # define $WkPath only if $WkId has a value in the CSV
        if ($RemoteId) { $RemotePath = (. SearchDrive -IdOfDriveToSearch $RemoteId) + $row.RemotePath }   # define $RemotePath only if $RemoteId has a value in the CSV

        switch ($RepoType)
        {
            "Git"
            {
                & $PSScriptRoot'.\lib\lib-Git-Sync.stex.ps1' -Action $Action -WkPath $WkPath -BranchName $BranchName -BareRepoName $RemoteName -BareRepoPath $RemotePath -LogFilePath $LogFilePath -CommitMessage "x" -Unattended $Unattended > $null
            }
            "Svn"
            {
                & $PSScriptRoot'.\lib\lib-Svn-Sync.stex.ps1' -PauseMessage $PauseMessage
            }
            "Mirr"
            {
                . ErrorMessage -ErrorMessage "Mirr not implemented; error in " + $ActionsLFileName
                & $PSScriptRoot'.\lib\lib-Mirr-Sync.stex.ps1' -PauseMessage $PauseMessage
            }
            # other >>> ERROR !!!
            default
            { throw "RepoType " + $RepoType + " in " + $ActionsLFileName + " is not valid !!!" }
        }
    }

    # end of script message + pause
    . pause -PauseMessage "END of script`n"

}

<#
################################################################################
################################################################################

OTHER EXTERNAL FUNCTIONS

################################################################################
################################################################################
#>



# Show an error message to STDOUT
function ErrorMessage()
{
    param (
    [string]$ErrorMessage= $(throw "-ErrorMessage is required.")
    )
    & $PSScriptRoot'.\lib-ErrorMessage.stex.ps1' -ErrorMessage $ErrorMessage
}



# Log a message to file LogFilePath
function LogAppend()
{
    param (
    [string]$LogFilePath = $(throw "-LogFilePath is required."), 
    [string]$CommandToLog = $(throw "-CommandToLog is required."), 
    [string]$CommandDescriptionToLog = $(throw "-CommandDescriptionToLog is required."), 
    $CommandOutputToLog = $(throw "-CommandOutputToLog is required.")
    )
    & $PSScriptRoot'.\lib-Log-Append.stex.ps1' -LogFilePath $LogFilePath -CommandToLog $CommandToLog -CommandDescriptionToLog $CommandDescriptionToLog -CommandOutputToLog $CommandOutputToLog
}



# Pause execution
function Pause()
{
param (
    [string]$PauseMessage = ""   # optional
)
    & $PSScriptRoot'.\lib\lib-Pause.stex.ps1' -PauseMessage $PauseMessage
}



# search for a Drive searching the file -IdOfDriveToSearch in the root of every drive.
# return the Drive as "C:\" or "Z:\"
function SearchDrive{param (
    [string]$IdOfDriveToSearch = $(throw "-IdOfDriveToSearch is required.")
)
    return & $PSScriptRoot'.\lib\lib-Search-Drive.stex.ps1' -IdOfDriveToSearch $IdOfDriveToSearch}



<#
################################################################################
################################################################################

START OF THE PROGRAM

################################################################################
################################################################################
#>

. Main
