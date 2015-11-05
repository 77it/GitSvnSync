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
script Svn-Sync
by Stefano Spinucci virgo977virgo at gmail.com
rev 201511050511

Input:
> -Action:   (case insensitive)
  >> CommitUpdate:  COMMIT(diff)+UPDATE
> -WkPath
  path della working directory
> [-BareRepoPath]
  opzionale, path del bare repository; se questo valore è presente, viene eseguito il comando "svn relocate" sulla nuova Repository Root
> -LogFilePath
  il nome del file di LOG nel quale appendere il dettaglio di ciò che viene fatto (una sintesi viene scritta nella command line)
> [-CommitMessage]
> -Unattended: True|False   (case insensitive)
  flag che determina se l'esecuzione del programma non viene mai interrotta per dialogare con l'utente e chiedere conferma di azioni

Return:
> True if there were no errors
> False if there were errors

Output:
> something, also when -Unattended = True
#>



<#
################################################################################
################################################################################

PARAM

################################################################################
################################################################################
#>



param (
#    [string]$WkPath = "http://defaultserver",   # read + default parameter
#    [string]$password = $( Read-Host "Input password, please" ),
#    [switch]$force = $false
#    [string]$SvnWkDir = $(throw "-SvnWkDir is required.")
    [Parameter(Mandatory = $true)]
    [string]$Action,
    [Parameter(Mandatory = $true)]
    [string]$WkPath,
    [Parameter(Mandatory = $true)]
    [string]$BareRepoPath = "",   #optional
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath,
    [string]$CommitMessage = "x",   #optional
    [Parameter(Mandatory = $true)]
    [string]$Unattended
)<#
################################################################################
################################################################################

MAIN

################################################################################
################################################################################
#>

function Main{
    # initialize Return Flag
    $ReturnFlag = $true

    # START MESSAGE
    write-host  "Repo '" $WkPath "' START " $Action -foregroundcolor "White" -backgroundcolor "blue"

    # SET Environment
    . SetEnvironment

    # do checks
    . Checks

    # if -BareRepoPath has a value <> "" 
    # if this value is present is executed the command "svn relocate" with the new Repository Root 
    if ($BareRepoPath)
    {
        if (!(. SvnReplaceRepositoryRoot -WkPath $WkPath -BareRepoPath $BareRepoPath -LogFilePath $LogFilePath))
        {
            ErrorMessage ("ERROR with Svn Relocate of " + $WkPath + " to " + $BareRepoPath )   # error message on stdout
        }
    }
        
    # do actions
    switch ($Action) 
    { 
        "CommitUpdate"
            {
                if (!(. ActionCommitUpdate))
                {
                # if ERROR with Git command
                    ErrorMessage ("ERROR with Git COMMIT(diff)+UPDATE in "+$WkPath)   # error message on stdout
                    $ReturnFlag = $false   # Return Error
                }
            }
        default
            { throw "-Action ( " + $Action + " ) is not a valid action !!!" }
    }

    # END MESSAGE
    write-host  "*****END*****" -foregroundcolor "White" -backgroundcolor "blue"

    # return Return Flag
    return $ReturnFlag

}



<#
################################################################################
################################################################################

SET ENV

################################################################################
################################################################################
#>



function SetEnvironment
{

    # nothing to do

}



<#
################################################################################
################################################################################

CHECKS

################################################################################
################################################################################
#>



