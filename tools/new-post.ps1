<#
.SYNOPSIS
  Creates a new blog post from _templates/post.md and an image folder for its diagrams.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\new-post.ps1 -Title "Streaming joins in practice" -Topic data-engineering

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\new-post.ps1 -Title "Choosing a vector store" -Topic ai-engineering -Date 2026-11-02
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$Title,

  [ValidateSet('data-architecture', 'data-engineering', 'ai-engineering')]
  [string]$Topic = 'data-architecture',

  [string]$Date = (Get-Date -Format 'yyyy-MM-dd')
)

$ErrorActionPreference = 'Stop'

$slug = $Title.ToLowerInvariant()
$slug = $slug -replace '[^a-z0-9\s-]', ''
$slug = $slug -replace '\s+', '-'
$slug = $slug -replace '-+', '-'
$slug = $slug.Trim('-')
if (-not $slug) { throw "Could not build a URL slug from the title '$Title'." }

$root     = Split-Path -Parent $PSScriptRoot
$postPath = Join-Path $root "_posts\$Date-$slug.md"
$imgDir   = Join-Path $root "assets\images\posts\$slug"

if (Test-Path $postPath) { throw "A post already exists at $postPath" }

$template = [System.IO.File]::ReadAllText((Join-Path $root '_templates\post.md'))
$content  = $template.Replace('__TITLE__', $Title.Replace('"', '\"')).Replace('__TOPIC__', $Topic).Replace('__SLUG__', $slug).Replace('__DATE__', $Date)

New-Item -ItemType Directory -Force -Path $imgDir | Out-Null
[System.IO.File]::WriteAllText($postPath, $content, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "Created post:   $postPath"
Write-Host "Diagram folder: $imgDir"
Write-Host "URL (after publishing): /blog/$slug/"
Write-Host ""
