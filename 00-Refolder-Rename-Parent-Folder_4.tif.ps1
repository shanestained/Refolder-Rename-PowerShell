#Set the delim that will be used to create the folder groupings, folder directory, and for files to be moved into.
$refolderdelim = '_'
#Set the character that seperates the paerent prefix and the number suffix during rename
$renameseperator = '_'

# Set Threads
$threads = 6

#Get .ps1 filename
$scriptPath = $MyInvocation.MyCommand.Path
$scriptName = Split-Path $scriptPath -leaf
#Substrings of the filename to be used for file type filter and number padding of rename suffix
$fileType = $scriptName -replace ('^.+?\.','.') -replace ('.ps1','')
$padding = $scriptName -replace ('^.+?_','') -replace ('.ps1','') -replace ($fileType,'')

Measure-Command {

#Error Check and Retry
function Invoke-Retry {
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [scriptblock] $ScriptBlock,
        [int] $RetryCount = 10,
        [int] $TimeoutInSecs = 3,
        [string] $FailureFile = ""
        )

    begin {
    }

    process {

        $Attempt = 1
        $Flag = $true

        do {
            try {
                $PreviousPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                Invoke-Command -ScriptBlock $ScriptBlock -OutVariable Result
                $ErrorActionPreference = $PreviousPreference
                $Flag = $false
            }
            catch {
                if ($Attempt -gt $RetryCount) {
                    Write-Verbose "Total retry attempts: $RetryCount"
                    Write-Verbose "[Error Message] $($_.exception.message) `n"
                    $Flag = $false
                }
                else {
                    Write-Verbose $_.Exception.Message
                    Write-Verbose "[$Attempt/$RetryCount] Retrying in $TimeoutInSecs seconds.."
                    Start-Sleep -Seconds $TimeoutInSecs
                    $Attempt = $Attempt + 1
                }
            }
        }
        While ($Flag)

    }

    end {
        if ($Attempt -gt $RetryCount) {
        Write-Verbose $FailureFile
        Read-Host -Prompt "Press Enter to exit"
        exit
        }
    }


}

#Sort Naturally like Windows Explorer
function Sort-Naturally
{
    PARAM([System.Collections.ArrayList]$Array)

    Add-Type -TypeDefinition @'
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
namespace NaturalSort {
    public static class NaturalSort
    {
        [DllImport("shlwapi.dll", CharSet = CharSet.Unicode)]
        public static extern int StrCmpLogicalW(string psz1, string psz2);
        public static System.Collections.ArrayList Sort(System.Collections.ArrayList foo)
        {
            foo.Sort(new NaturalStringComparer());
            return foo;
        }
    }
    public class NaturalStringComparer : IComparer
    {
        public int Compare(object x, object y)
        {
            return NaturalSort.StrCmpLogicalW(x.ToString(), y.ToString());
        }
    }
}
'@
    $Array.Sort((New-Object NaturalSort.NaturalStringComparer))
    return $Array
}


# Filters files in the script's directory by filetype in script filename.
Get-ChildItem -File -Filter *$fileType |
    Group-Object { $_.Name -replace ($refolderDelim + '.*') } |
        ForEach-Object -Parallel {
        
# Checks if folder exists and creates it if not
            if ( -Not ( Test-Path -Path $_.Name ) ) {
                $dir = New-Item -Type Directory -Name $_.Name
            }
            
# If folder does exist it only sets the $dir variable
            else {
                $dir = $_.Name
            }
# Filenames are moved to the repective folder
            $_.Group | Move-Item -Destination $dir
        } -ThrottleLimit $threads


#First Rename Script
$tifs = Get-ChildItem (".\*") -Recurse -Filter *$fileType
Sort-Naturally -Array $tifs

$i = 1
$zeropad = '00000000000000000000000000000000000000000000000000000'
#Used to avoid rename of file that already exists, also keeps files in order incase script fails mid way
$startrename = '--00--'

$tifs | ForEach {

$fileName = Split-Path $_.Basename -leaf
$parentName = ($_ -split '\\')[-2]
$parentNameQuotes = '"' + $parentName + '"'
#If on the first file in the folder, reset the number to 1
    if ($parentNameQuotes -ne "$lastFile" -Or $lastFile -eq $null){
        $i = 1
        $renamedFile = $_
        $pad = ($zeropad + $i)
        $number = $pad.ToString().Substring($pad.ToString().Length -$padding)
        $fileNameCut = ($startrename + $parentName + $renameseperator + $number + $fileType -f $i)
        Invoke-Retry -ScriptBlock {Rename-Item $renamedFile -NewName $fileNameCut} -TimeoutInSecs 5 -RetryCount 4 -FailureFile ('Problem File: ' + $renamedFile) -Verbose
        $lastFile = $parentNameQuotes
    }
#Elseif on all following files in the folder
    elseif ($parentNameQuotes -eq "$lastFile") {
        $renamedFile = $_
        $pad = ($zeropad + $i)
        $number = $pad.ToString().Substring($pad.ToString().Length -$padding)
        $fileNameCut = ($startrename + $parentName + $renameseperator + $number + $fileType -f $i)
        Invoke-Retry -ScriptBlock {Rename-Item $renamedFile -NewName $fileNameCut} -TimeoutInSecs 5 -RetryCount 4 -FailureFile ('Problem File: ' + $renamedFile) -Verbose
        $lastFile = $parentNameQuotes
    }
#increment by 1 for next file rename
$i=$i + 1

}


#Second Rename Script
$dectifs = Get-ChildItem (".\*") -Recurse -Filter *$fileType
Sort-Naturally -Array $dectifs
#Reverse Array to garnetee the files don't get sorted wrong if the script fails mid way
[array]::Reverse($dectifs)

$dectifs | ForEach {
$renamedFile = $_
$fileName = Split-Path $_.Basename -leaf
$fileNameCut = $fileName -replace ($startrename)
#removes the --00-- from the file name
Invoke-Retry -ScriptBlock {Rename-Item $renamedFile -NewName ($fileNameCut + $fileType)} -TimeoutInSecs 5 -RetryCount 4 -FailureFile ('Problem File: ' + $renamedFile) -Verbose

}

}


#End of Script - Empty .txt created as a visual indicator in Explorer that script ran and finished on directory
Write-Output 'RENAME FINISHED: Ready for Orchestrator'
$textfile = '.\rename-complete-' + 'padding-' + $padding + '-verified.txt'
if(-Not (Test-Path -Path $textfile)) {

New-Item $textfile
}

Read-Host -Prompt "Press Enter to exit"
exit
