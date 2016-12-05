
$crlDir = 'C:\eInvVat\task\crl' #"E:\TEMP\crl"
$imns = 'C:\Program Files (x86)\Avest\AvPCM_MNS\AvCmUt3.exe'
$nces = 'C:\Program Files (x86)\Avest\AvPCM_nces\AvCmUt3.exe'
$default = ''

if ( -not (Test-Path $crlDir) ) {
    New-Item $crlDir -ItemType "Directory"
    if ( -not (Test-Path $crlDir) ) { exit }
}

$imnsCrl = @()
$ncesCrl = @()
$defaultCrl = @()

rm "$crlDir\*"

$wc = new-object System.Net.WebClient
$wc.DownloadFile( "http://www.portal.nalog.gov.by/ca/mns-ca.crl", "$crlDir\mns-ca.mns.crl" )
$imnsCrl += "$crlDir\mns-ca.mns.crl"
$wc.DownloadFile( "http://www.portal.nalog.gov.by/ca/mns-ra.crl", "$crlDir\mns-ra.mns.crl" )
$imnsCrl += "$crlDir\mns-ra.mns.crl"
$wc.DownloadFile( "http://www.portal.nalog.gov.by/ca/rup.crl", "$crlDir\rup.mns.crl" )
$imnsCrl += "$crlDir\rup.mns.crl"
$wc.DownloadFile( "http://nces.by/wp-content/uploads/certificates/pki/kuc.crl", "$crlDir\kuc.nces.crl" )
$ncesCrl += "$crlDir\kuc.nces.crl"
# $wc.DownloadFile( "http://pki.gov.by/certs/-/kuc.crl", "$dir\all_cert\kuc.crl" )
$wc.DownloadFile( "http://nces.by/wp-content/uploads/certificates/pki/ruc.crl", "$crlDir\ruc.nces.crl" )
$ncesCrl += "$crlDir\ruc.nces.crl"
# $wc.DownloadFile( "http://pki.gov.by/certs/-/ruc.crl", "$dir\all_cert\ruc.crl" )

if ( Test-Path $imns ) {
    $default = $imns
    $imnsCrl | % { start $imns -ArgumentList "-C $_" -Wait }
}
else {
    $defaultCrl += $imnsCrl
}

if ( Test-Path $nces ) {
    $default = $nces
    $ncesCrl | % { start $nces -ArgumentList "-C $_" -Wait }
}
else {
    $defaultCrl += $ncesCrl
}

if ( ( $defaultCrl.Count -gt 0 ) -and ( Test-Path $default ) ) {
    $defaultCrl | % { start $default -ArgumentList "-C $_" -Wait }
}
