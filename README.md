# GitSvnSync
Powershell scripts to commit/fetch/merge/push many Git and Svn repositories automatically.

Best Features:
* if Git|Svn central repositories (bare repositories) are stored in an external disk this script can search
all drives for the repository and remap the remote url ("git remote" or "svn relocate") automatically
* all Git|Svn command output are checked for errors, and only error message are shown to the user
* with Unattended mode the user will have to choose what repository to sync and no other question will be asked;
otherwise, the user will be asked for confirmation only for commit/merge/push with content (empty commit/merge/push
will be skipped without question to the user).



The only 2 files you have to touch are:
* "Sync-Repos.stex.ps1" to see what the start script do (and to execute it when you are ready)
* "Sync-Repos-ActionsList-1.csv" to start configuring your repositories actions



To execute the script "Sync-Repos.stex.ps1" from Windows you have to enable
execution of unsigned scripts with the Powershell command form and Administrator prompt:
> "Set-ExecutionPolicy RemoteSigned"

For further info see https://technet.microsoft.com/library/hh849812.aspx and 
http://superuser.com/questions/106360/how-to-enable-execution-of-powershell-scripts



The "lib" directory contains Powershell libraries written by me to work with Git/Svn repositories.



To automate the use of repositories (eg GitHub, Bitbucket) that require passwords use Microsoft Git Credential Manager for Windows.
This program stores password securely and "automagically" (the first time the user insert the password in any Git command
the program saves them) and inserts automatically passwords for Git commands that require them.
* https://github.com/Microsoft/Git-Credential-Manager-for-Windows   
* https://github.com/Microsoft/Git-Credential-Manager-for-Windows/releases
