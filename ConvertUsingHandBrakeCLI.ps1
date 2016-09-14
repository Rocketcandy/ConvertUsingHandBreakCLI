####  Change Values below to match what your enviroment and file size to look for #####

# Look for TV Shows larger than this value
$TvShowSize = 1GB
# Look for Movies larger than this value
$MovieSize = 2GB
# TV Shows directory
$TvShowDir = "\\path\to\Seasons"
# Movies directory
$MovieDir = "\\path\to\Videos"
# Location of spreadsheet that contains previously converted files to skip on the next run do NOT create this file, just give it where you want it to go!
$ConversionCompleted = "\\path\to\ConversionsCompleted.csv"
# HandBreak Instillation directory (The directory that has HandBrakeCLI.exe in it) 
$HandBreakDir = "C:\Program Files\Handbrake"
# Directory you want log files to go to
$LogFileDir = "\\path\to\Logs"


##### DO NOT CHANGE BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING #####


# Create the Conversion Completed Spreadsheet if it does not exist
If(-not(Test-Path $ConversionCompleted)){
    $headers = "File Name", "Completed Date"
    $psObject = New-Object psobject
    foreach($header in $headers)
    {
     Add-Member -InputObject $psobject -MemberType noteproperty -Name $header -Value ""
    }
    $psObject | Export-Csv $ConversionCompleted -NoTypeInformation
}

#Create Hash table to check against before starting conversions.  This will prevent converting items that have already been converted (This spreadsheet updates automatically)
$CompletedTable = Import-Csv -Path $ConversionCompleted
$HashTable=@{}
foreach($file in $CompletedTable){
    $HashTable[$file."File Name"]=$file."Completed Date"
}

# Output that we are finding file
Write-Host "Finding Movie files over $($MovieSize/1GB)GB in $MovieDir and Episodes over $($TvShowSize/1GB)GB in $TvShowDir be patient..." -ForegroundColor Gray

# Find all files larger than 2GB
$LargeTvFiles = Get-ChildItem $TvShowDir -recurse | where-object {$_.length -gt $TvShowSize}  | Select-Object FullName,Directory,BaseName,Length
$LargeMovieFiles = Get-ChildItem $MovieDir -recurse | where-object {$_.length -gt $MovieSize}  | Select-Object FullName,Directory,BaseName,Length

# Merge the files from both locations into one array and sort largest to smallest (So we start by converting the largest file first)
$AllLargeFiles = $LargeTvFiles + $LargeMovieFiles | Sort-Object length -Descending

# Run through a loop for each file in our array, converting it to a .mkv file
foreach($File in $AllLargeFiles){
    # Full file name and path
    $InputFile = $File.FullName
    # File name + "-NEW.mkv" we want it to be an mkv file and we don't want to overwrite the file we are reading from if it is already a .mkv
    $OutputFile = "$($File.Directory)\$($File.BaseName)-NEW.mkv"
    # Just the file itself
    $EpisodeName = $File.BaseName
    # The final name that we will rename it to when the conversion is finished and we have deleted the original
    $FinalName = "$($File.Directory)\$($File.BaseName).mkv"
    # Check the Hash table we created from the Conversions Completed spreadsheet.  If it exists skip that file
    if(-not($HashTable.ContainsKey("$FinalName"))){
        # Change the CPU priorety of HandBreakCLI.exe to below Normal in 10 seconds so that the conversion has started
        Start-Job -ScriptBlock {
            Start-Sleep -s 10
            $p = Get-Process -Name HandBrakeCLI
            $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
        } 
        # Write that we are starting the conversion
        $StartingFileSize = $File.Length/1GB
        Write-Host "Starting conversion on $InputFile it is $([math]::Round($StartingFileSize,2))GB in size before conversion" -ForegroundColor Cyan
        # Change Directory to be in the HandBreak Directory
        cd $HandBreakDir
        # Start the Conversion (The switches used are based off of YIFY's settings and depending on the file can compress by 80% or more (The larger the starting file the more we should be able to shrink it)
        .\HandBrakeCLI.exe -i "$InputFile" -t 1 --angle 1 -o "$OutputFile" -f mkv -w 1862 -l 1066 --crop 0:0:0:58 --modulus 2 -e x265 -q 23 --cfr -a 1 -E copy:* -6 dpl2 -R 48 -B 64 -D 0 --gain 0 --audio-fallback ac3 -m --encoder-preset=veryfast --verbose=1 2> "$LogFileDir\$EpisodeName.txt"
        # Check to make sure that the output file actuall exists so that if there was a conversion error we don't delete the original
        if( Test-Path $OutputFile ){
            Remove-Item $InputFile -Force
            Rename-Item $OutputFile $FinalName
            Write-Host "Finished converting $FinalName" -ForegroundColor Green
            $EndingFile = Get-Item $FinalName | Select-Object Length
            $EndingFileSize = $EndingFile.Length/1GB
            Write-Host "Ending file size is $([math]::Round($EndingFileSize,2))GB so, space saved is $([math]::Round($StartingFileSize-$EndingFileSize,2))GB" -ForegroundColor Green
            # Add the completed file to the completed csv file so we don't convert it again later
            $csvFileName = "$FinalName"
            $csvCompletedDate = Get-Date -UFormat "%x - %I:%M %p"
            $hash = @{
                "File Name" =  $csvFileName
                "Completed Date" = $csvCompletedDate
            }
            $newRow = New-Object PsObject -Property $hash
            Export-Csv $ConversionCompleted -inputobject $newrow -append -Force
        }
        # If file not found write that the conversion failed.
        elseif (-not(Test-Path $OutputFile)){
            Write-Host "Failed to convert $InputFile" -ForegroundColor Red
        }
    }
    # If file exists in Conversions Completed Spreadsheet write that we are skipping the file because it was already converted
    elseif($HashTable.ContainsKey("$FinalName")){
        Write-Host "Skipping $InputFile because it was already converted." -ForegroundColor DarkGreen
    }
    # Cleanup our variables so there is nothing leftover for the next run
    Clear-Variable InputFile,OutputFile,EpisodeName,FinalName,AllLargeFiles,TvShowDir,MovieDir,LargeMovieFiles,LargeTvFiles,File,EndingFile,EndingFileSize,TvShowSize,MovieSize -ErrorAction SilentlyContinue
}
