[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false, Position=1)]
    [ValidateScript({ (Test-Path $_\all_cert) -and (Test-Path $_\import) })]
    [string]$dir = 'C:\eInvVat\',
    [switch]$inslall = $true,
    [switch]$importRoot = $true,   
    [switch]$downdoldCrl = $false,
    [switch]$importMy = $true,
    [switch]$ieSettings = $true
    )

if( $inslall ) {

    # установка плагина IE
    Write-Host
    Write-Host "Установка плагина IE" -ForegroundColor Yellow

    start $dir\AvCMXWebP-1.1.5r1-setup.exe -Wait

}

if ( $importMy ) {

    # импортировать сертификаты в личные
    Write-Host
    Write-Host "Импорт сетрификатов организаций" -ForegroundColor Yellow
    <#
    $certFiles = (gci $dir\import | Where-Object Extension -In @(".cer",".p7b"))
    foreach( $file in $certFiles ) {
        $byte = Get-Content $file.FullName -Encoding Byte -TotalCount 1 -ErrorAction SilentlyContinue
        if( $byte -ne $null) {
            start 'C:\Program Files (x86)\Avest\AvPCM_MNS\MngCert.exe' -ArgumentList "/importcert ""$($file.FullName)""" -Wait
        }
    }#>

    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    $Form = New-Object System.Windows.Forms.Form    
    $Form.Text = "Выбор ключей для импорта"
    $Form.StartPosition = "CenterScreen"
    $Form.KeyPreview = $True

    $Form.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            $Form.Controls[0].Controls.ForEach({
                if( $_.Checked ) {
                    $byte = Get-Content "$dir\import\$($_.Text)" -Encoding Byte -TotalCount 1 -ErrorAction SilentlyContinue
                    if( $byte -ne $null) {
                        start 'C:\Program Files (x86)\Avest\AvPCM_MNS\MngCert.exe' -ArgumentList "/importcert ""$dir\import\$($_.Text)""" -Wait
                    }
                }
            })
            $Form.Close()
        } elseif ($_.KeyCode -eq "Escape") {
            $Form.Close()
        }
    })


    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Location = New-Object System.Drawing.Size(20,20)
    $groupBox.Text = "Доступные сертификаты"

    $Form.Controls.Add($groupBox)

    $certFiles = (gci $dir\import | Where-Object Extension -In @(".cer",".p7b"))

    $Checkboxes = @()
    $y = 20
    foreach( $file in $certFiles ) {
    
        $Checkbox = New-Object System.Windows.Forms.Checkbox
        $Checkbox.Location = New-Object System.Drawing.Size(10,$y)
        $Checkbox.Size = New-Object System.Drawing.Size(200,20)
        $y += 30
        $Checkbox.Checked = $true
        $Checkbox.Text = $file.Name
        $groupBox.Controls.Add($Checkbox)
        $Checkboxes += $Checkbox

    }

    $Form.Size = New-Object System.Drawing.Size(280,(40*$Checkboxes.Count+80))
    $groupBox.Size = New-Object System.Drawing.Size(220,(40*$Checkboxes.Count))
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Text = "Enter для импорта Esc для отмены"
    $textBox.ReadOnly = $true
    $textBox.Size = New-Object System.Drawing.Size(220, 30)
    $textBox.Location = New-Object System.Drawing.Size(20, (40*$Checkboxes.Count+20))
    $Form.Controls.Add($textBox)

    $Form.ShowDialog() | Out-Null

}


if( $importRoot ) {

    # импорт сетрификатов
    # Import-Certificate -FilePath $certPath\my.p7b -CertStoreLocation Cert:\CurrentUser\My -Verbose
    Write-Host
    Import-Certificate -FilePath $dir\all_cert\root.p7b -CertStoreLocation Cert:\CurrentUser\Root -Verbose
    Write-Host
    Import-Certificate -FilePath $dir\all_cert\trusted.p7b -CertStoreLocation Cert:\CurrentUser\Trust -Verbose
    # загрузка СОС
    if( $downdoldCrl ) {
        
        Write-Host
        Write-Host "Удаление старого СОС" -ForegroundColor Yellow
        
        Remove-Item "$dir\all_cert\mns-ca.crl" -Force | Out-Null
        Remove-Item "$dir\all_cert\mns-ra.crl" -Force | Out-Null
        Remove-Item "$dir\all_cert\rup.crl" -Force | Out-Null
        Remove-Item "$dir\all_cert\kuc.crl" -Force | Out-Null
        Remove-Item "$dir\all_cert\ruc.crl" -Force | Out-Null
        
        Write-Host
        Write-Host "Загрузка сертификатов из интернета" -ForegroundColor Yellow

        $wc = new-object System.Net.WebClient
        $wc.DownloadFile( "http://www.portal.nalog.gov.by/ca/mns-ca.crl", "$dir\all_cert\mns-ca.crl" )
        $wc.DownloadFile( "http://www.portal.nalog.gov.by/ca/mns-ra.crl", "$dir\all_cert\mns-ra.crl" )
        $wc.DownloadFile( "http://www.portal.nalog.gov.by/ca/rup.crl", "$dir\all_cert\rup.crl" )
        $wc.DownloadFile( "http://pki.gov.by/certs/-/kuc.crl", "$dir\all_cert\kuc.crl" )
        $wc.DownloadFile( "http://pki.gov.by/certs/-/ruc.crl", "$dir\all_cert\ruc.crl" )
    }
    # импорт СОС
    Write-Host
    Write-Host "Импорт СОС"-ForegroundColor Yellow
   
    $crlFiles = (Get-ChildItem -Path $dir\all_cert | Where-Object Extension -EQ '.crl')
    $crlFiles | % { start 'C:\Program Files (x86)\Avest\AvPCM_MNS\AvCmUt3.exe' -ArgumentList "-C $($_.FullName)" -Wait }

}

if( $ieSettings ) {

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
        Write-Host "Не найден каталог реестра 'ZoneMap\Domains'" -ForegroundColor Yellow
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
        Write-Host "Не найден каталог реестра 'Zones\2'" -ForegroundColor Yellow
    }

}
