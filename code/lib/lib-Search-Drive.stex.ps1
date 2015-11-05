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
Ricerca in tutti i drive il file -IdOfDriveToSearch

by Stefano Spinucci virgo977virgo at gmail.com
rev 201510250147

Input:
> -IdOfDriveToSearch

Return:
> il path del drive nel quale il file è stato trovato, es "C:\" oppure "Z:\"
> se -IdOfDriveToSearch non viene trovato restituisce BLANK/NULLA/VUOTO

Event:
> NONE

Output:
> NONE

La chiamata a questo script si può fare nel modo seguente:
    $Result = & $PSScriptRoot'.\lib\lib-Search-Drive.stex.ps1' -IdOfDriveToSearch "ii.tx"    If ($Result)
        {
        Write-Host "ok"
        }
    else
        {
        Write-Host "ko"
        }
#>



param (
    [string]$IdOfDriveToSearch = $(throw "-IdOfDriveToSearch is required.")
)function Main{    $DrivesArray = "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"    foreach($Drive in $DrivesArray)
    {
        $PathToTest=$Drive + ":\" + $IdOfDriveToSearch
        #DEBUG# Write-Host $PathToTest

        If (Test-Path -path $PathToTest)
        {
            $Found=$true
            break
        }
    }
        If ($Found)
    {
        # return $IdOfDriveToSearch
        $Drive + ":\"
    }
    else {}   # return NOTHING

}



. Main
