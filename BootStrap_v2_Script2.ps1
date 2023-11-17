$LanguageRegionCode = '@lab.LanguageRegionCode'

$DecompressFunc_Base64 = '@lab.Variable(DecompressFunc)'
$DecompressFunc = [system.text.encoding]::utf8.GetString([Convert]::FromBase64String($DecompressFunc_Base64))
Invoke-Command -ScriptBlock ([scriptblock]::Create($DecompressFunc)) -NoNewScope

$Script1 = '@lab.Variable(Script1)'

Invoke-Command -NoNewScope -ScriptBlock ([scriptblock]::Create((Get-DecompressedByteArray $Script1)))

if ($Reboot) {shutdown -r -t 8}
