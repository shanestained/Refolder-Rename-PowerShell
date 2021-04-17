# Refolder-Rename-PowerShell
A small but growing variety of PowerShell rename scripts used for Directory organization.

    Use Powershell v7.1.3.

Make sure you have ps1 files open with pwsh.exe v7.1.3 under Properties.

To use, place in directory you would like task completed and double click.

To change the file type filter change that in the ps1 filename.
Any part of the filename before the two periods is okay to change. 

    00-Refolder.tif.ps1
    00-Refolder.txt.ps1 
    Call-Me-Whatever.txt.ps1  
    00-Refolder.jpg.ps1
    
To change ranaming number padding change the number after the underscore in the ps1 filename.

    00-Refolder-Rename-Parent-Folder_4.tif.ps1
    00-Refolder-Rename-Parent-Folder_7.txt.ps1
    00-Refolder-Rename-Parent-Folder_15.jpg.ps1
    Call-Me-Whatever_15.jpg.ps1
                                                                                                  
To change the delim for refoldering you will need to edit line 2 on both rename and stand alone refolder ps1

    $refolderDelim = '_'

To change the rename sperator you will have to edit line 4 of the rename ps1

    $renameseperator = '_'
