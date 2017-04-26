Param(
    [Parameter(Mandatory=$false)]
    $Class,
    [Parameter(Mandatory=$false)]
    $CollectorName = ($Class -replace 'Win32_PerfFormattedData_Perf','t'),
    [Parameter(Mandatory=$false)]
    $ComputerName = "localhost",
    [Parameter(Mandatory=$false)]
    $Credential
)
$ErrorActionPreference = "Stop"

$name = "Win32_PerfFormattedData" 
$WMIClasses = Get-WmiObject -List | Where-Object {$_.name -Match $name}
if ($Class -eq $null){
    foreach($Class in $WMIClasses)
    {
        $Class.Name
        if ($Class.Name -ne $name){
            $wmiObject = Get-WMIObject -ComputerName $ComputerName -Class $Class
            $members = $wmiObject `
                | Get-Member -MemberType Properties `
                | Where-Object { $_.Definition -Match '^u?int' -and $_.Name -NotMatch '_' } `
                | Select-Object Name, @{Name="Type";Expression={$_.Definition.Split(" ")[0]}}
            $input = @{
                "Class"=$Class;
                "CollectorName"=t$CollectorName;
                "Members"=$members
            } | ConvertTo-Json
            $outFileName = "..\..\collector\t$CollectorName.go".ToLower()
            $input | .\collector-generator.exe | Out-File -NoClobber -Encoding UTF8 $outFileName
            go fmt $outFileName
        }
    }
}else{
    if ($Class.Name -ne $name){
        $wmiObject = Get-WMIObject -ComputerName $ComputerName -Class $Class
        $members = $wmiObject `
            | Get-Member -MemberType Properties `
            | Where-Object { $_.Definition -Match '^u?int' -and $_.Name -NotMatch '_' } `
            | Select-Object Name, @{Name="Type";Expression={$_.Definition.Split(" ")[0]}}
        $input = @{
            "Class"=$Class;
            "CollectorName"=$CollectorName;
            "Members"=$members
        } | ConvertTo-Json
        $outFileName = "..\..\collector\$CollectorName.go".ToLower()
        $input | .\collector-generator.exe | Out-File -NoClobber -Encoding UTF8 $outFileName
        go fmt $outFileName
    }
}