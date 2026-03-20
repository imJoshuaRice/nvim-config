$notesRoot  = "$env:USERPROFILE\notes"
$publicRoot = "$env:USERPROFILE\public-notes"
$timestamp  = Get-Date -Format "yyyy-MM-dd HH:mm"

# Build a set of filenames that should be in the public repo
# (source file exists AND has public: true)
$shouldBePublic = @{}

$allNotes = Get-ChildItem -Path $notesRoot -Recurse -Filter "*.md"

foreach ($file in $allNotes) {
  $content = Get-Content $file.FullName -Raw
  if ($content -match "(?m)^public:\s*true") {
    $shouldBePublic[$file.Name] = $file.FullName
  }
}

# Copy all public notes to public-notes folder
$published = 0
foreach ($name in $shouldBePublic.Keys) {
  $dest = Join-Path $publicRoot $name
  Copy-Item $shouldBePublic[$name] $dest -Force
  $published++
  Write-Host "  Published: $name" -ForegroundColor Green
}

# Remove any files in public-notes that should no longer be there
# (either source deleted, or public: true removed)
$publicFiles = Get-ChildItem -Path $publicRoot -Filter "*.md" |
  Where-Object { $_.Name -ne "README.md" }

$removed = 0
foreach ($file in $publicFiles) {
  if (-not $shouldBePublic.ContainsKey($file.Name)) {
    Remove-Item $file.FullName -Force
    $removed++
    Write-Host "  Removed: $($file.Name)" -ForegroundColor Yellow
  }
}

if ($published -eq 0 -and $removed -eq 0) {
  Write-Host "  Nothing to publish or remove." -ForegroundColor Yellow
  exit 0
}

# Commit and push
Set-Location $publicRoot
git add -A
git commit -m "publish: $timestamp"
git push

Write-Host "`n  Published: $published  Removed: $removed" -ForegroundColor Cyan
