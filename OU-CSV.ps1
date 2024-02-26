cls
$csvpath = "$($(pwd | Select-Object).Path)" + "\myou.csv"
$mycsv = Import-Csv $csvpath

$usage = "
This script automatically creates Organization Units imported from myou.csv
---------------------------------------------------------------------------
Create myou.csv file and add values comma seperated as follows

path
Parent\Child\Child\Child

You only need to specify full pattern of OU

> IMPORTANT:
myou.csv file should be located at the same directory with PS1
"
if (($args[0] -eq "-h") -or ($args[0] -eq "--help") -or ($args[0] -eq "/?") ){
    Write-Host $usage
    Exit
}


$domainFull = $(Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Domain).Domain
$domainName = $domainFull.Split(".")[0]
$domainTLD = $domainFull.Split(".")[1]
#New-ADOrganizationalUnit -Name "NewOU" -Path "OU=ParentOU,DC=$domainName,DC=$domainTLD"

$path = "DC=$domainName,DC=$domainTLD"
forEach($i in $mycsv){
    $ou = $i.path
    $fullOUPath = $ou.Split("\")
    #[array]::Reverse($fullOUPath)
    forEach($ou in $fullOUPath){
        $checkou = "OU=$ou,$path"
        if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq '$checkou'"){
            Write-Host "$checkou already exists!" -ForegroundColor Blue -BackgroundColor Yellow
        } else {
            try {
                New-ADOrganizationalUnit -Name $ou -Path $path -ProtectedFromAccidentalDeletion $false
                Write-Host "$checkou created!" -ForegroundColor White -BackgroundColor DarkGreen
            } catch {
                Write-Host "OU could not be created!" -ForegroundColor Red -BackgroundColor White
            }
        }
        $path = $checkou
    }
    $path = "DC=$domainName,DC=$domainTLD"
}

