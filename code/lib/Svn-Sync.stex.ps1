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
rev 2015-11-28 01.54

Input:
> -Action:   (case insensitive)
  >> CommitUpdate:  COMMIT(diff)+UPDATE
> -WkPath
  path della working directory
> [-BareRepoPath]
  opzionale, path del bare repository; se questo valore è presente, viene eseguito il comando "svn relocate" sulla nuova Repository Root
  il formato di questo parametro deve essere quello richiesto da "svn relocate", quindi "file:///C:/e4-linked/@svnbare/piccolaimpresa   res.big.svn"
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
    write-host  "`nRepo '" $WkPath "' START " $Action -foregroundcolor "White" -backgroundcolor "blue"

    # SET Environment
    . SetEnvironment

    # do checks
    #
    # if error with checks, Return Error
    if (!(. Checks))   # checks is called with "." for variable persistence
    {
        ErrorMessage ("Checks failed, sync SKIPPED; read LOG for details")   # error message on stdout 
        $ReturnFlag = $false   # Return Error
    }
    # if no error with checks
    else
    {
        # if -BareRepoPath has a value <> "" 
        # if this value is present is executed the command "svn relocate" with the new Repository Root 
        if ($BareRepoPath)
        {
            if (!(SvnReplaceRepositoryRoot -WkPath $WkPath -BareRepoPath $BareRepoPath -LogFilePath $LogFilePath))
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
                # if ERROR with Svn command
                    ErrorMessage ("ERROR with Svn COMMIT(diff)+UPDATE in "+$WkPath)   # error message on stdout
                    $ReturnFlag = $false   # Return Error
                }
            }
            default
            { 
                ErrorMessage ("-Action ( " + $Action + " ) is not a valid action !!!")   # error message on stdout
                $ReturnFlag = $false   # Return Error
            }
        }
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
        LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-LogFilePath ( " + $LogFilePath + " ) is not a file !!!" +"   Wk: "+$WkPath) ""
        return $false   # return Error value
    }

<#
check if dirs exists:
> WkPath
#>
    If (!(Test-Path -path $WkPath -PathType Container))
    {
        LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-WkPath ( " + $WkPath + " ) is not a directory !!!" +"   Wk: "+$WkPath) ""
        return $false   # return Error value
    }

<#
!!! THIS CONTROL IS NOT DONE BECAUSE -BareRepoPath CAN BE A NETWORK SHARE

check if dirs exists:
#>
<#
> [BareRepoPath]
    If ( ($BareRepoPath -ne "") -and (!(Test-Path -path $BareRepoPath -PathType Container)) )
    {
        LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-BareRepoPath ( " + $BareRepoPath + " ) is not a directory !!!" +"   Wk: "+$WkPath) ""
        return $false   # return Error value
    }
#>


<#
check if is a working copy:
> WkPath
#>
    If (! (SvnTestIfDirIsUnderControl -PathToTest $WkPath -LogFilePath $LogFilePath ))    
    {
        LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-WkPath ( " + $WkPath + " ) is not a directory under Svn control !!!" +"   Wk: "+$WkPath) ""
        return $false   # return Error value
    }

    
<#
!!! THIS CONTROL IS NOT DONE BECAUSE -BareRepoPath CAN BE A NETWORK SHARE

check if remote path contains a bare repository:
> [BareRepoPath]
#>
<#
    # if $BareRepoName is defined, continue with testing
    If ($BareRepoPath -ne "")
    {
        # if $BareRepoPath is not a bare repository, exit with error
        If (! (SvnTestIfRepoIsBare $BareRepoPath $LogFilePath))    
        {
            LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-BareRepoPath ( " + $BareRepoPath + " ) is not a Bare Repository !!!" +"   Wk: "+$WkPath) ""
            return $false   # return Error value
        }
    }
#>


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
            { 
                LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("Missing -WkPath" +"   Wk: "+$WkPath) ""
                return $false   # return Error value
            }
        } 
        default
        { 
            LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-Action ( " + $Action + " ) is not a valid action !!!" +"   Wk: "+$WkPath) ""
            return $false   # return Error value
        }
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
        {
            LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-Unattended ( " + $Unattended + " ) is not True or False !!!" +"   Wk: "+$WkPath) ""
            return $false   # return Error value
        }
    }

    # return success value
    return $true

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


