#!/usr/bin/env pwsh
# Re-apply ALLOWED_ORIGINS for the current localhost.run / ngrok public hostname.
# Usage (from repo root):
#   pwsh -File scripts/mvp/reapply-tunnel-cors.ps1
#   pwsh -File scripts/mvp/reapply-tunnel-cors.ps1 -PublicUrl https://xxxx.lhr.life
param(
  [string]$PublicUrl = ""
)
$ErrorActionPreference = "Stop"
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $root "infra/docker/docker-compose.yml"))) {
  $root = (Get-Location).Path
}
Set-Location $root
$env:Path = "$env:LOCALAPPDATA\Programs\DockerDesktop\resources\bin;" + $env:Path

function Get-ActiveTunnelUrl {
  param([string]$Hint)
  $cands = @()
  if ($Hint) { $cands += $Hint.TrimEnd('/') }
  $f = Join-Path $root "var/public-tunnel-url.txt"
  if (Test-Path $f) { $cands += (Get-Content $f -Raw).Trim().TrimEnd('/') }
  foreach ($log in @("var/localhost-run.err.log","var/localhost-run.out.log")) {
    $p = Join-Path $root $log
    if (Test-Path $p) {
      $t = [string](Get-Content $p -Raw -EA SilentlyContinue)
      [regex]::Matches($t, 'https://[a-z0-9]+\.lhr\.life') | ForEach-Object { $cands += $_.Value }
    }
  }
  try {
    $api = Invoke-RestMethod "http://127.0.0.1:4040/api/tunnels" -TimeoutSec 2
    $api.tunnels | ForEach-Object { if ($_.public_url -match '^https://') { $cands += $_.public_url } }
  } catch {}
  $cands = $cands | Where-Object { $_ -and $_ -notmatch 'admin\.localhost\.run' } | Select-Object -Unique
  foreach ($u in $cands) {
    try {
      $r = Invoke-WebRequest "$u/api/user/healthz" -UseBasicParsing -TimeoutSec 12
      if ($r.StatusCode -eq 200 -and $r.Content -match 'status') { return $u.TrimEnd('/') }
    } catch {}
  }
  return $null
}

$public = Get-ActiveTunnelUrl -Hint $PublicUrl
if (-not $public) { throw "No live public tunnel found. Start: ssh -R 80:127.0.0.1:8080 nokey@localhost.run" }

$local = @("http://127.0.0.1:8080","http://localhost:8080","http://127.0.0.1:5173","http://localhost:5173")
$origins = ($local + $public) -join ","
$envFile = Join-Path $root "infra/docker/.env.tunnel"
@(
  "ALLOWED_ORIGINS=$origins",
  "USER_CORS_ALLOWED_ORIGINS=$origins",
  "TRADE_CORS_ALLOWED_ORIGINS=$origins",
  "PAYMENT_CORS_ALLOWED_ORIGINS=$origins",
  "USER_FRONTEND_ORIGIN=$public",
  "TELEGRAM_MINI_APP_URL=$public/miniapp"
) | Set-Content $envFile -Encoding ascii
$public | Set-Content (Join-Path $root "var/public-tunnel-url.txt") -Encoding ascii

Write-Host "Public URL: $public"
Write-Host "Origins:    $origins"
Write-Host "Recreating api-server + trading-core..."

docker compose -f infra/docker/docker-compose.yml -f infra/docker/docker-compose.lite.yml `
  --env-file infra/docker/.env.tunnel --profile app `
  up -d --force-recreate --no-deps api-server trading-core | Out-Host

Start-Sleep 12
Write-Host "api ALLOWED_ORIGINS=$(docker exec tragge_api_server printenv ALLOWED_ORIGINS)"

$h = @{ Origin=$public; "X-Requested-With"="XMLHttpRequest"; "Content-Type"="application/json" }
$health = Invoke-WebRequest "$public/api/user/healthz" -Headers @{Origin=$public;"X-Requested-With"="XMLHttpRequest"} -UseBasicParsing -TimeoutSec 20
Write-Host "healthz $($health.StatusCode) ACAO=$($health.Headers['Access-Control-Allow-Origin'])"
$login = Invoke-WebRequest "$public/api/user/auth/login" -Method POST -Headers $h -Body '{"email":"user@tragge.com","password":"user123456"}' -UseBasicParsing -TimeoutSec 20
Write-Host "login $($login.StatusCode) ACAO=$($login.Headers['Access-Control-Allow-Origin'])"
Write-Host "Done. Open: $public/user/login"
