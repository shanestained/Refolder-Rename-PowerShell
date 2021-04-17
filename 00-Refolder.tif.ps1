# Set the delim - all characters in the filenames before the delim will become the new folders.
$refolderDelim = '_'

# Set Threads for multithreading
$threads = 6

# Get the filename of the script to then use substrings of the filename to set variables. 
$scriptPath = $MyInvocation.MyCommand.Path
$scriptName = Split-Path $scriptPath -leaf

# The file type before .ps1 is used as the filter, The two .'s are used to replace, Text before the two .'s in the filename can be changed.
$fileType = $scriptName -replace ('^.+?\.','.') -replace ('.ps1')

Measure-Command {

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
# Filenames are moved to their respective folder
            $_.Group | Move-Item -Destination $dir
        } -ThrottleLimit $threads
}

Write-Output 'REFOLDER FINISHED: Ready for Next Step'

# Remove lines below if you want Powershell to close automatically after running.
Read-Host -Prompt "Press Enter to exit"
exit
