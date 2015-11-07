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
script Git-Sync
by Stefano Spinucci virgo977virgo at gmail.com
rev 2015-11-07 02.13

Input:
> -Action:   (case insensitive)
  >> CommitFetchMergePush:  COMMIT(diff)+FETCH+MERGE(diff)+PUSH+LOG
  >> FetchMergeErrorIfCommit:   FETCH+MERGE+ERROR IF COMMIT (error if there is something to commit in the local directory)
  >> CommitPush:   STATUS+COMMIT+PUSH+LOG
  >> Status:   STATUS
  >> Commit:   COMMIT+LOG
  >> LogToday:   TODAY (added+deleted+modified+total)
> -WkPath
  path della working directory
> -BranchName
  branch-name
> [-BareRepoName]
  opzionale, nome del bare repository (remote-name)
> [-BareRepoPath]
  optional, path of bare repository; if this value is present -BareRepoPath is compared with the repo url defined in -BareRepoName; 
  if the tracked remote repository is different, the remote URL is replaced in -BareRepoName with -BareRepoPath
> -LogFilePath
  il nome del file di LOG nel quale appendere il dettaglio di ciò che viene fatto (una sintesi viene scritta nella command line)
> [-CommitMessage]
> -Unattended: True|False   (case insensitive)
  flag che determina se l'esecuzione del programma non viene mai interrotta per dialogare con l'utente e chiedere conferma di azioni

Le chiamate a Git vengono fatte quando possibile con l'opzione -Porcelain, per solidità nella lettura delle videate


Return:
> True if there were no errors
> False if there were errors

Output:
> something, also when -Unattended = True



Notes:

