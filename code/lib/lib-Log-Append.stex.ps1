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
Script to append $CommandToLog and $MessageToLog to the file $LogFilePath

by Stefano Spinucci virgo977virgo at gmail.com
rev 201510250147

Input:
> -LogFilePath
> -CommandToLog
> -CommandDescriptionToLog
> -CommandOutputToLog

Return:
> True if there were no errors
> False if there were errors

Event:
> if error with parameters
> if LogFilePath is not a file

Output:
> NONE
#>



param (
    [string]$LogFilePath = $(throw "-LogFilePath is required."),
    [string]$CommandToLog = $(throw "-CommandToLog is required."),
    [string]$CommandDescriptionToLog = $(throw "-CommandDescriptionToLog is required."),
    $CommandOutputToLog = $(throw "-CommandOutputToLog is required.")
)



function Main
{
    # if log file is missing, tries to create it
    If (!(Test-Path -path $LogFilePath -PathType Leaf))
    {
        "." >> $LogFilePath
    }

    # if log file is again missing, raise an error
    If (!(Test-Path -path $LogFilePath -PathType Leaf))
    {
        throw "-LogFilePath ( " + $LogFilePath + " ) is not a file !!!"
        break
    }

    Get-Date -format "yyyy-MM-dd hh:mm.ss" >> $LogFilePath
    '$ '+$CommandToLog >> $LogFilePath
    $CommandDescriptionToLog >> $LogFilePath
    " " >> $LogFilePath
    $CommandOutputToLog >> $LogFilePath
    " " >> $LogFilePath
    "#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####" >> $LogFilePath
}



. Main
