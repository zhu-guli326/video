param(
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][int]$Width,
    [Parameter(Mandatory = $true)][int]$Height,
    [Parameter(Mandatory = $true)][int]$Left,
    [Parameter(Mandatory = $true)][int]$Top,
    [Parameter(Mandatory = $true)][int]$Right,
    [Parameter(Mandatory = $true)][int]$Bottom,
    [Parameter(Mandatory = $true)][int]$Radius
)

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $OutputPath
if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$visibleWidth = [Math]::Max(1, $Width - $Left - $Right)
$visibleHeight = [Math]::Max(1, $Height - $Top - $Bottom)
$radius = [Math]::Min([Math]::Max(0, $Radius), [Math]::Floor([Math]::Min($visibleWidth, $visibleHeight) / 2))

$bitmap = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))

$rect = New-Object System.Drawing.Rectangle $Left, $Top, $visibleWidth, $visibleHeight
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
if ($radius -le 0) {
    $path.AddRectangle($rect)
} else {
    $diameter = $radius * 2
    $path.AddArc($rect.Left, $rect.Top, $diameter, $diameter, 180, 90)
    $path.AddArc($rect.Right - $diameter, $rect.Top, $diameter, $diameter, 270, 90)
    $path.AddArc($rect.Right - $diameter, $rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($rect.Left, $rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
}

$brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$graphics.FillPath($brush, $path)
$bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$brush.Dispose()
$path.Dispose()
$graphics.Dispose()
$bitmap.Dispose()
