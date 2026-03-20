$notesRoot  = "$env:USERPROFILE\notes"
$publicRoot = "$env:USERPROFILE\public-notes"
$timestamp  = Get-Date -Format "yyyy-MM-dd HH:mm"

# Map note types to folders
$typeFolderMap = @{
  "fleeting"   = "zettelkasten\fleeting"
  "literature" = "zettelkasten\literature"
  "permanent"  = "zettelkasten\permanent"
  "project"    = "projects"
  "area"       = "areas"
}

# Build set of notes that should be public, with their target folder
$shouldBePublic = @{}  # filename -> @{ source, destFolder }

$allNotes = Get-ChildItem -Path $notesRoot -Recurse -Filter "*.md"
foreach ($file in $allNotes) {
  $content = Get-Content $file.FullName -Raw
  if ($content -match "(?m)^public:\s*true") {
    # Determine note type from frontmatter
    $noteType = ""
    if ($content -match "(?m)^type:\s*(\S+)") {
      $noteType = $Matches[1].Trim()
    }
    $destFolder = if ($typeFolderMap.ContainsKey($noteType)) { $typeFolderMap[$noteType] } else { "notes" }
    $shouldBePublic[$file.Name] = @{
      source     = $file.FullName
      destFolder = $destFolder
    }
  }
}

# Copy all public notes to their correct subfolder
$published = 0
foreach ($name in $shouldBePublic.Keys) {
  $entry      = $shouldBePublic[$name]
  $destDir    = Join-Path $publicRoot $entry.destFolder
  $destFile   = Join-Path $destDir $name

  if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  }

  Copy-Item $entry.source $destFile -Force
  $published++
  Write-Host "  Published: $($entry.destFolder)\$name" -ForegroundColor Green
}

# Remove any files in public-notes subfolders that are no longer public
$removed = 0
$publicFiles = Get-ChildItem -Path $publicRoot -Recurse -Filter "*.md" |
  Where-Object { $_.Name -ne "README.md" }

foreach ($file in $publicFiles) {
  if (-not $shouldBePublic.ContainsKey($file.Name)) {
    Remove-Item $file.FullName -Force
    $removed++
    Write-Host "  Removed: $($file.Name)" -ForegroundColor Yellow
  }
}

# Clean up empty folders
Get-ChildItem -Path $publicRoot -Recurse -Directory |
  Where-Object { (Get-ChildItem $_.FullName).Count -eq 0 } |
  Remove-Item -Force

if ($published -eq 0 -and $removed -eq 0) {
  Write-Host "  Nothing to publish or remove."; exit 0
}

Set-Location $publicRoot
git add -A
git commit -m "publish: $timestamp"
git push

Write-Host "`n  Published: $published  Removed: $removed" -ForegroundColor Cyan
