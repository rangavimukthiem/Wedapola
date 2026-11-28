Add-Type -AssemblyName System.Drawing

$mobileRoot = Split-Path -Parent $PSScriptRoot
$blue = [System.Drawing.Color]::FromArgb(255, 0, 102, 255)
$white = [System.Drawing.Color]::White
$gold = [System.Drawing.Color]::FromArgb(255, 245, 210, 122)

function New-Canvas([int]$size, [bool]$transparent) {
    $format = if ($transparent) { [System.Drawing.Imaging.PixelFormat]::Format32bppArgb } else { [System.Drawing.Imaging.PixelFormat]::Format24bppRgb }
    $bitmap = [System.Drawing.Bitmap]::new($size, $size, $format)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear($(if ($transparent) { [System.Drawing.Color]::Transparent } else { $blue }))
    return @($bitmap, $graphics)
}

function Draw-Mark($graphics, [single]$centerX, [single]$centerY, [single]$unit) {
    $ringPen = [System.Drawing.Pen]::new($white, [single]($unit * 0.052))
    $ringPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $ringPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $diameter = [single]($unit * 0.40)
    $offset = [single]($unit * 0.12)
    $graphics.DrawEllipse($ringPen, [single]($centerX - $offset - $diameter / 2), [single]($centerY - $diameter / 2), $diameter, $diameter)
    $graphics.DrawEllipse($ringPen, [single]($centerX + $offset - $diameter / 2), [single]($centerY - $diameter / 2), $diameter, $diameter)
    $ringPen.Dispose()

    $diamondHalf = [single]($unit * 0.075)
    $diamondY = [single]($centerY - $unit * 0.30)
    $diamond = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($centerX, [single]($diamondY - $diamondHalf)),
        [System.Drawing.PointF]::new([single]($centerX + $diamondHalf), $diamondY),
        [System.Drawing.PointF]::new($centerX, [single]($diamondY + $diamondHalf)),
        [System.Drawing.PointF]::new([single]($centerX - $diamondHalf), $diamondY)
    )
    $gemBrush = [System.Drawing.SolidBrush]::new($gold)
    $graphics.FillPolygon($gemBrush, $diamond)
    $gemBrush.Dispose()
}

function Save-BrandIcon([string]$path, [int]$size, [bool]$maskable = $false, [bool]$transparent = $false) {
    $canvas, $graphics = New-Canvas $size $transparent
    $scale = if ($maskable) { 0.78 } else { 0.92 }
    Draw-Mark $graphics ($size / 2) ($size / 2) ([single]($size * $scale))
    $canvas.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $canvas.Dispose()
}

function Save-SplashImage([string]$path, [int]$width, [int]$height) {
    $bitmap = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear($blue)
    $unit = [single]($width * 0.70)
    Draw-Mark $graphics ($width / 2) ([single]($height * 0.38)) $unit
    $font = [System.Drawing.Font]::new('Segoe UI', [single]($width * 0.095), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $textBrush = [System.Drawing.SolidBrush]::new($white)
    $graphics.DrawString('WEDAPOLA', $font, $textBrush, [System.Drawing.RectangleF]::new(0, [single]($height * 0.68), $width, [single]($height * 0.18)), $format)
    $textBrush.Dispose()
    $format.Dispose()
    $font.Dispose()
    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

function Save-Ico([string]$path) {
    $entries = @()
    foreach ($size in @(16, 32, 48, 64, 128, 256)) {
        $bitmap, $graphics = New-Canvas $size $false
        Draw-Mark $graphics ($size / 2) ($size / 2) ([single]($size * 0.92))
        $stream = [System.IO.MemoryStream]::new()
        $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
        $entries += ,@($size, $stream.ToArray())
        $stream.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
    $output = [System.IO.File]::Create($path)
    $writer = [System.IO.BinaryWriter]::new($output)
    $writer.Write([UInt16]0)
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]$entries.Count)
    $offset = 6 + 16 * $entries.Count
    foreach ($entry in $entries) {
        $size = [int]$entry[0]
        $data = [byte[]]$entry[1]
        $dimension = if ($size -eq 256) { [byte]0 } else { [byte]$size }
        $writer.Write($dimension)
        $writer.Write($dimension)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]32)
        $writer.Write([UInt32]$data.Length)
        $writer.Write([UInt32]$offset)
        $offset += $data.Length
    }
    foreach ($entry in $entries) { $writer.Write([byte[]]$entry[1]) }
    $writer.Dispose()
    $output.Dispose()
}

