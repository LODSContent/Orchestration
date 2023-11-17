$Decompress_Base64 = @'
RnVuY3Rpb24gR2V0LURlY29tcHJlc3NlZEJ5dGVBcnJheSB7DQogICAgUGFy
YW0gKCRCYXNlNjRTdHJpbmcpDQogICAgJGJ5dGVBcnJheSA9IFtDb252ZXJ0
XTo6RnJvbUJhc2U2NFN0cmluZygkQmFzZTY0U3RyaW5nKQ0KICAgICRpbnB1
dFN0cmVhbSA9IE5ldy1PYmplY3QgU3lzdGVtLklPLk1lbW9yeVN0cmVhbSgg
LCAkYnl0ZUFycmF5ICkNCgkkb3V0cHV0U3RyZWFtID0gTmV3LU9iamVjdCBT
eXN0ZW0uSU8uTWVtb3J5U3RyZWFtDQogICAgJGd6aXBTdHJlYW0gPSBOZXct
T2JqZWN0IFN5c3RlbS5JTy5Db21wcmVzc2lvbi5HemlwU3RyZWFtICRpbnB1
dFN0cmVhbSwgKFtJTy5Db21wcmVzc2lvbi5Db21wcmVzc2lvbk1vZGVdOjpE
ZWNvbXByZXNzKQ0KCSRnemlwU3RyZWFtLkNvcHlUbyggJG91dHB1dFN0cmVh
bSApDQogICAgJGd6aXBTdHJlYW0uQ2xvc2UoKQ0KCSRpbnB1dFN0cmVhbS5D
bG9zZSgpDQogICAgW1N5c3RlbS5UZXh0LkVuY29kaW5nXTo6VVRGOC5HZXRT
dHJpbmcoJG91dHB1dFN0cmVhbS5Ub0FycmF5KCkpDQp9
'@

$DecompressFunc = [system.text.encoding]::utf8.GetString(
    [Convert]::FromBase64String($Decompress_Base64)
)
Invoke-Command -ScriptBlock ([scriptblock]::Create($DecompressFunc)) -NoNewScope

$CoreFunctions_Base64 = @'
H4sIAAAAAAAEAMVWbW/bNhD+HiD/gdCEScIsOfGKonARIE5WJy6WFyROUyAINlq62OwkUiCpZK6n/96T
RPktspMCAaYvEsm75+65N7Gf8VAzwckJaP9YJKkEpSA6mmroSUmnZLa7Q/C5pJImxLWvtWR87FWb9mgu
dkDurqdKQxIM4V8dfOKhiFDwvtu9GfY/BIheQKp1AJHpNNO4B4h+QM7hyb8YfYNQE4M2uAjOIBFyWskY
tfF3lm5XqqkgteBkIb1isEXcuzXRpe8zEQG6X+94z0wHt5JpcJei0CJ7raVl8CfwsZ6QBtXjWChwm6Kw
enR3LPgjSI2ODMURVfD+XRVAd1VpKEqLrod6+e5OfzmrJ0yfZiME0sC12t2Z1dBJFGNaGC8S5f4BDzSL
dZln0CCvQZ/jF8bXucxGMQsd736lFKpFiTRXcs8oj6jGdLXIFiQ8FIqVDh6QvRr3J6Eke6QatmGpMlL3
di8MRcZ1a3fnrXzef0Of9xt9voJUvKHDnTd0uNPocJ/FcEn1ZJPTr4b/vTmHmZ4MxT/Aq7O6c76AHGG7
oJr760w9MR1OXJvKsfJmVlHxjGdgzWwtM8g/RlWJz+wHGivI89yt9S8lPIAEHoJnkAcPOByM8W53oM6z
OL6QtxPs+OuUhuAuPPK8ekgWTzkU/Nova06bIO8uqXJjkVqgW3uwALArGaRUul0d5NUL4lry9RarGG80
aZB7UeQPpykQv4fzPxnF0zJJZqDewsgE/AqUPgM9EdFfc0MKfT2c5dskAsR3nWrbaTk4lhzvZfkbBTjz
WIj7ChPhtMqILGXIxMp7FpMtqAuh4nFurgZOa3XvbsE6ONU6vdEsZnpa/MtkXNR4+XcD15rgoeq225I+
BWOmJ9koUyDDatIGoUja9swMnxw/i57O2wllHBd1v+SWt7DureTkE2ab/FJn8H/mSFNmOJbEJHJRTfQM
e/UCxZ8jcAo0ArnO4XC2ui7rOAwh1ViQFk1TLA1aTJX2I4+M8799U4JbDXrYzUKy79RMIesIqMQeQoZ1
n+cNatZX83v1eykrOqy4OViFfmev0/H39/3OhzW1fFO61/q4MTjdv7ntbmjC/4i5LAyF/xlZ4sZFpn1z
4do4AGxzM0CnB/wRifoLeHLYaOoVDShBZ5LPwZ/V9SaFl26R5vazdC/qS5Gs3Izc2mhgatHzFoHOfwCg
iz388QoAAA==
'@

$CoreFunctions = Get-DecompressedByteArray $CoreFunctions_Base64

Invoke-Command -ScriptBlock ([scriptblock]::Create($CoreFunctions)) -NoNewScope

$Functions_Content = Get-GitHubContents 'LODSContent' 'Orchestration' 'Functions.ps1'
$TimeSync_Content = Get-GitHubContents 'LODSContent' 'Orchestration' 'TimeSync/Set-TimeSync.ps1'
$Localization_Content = Get-GitHubContents 'LODSContent' 'Orchestration' 'Localization/Set-Localization.ps1'

$Script1_String += $Functions_Content | Out-String
$Script1_String += $TimeSync_Content | Out-String
$Script1_String += $Localization_Content | Out-String

$Script1_CompBase64 = Get-CompressedByteArray $Script1_String

Set-LabVariable -Name 'DecompressFunc' -Value $Decompress_Base64
Set-LabVariable -Name 'Script1' -Value $Script1_CompBase64