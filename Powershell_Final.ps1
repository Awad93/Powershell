function Get-Info{
    param(
        [Parameter (Mandatory=$false)][string] $survey #Optional parameter to specify file name to save the output
    )

    #This block gets the information which the user want and save them into a variable

    $computerName = hostname
    $dateTime = Get-Date
    $osVersion = systeminfo | findstr /R /C:"^OS Version"
    $processes = Get-process | Sort-Object -Property SI
    $connections = netstat -an

    #This block prints the information to powershell command line

    echo "Computer Name: $computerName"
    echo "Date/Time: $dateTime"
    echo $osVersion
    echo "Processes:"
    echo $processes
    echo "Connections:"
    echo $connections

    if($survey -ne ''){ #checks if the user specify any file name
        if(Test-Path $survey){ # checks if the file exist
            
            #This blocks prints and saves the information to the file that user specified
            
            echo "Computer Name: $computerName" > $survey
            echo "Date/Time: $dateTime" >> $survey
            echo $osVersion >> $survey
            echo "Processes:" >> $survey
            echo $processes >> $survey
            echo "Connections:" >> $survey
            echo $connections >> $survey
        }

        else{
            echo "File Does Not Exist!!!"
        }
    }

}

function Hash-Files{
    param(
        [Parameter (Mandatory=$true)][string] $dir, #Specify the directory to begin hashing from.
        [Parameter (Mandatory=$false)][string] $outfile #Specify the file that will save the hashings
    )

    if(Test-Path $dir){ #check if the directory that specified exist
        $hashes = @{}   #create associate array to save the hashs

        #This block will get every file in the directory and hash them than save them to the associate array
        foreach ($file in $(Get-ChildItem -Recurse -File $dir)){
            $hashes[$file.FullName] = Get-FileHash -Algorithm SHA1 -LiteralPath $file.FullName
        }

        Write-Output $hashes #prints the hashes to powershell command line

        if($outfile -ne ''){ #check if the user specify output file to save the hashes in
            Write-Output $hashes > $outfile #prints the hashed into the specified output file
        }
    }
    else{
        echo "File Does Not Exist!!!"
    }
}

function Compare-Hash{
    param(
        [Parameter (Mandatory=$true)][string] $file #Specify file to keep eye on it
    )

    if(Test-Path $file -PathType Leaf){ #check if it is exist and it is a file

        $file > $env:USERPROFILE\fileName.txt #save the full path of file in other file
        $(Get-FileHash $file).Hash > $env:USERPROFILE\schHash.txt #Hash the file and save it to schHash.txt file

        $jobName = [GUID]::NewGuid() #random name for the schduled task
                        
        $trigger = New-JobTrigger -Daily -At '3:30PM' #the scheduled task trigger daily and at 3:30PM

        #This line will register scheduled task with a random name and trigger that is specified previously
        #The Scheduled task will run a script that do:
        #1. get the hash from the file that save the hash previously which is schHash.txt and save it to variable ($refHash)
        #2. get the full path of the original file and save it to a variable ($file)
        #3. hash the file and save it to a variable ($nowHash)
        #4. compare the two hashes ($refHash & $nowHash) and save the result to warning.txt

        Register-ScheduledJob -Name $jobName -ScriptBlock { $refHash = Get-Content  $env:USERPROFILE\schHash.txt; $file = Get-Content $env:USERPROFILE\fileName.txt; $nowHash = $(Get-FileHash $file).Hash; if ($refHash.compareTo($nowHash) -ne 0){echo "File has been modified" > $env:USERPROFILE\warning.txt} else{echo "Everthing OK" > $env:USERPROFILE\warning.txt} } -Trigger $trigger

    }

    else{
        echo "File Does Not Exist!!!"
    }
}