# Android legacy and adaptive launcher icons.
$androidRes = Join-Path $mobileRoot 'android/app/src/main/res'
$densitySizes = @{ 'mipmap-mdpi' = 48; 'mipmap-hdpi' = 72; 'mipmap-xhdpi' = 96; 'mipmap-xxhdpi' = 144; 'mipmap-xxxhdpi' = 192 }
foreach ($density in $densitySizes.Keys) {
    $folder = Join-Path $androidRes $density
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    Save-BrandIcon (Join-Path $folder 'ic_launcher.png') $densitySizes[$density]
}
$adaptiveSizes = @{ 'mipmap-mdpi' = 108; 'mipmap-hdpi' = 162; 'mipmap-xhdpi' = 216; 'mipmap-xxhdpi' = 324; 'mipmap-xxxhdpi' = 432 }
foreach ($density in $adaptiveSizes.Keys) {
    $folder = Join-Path $androidRes $density
    Save-BrandIcon (Join-Path $folder 'ic_launcher_foreground.png') $adaptiveSizes[$density] $true $true
}
$splashSizes = @{ 'drawable-mdpi' = 288; 'drawable-hdpi' = 432; 'drawable-xhdpi' = 576; 'drawable-xxhdpi' = 864; 'drawable-xxxhdpi' = 1152 }
foreach ($density in $splashSizes.Keys) {
    $folder = Join-Path $androidRes $density
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    Save-BrandIcon (Join-Path $folder 'splash_icon.png') $splashSizes[$density] $true $true
}
Save-BrandIcon (Join-Path $androidRes 'drawable/splash_icon.png') 432 $true $true
Save-SplashImage (Join-Path $androidRes 'drawable/launch_splash.png') 288 288

# iOS, macOS, Windows, and web launcher assets.
$iosIcons = Join-Path $mobileRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$iosMap = @{
    'Icon-App-20x20@1x.png' = 20; 'Icon-App-20x20@2x.png' = 40; 'Icon-App-20x20@3x.png' = 60
    'Icon-App-29x29@1x.png' = 29; 'Icon-App-29x29@2x.png' = 58; 'Icon-App-29x29@3x.png' = 87
    'Icon-App-40x40@1x.png' = 40; 'Icon-App-40x40@2x.png' = 80; 'Icon-App-40x40@3x.png' = 120
    'Icon-App-60x60@2x.png' = 120; 'Icon-App-60x60@3x.png' = 180
    'Icon-App-76x76@1x.png' = 76; 'Icon-App-76x76@2x.png' = 152
    'Icon-App-83.5x83.5@2x.png' = 167; 'Icon-App-1024x1024@1x.png' = 1024
}
foreach ($name in $iosMap.Keys) { Save-BrandIcon (Join-Path $iosIcons $name) $iosMap[$name] }

$macIcons = Join-Path $mobileRoot 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
foreach ($size in @(16, 32, 64, 128, 256, 512, 1024)) { Save-BrandIcon (Join-Path $macIcons "app_icon_$size.png") $size }
Save-Ico (Join-Path $mobileRoot 'windows/runner/resources/app_icon.ico')

$webIcons = Join-Path $mobileRoot 'web/icons'
Save-BrandIcon (Join-Path $webIcons 'Icon-192.png') 192
Save-BrandIcon (Join-Path $webIcons 'Icon-512.png') 512
Save-BrandIcon (Join-Path $webIcons 'Icon-maskable-192.png') 192 $true
Save-BrandIcon (Join-Path $webIcons 'Icon-maskable-512.png') 512 $true

# Native splash images are independent from launcher icons.
$iosSplash = Join-Path $mobileRoot 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
Save-SplashImage (Join-Path $iosSplash 'LaunchImage.png') 180 185
Save-SplashImage (Join-Path $iosSplash 'LaunchImage@2x.png') 360 370
Save-SplashImage (Join-Path $iosSplash 'LaunchImage@3x.png') 540 555
