$required = @(
  "DATABASE_URL",
  "REDIS_URL",
  "JWT_ACCESS_SECRET",
  "JWT_REFRESH_SECRET",
  "CORS_ORIGINS",
  "AI_SERVICE_URL"
)

$missing = @()
foreach ($name in $required) {
  if (-not [Environment]::GetEnvironmentVariable($name)) {
    $missing += $name
  }
}

if ($missing.Count -gt 0) {
  Write-Error "Missing required environment variables: $($missing -join ', ')"
  exit 1
}

Write-Output "Environment looks ready."
