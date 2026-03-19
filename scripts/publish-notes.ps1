$notesRoot   = "$env:USERPROFILE\notes"
$publicRoot  = "$env:USERPROFILE\public-notes"
$timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm"

# Find all markdown files with 'public: true' in frontmatter
$files = Get-ChildItem -Path $notesRoot -Recurse -Filter "*.md"
$published = 0

foreach ($file in $files) {
  $content = Get-Content $file.FullName -Raw
  if ($content -match "(?m)^public:\s*true") {
    $dest = Join-Path $publicRoot $file.Name
    Copy-Item $file.FullName $dest -Force
    $published++
    Write-Host "  Published: $($file.Name)" -ForegroundColor Green
  }
}

# Remove any files in public-notes that no longer have public: true
$publicFiles = Get-ChildItem -Path $publicRoot -Filter "*.md" | Where-Object { $_.Name -ne "README.md" }
foreach ($file in $publicFiles) {
  $source = Get-ChildItem -Path $notesRoot -Recurse -Filter $file.Name | Select-Object -First 1
  if ($source) {
    $content = Get-Content $source.FullName -Raw
    if ($content -notmatch "(?m)^public:\s*true") {
      Remove-Item $file.FullName -Force
      Write-Host "  Unpublished: $($file.Name)" -ForegroundColor Yellow
    }
  } else {
    Remove-Item $file.FullName -Force
    Write-Host "  Removed (source deleted): $($file.Name)" -ForegroundColor Yellow
  }
}

if ($published -eq 0) {
  Write-Host "  No notes marked public: true" -ForegroundColor Yellow
  exit
}

# Commit and push
cd $publicRoot
git add -A
git commit -m "publish: $timestamp"
git push

Write-Host "`nPublished $published note(s) to public-notes." -ForegroundColor Cyan