per il salvataggio automatico delle password Git installare "Git Credential Manager for Windows" :
https://github.com/Microsoft/Git-Credential-Manager-for-Windows   +   https://github.com/Microsoft/Git-Credential-Manager-for-Windows/releases
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
    [string]$BranchName,
    [string]$BareRepoName = "",   #optional
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
    if (!(Checks))
    {
        ErrorMessage ("Checks failed, sync SKIPPED; read LOG for details")   # error message on stdout 
        $ReturnFlag = $false   # Return Error
    }
    # if no error with checks
    else
    {
        # If -BareRepoPath has a value <> "" 
        # -BareRepoPath is compared with the repo url defined in -BareRepoName.
        # If the tracked remote repository is different, the remote URL is replaced in -BareRepoName with -BareRepoPath.
        # If $BareRepoPath is not a valid Remote Repository 
        # DOESN'T revert to the old tracked URL (because is not what the user asked, to push to a different URL).
        if ($BareRepoPath)
        {
            . ActionReplaceBareRepoPath -WkPath $WkPath -BareRepoName $BareRepoName -RevertIfError "False" -BareRepoPath $BareRepoPath > $null
        }

        # do actions
        switch ($Action) 
        { 
            "CommitFetchMergePush"
                {
                    if (!(. ActionCommitFetchMergePush))
                    {
                    # if ERROR with Git command
                        ErrorMessage ("ERROR with Git Commit+Fetch+Merge+Push in "+$WkPath)   # error message on stdout
                        $ReturnFlag = $false   # Return Error
                    }
                }
            "FetchMergeErrorIfCommit"
                {
                    if (!(. ActionFetchMergeErrorIfCommit))
                    {
                    # if ERROR with Git command
                        ErrorMessage ("ERROR with Git Fetch+Merge+ErrorIfCommit in "+$WkPath)   # error message on stdout
                        $ReturnFlag = $false   # Return Error
                    }
                }
            "CommitPush"
                {
                    if (!(. ActionCommitPush))
                    {
                    # if ERROR with Git command
                        ErrorMessage ("ERROR with Git Commit+Push in "+$WkPath)   # error message on stdout
                        $ReturnFlag = $false   # Return Error
                    }
                } 
            "Status"
                {
                    if (!(. ActionStatus))
                    {
                    # if ERROR with Git command
                        ErrorMessage ("ERROR with Git Status in "+$WkPath)   # error message on stdout
                        $ReturnFlag = $false   # Return Error
                    }
                } 
            "Commit"
                {
                    if (!(. ActionCommit))
                    {
                    # if ERROR with Git command
                        ErrorMessage ("ERROR with Git Commit in "+$WkPath)   # error message on stdout
                        $ReturnFlag = $false   # Return Error
                    }
                } 
            "LogToday"
                {
                    if (!(. ActionLogToday))
                    {
                    # if ERROR with Git command
                        ErrorMessage ("ERROR with Git LogToday in "+$WkPath)   # error message on stdout
                        $ReturnFlag = $false   # Return Error
                    }
                } 
            default
                {
                    ErrorMessage ("-Action ( " + $Action + " ) is not a valid action !!!" )   # error message on stdout
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

# SET Environment configuration (from   https://tiredblogger.wordpress.com/2009/08/21/using-git-and-everything-else-through-powershell/ )
# Add Git executables to the mix.
#[System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";" + (Join-Path $pathToPortableGit "\bin") + ";" + $scripts, "Process")
[System.Environment]::SetEnvironmentVariable("PATH", $Env:Path)
# Setup Home so that Git doesn't freak out.
[System.Environment]::SetEnvironmentVariable("HOME", (Join-Path $Env:HomeDrive $Env:HomePath), "Process")

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
> [BareRepoPath]
#>
<#
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
    If (! (GitTestIfDirIsUnderControl -PathToTest $WkPath -LogFilePath $LogFilePath ))    
    {
        LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-WkPath ( " + $WkPath + " ) is not a directory under Git control !!!" +"   Wk: "+$WkPath) ""
        return $false   # return Error value
    }
    
<#
check if remote name is defined in WkPath:
> [BareRepoName]
#>
    # if $BareRepoName is defined, continue with testing
    If ($BareRepoName -ne "")
    {
        # if $BareRepoName is not a Remote in $WkPath, exit with error
        If (! (GitTestIfRemoteIsDefined -PathToTest $WkPath -NameToTest $BareRepoName -LogFilePath $LogFilePath ))    
        {
            LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-BareRepoName ( " + $BareRepoName + " ) is not a Remote defined in '" + $WkPath + "' !!!" +"   Wk: "+$WkPath) ""
            return $false   # return Error value
        }
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
        If (! (GitTestIfRepoIsBare $BareRepoPath $LogFilePath))    
        {
            LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-BareRepoPath ( " + $BareRepoPath + " ) is not a Bare Repository !!!" +"   Wk: "+$WkPath) ""
            return $false   # return Error value
        }
    }
#>

<#
check if BranchName is defined in:
> WkPath (working copy)
#>
    # if $BranchName is not a branch defined in $WkPath, exit with error
    If (! (GitTestIfBranchIsDefined -PathToTest $WkPath -NameToTest $BranchName -LogFilePath $LogFilePath ))    
    {
        LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-BranchName ( " + $BranchName + " ) is not a Branch defined in '" + $WkPath + "' !!!" +"   Wk: "+$WkPath) ""
        return $false   # return Error value
    }

<#
!!! THIS CONTROL IS NOT DONE BECAUSE -BareRepoPath CAN BE A NETWORK SHARE

check if BranchName is defined in:
> BareRepoPath (bare repository, if defined):
#>
<#
    # if $BareRepoName is defined, continue with testing
    If ($BareRepoPath -ne "")
    {
        # if $BranchName is not a branch defined in $BareRepoPath, exit with error
        If (! (GitTestIfBranchIsDefined -PathToTest $BareRepoPath -NameToTest $BranchName -LogFilePath $LogFilePath ))    
        {
            LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("-BranchName ( " + $BranchName + " ) is not a Branch defined in '" + $BareRepoPath + "' !!!" +"   Wk: "+$WkPath) ""
            return $false   # return Error value
        }
    }
#>

<#
check if Action is one element of the list
AND
if Action have needed parameters:
> CommitFetchMergePush:
  WkPath
  BranchName
  BareRepoName
> FetchMergeErrorIfCommit:   
  WkPath
  BranchName
  BareRepoName
> CommitPush:   
  WkPath
  BranchName
  BareRepoName
> Status:   
  WkPath
> Commit:   
  WkPath
  BranchName
>LogToday:
  WkPath
#>
    switch ($Action) 
    { 
        "CommitFetchMergePush"
        {
            if (! ( ($WkPath) -and ($BranchName) -and ($BareRepoName) ) )
            {
                LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("Missing one or more parameters in -WkPath, BranchName, BareRepoName"+"   Wk: "+$WkPath) ""
                return $false   # return Error value
            }
        } 
        "FetchMergeErrorIfCommit"
        {
            if (! ( ($WkPath) -and ($BranchName) -and ($BareRepoName) ) )
            {
                LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("Missing one or more parameters in -WkPath, BranchName, BareRepoName"+"   Wk: "+$WkPath) ""
                return $false   # return Error value
            }
        }
        "CommitPush"
        {
            if (! ( ($WkPath) -and ($BranchName) -and ($BareRepoName) ) )
            {
                LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("Missing one or more parameters in -WkPath, BranchName, BareRepoName" +"   Wk: "+$WkPath) ""
                return $false   # return Error value
            }
        } 
        "Status"
        {
            if (! ($WkPath) )
            {
                LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("Missing -WkPath" +"   Wk: "+$WkPath) ""
                return $false   # return Error value
            }
        } 
        "Commit"
        {
            if (! ( ($WkPath) -and ($BranchName) ) )
            {
                LogAppend ($LogFilePath + ".error.txt") ("Internal checks FAILED") ("Missing one or more parameters in -WkPath, BranchName" +"   Wk: "+$WkPath) ""
                return $false   # return Error value
            }
        } 
        "LogToday"
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

GIT ACTIONS

################################################################################
################################################################################
#>

<#

GIT ADD   
cd WK
git add --all   <output on LOG>
<check $LASTEXITCODE>
<if $LASTEXITCODE <> 0 return False>

GIT STATUS   
cd WK
git status --porcelain   <output on STDOUT>
git status   <output on LOG>
<if $LASTEXITCODE <> 0 return False>

GIT COMMIT DIFF
cd WK
git diff master >> LOG.txt

GIT COMMIT
cd WK
git commit -m "commit msg"

GIT FETCH from BARE REPO
git fetch originBareLocal 

GIT MERGE DIFF
git diff --stat ...originBareLocal/master    # short, on stdout
git diff --stat ...originBareLocal/master >> LOG.txt     # short, on log
git diff ...originBareLocal/master >> LOG.txt   # long, on log

GIT MERGE
git merge originBareLocal/master

GIT PUSH
git push originBareLocal
<OR>
git push originBareLocal master

GIT LOG
cd WK
git log --diff-filter=D --name-status --find-copies=100%% --since="1 day"   # DELETED
git log --diff-filter=A --name-status --find-copies=100%% --since="1 day"   # ADDED
git log --diff-filter=M --name-status --find-copies=100%% --since="1 day"   # MODIFIED
git log --diff-filter=R --name-status --find-copies=100%% --since="1 day"   # RENAMED
git log --name-status --find-copies=100%% --since="1 day"   # ALL

#>



<#
the Remote $BareRepoName is checked and if the tracked remote repository is different from $BareRepoPath,
$BareRepoName tracked URL is replaced with $BareRepoPath
#>
function ActionReplaceBareRepoPath ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$RevertIfError = $(throw "-RevertIfError is required."),
    [string]$BareRepoPath = $(throw "-BareRepoPath is required.")
)

    # read the remote URL tracked by $BareRepoName 
    $RemoteTrackedRepo = GitReadRemoteTrackedRepo -WkPath $WkPath -BareRepoName $BareRepoName -LogFilePath $LogFilePath

    # if the remote URL tracked by $BareRepoName is <> $BareRepoPath then
    # $BareRepoName tracked URL is replaced with $BareRepoPath
    if ($RemoteTrackedRepo -ne $BareRepoPath)
    {
        GitReplaceRemoteTrackedRepo -WkPath $WkPath -BareRepoName $BareRepoName -BareRepoPath $BareRepoPath -RevertIfError $RevertIfError -LogFilePath $LogFilePath > $null
    }
}


# CommitFetchMergePush:  COMMIT(diff)+FETCH+MERGE(diff)+PUSH+LOG
function ActionCommitFetchMergePush ()
{

    # iniziatlize Return Flag
    $ReturnFlag = $true

    # git add
    if (!(GitAdd -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git ADD in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }

    # git status: Print / Check if error
    #
    # if not unattended, show git status
    if (! $UnattBool)
    {
        $cmdOutput = GitStatusMessage -WkPath $WkPath -LogFilePath $LogFilePath 
        # if there is some status message, print the message
        if ($cmdOutput)
        {
            write-host "`nGit STATUS" -ForegroundColor Red
            write-host $cmdOutput
        }
    }
    # git status, and check if command goes in error
    if (!(GitStatus -WkPath $WkPath -LogFilePath $LogFilePath))   
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git STATUS in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }

    # git Commit
    #
    # if there is something to commit...
    if (GitCheckIfCommitIsNeeded -WkPath $WkPath -LogFilePath $LogFilePath)
    {
        # if unattended, commit
        if ($UnattBool)
        {
            if (!(GitCommit -WkPath $WkPath -CommitMessage $CommitMessage -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False
            {
                ErrorMessage ("ERROR with Git COMMIT in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
            }   
        }
        else
        # if not unattended, ask user to commit
        {
            write-host "`nGit COMMIT" -ForegroundColor Red
            # git commit diff on Log
            GitCommitDiff -WkPath $WkPath -LogFilePath $LogFilePath > $null
            write-host "`nsaved detailed Commit diff on LOG `n"
            # pause
            Pause -PauseMessage "Press any key to COMMIT <paused...>`n"
            # commit
            if (!(GitCommit -WkPath $WkPath -CommitMessage $CommitMessage -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False and pause
            {
                ErrorMessage ("ERROR with Git COMMIT in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
                Pause -PauseMessage "check LOG and continue <paused...>`n"
            }   
        }
    }

    # git fetch
    if (!(GitFetch -WkPath $WkPath -BareRepoName $BareRepoName -LogFilePath $LogFilePath))
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git FETCH in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }


    # git Merge
    #
    # if there is something to Merge...
    if (GitCheckIfMergeIsNeeded -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath)
    {
        # if unattended, Merge
        if ($UnattBool)
        {
            if (!(GitMerge -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False
            {
                ErrorMessage ("ERROR with Git MERGE in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
            }   
        }
        else
        # if not unattended, ask user to Merge
        {
            # short git Merge diff on STDOUT
            write-host "`nGit MERGE" -ForegroundColor Red
            $cmdOutput = GitMergeDiffMessage -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath
            write-host $cmdOutput
            # git Merge diff on Log
            GitMergeDiff -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath > $null
            write-host "`nsaved detailed Merge diff on LOG `n"
            # pause
            Pause -PauseMessage "Press any key to MERGE <paused...>"
            # Merge
            if (!(GitMerge -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False and pause
            {
                ErrorMessage ("ERROR with Git MERGE in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
                Pause -PauseMessage "check LOG and continue <paused...>`n"
            }   
        }
    }

    # git push
    #
    # if there is something to Push...
    if (GitCheckIfPushIsNeeded -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath)
    {
        # if unattended, Push
        if ($UnattBool)
        {
            if (!(GitPush -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False
            {
                ErrorMessage ("ERROR with Git PUSH in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
            }   
        }
        else
        # if not unattended, ask user to Push
        {
            # short git Push diff on STDOUT
            write-host "`nGit PUSH" -ForegroundColor Red
            $cmdOutput = GitPushDiffMessage -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath
            write-host $cmdOutput
            # git Push diff on Log
            GitPushDiff -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath > $null
            write-host "`nsaved detailed Push diff on LOG `n"
            # pause
            Pause -PauseMessage "Press any key to PUSH <paused...>"
            # Push
            if (!(GitPush -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False and pause
            {
                ErrorMessage ("ERROR with Git PUSH in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
                Pause -PauseMessage "check LOG and continue <paused...>`n"
            }   
        }
    }


    # git log
    if (!(GitLog -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git LOG in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
    }

    # return Return Flag
    return $ReturnFlag

}

# FetchMergeErrorIfCommit:   FETCH+MERGE+ERROR IF COMMIT (error if there is something to commit in the local directory)
function ActionFetchMergeErrorIfCommit ()
{
    # iniziatlize Return Flag
    $ReturnFlag = $true

    # git fetch
    if (!(GitFetch -WkPath $WkPath -BareRepoName $BareRepoName -LogFilePath $LogFilePath))
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git FETCH in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }


    # git Merge
    #
    # if there is something to Merge...
    if (GitCheckIfMergeIsNeeded -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath)
    {
        # if unattended, Merge
        if ($UnattBool)
        {
            if (!(GitMerge -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False
            {
                ErrorMessage ("ERROR with Git MERGE in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
            }   
        }
        else
        # if not unattended, ask user to Merge
        {
            # short git Merge diff on STDOUT
            write-host "`nGit MERGE" -ForegroundColor Red
            $cmdOutput = GitMergeDiffMessage -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath
            write-host $cmdOutput
            # git Merge diff on Log
            GitMergeDiff -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath > $null
            write-host "`nsaved detailed Merge diff on LOG `n"
            # pause
            Pause -PauseMessage "Press any key to MERGE <paused...>"
            # Merge
            if (!(GitMerge -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False and pause
            {
                ErrorMessage ("ERROR with Git MERGE in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
                Pause -PauseMessage "check LOG and continue <paused...>`n"
            }   
        }
    }

    # if there is something to commit, ERROR !!!
    if (GitCheckIfCommitIsNeeded -WkPath $WkPath -LogFilePath $LogFilePath)
    {
        ErrorMessage ("ERROR, there is something to COMMIT in "+ $WkPath + "; Git Status saved in LOG")   # error message on stdout
        GitStatus -WkPath $WkPath -LogFilePath ($LogFilePath + ".error.txt")   # save Git Status on ERROR LOG
        $ReturnFlag = $false
        if (! $UnattBool)   # if not Unattended, PAUSE
        { Pause -PauseMessage "check LOG and continue <paused...>`n" }
    }   


    # git log
    if (!(GitLog -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git LOG in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
    }

    # return Return Flag
    return $ReturnFlag

}

# CommitPush:   STATUS+COMMIT+PUSH+LOG
function ActionCommitPush ()
{

    # iniziatlize Return Flag
    $ReturnFlag = $true

    # git add
    if (!(GitAdd -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git ADD in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }

    # git status: Print / Check if error
    #
    # if not unattended, show git status
    if (! $UnattBool)
    {
        $cmdOutput = GitStatusMessage -WkPath $WkPath -LogFilePath $LogFilePath 
        # if there is some status message, print the message
        if ($cmdOutput)
        {
            write-host "`nGit STATUS" -ForegroundColor Red
            write-host $cmdOutput
        }
    }
    # git status, and check if command goes in error
    if (!(GitStatus -WkPath $WkPath -LogFilePath $LogFilePath))   
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git STATUS in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }

    # git Commit
    #
    # if there is something to commit...
    if (GitCheckIfCommitIsNeeded -WkPath $WkPath -LogFilePath $LogFilePath)
    {
        # if unattended, commit
        if ($UnattBool)
        {
            if (!(GitCommit -WkPath $WkPath -CommitMessage $CommitMessage -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False
            {
                ErrorMessage ("ERROR with Git COMMIT in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
            }   
        }
        else
        # if not unattended, ask user to commit
        {
            write-host "`nGit COMMIT" -ForegroundColor Red
            # git commit diff on Log
            GitCommitDiff -WkPath $WkPath -LogFilePath $LogFilePath > $null
            write-host "`nsaved detailed Commit diff on LOG `n"
            # pause
            Pause -PauseMessage "Press any key to COMMIT <paused...>`n"
            # commit
            if (!(GitCommit -WkPath $WkPath -CommitMessage $CommitMessage -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False and pause
            {
                ErrorMessage ("ERROR with Git COMMIT in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
                Pause -PauseMessage "check LOG and continue <paused...>`n"
            }   
        }
    }

    # git push
    #
    # if there is something to Push...
    if (GitCheckIfPushIsNeeded -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath)
    {
        # if unattended, Push
        if ($UnattBool)
        {
            if (!(GitPush -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False
            {
                ErrorMessage ("ERROR with Git PUSH in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
            }   
        }
        else
        # if not unattended, ask user to Push
        {
            # short git Push diff on STDOUT
            write-host "`nGit PUSH" -ForegroundColor Red
            $cmdOutput = GitPushDiffMessage -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath
            write-host $cmdOutput
            # git Push diff on Log
            GitPushDiff -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath > $null
            write-host "`nsaved detailed Push diff on LOG `n"
            # pause
            Pause -PauseMessage "Press any key to PUSH <paused...>"
            # Push
            if (!(GitPush -WkPath $WkPath -BranchName $BranchName -BareRepoName $BareRepoName -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False and pause
            {
                ErrorMessage ("ERROR with Git PUSH in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
                Pause -PauseMessage "check LOG and continue <paused...>`n"
            }   
        }
    }


    # git log
    if (!(GitLog -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git LOG in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
    }

    # return Return Flag
    return $ReturnFlag

}

# Status:   STATUS
function ActionStatus ()
{

    # iniziatlize Return Flag
    $ReturnFlag = $true

    # git status: Print / Check if error
    #
    # if not unattended, show git status
    if (! $UnattBool)
    {
        $cmdOutput = GitStatusMessage -WkPath $WkPath -LogFilePath $LogFilePath 
        # if there is some status message, print the message
        if ($cmdOutput)
        {
            write-host "`nGit STATUS" -ForegroundColor Red
            write-host $cmdOutput
        }
    }
    # git status, and check if command goes in error
    if (!(GitStatus -WkPath $WkPath -LogFilePath $LogFilePath))   
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git STATUS in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }

    # return Return Flag
    return $ReturnFlag
}

# Commit:   COMMIT+LOG
function ActionCommit ()
{

    # iniziatlize Return Flag
    $ReturnFlag = $true

    # git add
    if (!(GitAdd -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git ADD in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }

    # git status: Print / Check if error
    #
    # if not unattended, show git status
    if (! $UnattBool)
    {
        $cmdOutput = GitStatusMessage -WkPath $WkPath -LogFilePath $LogFilePath 
        # if there is some status message, print the message
        if ($cmdOutput)
        {
            write-host "`nGit STATUS" -ForegroundColor Red
            write-host $cmdOutput
        }
    }
    # git status, and check if command goes in error
    if (!(GitStatus -WkPath $WkPath -LogFilePath $LogFilePath))   
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git STATUS in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
        # if not Unattended pause
        if (! $UnattBool)
        {
            Pause -PauseMessage "check LOG and continue <paused...>`n"
        }
    }

    # git Commit
    #
    # if there is something to commit...
    if (GitCheckIfCommitIsNeeded -WkPath $WkPath -LogFilePath $LogFilePath)
    {
        # if unattended, commit
        if ($UnattBool)
        {
            if (!(GitCommit -WkPath $WkPath -CommitMessage $CommitMessage -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False
            {
                ErrorMessage ("ERROR with Git COMMIT in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
            }   
        }
        else
        # if not unattended, ask user to commit
        {
            write-host "`nGit COMMIT" -ForegroundColor Red
            # git commit diff on Log
            GitCommitDiff -WkPath $WkPath -LogFilePath $LogFilePath > $null
            write-host "`nsaved detailed Commit diff on LOG `n"
            # pause
            Pause -PauseMessage "Press any key to COMMIT <paused...>`n"
            # commit
            if (!(GitCommit -WkPath $WkPath -CommitMessage $CommitMessage -LogFilePath $LogFilePath))
            # if ERROR with Git command, set Return Flag to False and pause
            {
                ErrorMessage ("ERROR with Git COMMIT in "+$WkPath)   # error message on stdout
                $ReturnFlag = $false
                Pause -PauseMessage "check LOG and continue <paused...>`n"
            }   
        }
    }

    # git log
    if (!(GitLog -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git LOG in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
    }

    # return Return Flag
    return $ReturnFlag

}

# LogToday:   TODAY (added+deleted+modified+total)
function ActionLogToday ()
{

    # iniziatlize Return Flag
    $ReturnFlag = $true

    # git log
    if (!(GitLog -WkPath $WkPath -LogFilePath $LogFilePath))
    {
    # if ERROR with Git command
        ErrorMessage ("ERROR with Git LOG in "+$WkPath)   # error message on stdout
        $ReturnFlag = $false   # set Return Flag to False
    }

    # return Return Flag
    return $ReturnFlag

}



<#
################################################################################
################################################################################

INTERNAL FUNCTIONS, GIT WRAPPERS

################################################################################
################################################################################
#>



<#
Launch in Working copy git repository $WkPath the command
"git config credential.helper 'cache --timeout=???'"
with timeout value $CachePwdSec

Input:
> WkPath: working copy path to set
> CachePwdSec: seconds of cache timeout to set
> LogFilePath: log file path

Return:
> True if there were no errors
> False if there were errors

Event:
> if error with parameters

Output:
> on log

see   https://git-scm.com/docs/git-credential-cache
      https://git-scm.com/docs/git-credential-store
      https://git-scm.com/docs/gitcredentials
#>
function GitSetCachePwd ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$CachePwdSec = $(throw "-CachePwdSec is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    $GitCommands = "config", "credential.helper", ("cache --timeout="+$CachePwdSec)
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend $LogFilePath ("git "+$GitCommands) (" called to set 'credential.helper cache --timeout' to " + $CachePwdSec + " seconds in "+$WkPath) $cmdOutput 
    
    # check exit code
    # exit with error if $LASTEXITCODE <> 0 
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called to set 'credential.helper cache --timeout' to " + $CachePwdSec + " seconds in "+$WkPath) $cmdOutput 
        return $false   # exit function with ERROR
    }

    return $true   # exit function with SUCCESS

}



<#
Return the remote repository tracked by Remote $BareRepoName

Input:
> WkPath: Working Copy path to read
> BareRepoName: Remote name 
> LogFilePath: log file path

Return:
> The URL of the remote tracked in the remote
> "" if there was an error with $LASTEXITCODE or if the tracked URL was not found

Event:
> if error with parameters

Output:
> on log
#>
function GitReadRemoteTrackedRepo ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # set success flag
    $SuccessFlag=$false

    # cd to working copy $WkPath
    cd $WkPath

    # run "git remote show $BareRepoName" to show details about $BareRepoName remote
    $GitCommands = "remote", "show", $BareRepoName
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    #LogAppend $LogFilePath ("git "+$GitCommands) (" called to read the URL tracked by remote " + $BareRepoName + " in "+$WkPath) $cmdOutput #DEBUG#

    # check exit code
    # exit with error if $LASTEXITCODE <> 0 
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called to read the URL tracked by remote " + $BareRepoName + " in "+$WkPath) $cmdOutput #DEBUG#
        return ""   # exit function with ERROR
    }

    # if string "  Fetch URL: " is found in $cmdOutput exit loop with $SuccessFlag = $true
    foreach ($elem in $cmdOutput)
    {
        if ( $elem.Substring(0,13) -eq "  Fetch URL: ")
        {
            $SuccessFlag=$true
            break
        }
        
    }

    # if $SuccessFlag = $true return the tracked FETCH URL
    if ($SuccessFlag)
    {
        $elem.Substring("  Fetch URL: ".Length)
    }
    # if is not found, return ""
    else
    {
        return ""
    }

}



<#
Replace in Remote -BareRepoName (defined in WK -WkPath) the tracked URL with with -BareRepoPath.
Optionally don't do any replacement if -BareRepoPath is not a valid tracked URL (if -RevertIfError = "True").

Input:
> WkPath: Working Copy path to read
> BareRepoName: Remote name 
> BareRepoPath: Tracked remote path
> RevertIfError: "True"|"False"; if "True", revert old tracked URL if error; if "False", *doesn't* revert old URL if error
> LogFilePath: log file path

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function GitReplaceRemoteTrackedRepo ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$BareRepoPath = $(throw "-BareRepoPath is required."),
    [string]$RevertIfError = $(throw "-RevertIfError is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # save the remote tracked URL in $BareRepoName before editing it to restore it if there is some error
    $RemoteTrackedRepo = GitReadRemoteTrackedRepo -WkPath $WkPath -BareRepoName $BareRepoName -LogFilePath $LogFilePath

    # run "git remote set-url $BareRepoName $BareRepoPath" to replace in the Remote $BareRepoName the tracked URL with $BareRepoPath
    $GitCommands = "remote", "set-url", $BareRepoName, $BareRepoPath
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend $LogFilePath ("git "+$GitCommands) (" called to replace URL tracked by remote " + $BareRepoName + " in "+$WkPath + " WK to " + $BareRepoPath + "new tracked URL.") $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    # > restore the old tracked URL
    # > exit with error
    if ($LASTEXITCODE -ne 0)
    {
        # if $RevertIfError = "True", revert old tracked URL
        if ($RevertIfError -eq "True")
        {
            $GitCommands = "remote", "set-url", $BareRepoName, $RemoteTrackedRepo
            $cmdOutput = & "git" $GitCommands 2>&1
            LogAppend $LogFilePath ("git "+$GitCommands) (" called to restore tracked URL by remote " + $BareRepoName + " in "+$WkPath + " WK.") $cmdOutput
            LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called to restore tracked URL by remote " + $BareRepoName + " in "+$WkPath + " WK.") $cmdOutput
        }
        return $false   # exit function with ERROR
    }

    # run "git remote show $BareRepoName" to see if the tracked URL replacement was successful
    $GitCommands = "remote", "show", $BareRepoName
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend $LogFilePath ("git "+$GitCommands) (" called to show if remote tracked URL replacement was successful in Remote " + $BareRepoName + " in Wk "+$WkPath) $cmdOutput #DEBUG#

    # if error in the last command ($LASTEXITCODE <> 0 ):
    # > if $RevertIfError = "True" restore the old tracked URL
    # > exit with error
    if ($LASTEXITCODE -ne 0)
    {
        if ($RevertIfError -eq "True") 
        {
            $GitCommands = "remote", "set-url", $BareRepoName, $RemoteTrackedRepo
            $cmdOutput = & "git" $GitCommands 2>&1
            LogAppend $LogFilePath ("git "+$GitCommands) (" called to restore tracked URL by remote " + $BareRepoName + " in "+$WkPath + " WK.") $cmdOutput
            LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called to restore tracked URL by remote " + $BareRepoName + " in "+$WkPath + " WK.") $cmdOutput
        }
        return $false   # exit function with ERROR
    }

    return $true

}



<#
Git add

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
function GitAdd ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git add --all" to add all files to commit
    $GitCommands = "add", "--all"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend $LogFilePath ("git "+$GitCommands) (" called to add all files in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called to add all files in "+$WkPath) $cmdOutput
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}




<#
Git status

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
function GitStatus ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git status" and save in LOG
    $GitCommands = "status"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend $LogFilePath ("git "+$GitCommands) (" called in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        #NOT NEEDED, IS A MARGINAL COMMAND, AND SOMETIMES GitStatus is called with Log Path already with ".error.txt", as with Action FetchMergeErrorIfCommit
        #LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called in "+$WkPath) $cmdOutput
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}



<#
Return git status output

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
function GitStatusMessage ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git status" and save in LOG
    $GitCommands = "status", "--porcelain"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend $LogFilePath ("git "+$GitCommands) (" called in "+$WkPath) $cmdOutput

    # return Git status message
    return $cmdOutput

}



<#
Git Commit Diff

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
function GitCommitDiff ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git diff $BranchName" and save in LOG
    $GitCommands = "diff", "HEAD"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend ($LogFilePath + ".diff.txt") ("git "+$GitCommands) (" called DIFF before COMMIT in " + $WkPath + ", branch " + $BranchName) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called DIFF before COMMIT in " + $WkPath + ", branch " + $BranchName) $cmdOutput
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
function GitCheckIfCommitIsNeeded ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git status"
    $GitCommands = "status", "--porcelain"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    #LogAppend $LogFilePath ("git "+$GitCommands) (" called in "+$WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called in "+$WkPath) $cmdOutput
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
Git Commit

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
function GitCommit ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$CommitMessage = $(throw "-CommitMessage is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git commit -m '$CommitMessage'" and save in LOG 
    $GitCommands = "commit", "-m", $CommitMessage
    $cmdOutput = & "git" $GitCommands 2>&1
    LogAppend $LogFilePath ("git "+$GitCommands) ("called in " + $WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) ("called in " + $WkPath) $cmdOutput
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}


 
<#
Git Fetch

Input:
> WkPath: Working Copy path in which do fetch
> BareRepoName: Remote repo to fetch from
> LogFilePath: log file path

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function GitFetch ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git fetch" and save in LOG 
    $GitCommands = "fetch", $BareRepoName
    $cmdOutput = & "git" $GitCommands 2>&1
    LogAppend $LogFilePath ("git "+$GitCommands) ("called in " + $WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) ("called in " + $WkPath) $cmdOutput
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}



<#
Git Merge Diff

Input:
> WkPath: Working Copy path in which do Merge
> BranchName: name of the branch in which do merge
> BareRepoName: remote repository to merge from
> LogFilePath: log file path

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function GitMergeDiff ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BranchName = $(throw "-BranchName is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    
    # run "git diff --stat $BranchName...$BareRepoName/$BranchName" and save in LOG
    $GitCommands = "diff", "--stat", "$BranchName...$BareRepoName/$BranchName"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend ($LogFilePath + ".diff.txt") ("git "+$GitCommands) (" called short DIFF before MERGE in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput

    # run "git diff $BranchName...$BareRepoName/$BranchName" and save in LOG
    $GitCommands = "diff", "$BranchName...$BareRepoName/$BranchName"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend ($LogFilePath + ".diff.txt") ("git "+$GitCommands) (" called DIFF before MERGE in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput
    
    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called DIFF before MERGE in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}



<#
Check if there is something to Merge

Input:
> WkPath: Working Copy path in which do Merge
> BranchName: name of the branch in which do merge
> BareRepoName: remote repository to merge from
> LogFilePath: log file path

Return:
> True if there is something to commit
> False if there is nothing to commit

Event:
> if error with parameters

Output:
> on log
#>
function GitCheckIfMergeIsNeeded ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BranchName = $(throw "-BranchName is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git diff --stat $BranchName...$BareRepoName/$BranchName" and save output in $cmdOutput
    $GitCommands = "diff", "--stat", "$BranchName...$BareRepoName/$BranchName"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    #LogAppend $LogFilePath ("git "+$GitCommands) (" called in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput
        return $false   # exit function with False (nothing to Merge)
    }

    # if there were some output saved in $cmdOutput
    if ($cmdOutput)
    {
        # exit function with True (something to Merge)
        return $true
    }
    else
    {
        return $false   # exit function with False (nothing to Merge)
    }
}



<#
Return git Merge diff (short) message

Input:
> WkPath: Working Copy path in which do Merge
> BranchName: name of the branch in which do merge
> BareRepoName: remote repository to merge from
> LogFilePath: log file path

Return:
> Git Merge diff (short) output

Event:
> if error with parameters

Output:
> on log
#>
function GitMergeDiffMessage ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BranchName = $(throw "-BranchName is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git diff --stat $BranchName...$BareRepoName/$BranchName" and save output in $cmdOutput
    $GitCommands = "diff", "--stat", "$BranchName...$BareRepoName/$BranchName"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    #LogAppend $LogFilePath ("git "+$GitCommands) (" called in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput

    # return Git status message
    return $cmdOutput

}



<#
Git Merge

Input:
> WkPath: Working Copy path in which do Merge
> BranchName: name of the branch in which do merge
> BareRepoName: remote repository to merge from
> LogFilePath: log file path

Output:
> on LOG 

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function GitMerge ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BranchName = $(throw "-BranchName is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git merge $BareRepoName/$BranchName" and save in LOG 
    $GitCommands = "merge", "$BareRepoName/$BranchName"
    $cmdOutput = & "git" $GitCommands 2>&1
    LogAppend $LogFilePath ("git "+$GitCommands) (" called in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}



<#
Git Push Diff

Input:
> WkPath: Working Copy path in which do Push
> BranchName: name of the branch in which do Push
> BareRepoName: remote repository to Push from
> LogFilePath: log file path

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function GitPushDiff ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BranchName = $(throw "-BranchName is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    
    # run "git diff --stat $BareRepoName/$BranchName...$BranchName" and save in LOG
    $GitCommands = "diff", "--stat", "$BareRepoName/$BranchName...$BranchName"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend ($LogFilePath + ".diff.txt") ("git "+$GitCommands) (" called Short DIFF before PUSH in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput

    # run "git diff $BareRepoName/$BranchName...$BranchName" and save in LOG
    $GitCommands = "diff", "$BareRepoName/$BranchName...$BranchName"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    LogAppend ($LogFilePath + ".diff.txt") ("git "+$GitCommands) (" called DIFF before PUSH in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput
    
    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called DIFF before PUSH in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}



<#
Check if there is something to Push

Input:
> WkPath: Working Copy path in which do Push
> BranchName: name of the branch in which do Push
> BareRepoName: remote repository to Push from
> LogFilePath: log file path

Return:
> True if there is something to commit
> False if there is nothing to commit

Event:
> if error with parameters

Output:
> on log
#>
function GitCheckIfPushIsNeeded ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BranchName = $(throw "-BranchName is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git diff --stat $BareRepoName/$BranchName...$BranchName" and save output in $cmdOutput
    $GitCommands = "diff", "--stat", "$BareRepoName/$BranchName...$BranchName"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    #LogAppend $LogFilePath ("git "+$GitCommands) (" called in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput
        return $false   # exit function with False (nothing to commit)
    }

    # if there were some output saved in $cmdOutput
    if ($cmdOutput)
    {
        # exit function with True (something to Push)
        return $true
    }
    else
    {
        return $false   # exit function with False (nothing to Push)
    }
}



<#
Return git Push diff (short) message

Input:
> WkPath: Working Copy path in which do Push
> BranchName: name of the branch in which do Push
> BareRepoName: remote repository to Push from
> LogFilePath: log file path

Return:
> Git Push diff (short) output

Event:
> if error with parameters

Output:
> on log
#>
function GitPushDiffMessage ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BranchName = $(throw "-BranchName is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git diff --stat $BareRepoName/$BranchName...$BranchName" and save output in $cmdOutput
    $GitCommands = "diff", "--stat", "$BareRepoName/$BranchName...$BranchName"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    #LogAppend $LogFilePath ("git "+$GitCommands) (" called in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput

    # return Git status message
    return $cmdOutput

}



<#
Git Push

Input:
> WkPath: Working Copy path in which do Push
> BranchName: name of the branch in which do Push
> BareRepoName: remote repository to Push from
> LogFilePath: log file path

Output:
> on LOG 

Return:
> True if success
> False if error

Event:
> if error with parameters

Output:
> on log
#>
function GitPush ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$BranchName = $(throw "-BranchName is required."),
    [string]$BareRepoName = $(throw "-BareRepoName is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run "git Push $BareRepoName $BranchName" and save in LOG 
    $GitCommands = "push", $BareRepoName, $BranchName, "--porcelain"
    $cmdOutput = & "git" $GitCommands 2>&1
    LogAppend $LogFilePath ("git "+$GitCommands) (" called in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) (" called in " + $WkPath + ", branch " + $BranchName + ", remote " + $BareRepoName) $cmdOutput
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}



<#
Git Log

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
function GitLog ()
{
param (
    [string]$WkPath = $(throw "-WkPath is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # cd to working copy $WkPath
    cd $WkPath

    # run the following commands and save in LOG 
    # git log --diff-filter=D --name-status --find-copies=100% --since="1 day"   # DELETED
    # git log --diff-filter=A --name-status --find-copies=100% --since="1 day"   # ADDED
    # git log --diff-filter=M --name-status --find-copies=100% --since="1 day"   # MODIFIED
    # git log --diff-filter=R --name-status --find-copies=100% --since="1 day"   # RENAMED
    # git log --name-status --find-copies=100% --since="1 day"   # ALL
    #
    # DELETED
    $GitCommands = "log", "--diff-filter=D", "--name-status", "--find-copies=100%", "--since='1 day'"
    $cmdOutput = & "git" $GitCommands 2>&1
    LogAppend -LogFilePath ($LogFilePath + ".log2.txt") ("git "+$GitCommands) ("called in " + $WkPath) $cmdOutput
    # ADDED
    $GitCommands = "log", "--diff-filter=A", "--name-status", "--find-copies=100%", "--since='1 day'"
    $cmdOutput = & "git" $GitCommands 2>&1
    LogAppend -LogFilePath ($LogFilePath + ".log2.txt") ("git "+$GitCommands) ("called in " + $WkPath) $cmdOutput
    # MODIFIED
    $GitCommands = "log", "--diff-filter=M", "--name-status", "--find-copies=100%", "--since='1 day'"
    $cmdOutput = & "git" $GitCommands 2>&1
    LogAppend -LogFilePath ($LogFilePath + ".log2.txt") ("git "+$GitCommands) ("called in " + $WkPath) $cmdOutput
    # RENAMED
    $GitCommands = "log", "--diff-filter=R", "--name-status", "--find-copies=100%", "--since='1 day'"
    $cmdOutput = & "git" $GitCommands 2>&1
    LogAppend -LogFilePath ($LogFilePath + ".log2.txt") ("git "+$GitCommands) ("called in " + $WkPath) $cmdOutput
    # ALL
    $GitCommands = "log", "--name-status", "--find-copies=100%", "--since='1 day'"
    $cmdOutput = & "git" $GitCommands 2>&1
    LogAppend -LogFilePath ($LogFilePath + ".log2.txt") ("git "+$GitCommands) ("called in " + $WkPath) $cmdOutput

    # if error in the last command ($LASTEXITCODE <> 0 ):
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) ("called in " + $WkPath) $cmdOutput
        return $false   # exit function with ERROR
    }

    # exit function with SUCCESS
    return $true

}




<#
Test if -NameToTest is a branch defined in Git repository directory -PathToTest.

Input:
> -PathToTest   Git repository directory
> -NameToTest   branch name to test if defined in Git repository directory -PathToTest
> -LogFilePath   Log File

Return:
> True if -NameToTest is a branch (current or not) defined in -PathToTest.
> False if -NameToTest is NOT a branch (current or not) defined in -PathToTest.

Event:
> if error with parameters

Output:
> NONE

Note:
-PathToTest is not checked to be a valid Git working copy. To do this use 'lib-Git-TestIfDirIsUnderControl.stex.ps1'.
#>
function GitTestIfBranchIsDefined()
{
param (
    [string]$PathToTest = $(throw "-PathToTest is required."),
    [string]$NameToTest = $(throw "-NameToTest is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # run git remote and search for $NameToTest
    cd $PathToTest
    $GitCommands = "branch"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    #LogAppend $LogFilePath ("git "+$GitCommands) ("called to check if '"+$NameToTest+"' is a branch defined in '"+$PathToTest+"'.") $cmdOutput #DEBUG#
    
    # check exit code
    # exit with error if $LASTEXITCODE <> 0 
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) ("called to check if '"+$NameToTest+"' is a branch defined in '"+$PathToTest+"'.") $cmdOutput #DEBUG#
        return $false   # exit function with ERROR
    }

    # check $cmdOutput content.
    # exit with error if $cmdOutput doesn't contain '  '+$NameToTest' OR '* '+$NameToTest   
    #    (because the current branch is highlighted with an asterisk.   see http://git-scm.com/docs/git-branch )
    if (! ( ($cmdOutput -contains '  '+$NameToTest) -or ($cmdOutput -contains '* '+$NameToTest) ) )
    {
        return $false   # exit function with ERROR
    }
    
    return $true   # exit function with SUCCESS

}



<#
Test if -PathToTest is a Git repository directory.

Input:
> -PathToTest   Git repository directory
> -LogFilePath   Log File

Return:
> True if -PathToTest is a Git repository directory.
> False if -PathToTest is NOT a Git repository directory.

Event:
> if error with parameters

Output:
> NONE
#>
function GitTestIfDirIsUnderControl()
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

    # 2) check if in the directory $PathToTest there is a .git file or directory
    If (! ( (Test-Path -path $PathToTest\.git -pathtype Leaf) -or (Test-Path -path $PathToTest\.git -pathtype Container) ) )
    {
        return $false   # exit function with ERROR
    }

    # 3) run git status (OK if no errors)
    cd $PathToTest
    $GitCommands = "status", "--porcelain"
    $cmdOutput = & "git" $GitCommands 2>&1
    #DEBUG# LogAppend $LogFilePath ("git "+$GitCommands) ("called to check if '"+$PathToTest+"' is under git control") $cmdOutput #DEBUG#
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) ("called to check if '"+$PathToTest+"' is under git control") $cmdOutput 
        return $false   # exit function with ERROR
    }
    
    return $true   # exit function with SUCCESS

}



<#
Test if -NameToTest is a remote defined in Git repository directory -PathToTest.

Input:
> -PathToTest   Git repository directory
> -NameToTest   remote name to test if defined in Git repository directory -PathToTest
> -LogFilePath   Log File

Return:
> True if -NameToTest is a remote defined in -PathToTest.
> False if -NameToTest is NOT a remote defined in -PathToTest.

Event:
> if error with parameters

Output:
> NONE

Note:
-PathToTest is not checked to be a valid Git working copy. To do this use 'lib-Git-TestIfDirIsUnderControl.stex.ps1'.

#>
function GitTestIfRemoteIsDefined()
{
param (
    [string]$PathToTest = $(throw "-PathToTest is required."),
    [string]$NameToTest = $(throw "-NameToTest is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # run git remote and search for $NameToTest
    cd $PathToTest
    $GitCommands = "remote"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    #LogAppend $LogFilePath ("git "+$GitCommands) ("called to check if '"+$NameToTest+"' is a remote defined in '"+$PathToTest+"'.") $cmdOutput #DEBUG#
    #$cmdOutput = $null #DEBUG#   #test following code with $null value
    #$cmdOutput = "origin" #DEBUG#   #test following code with a string value
    #$cmdOutput = "origin", "origin2" #DEBUG#   #test following code with an array value
    
    # check exit code
    # exit with error if $LASTEXITCODE <> 0 
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) ("called to check if '"+$NameToTest+"' is a remote defined in '"+$PathToTest+"'.") $cmdOutput 
        return $false   # exit function with ERROR
    }

    # check $cmdOutput content.
    # exit with error if $cmdOutput doesn't contain $NameToTest
    if (!($cmdOutput -contains $NameToTest)) 
    {
        return $false   # exit function with ERROR
    }
    
    return $true   # exit function with SUCCESS

}



<#
Test if -PathToTest is a bare repository.

Input:
> -PathToTest   Git repository directory
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
function GitTestIfRepoIsBare()
{
param (
    [string]$PathToTest = $(throw "-PathToTest is required."),
    [string]$LogFilePath = $(throw "-LogFilePath is required.")
)

    # run git remote and search for $NameToTest
    cd $PathToTest
    $GitCommands = "config", "core.bare"
    $cmdOutput = & "git" $GitCommands 2>&1
    #$cmdOutput #DEBUG#
    #LogAppend $LogFilePath ("git "+$GitCommands) ("called to check if '"+$PathToTest+"' is a Bare repository") $cmdOutput #DEBUG#
    
    # check exit code
    # exit with error if $LASTEXITCODE <> 0 
    if ($LASTEXITCODE -ne 0)
    {
        LogAppend ($LogFilePath + ".error.txt") ("git "+$GitCommands) ("called to check if '"+$PathToTest+"' is a Bare repository") $cmdOutput #DEBUG#
        return $false   # exit function with ERROR
    }

    # check $cmdOutput content.
    # exit with error if $cmdOutput doesn't contain the string 'true'
    if (!($cmdOutput -contains 'true')) 
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



LogAppend -LogFilePath $LogFilePath -CommandToLog "lib-Git-Sync.stex.ps1" -CommandDescriptionToLog "start" -CommandOutputToLog ""

. Main

LogAppend -LogFilePath $LogFilePath -CommandToLog "lib-Git-Sync.stex.ps1" -CommandDescriptionToLog "end" -CommandOutputToLog ""
