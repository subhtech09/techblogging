<#
.SYNOPSIS
  Regenerates assets/images/og-default.jpg — the 1200x630 image shown when a
  page without its own `image:` is shared on LinkedIn, X, Slack, etc.
  Run it again whenever you change the site title or tagline.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\make-og-image.ps1 -Title "The Data Blueprint" -Url "subhtech09.github.io/techblogging"
#>
param(
  [string]$Title   = 'The Data Blueprint',
  [string]$Tagline = ('Data architecture  {0}  Data engineering  {0}  AI engineering' -f [char]0x00B7),
  [string]$Url     = 'subhtech09.github.io/techblogging'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function C([string]$hex, [int]$a = 255) {
  $c = [System.Drawing.ColorTranslator]::FromHtml($hex)
  [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B)
}
function Txt($g, $text, $x, $y, $size, $color, $style = 'Regular', $family = 'Segoe UI') {
  $f = New-Object System.Drawing.Font($family, [float]$size, [System.Drawing.FontStyle]$style, [System.Drawing.GraphicsUnit]::Pixel)
  $b = New-Object System.Drawing.SolidBrush($color)
  $g.DrawString($text, $f, $b, [float]$x, [float]$y)
  $f.Dispose(); $b.Dispose()
}

$W = 1200; $H = 630
$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.TextRenderingHint = 'AntiAliasGridFit'

# Deep green gradient background
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Point(0, 0)), (New-Object System.Drawing.Point(0, $H)), (C '#1B3139'), (C '#0B2026'))
$g.FillRectangle($bg, 0, 0, $W, $H); $bg.Dispose()

# Blueprint grid
$gridPen = New-Object System.Drawing.Pen((C '#FFFFFF' 12), 1)
for ($x = 0; $x -le $W; $x += 40) { $g.DrawLine($gridPen, $x, 0, $x, $H) }
for ($y = 0; $y -le $H; $y += 40) { $g.DrawLine($gridPen, 0, $y, $W, $y) }
$gridPen.Dispose()

# Brick-red glow, top right
$glow = New-Object System.Drawing.Drawing2D.GraphicsPath
$glow.AddEllipse(700, -380, 800, 800)
$pgb = New-Object System.Drawing.Drawing2D.PathGradientBrush($glow)
$pgb.CenterColor = (C '#FF3621' 110)
$pgb.SurroundColors = [System.Drawing.Color[]]@((C '#FF3621' 0))
$g.FillPath($pgb, $glow); $pgb.Dispose(); $glow.Dispose()

# Logo mark (the 32px SVG scaled x3)
$s = 3; $ox = 80; $oy = 150
$p = New-Object System.Drawing.Drawing2D.GraphicsPath
$rr = 7 * $s; $d = $rr * 2; $lw = 32 * $s
$p.AddArc($ox, $oy, $d, $d, 180, 90); $p.AddArc($ox + $lw - $d, $oy, $d, $d, 270, 90)
$p.AddArc($ox + $lw - $d, $oy + $lw - $d, $d, $d, 0, 90); $p.AddArc($ox, $oy + $lw - $d, $d, $d, 90, 90); $p.CloseFigure()
$brick = New-Object System.Drawing.SolidBrush((C '#FF3621')); $g.FillPath($brick, $p); $brick.Dispose(); $p.Dispose()
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, (2.2 * $s))
$pen.StartCap = 'Round'; $pen.EndCap = 'Round'; $pen.LineJoin = 'Round'
$g.DrawLines($pen, [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF(($ox + 9 * $s), ($oy + 10.5 * $s))), (New-Object System.Drawing.PointF(($ox + 15.5 * $s), ($oy + 10.5 * $s))), (New-Object System.Drawing.PointF(($ox + 22.5 * $s), ($oy + 16 * $s)))))
$g.DrawLines($pen, [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF(($ox + 9 * $s), ($oy + 21.5 * $s))), (New-Object System.Drawing.PointF(($ox + 15.5 * $s), ($oy + 21.5 * $s))), (New-Object System.Drawing.PointF(($ox + 22.5 * $s), ($oy + 16 * $s)))))
$pen.Dispose()
$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
foreach ($c in @(@(8.5, 10.5, 2.5), @(8.5, 21.5, 2.5), @(23, 16, 3))) {
  $cr = $c[2] * $s
  $g.FillEllipse($white, ($ox + $c[0] * $s - $cr), ($oy + $c[1] * $s - $cr), (2 * $cr), (2 * $cr))
}
$white.Dispose()

Txt $g $Title 72 280 78 ([System.Drawing.Color]::White) 'Bold'
Txt $g $Tagline 80 390 30 (C '#FF7A63')
Txt $g $Url 80 530 24 (C '#FFFFFF' 150) 'Regular' 'Consolas'

$bar = New-Object System.Drawing.SolidBrush((C '#FF3621'))
$g.FillRectangle($bar, 0, ($H - 8), $W, 8); $bar.Dispose()

$out = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets\images\og-default.jpg'
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]90)
$bmp.Save($out, $codec, $ep)
$g.Dispose(); $bmp.Dispose()
Write-Host "Wrote $out"