#!!! THIS CONTROL IS NOT DONE BECAUSE -BareRepoPath CAN BE A NETWORK SHARE
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
    if (!(SvnAdd -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Svn command
        ErrorMessage ("ERROR with Svn ADD in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>"
        }
    }

    # Svn status: Print / Check if error
    #
    # if not unattended, show svn status
    if (! $UnattBool)
    {
        $cmdOutput = SvnStatusMessage -WkPath $WkPath -LogFilePath $LogFilePath 
        # if there is some status message, print the message
        if ($cmdOutput)
        {
            write-host "`nSvn STATUS" -ForegroundColor Red
            write-host $cmdOutput
        }
    }
    # svn status, and check if command goes in error
    if (!(SvnStatus -WkPath $WkPath -LogFilePath $LogFilePath))   
    {
    # if ERROR with Svn command
        ErrorMessage ("ERROR with Svn STATUS in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>"
        }
    }

    # svn Commit
    #
    # if there is something to commit...
    if (SvnCheckIfCommitIsNeeded -WkPath $WkPath -LogFilePath $LogFilePath)
    {
        # if unattended, commit
        if ($UnattBool)
        {
            # svn commit diff on Log
            SvnCommitDiff -WkPath $WkPath -LogFilePath $LogFilePath > $null

            if (!(SvnCommit -WkPath $WkPath -CommitMessage $CommitMessage -LogFilePath $LogFilePath))
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
            SvnCommitDiff -WkPath $WkPath -LogFilePath $LogFilePath > $null
            write-host "`nsaved detailed Commit diff on LOG `n"
            # pause
            Pause -PauseMessage "Press any key to COMMIT <paused...>"
            # commit
            if (!(SvnCommit -WkPath $WkPath -CommitMessage $CommitMessage -LogFilePath $LogFilePath))
            # if ERROR with Svn command, set Return Flag to False and pause
            {
                ErrorMessage ("ERROR with Svn COMMIT in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
                Pause -PauseMessage "check LOG and continue <paused...>"
            }   
        }
    }

    # svn update
    write-host "`nSvn UPDATE" -ForegroundColor Red
    if (!(SvnUpdate -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Svn command
        ErrorMessage ("ERROR with Svn UPDATE in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>"
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
Replace in working copy -WkPath the Repository Root with with -BareRepoPath
Is executed the command
    $ svn relocate "file:///C:/e4-linked/@svnbare/piccolaimpresa   res.big.svn"

Input:
> WkPath: Working Copy path to read
> BareRepoPath: New Repository Root
  the format of this parameter is the same requested from "svn relocate": "file:///C:/e4-linked/@svnbare/piccolaimpresa   res.big.svn"
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
    $SvnCommands = "relocate", $BareRepoPath
    $cmdOutput = & "svn" $SvnCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend $LogFilePath ("svn "+$SvnCommands) (" called to replace Repository Root in "+$WkPath + " WK to " + $BareRepoPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    # > restore the old tracked URL
    # > exit with error
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("svn "+$SvnCommands) (" called to replace Repository Root in "+$WkPath + " WK to " + $BareRepoPath) $cmdOutput
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
    LogAppend $LogFilePath ("svn "+$SvnCommands) (" called to add all files in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("svn "+$SvnCommands) (" called to add all files in "+$WkPath) $cmdOutput
        $ReturnFlag = $false   # set return value to $false
    }


    # run "svn status | ? { $_ -match '^!\s+(.*)' } | % { svn rm $Matches[1] }" to do svn rm for all deleted files
    # from   http://stackoverflow.com/questions/9600382/svn-command-to-delete-all-locally-missing-files
    $cmdOutput = svn status | ? { $_ -match '^!\s+(.*)' } | % { svn rm $Matches[1] } 2>&1
    #$cmdOutput #DEBUG#
    LogAppend $LogFilePath ("svn status | svn rm") (" called to remove from repository all deleted files in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("svn status | svn rm") (" called to remove from repository all deleted files in "+$WkPath) $cmdOutput
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
    LogAppend $LogFilePath ("svn "+$SvnCommands) (" called in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("svn "+$SvnCommands) (" called in "+$WkPath) $cmdOutput
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
> Svn status output

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
    #LogAppend $LogFilePath ("svn "+$SvnCommands) (" called in "+$WkPath) $cmdOutput

    # return Svn status message
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
    LogAppend ($LogFilePath + ".diff.txt") ("svn "+$SvnCommands) (" called DIFF before COMMIT in " + $WkPath + ", branch " + $BranchName) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("svn "+$SvnCommands) (" called DIFF before COMMIT in " + $WkPath + ", branch " + $BranchName) $cmdOutput
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
    #LogAppend $LogFilePath ("svn "+$SvnCommands) (" called in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("svn "+$SvnCommands) (" called in "+$WkPath) $cmdOutput
        return $false   # exit function with False (nothing to commit)
    }

    # if there were some output to "Svn status --porcelain"
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
    LogAppend $LogFilePath ("svn "+$SvnCommands) ("called in " + $WkPath) $cmdOutput
    LogAppend ($LogFilePath + ".core.txt") ("svn "+$SvnCommands) ("called in " + $WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("svn "+$SvnCommands) ("called in " + $WkPath) $cmdOutput
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
    LogAppend $LogFilePath ("svn "+$SvnCommands) ("called in " + $WkPath) $cmdOutput

    # if "svn update" updated something (at row 2 there isn't the text "At revision ")
    # write $cmdOutput in ".core" LOG
    if (!(SearchArrayForRegexpInARow -ArrayToTest $cmdOutput -RowNumToTest 2 -RegexToTest "^At revision "))
    {
        LogAppend ($LogFilePath + ".core.txt") ("svn "+$SvnCommands) ("called in " + $WkPath) $cmdOutput
    }

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("svn "+$SvnCommands) ("called in " + $WkPath) $cmdOutput
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}



<#
Test if -PathToTest is a Svn working copy.

Input:
> -PathToTest   Svn repository directory
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
    #DEBUG# LogAppend $LogFilePath ("svn "+$SvnCommands) ("called to check if '"+$PathToTest+"' is under svn control") $cmdOutput #DEBUG#
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt")  ("svn "+$SvnCommands) ("called to check if '"+$PathToTest+"' is under svn control") $cmdOutput #DEBUG#
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
    #LogAppend $LogFilePath ("svn "+$SvnCommands) ("called to check if '"+$PathToTest+"' is a Bare repository") $cmdOutput #DEBUG#
    
    # check exit code
    # exit with error if $LASTEXITCODE <> 0 
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("svn "+$SvnCommands) ("called to check if '"+$PathToTest+"' is a Bare repository") $cmdOutput #DEBUG#
        return $false   # exit function with ERROR
    }

    return $true   # exit function with SUCCESS

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



LogAppend -LogFilePath $LogFilePath -CommandToLog ("lib-Svn-Sync.stex.ps1, action " + $Action + " on " + $WkPath) -CommandDescriptionToLog "start" -CommandOutputToLog ""

. Main

LogAppend -LogFilePath $LogFilePath -CommandToLog "lib-Svn-Sync.stex.ps1" -CommandDescriptionToLog "end" -CommandOutputToLog ""
