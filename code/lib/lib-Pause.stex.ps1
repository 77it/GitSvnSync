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
show message and PAUSE

by Stefano Spinucci virgo977virgo at gmail.com

rev 2015-11-07 13.42




Input:
> a message

Return:
> NONE

Event:
> if error with parameters

Output:
> the message on STDOUT
#>



param (
    [string]$PauseMessage = ""   # optional
)
function Main()
{
    # from   http://blog.danskingdom.com/allow-others-to-run-your-powershell-scripts-from-a-batch-file-they-will-love-you-for-it/
    # If running in the console, wait for input before closing.
    if ($Host.Name -eq "ConsoleHost")
    { 
        if ($PauseMessage)
        {
            Write-Host $PauseMessage   # write user message
        }
        else
        {
            Write-Host "Press any key to continue..."
        }
        $Host.UI.RawUI.FlushInputBuffer()   # Make sure buffered input doesn't "press a key" and skip the ReadKey().
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null

        Write-Host "."   # write a blank line
    }
    else
    # if not running in the console (e.g. is running in Powershell Ide in debug mode)
    # write only the message without pause
    {
        Write-Host $PauseMessage
    }
}



. Main

