#!/usr/bin/env pwsh
# Re-apply CORS allowlist for the public user origin (gateway :8080).
# Canonical production-like local/staging origin: https://panel.tragge.com
# Also supports ephemeral tunnels (localhost.run / ngrok) via -PublicUrl.
#
# Usage (from repo root):
#   pwsh -File scripts/mvp/reapply-tunnel-cors.ps1
#   pwsh -File scripts/mvp/reapply-tunnel-cors.ps1 -PublicUrl https://panel.tragge.com
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

function Test-PublicHealthz {
  param([string]$Base)
  if (-not $Base) { return $false }
  $u = $Base.TrimEnd('/')
  try {
    $r = Invoke-WebRequest "$u/api/user/healthz" -UseBasicParsing -TimeoutSec 12
    return ($r.StatusCode -eq 200 -and $r.Content -match 'status')
  } catch {
    return $false
  }
}

function Get-ActivePublicUrl {
  param([string]$Hint)
  $cands = @()
  if ($Hint) { $cands += $Hint.TrimEnd('/') }

  # Canonical Cloudflare Tunnel hostname for this lab (preferred).
  $cands += "https://panel.tragge.com"

  $f = Join-Path $root "var/public-tunnel-url.txt"
  if (Test-Path $f) { $cands += (Get-Content $f -Raw).Trim().TrimEnd('/') }

  foreach ($log in @("var/localhost-run.err.log", "var/localhost-run.out.log")) {
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
    if (Test-PublicHealthz -Base $u) { return $u.TrimEnd('/') }
  }
  return $null
}

$public = Get-ActivePublicUrl -Hint $PublicUrl
if (-not $public) {
  throw "No live public origin found. Prefer https://panel.tragge.com (Cloudflare Tunnel → gateway :8080), or pass -PublicUrl."
}

$userLocal = @(
  "http://127.0.0.1:8080",
  "http://localhost:8080",
  "http://127.0.0.1:5173",
  "http://localhost:5173"
)
$adminLocal = @(
  "http://127.0.0.1:8081",
  "http://localhost:8081",
  "http://127.0.0.1:5174",
  "http://localhost:5174"
)
# Canonical public origins (exact — never "*")
$userPublic = if ($public -match 'panel\.tragge\.com') { $public } else { $public }
$adminPublic = "https://manage.tragge.com"
# Keep panel as user origin even when -PublicUrl is an ephemeral tunnel.
if ($public -notmatch 'panel\.tragge\.com') {
  $userOrigins = ($userLocal + $public + "https://panel.tragge.com") | Select-Object -Unique
} else {
  $userOrigins = ($userLocal + $userPublic) | Select-Object -Unique
}
$adminOrigins = ($adminLocal + $adminPublic) | Select-Object -Unique
$allOrigins = ($userOrigins + $adminOrigins) | Select-Object -Unique

$userOriginsCsv = $userOrigins -join ","
$adminOriginsCsv = $adminOrigins -join ","
$allOriginsCsv = $allOrigins -join ","

$envFile = Join-Path $root "infra/docker/.env.tunnel"
@(
  "ALLOWED_ORIGINS=$allOriginsCsv",
  "USER_CORS_ALLOWED_ORIGINS=$userOriginsCsv",
  "ADMIN_CORS_ALLOWED_ORIGINS=$adminOriginsCsv",
  "TRADE_CORS_ALLOWED_ORIGINS=$userOriginsCsv",
  "PAYMENT_CORS_ALLOWED_ORIGINS=$userOriginsCsv",
  "USER_FRONTEND_ORIGIN=$(if ($public -match 'panel\.tragge\.com' -or $public -match 'lhr\.life|ngrok') { $public } else { 'https://panel.tragge.com' })",
  "ADMIN_FRONTEND_ORIGIN=$adminPublic",
  "TELEGRAM_MINI_APP_URL=$(if ($public -match 'https://') { "$public/miniapp" } else { 'https://panel.tragge.com/miniapp' })"
) | Set-Content $envFile -Encoding ascii
$public | Set-Content (Join-Path $root "var/public-tunnel-url.txt") -Encoding ascii

Write-Host "User public:  $public"
Write-Host "Admin public: $adminPublic"
Write-Host "USER_CORS:    $userOriginsCsv"
Write-Host "ADMIN_CORS:   $adminOriginsCsv"
Write-Host "Recreating api-server + trading-core with runtime CORS env..."
# CORS-only: writes gitignored .env.tunnel and force-recreates containers.
# Does NOT rebuild images, change Cloudflare Tunnel, or modify MFA policy.
# Does NOT set wildcard origins.

docker compose -f infra/docker/docker-compose.yml -f infra/docker/docker-compose.lite.yml `
  --env-file infra/docker/.env.tunnel --profile app `
  up -d --force-recreate --no-deps api-server trading-core | Out-Host

Start-Sleep 14
Write-Host "api ALLOWED_ORIGINS=$(docker exec tragge_api_server printenv ALLOWED_ORIGINS)"
Write-Host "api USER_CORS=$(docker exec tragge_api_server printenv USER_CORS_ALLOWED_ORIGINS)"
Write-Host "api ADMIN_CORS=$(docker exec tragge_api_server printenv ADMIN_CORS_ALLOWED_ORIGINS)"
Write-Host "trade TRADE_CORS=$(docker exec tragge_trading_core printenv TRADE_CORS_ALLOWED_ORIGINS)"

$h = @{
  Origin            = $public
  "X-Requested-With"= "XMLHttpRequest"
  "Content-Type"    = "application/json"
}
$health = Invoke-WebRequest "$public/api/user/healthz" -Headers @{ Origin = $public; "X-Requested-With" = "XMLHttpRequest" } -UseBasicParsing -TimeoutSec 20
Write-Host "healthz $($health.StatusCode) ACAO=$($health.Headers['Access-Control-Allow-Origin'])"
try {
  $login = Invoke-WebRequest "$public/api/user/auth/login" -Method POST -Headers $h -Body '{"email":"user@tragge.com","password":"user123456"}' -UseBasicParsing -TimeoutSec 20
  Write-Host "login $($login.StatusCode) ACAO=$($login.Headers['Access-Control-Allow-Origin'])"
} catch {
  if ($_.Exception.Response) {
    Write-Host "login status=$([int]$_.Exception.Response.StatusCode)"
  } else { Write-Host "login err=$_" }
}
Write-Host "Done. Open: $public/user/login  and  $public/miniapp/home"