# do checks
function Checks
{

<#
check if file exists:
> LogFilePath
#>
    If (!(Test-Path -path $LogFilePath -PathType Leaf))
    {
        throw "-LogFilePath ( " + $LogFilePath + " ) is not a file !!!"
    }

<#
check if dirs exists:
> WkPath
> [BareRepoPath]
#>
    If (!(Test-Path -path $WkPath -PathType Container))
    {
        throw "-WkPath ( " + $WkPath + " ) is not a directory !!!"
    }

    If ( ($BareRepoPath -ne "") -and (!(Test-Path -path $BareRepoPath -PathType Container)) )
    {
        throw "-BareRepoPath ( " + $BareRepoPath + " ) is not a directory !!!"   
    }

<#
check if is a working copy:
> WkPath
#>
    If (! (. SvnTestIfDirIsUnderControl -PathToTest $WkPath -LogFilePath $LogFilePath ))    
    {
        throw "-WkPath ( " + $WkPath + " ) is not a directory under Git control !!!"   
    }
    
<#
check if remote path contains a bare repository:
> [BareRepoPath]
#>
    # if $BareRepoName is defined, continue with testing
    If ($BareRepoPath -ne "")
    {
        # if $BareRepoPath is not a bare repository, exit with error
        If (! (. SvnTestIfRepoIsBare $BareRepoPath $LogFilePath))    
        {
            throw "-BareRepoPath ( " + $BareRepoPath + " ) is not a Bare Repository !!!"   
        }
    }

<#
check if Action is one element of the list
AND
if Action have needed parameters:
> CommitUpdate:
  WkPath
#>
    switch ($Action) 
    { 
        "CommitUpdate"
        {
            if (! ($WkPath) )
            { throw "Missing -WkPath" }
        } 
        default
        { throw "-Action ( " + $Action + " ) is not a valid action !!!" }
    }


<#
check CommitMessage value
#>
    if (!($CommitMessage))
    {
        $CommitMessage = "x"
    }
    
<#
check Unattended value
#>
    switch ($Unattended) 
    { 
        "True"
        {
            $UnattBool=$true
        } 
        "False"
        {
            $UnattBool=$false
        } 
        default
        { throw "-Unattended ( " + $Unattended + " ) is not True or False !!!" }
    }

}




<#
################################################################################
################################################################################

SVN ACTIONS

################################################################################
################################################################################
#>

<#

# check if -WkPath is a SVN directoty
svn info


# check if -BareRepoPath is a SVN repository
svnadmin info .


svn relocate "file:///C:/e4-linked/@svnbare/piccolaimpresa   res.big.svn"


cd %1


svn add *.* --force

# from   http://stackoverflow.com/questions/9600382/svn-command-to-delete-all-locally-missing-files
svn status | ? { $_ -match '^!\s+(.*)' } | % { svn rm $Matches[1] }

svn st >> %TEMP%\svndiff.stex.txt
start %TEMP%\svndiff.stex.txt


svn diff >> %TEMP%\svndiff.stex.txt
start %TEMP%\svndiff.stex.txt


svn ci -m "x"


svn st


svn up

#>



