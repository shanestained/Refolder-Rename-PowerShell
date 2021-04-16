$refolderdelim = '_'



$scriptPath = $MyInvocation.MyCommand.Path
$scriptName = Split-Path $scriptPath -leaf
$fileType = $scriptName -replace ('^.+?\.','.') -replace ('.ps1')

Measure-Command {
Get-ChildItem -File -Filter *$fileType |
  Group-Object { $_.Name -replace ($refolderdelim + '.*') } |
  ForEach-Object {
    if (-Not (Test-Path -Path $_.Name)) {
    $dir = New-Item -Type Directory -Name $_.Name
    }
    else {
    $dir = $_.Name
    }
    $_.Group | Move-Item -Destination $dir
  }
}

Write-Output 'RENAME FINISHED: Ready for Renaming'

Read-Host -Prompt "Press Enter to exit"
exit