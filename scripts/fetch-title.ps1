param([string]$url)

try {
  $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
  $html     = $response.Content

  # Try og:title first
  if ($html -match '<meta[^>]+property="og:title"[^>]+content="([^"]+)"') {
    Write-Output $Matches[1]
    exit 0
  }

  # Fall back to <title> tag
  if ($html -match '<title[^>]*>([^<]+)</title>') {
    $title = $Matches[1].Trim()
    # Strip site name suffix (e.g. "Article | Site Name")
    $title = $title -replace '\s*[|\-]\s*[^|\-]+$', ''
    Write-Output $title.Trim()
    exit 0
  }

  Write-Output ""
  exit 0
} catch {
  Write-Output ""
  exit 1
}
