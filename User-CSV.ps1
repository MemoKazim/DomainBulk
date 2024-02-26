cls
$csvpath = "$($(pwd | Select-Object).Path)" + "\mydata.csv"
$mycsv = Import-Csv $csvpath
$usage = "
This script automatically creates users imported from mydata.csv
----------------------------------------------------------------
Create mydata.csv file and add values comma seperated as follows

name,surname,password,path

> IMPORTANT:
mydata.csv file should be located at the same directory with PS1
"
if (($args[0] -eq "-h") -or ($args[0] -eq "--help") -or ($args[0] -eq "/?") ){
    Write-Host $usage
    Exit
}
try{
    $domainFull = $(Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Domain) -split "=" -split "}" | Select-Object -Last 2
    $domainName = $domainFull.Split(".")[0]
    $domainTLD = $domainFull.Split(".")[1]
    $counter = 0
    forEach ($user in $mycsv){
        $counter = $counter + 1
        $name = $user.name
        $surname = $user.surname
        $passwd = $user.password
        $ou = $user.path
        $cn = $name + "." + $surname
        $upn = $name[0] + "." + $surname + "@" + $domainFull
        $sam = $name[0] + "." + $surname
        $path = [string]::Format("DC={0}, DC={1}" , $domainName, $domainTLD)
        $oupath = $ou.Split("\")
        for ($i = $oupath.Length-1; $i -gt -1; $i--){
            $cur_path = $ou.Split("\")[$i]
            $path = "OU=$cur_path, " + $path
        }
        Write-Host ""
        Write-Host ""
        New-ADUser -Name $name -DisplayName "$name $surname" -Surname $surname -SamAccountName $sam -UserPrincipalName $upn -AccountPassword (ConvertTo-SecureString -AsPlainText "$passwd" -Force ) -Enabled $true -Path $path
        Write-Host "[$counter] $name.$surname successfully created at $path" -ForegroundColor white -BackgroundColor DarkGreen
    }    
} catch {
    Write-Host ""
    Write-Host ""
    Write-Host "Something went wrong. Here is an error: " -ForegroundColor Red -BackgroundColor White
    Write-Host $_ -ForegroundColor red
    Write-Host "Exiting..."
    Exit
}