function ActionCommitUpdate ()
{

    # iniziatlize Return Flag
    $ReturnFlag = $true

    # svn add (and do svn rm for all deleted files)
    if (!(. SvnAdd -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Svn command
        ErrorMessage ("ERROR with Svn ADD in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            . pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }

    # git status: Print / Check if error
    #
    # if not unattended, show svn status
    if (! $UnattBool)
    {
        $cmdOutput = . SvnStatusMessage -WkPath $WkPath -LogFilePath $LogFilePath 
        # if there is some status message, print the message
        if ($cmdOutput)
        {
            write-host "`nSvn STATUS" -ForegroundColor Red
            write-host $cmdOutput
        }
    }
    # svn status, and check if command goes in error
    if (!(. SvnStatus -WkPath $WkPath -LogFilePath $LogFilePath))   
    {
    # if ERROR with Svn command
        ErrorMessage ("ERROR with Svn STATUS in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            . pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }

    # svn Commit
    #
    # if there is something to commit...
    if (. SvnCheckIfCommitIsNeeded -WkPath $WkPath -LogFilePath $LogFilePath)
    {
        # if unattended, commit
        if ($UnattBool)
        {
            if (!(. SvnCommit -WkPath $WkPath -CommitMessage $CommitMessage -LogFilePath $LogFilePath))
            # if ERROR with Svn command, set Return Flag to False
            {
                ErrorMessage ("ERROR with Svn COMMIT in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
            }   
        }
        else
        # if not unattended, ask user to commit
        {
            write-host "`nSvn COMMIT" -ForegroundColor Red
            # svn commit diff on Log
            . SvnCommitDiff -WkPath $WkPath -LogFilePath $LogFilePath > $null
            write-host "`nsaved detailed Commit diff on LOG `n"
            # pause
            . pause -PauseMessage "Press any key to COMMIT <paused...>`n"
            # commit
            if (!(. SvnCommit -WkPath $WkPath -CommitMessage $CommitMessage -LogFilePath $LogFilePath))
            # if ERROR with Svn command, set Return Flag to False and pause
            {
                ErrorMessage ("ERROR with Svn COMMIT in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
                . pause -PauseMessage "check LOG and continue <paused...>`n"
            }   
        }
    }

    # svn update
    if (!(. SvnUpdate -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Svn command
        ErrorMessage ("ERROR with Svn UPDATE in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            . pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }
    # if no errors
    else
    {
        if (! $UnattBool)
        {
            write-host "`nSvn UPDATE" -ForegroundColor Red
        }
    }

    # return Return Flag
    return $ReturnFlag

}



<#
################################################################################
################################################################################

INTERNAL FUNCTIONS, SVN WRAPPERS

################################################################################
################################################################################
#>



<#
Replace in working copy -WkPath the Repository Root with with -BareRepoPath.

Input:
> WkPath: Working Copy path to read
> BareRepoPath: New Repository Root
> LogFilePath: log file path

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function SvnReplaceRepositoryRoot ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BareRepoPath = $(throw "-BareRepoPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "svn relocate $BareRepoPath" to replace in working copy -WkPath the Repository Root with with -BareRepoPath
    #
    # $BareRepoPath is transformed in the format "file:///C:/e4-linked/@svnbare/piccolaimpresa   res.big.svn"
    $BareRepoPath="file:///"+$BareRepoPath.Replace("\","/")
    # run "svn relocate $BareRepoPath"
    $SvnCommands = "relocate", $BareRepoPath
    $cmdOutput = & "svn" $SvnCommands 2>&1
    #$cmdOutput #DEBUG#
    . LogAppend $LogFilePath ("svn "+$SvnCommands) (" called to replace Repository Root in "+$WkPath + " WK to " + $BareRepoPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    # > restore the old tracked URL
    # > exit with error
    if ($LASTEXITCODE -ne 0)
    {
        return $false   # exit function with ERROR
    }

    return $true

}



<#
svn add (and do svn rm for all deleted files)
# 'svn rm' string from   http://stackoverflow.com/questions/9600382/svn-command-to-delete-all-locally-missing-files

Input:
> WkPath: Working Copy path to read
> LogFilePath: log file path

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function SvnAdd ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # initialize Return Flag
    $ReturnFlag = $true

    # cd to working copy $WkPath
    cd $WkPath

    # run "svn add *.* --force" to add all files to commit
    $SvnCommands = "add", "*.*", "--force"
    $cmdOutput = & "svn" $SvnCommands 2>&1
    #$cmdOutput #DEBUG#
    . LogAppend $LogFilePath ("svn "+$SvnCommands) (" called to add all files in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        $ReturnFlag = $false   # set return value to $false
    }


    # run "svn status | ? { $_ -match '^!\s+(.*)' } | % { svn rm $Matches[1] }" to do svn rm for all deleted files
    # from   http://stackoverflow.com/questions/9600382/svn-command-to-delete-all-locally-missing-files
    $cmdOutput = svn status | ? { $_ -match '^!\s+(.*)' } | % { svn rm $Matches[1] } 2>&1
    #$cmdOutput #DEBUG#
    . LogAppend $LogFilePath ("svn status | svn rm") (" called to remove from repository all deleted files in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        $ReturnFlag = $false   # set return value to $false
    }

    # return $ReturnFlag
    return $ReturnFlag

}




<#
Svn status

Input:
> WkPath: Working Copy path to read
> LogFilePath: log file path

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> verbose status on LOG
#>
function SvnStatus ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "svn status" and save in LOG
    $SvnCommands = "status"
    $cmdOutput = & "svn" $SvnCommands 2>&1
    #$cmdOutput #DEBUG#
    . LogAppend $LogFilePath ("svn "+$SvnCommands) (" called in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}



<#
Return Svn status output

Input:
> WkPath: Working Copy path to read
> LogFilePath: log file path

Return:
> Git status output

Event:
> if error with parameters

Output:
> on log
#>
function SvnStatusMessage ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "svn status" and save in LOG
    $SvnCommands = "status"
    $cmdOutput = & "svn" $SvnCommands 2>&1
    #$cmdOutput #DEBUG#
    #. LogAppend $LogFilePath ("svn "+$SvnCommands) (" called in "+$WkPath) $cmdOutput

    # return Git status message
    return $cmdOutput

}



<#
Svn Commit Diff

Input:
> WkPath: Working Copy path to read
> LogFilePath: log file path

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function SvnCommitDiff ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "svn diff $BranchName" and save in LOG
    $SvnCommands = "diff"
    $cmdOutput = & "svn" $SvnCommands 2>&1
    #$cmdOutput #DEBUG#
    . LogAppend $LogFilePath ("svn "+$SvnCommands) (" called DIFF before COMMIT in " + $WkPath + ", branch " + $BranchName) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}



<#
Check if there is something to Commit

Input:
> WkPath: Working Copy path to read
> LogFilePath: log file path

Return:
> True if there is something to commit
> False if there is nothing to commit

Event:
> if error with parameters

Output:
> on log
#>
function SvnCheckIfCommitIsNeeded ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "svn status"
    $SvnCommands = "status"
    $cmdOutput = & "svn" $SvnCommands 2>&1
    #$cmdOutput #DEBUG#
    #. LogAppend $LogFilePath ("svn "+$SvnCommands) (" called in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        return $false   # exit function with False (nothing to commit)
    }

    # if there were some output to "git status --porcelain"
    if ($cmdOutput)
    {
        # exit function with True (something to commit)
        return $true
    }
    else
    {
        return $false   # exit function with False (nothing to commit)
    }
}



<#
Svn Commit

Input:
> WkPath: Working Copy path to read
> CommitMessage: Commit message
> LogFilePath: log file path

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function SvnCommit ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$CommitMessage = $(throw "-CommitMessage is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "svn commit -m '$CommitMessage'" and save in LOG 
    $SvnCommands = "commit", "-m", $CommitMessage
    $cmdOutput = & "svn" $SvnCommands 2>&1
    . LogAppend $LogFilePath ("svn "+$SvnCommands) ("called in " + $WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}


 
<#
Svn Update

Input:
> WkPath: Working Copy path in which do fetch
> LogFilePath: log file path

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function SvnUpdate ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "svn update" and save in LOG 
    $SvnCommands = "update"
    $cmdOutput = & "svn" $SvnCommands 2>&1
    . LogAppend $LogFilePath ("svn "+$SvnCommands) ("called in " + $WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}



<#
Test if -PathToTest is a Svn working copy.

Input:
> -PathToTest   Git repository directory
> -LogFilePath   Log File

Return:
> True if -PathToTest is a Svn working copy.
> False if -PathToTest is NOT a Svn working copy.

Event:
> if error with parameters

Output:
> NONE
#>
function SvnTestIfDirIsUnderControl()
{
param (
    [string]$PathToTest = $(throw "-PathToTest is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)
    
    # 1) check if $PathToTest is a directory
    If (!(Test-Path -path $PathToTest -PathType Container ))
    {
        return $false   # exit function with ERROR
    }

    # 2) check if in the directory $PathToTest there is a .svn directory
    If (! (Test-Path -path $PathToTest\.svn -pathtype Container) )
    {
        return $false   # exit function with ERROR
    }

    # 3) run svn info (OK if no errors) 
    cd $PathToTest
    $SvnCommands = "info"
    $cmdOutput = & "svn" $SvnCommands 2>&1
    #DEBUG# . LogAppend $LogFilePath ("svn "+$SvnCommands) ("called to check if '"+$PathToTest+"' is under svn control") $cmdOutput #DEBUG#
    if ($LASTEXITCODE -ne 0)
    {
        return $false   # exit function with ERROR
    }
    
    return $true   # exit function with SUCCESS

}



<#
Test if -PathToTest is a bare repository.

Input:
> -PathToTest   Svn repository directory
> -LogFilePath   Log File

Return:
> True if -PathToTest is a Bare repository.
> False if -PathToTest is NOT a Bare repository.
> False if -PathToTest is NOT a repository at all.

Event:
> if error with parameters

Output:
> NONE
#>
function SvnTestIfRepoIsBare()
{
param (
    [string]$PathToTest = $(throw "-PathToTest is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # run "svnadmin info ." and check exit code
    cd $PathToTest
    $SvnCommands = "info", "."
    $cmdOutput = & "svnadmin" $SvnCommands 2>&1
    #$cmdOutput #DEBUG#
    #. LogAppend $LogFilePath ("svn "+$SvnCommands) ("called to check if '"+$PathToTest+"' is a Bare repository") $cmdOutput #DEBUG#
    
    # check exit code
    # exit with error if $LASTEXITCODE <> 0 
    if ($LASTEXITCODE -ne 0)
    {
        return $false   # exit function with ERROR
    }

    return $true   # exit function with SUCCESS

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
    & $PSScriptRoot'.\lib-Pause.stex.ps1' -PauseMessage $PauseMessage
}


<#
################################################################################
################################################################################

START OF THE PROGRAM

################################################################################
################################################################################
#>



. LogAppend -LogFilePath $LogFilePath -CommandToLog "lib-Git-Sync.stex.ps1" -CommandDescriptionToLog "start" -CommandOutputToLog ""

. Main

. LogAppend -LogFilePath $LogFilePath -CommandToLog "lib-Git-Sync.stex.ps1" -CommandDescriptionToLog "end" -CommandOutputToLog ""
