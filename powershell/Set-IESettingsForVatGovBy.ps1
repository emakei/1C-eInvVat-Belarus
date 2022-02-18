
$domains = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"
$domain = "vat.gov.by"

if( Test-Path $domains ) {
    
    # добавление зоны *.vat.gov.by
    if( Test-Path "$domains\$domain" ) {
        Remove-Item -Path "$domains\$domain" -Recurse -Force -Confirm:$false
    }

    New-Item "$domains\$domain"
    New-ItemProperty "$domains\$domain" -Name * -Value 2 -Type DWORD -Force -Verbose

} else {
    Write-Warning "Не найден каталог реестра 'ZoneMap\Domains'"
}

# включение ActiveX
$trusted = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2"

if( Test-Path $trusted ) {
    
    # https://support.microsoft.com/en-us/kb/182569
    New-ItemProperty $trusted -Name 1001 -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 1004 -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 1200 -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 1201 -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 1208 -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 1209 -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 120A -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 120B -Value 3 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 1405 -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 2000 -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 2201 -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 2702 -Value 0 -Type DWORD -Force -Verbose
    New-ItemProperty $trusted -Name 270C -Value 0 -Type DWORD -Force -Verbose

} else {
    Write-Warning "Не найден каталог реестра 'Zones\2'"
}
