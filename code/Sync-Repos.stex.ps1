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
script che processa un file CSV a scelta dell'utente eseguendo per ogni riga del file Git | Svn | Winmergerev 2016-01-17 15.40
#>
<# 
TODOXXXXXXXXXXXXXAAAAAAAAAAAAAA

***ERRORI NON COMPLETAMENTE STAMPATI
controlla riga 217 / 237 di errore in Sync-Repos.stex.ps1 (non stampa integralmente l'errore)



*** LASTEXITCODE SU GIT E SVN
controlla su Git e Svn LASTEXITCODE appena dopo $cmdoutput e non dopo LOG



***Run filelen/filesize check before commit, ONLY ON NEW FILES, *NOT* on all files
Options of SIZE+LEN on file xl
If problems, alert user and pause to wait for commit confirmation.
If unattended SKIP commit + log error + show error.




***Dividi colonna "RemotePath2DriveLetterID" in 2 parti: "RemotePath2Type" + "RemotePath2Value"   (IMPLEMENTA SENZA FRETTA, E' UTILE SOLO PER LA SINCRONIZZAZIONE DI SUBVERSION SU RETE CON SVNSERVE UTILIZZANDO L'INDIRIZZO IP DEL PC COL REPOSITORY)
Type: FromPcNameToIp|FromFileInRootToDriveName|AskUser
Value: PC Name, File Name, Prameter Name to be asked to the user (don't ask 2 times the same "parameter")

Spiegazione:
> "FromPcNameToIp" serve per i repository svn, per i quali SvnServe utilizza l'ip e non il nome computer




#>
<# 
per Git viene chiamato lo script Git-Syncper SVN viene chiamato lo script Svn-Sync
per MIRR viene chiamato lo script Mirr-Sync (che usa WinMerge)
#>

<# 
viene definito un file di LOG nella directory MyDocuments che viene passato ad ogni chiamata di Git-Sync e Svn-Sync
il log viene aperto in automatico
    (configura Notepad++ come editor predefinito, e impostalo per aggiornare automaticamente i file
    Settings > Preferences > MISC > File Status Auto-Detection | Update silently)
#>

<# 
il contenuto del file CSV (separato da ";") è il seguente :
----x-----x------x------ 
Git | Svn | Mirr | Field 
----x-----x------x------ 
 X  |  X  |  X   | Description
 X  |  X  |  X   | Category
 X  |  X  |  X   | RepoType = Git | Svn | Mirr
 X  |  X  |  X   | WkPath1Start = start of the Working path
 X  |  X  |  X   | WkPath2DriveLetterID = Working Copy ID of the Drive Letter
 X  |  X  |  X   | WkPath3End = end of the Working Copy Path
 X  |     |      | BranchName = Branch Name
 X  |     |      | RemoteName = Remote Repository Name
 X  |  X  |  X   | RemotePath1Start = start of the Remote Repository Path
 X  |  X  |  X   | RemotePath2DriveLetterID = Remote Repository ID of the Drive Letter
 X  |  X  |  X   | RemotePath3End = end of the Remote Repository Path
 X  |  X  |  X   | Action = Action to execute (passed to the called script; not defined here, but in the called script)


there are cases, for example with network drives, in which $RemotePath is defined and $RemoteId not.
or, maybe, the user wants to specify in $WkPath the full path comprised of drive letter without using
$WkId (for example because can't/does not want write to the root of the disk).
#>

<# 
il file CSV eseguito è uno tra i seguenti, che si deve trovare nella stessa directory di questo script:
> Sync-Repos-loc.stex.csv
> Sync-Repos-loc+onl.stex.csv
> Sync-Repos-loc+netsh.stex.csv
> Sync-Repos-loc+netsh+onl.stex.csv
#>

<# 
per il salvataggio automatico delle password Git installare "Git Credential Manager for Windows" :
https://github.com/Microsoft/Git-Credential-Manager-for-Windows   +   https://github.com/Microsoft/Git-Credential-Manager-for-Windows/releases
#>

function Main{    # define LOG FILE $LogFilePath and open it    $MyDocsPath = [Environment]::GetFolderPath("mydocuments")    $date = Get-Date -format "yyyyMMddHHmmss"
    $LogFilePath = $MyDocsPath + '\' + 'Sync-Repos-Log.' + $date + '.log.txt'
    "#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####" >> $LogFilePath
    Invoke-Item $LogFilePath   # open $LogFilePath   

    # ask user if elaboration is Unattended
    $Unattended = read-host "`nExecution is unattended [True|False <default>]? "
    if (($Unattended -eq $null) -or ($Unattended -eq "")){$Unattended = "False"}

    # ask user the type of Action List to read   
    $ActionsList = read-host "`nChoose the type of action list to read:`n1 = <default>`n"
    if (($ActionsList -eq $null) -or ($ActionsList -eq "")){$ActionsList = "1"}

    # with $ActionsList set $ActionsLFileName, containing the name of the Action List file to read
    switch ($ActionsList) 
    { 
        # LOCAL + ONLINE
        "1"
            { $ActionsLFileName = "Sync-Repos-ActionsList-1.csv" }
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

    # ask user to select CSV filter; fields filtered:
    # > CATEGORY
    #
    # read the Category Column (an unsorted, duplicated list)
    $ListTotal = $FileCsvContent.Category
    # save the List item selected by the user
    $ListSelectedValue= ListSelectItem -ListTotal $ListTotal -MessageToUser "`nSelect a Category of action from the list"
    # check the return value
    if ($ListSelectedValue -eq $null )
    {
       throw "No valid category was selected. EXIT !!!!!"
    }

    # process the CSV file
    foreach ($row in $FileCsvContent)
    {

        # read the content of CSV file
        $Description = $row.Description 
        $Category = $row.Category 
        $RepoType = $row.RepoType
        $WkPath1 = $row.WkPath1Start
        $WkPath2 = $row.WkPath2DriveLetterID
        $WkPath3 = $row.WkPath3End
        $BranchName = $row.BranchName
        $RemoteName = $row.RemoteName
        $RemotePath1 = $row.RemotePath1Start
        $RemotePath2 = $row.RemotePath2DriveLetterID
        $RemotePath3 = $row.RemotePath3End
        $Action = $row.Action

        # if the current ROW doesn't match the user selection EXIT current loop iteration   
        if ($Category -ne $ListSelectedValue) { continue }   #   <<< LOOP SKIP

        # remove spaces from read strings
        $RepoType = $RepoType.Trim()
        $WkPath1 = $WkPath1.Trim()
        $WkPath2 = $WkPath2.Trim()
        $WkPath3 = $WkPath3.Trim()
        $BranchName = $BranchName.Trim()
        $RemoteName = $RemoteName.Trim()
        $RemotePath1 = $RemotePath1.Trim()
        $RemotePath2 = $RemotePath2.Trim()
        $RemotePath3 = $RemotePath3.Trim()
        $Action = $Action.Trim()

        # If present, search $WkPath2 and $RemotePath2 with SearchDrive function and replace value of $WkPath2 and $RemotePath2.
        #
        # There are cases, for example with network drives, in which $RemotePath3 is defined and $RemotePath2 (and $RemotePath1) not.
        # or, maybe, the user wants to specify in $WkPath3 the full path comprised of drive letter without using $WkPath2 (for example because can't/does not want write to the root of the disk).
        #
        # If $WkPath2 is not found raise an error and skip calling Git | Svn | Mirr
        #
        #
        #
        # If $WkPath2 is defined, continue below
        if ($WkPath2)
        {
            # search for $WkPath2 with function SearchDrive
            $WkPathDrive = (SearchDrive -IdOfDriveToSearch $WkPath2) + ":/" 
            
            # if $WkPath2 was not found with SearchDrive
            if ($WkPathDrive -eq ":/")
            {
                # error message to the user
                ErrorMessage -ErrorMessage $WkPath2 + " ID not found. Wk " + $WkPath1 + $WkPath3 + " elaboration skipped."
                # set CallExternalScript flag to $false (later in the loop DO NOT call Git | Svn | Mirr scripts
                # because $WkPath2 was not found with function SearchDrive)
                $FlagCallExternalScript = $true
                # pause, if not $Unattended
                if (! $Unattended) { Pause -PauseMessage $PauseMessage }   
                # EXIT current loop iteration
                continue   #   <<< LOOP SKIP
            }
        }
        # If $RemotePath2 is defined, continue below
        if ($RemotePath2) 
        { 
            # search for $RemotePath2 with function SearchDrive
            $RemotePathDrive = (SearchDrive -IdOfDriveToSearch $RemotePath2) + ":/" 

            # if $RemotePath2 was not found with SearchDrive
            if ($RemotePathDrive -eq ":/")
            {
                # error message to the user
                ErrorMessage -ErrorMessage ("'" + $RemotePath2 + "' ID not found. Skipped Wk '" + $WkPath1 + $WkPath3 + "'")
                # set CallExternalScript flag to $false (later in the loop DO NOT call Git | Svn | Mirr scripts
                # because $WkPath2 was not found with function SearchDrive)
                $FlagCallExternalScript = $true
                # pause, if not $Unattended
                if (! $Unattended) { Pause -PauseMessage $PauseMessage }   
                # EXIT current loop iteration
                continue   #   <<< LOOP SKIP
            }
        }
        
        # build $WkPath and $RemotePath   (the path is built also if $WkPath2 and $RemotePath2 are without value (because 1 and 3 can have a value)
        $WkPath = $WkPath1 + $WkPathDrive + $WkPath3
        $RemotePath = $RemotePath1 + $RemotePathDrive + $RemotePath3

        # call Git | Svn | Mirr scripts
        switch ($RepoType)
        {
            "git"
            {
                GitSyncX -Action $Action -WkPath $WkPath -BranchName $BranchName -BareRepoName $RemoteName -BareRepoPath $RemotePath -LogFilePath $LogFilePath -CommitMessage "x" -Unattended $Unattended > $null
            }
            "svn"
            {
                SvnSyncX -Action $Action -WkPath $WkPath -BareRepoPath $RemotePath -LogFilePath $LogFilePath -CommitMessage $commmmmmmmmmm -Unattended $Unattended > $null
            }
            "mirr"
            {
                ErrorMessage -ErrorMessage "Mirr not implemented; error in " + $ActionsLFileName   # show error message
                if (! $Unattended) { Pause -PauseMessage $PauseMessage }   # pause, if not $Unattended
            }
            # other >>> ERROR !!!
            default
            { throw "RepoType " + $RepoType + " in " + $ActionsLFileName + " is not valid !!!" }
        }
    }

    # end of script message + pause
    Pause -PauseMessage "`nEND of script"

}

<#
################################################################################
################################################################################

INTERNAL FUNCTIONS

################################################################################
################################################################################
#>

<# 
Powershell snippet >[#ListSelectItemPsSnippetStex20151107] on onenote
#>
<# 
FUNCTION THAT TAKES AND UNSORTED/DUPLICATED LIST AND RETURN AN ITEM CHOOSEN BY THE USER

Input:
> -ListTotal   (an unsorted, duplicated list)

Return:
> the list item selected by the user
> $null if user select a wrong item

Event:
> NONE

Output:
> NONE
#>
function ListSelectItem()
{
    param (
    [array]$ListTotal = $(throw "-ListTotal is required."),
    [string]$MessageToUser = $(throw "-MessageToUser is required.")
    )
    
    # make unique, sorted list
    $ListSortUnique = $ListTotal | sort -Unique

    # show message to the user
    write-host $MessageToUser

    # show element number and list element
    $Count=0
    foreach ($elem in $ListSortUnique)
    {
        write-host ($count, ">", $elem, "<", $count) 
        $count = $count + 1
    }

    # ask for a list element
    $ListElement = read-host "Insert a number between 0 and " ($ListSortUnique.Count - 1)

    # return $null if no choice was made
    if (($ListElement -eq $null) -or ($ListElement -eq "")) { return $null }

    # selected item; if user select an item not listed (e.g. 9 in a list from 1 to 5) $SelectedItem will be $null
    $SelectedItem = $ListSortUnique[$ListElement]

    # return a list element
    return $SelectedItem
}



<# 
Powershell snippet >[#ArraySearchTextInASpecificRowPsSnippetStex20151107] on onenote
#>
<# 
Function to search inside an array, at a specific row, some text (a regex)

Input:
> -ArrayToTest: the array to search in
> -RowNumToTest: the number of the row of the array in which is expected the text that match $RegexToTest
> -RegexToTest: the regular expression to test

Return:
> $true: if the text was found
> $false: if the text was not fount

Event:
> NONE

Output:
> NONE
#>
function SearchArrayForRegexpInARow()
{
param (
$ArrayToTest = $(throw "-ArrayToSearch is required."), 
[int]$RowNumToTest = $(throw "-RowToTest is required."), 
[string]$RegexToTest = $(throw "-RegexToTest is required.")
)

    $Count=1
    $TextFound = $false

    foreach ($row in $ArrayToTest)
    {
        if (($count -eq $RowNumToTest) -and ($row -match $RegexToTest))
        {
            return $true   # return SUCCESS and exit loop
        }
        $count = $count + 1
    }

    return $false   # return FAILED SEARCH

}



<#
################################################################################
################################################################################

OTHER EXTERNAL FUNCTIONS

################################################################################
################################################################################
#>

# git 
function GitSyncX()
{
param (
    [Parameter(Mandatory = $true)]
    [string]$Action,
    [Parameter(Mandatory = $true)]
    [string]$WkPath,
    [string]$BranchName = "",   #optional
    [string]$BareRepoName = "",   #optional
    [string]$BareRepoPath = "",   #optional
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath,
    [string]$CommitMessage = "x",   #optional
    [Parameter(Mandatory = $true)]
    [string]$Unattended
)

    & $PSScriptRoot'.\lib\Git-Sync.stex.ps1' -Action $Action -WkPath $WkPath -BranchName $BranchName -BareRepoName $RemoteName -BareRepoPath $RemotePath -LogFilePath $LogFilePath -CommitMessage "x" -Unattended $Unattended > $null
}


# svn
function SvnSyncX()
{
param (
    [Parameter(Mandatory = $true)]
    [string]$Action,
    [Parameter(Mandatory = $true)]
    [string]$WkPath,
    [string]$BareRepoPath = "",   #optional
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath,
    [string]$CommitMessage = "x",   #optional
    [Parameter(Mandatory = $true)]
    [string]$Unattended
)
    & $PSScriptRoot'.\lib\Svn-Sync.stex.ps1' -Action $Action -WkPath $WkPath -BareRepoPath $RemotePath -LogFilePath $LogFilePath -CommitMessage $CommitMessage -Unattended $Unattended > $null
}


# Show an error message to STDOUT
function ErrorMessage()
{
    param (
    [string]$ErrorMessage= $(throw "-ErrorMessage is required.")
    )
    & $PSScriptRoot'.\lib\lib-ErrorMessage.stex.ps1' -ErrorMessage $ErrorMessage
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
    & $PSScriptRoot'.\lib\lib-Log-Append.stex.ps1' -LogFilePath $LogFilePath -CommandToLog $CommandToLog -CommandDescriptionToLog $CommandDescriptionToLog -CommandOutputToLog $CommandOutputToLog
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
function SearchDrive(){param (
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
