# GitSvnSync
Powershell scripts to automate working with Git and Svn repositories

The only 2 files you have to touch are:
* "Sync-Repos-loc.stex.csv" to start configuring your repositories actions
* "Sync-Repos.stex.ps1" to see what the start script do

To execute the script "Sync-Repos.stex.ps1" from Windows you have to enable
execution of unsigned scripts with the Powershell command:
> "Set-ExecutionPolicy RemoteSigned"
For further info see https://technet.microsoft.com/library/hh849812.aspx and 
http://superuser.com/questions/106360/how-to-enable-execution-of-powershell-scripts

The "lib" directory contains Powershell libraries written by me to work with Git/Svn repositories.
