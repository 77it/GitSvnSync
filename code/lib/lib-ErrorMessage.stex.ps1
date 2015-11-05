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
show error messages

by Stefano Spinucci virgo977virgo at gmail.com
rev 201510290030




Input:
> an error message

Return:
> NONE

Event:
> if error with parameters

Output:
> the error message on STDOUT
#>



param (
    [string]$ErrorMessage = $(throw "-ErrorMessage is required.")
)function Main{    write-host  $ErrorMessage -foregroundcolor "White" -backgroundcolor "red"
}



. Main
