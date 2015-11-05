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
script Mirr-Sync
by Stefano Spinucci virgo977virgo at gmail.com
rev 201511022202

Input:
todo XXXXXXXXXXXXXXXXXXXX

Return:
todo XXXXXXXXXXXXXXXXXXXX

Output:
todo XXXXXXXXXXXXXXXXXXXX
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

function Main{    . ErrorMessage -ErrorMessage "Mirr script is not implemented. Error !!!"
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
