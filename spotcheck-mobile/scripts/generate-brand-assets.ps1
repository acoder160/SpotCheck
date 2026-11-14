$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assetsDir = Join-Path $root "assets\images"
$fontBlackPath = Join-Path $root "node_modules\@expo-google-fonts\big-shoulders-display\BigShouldersDisplay_900Black.ttf"

$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$pfc.AddFontFile($fontBlackPath)
$fontFamily = $pfc.Families[0]
# Check which FontStyle is supported by this TTF face
$fontStyle = [int][System.Drawing.FontStyle]::Regular
if (-not $fontFamily.IsStyleAvailable([System.Drawing.FontStyle]::Regular)) {
    $fontStyle = [int][System.Drawing.FontStyle]::Bold
}

function New-Color([string]$hex, [int]$alpha = 255) {
    $c = [System.Drawing.ColorTranslator]::FromHtml($hex)
    return [System.Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B)
}

function New-RoundedRectPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    if ($r -le 0) {
        $path.AddRectangle((New-Object System.Drawing.RectangleF($x, $y, $w, $h)))
        return $path
    }
    $d = [Math]::Min($r * 2, [Math]::Min($w, $h))
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Set-HighQuality([System.Drawing.Graphics]$g) {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
}

# Colors from DESIGN.md ("Locate Paint")
$cBlackTop    = New-Color "#1A1A1A"
$cBlackBottom = New-Color "#0B0B0B"
$cAsphalt     = New-Color "#141414"
$cWhite       = New-Color "#FFFFFF"
$cPinkTop     = New-Color "#FF66B0"
$cPink        = New-Color "#FF4FA3"
$cOrange      = New-Color "#FF7A00"
$cYellow      = New-Color "#FFD400"
$cBlue        = New-Color "#2F6BFF"
$cGreen       = New-Color "#18A558"
$paints       = @($cOrange, $cYellow, $cBlue, $cGreen, $cPink)

function Draw-AsphaltBackground([System.Drawing.Graphics]$g, [int]$size, [bool]$withDetail = $true) {
    $rect = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $cBlackTop, $cBlackBottom, 90.0)
    $g.FillRectangle($grad, $rect)
    $grad.Dispose()

    if ($withDetail) {
        # Subtle warm-asphalt radial spotlight in the center
        $centerPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $r = $size * 0.45
        $centerPath.AddEllipse($size * 0.5 - $r, $size * 0.5 - $r, $r * 2, $r * 2)
        $pgb = New-Object System.Drawing.Drawing2D.PathGradientBrush($centerPath)
        $pgb.CenterColor = New-Color "#252525" 185
        $pgb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 12, 12, 12))
        $g.FillPath($pgb, $centerPath)
        $pgb.Dispose()
        $centerPath.Dispose()

        # Subtle street-locate radar circle in the background
        $ringPen = New-Object System.Drawing.Pen((New-Color "#FFFFFF" 16), ($size * 0.004))
        $ringPen.DashCap = [System.Drawing.Drawing2D.DashCap]::Round
        $ringPen.DashPattern = @(2.0, 4.0)
        $rad = $size * 0.295
        $g.DrawEllipse($ringPen, $size * 0.5 - $rad, $size * 0.5 - $rad, $rad * 2, $rad * 2)
        $ringPen.Dispose()
    }
}

function Draw-ForegroundMark(
    [System.Drawing.Graphics]$g,
    [int]$size,
    [float]$scale = 1.0,
    [float]$offsetY = 0.0,
    [bool]$monochrome = $false,
    [bool]$showWordmark = $false
) {
    $cx = $size * 0.5
    $cy = ($size * 0.5) + $offsetY

    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    # Build the ultra-bold "S" glyph path from BigShouldersDisplay_900Black
    $sPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $emSize = $size * 0.43 * $scale
    $sPath.AddString(
        "S",
        $fontFamily,
        $fontStyle,
        $emSize,
        (New-Object System.Drawing.PointF(0, 0)),
        $sf
    )

    $rawBounds = $sPath.GetBounds()
    $rawCx = $rawBounds.X + ($rawBounds.Width * 0.5)
    $rawCy = $rawBounds.Y + ($rawBounds.Height * 0.5)

    $sTargetY = $cy - ($size * 0.044 * $scale)
    $mat = New-Object System.Drawing.Drawing2D.Matrix
    $mat.Translate($cx, $sTargetY)
    $mat.Scale(1.32, 1.0)
    $mat.Translate(-$rawCx, -$rawCy)
    $sPath.Transform($mat)
    $mat.Dispose()

    $sBounds = $sPath.GetBounds()

    if (-not $monochrome) {
        # Signature Dashed Pink Painted Route curving around the upper-left to upper-right of the S
        # and ending at a Locate Spot Marker Dot (never colliding with the bottom 5-paint strip!)
        $arcR = $size * 0.232 * $scale
        $routePen = New-Object System.Drawing.Pen($cPink, ($size * 0.0125 * $scale))
        $routePen.DashCap = [System.Drawing.Drawing2D.DashCap]::Round
        $routePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $routePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $routePen.DashPattern = @(0.95, 1.85)
        $arcRect = New-Object System.Drawing.RectangleF(($cx - $arcR), ($sTargetY - $arcR), ($arcR * 2), ($arcR * 2))
        # Left/top route sweep from 166 deg to 306 deg
        $g.DrawArc($routePen, $arcRect, 166, 140)
        $routePen.Dispose()

        # Target Spot Marker Dot at 322 deg on the arc (like arriving at a skate spot on the map)
        $angleRad = 324.0 * [Math]::PI / 180.0
        $pinX = $cx + ($arcR * [Math]::Cos($angleRad))
        $pinY = $sTargetY + ($arcR * [Math]::Sin($angleRad))
        $pinR = $size * 0.025 * $scale

        $pinDarkOuter = New-Object System.Drawing.SolidBrush($cAsphalt)
        $g.FillEllipse($pinDarkOuter, $pinX - $pinR * 1.38, $pinY - $pinR * 1.38, $pinR * 2.76, $pinR * 2.76)
        $pinDarkOuter.Dispose()

        $pinWhiteRing = New-Object System.Drawing.SolidBrush($cWhite)
        $g.FillEllipse($pinWhiteRing, $pinX - $pinR * 1.08, $pinY - $pinR * 1.08, $pinR * 2.16, $pinR * 2.16)
        $pinWhiteRing.Dispose()

        $pinDarkInner = New-Object System.Drawing.SolidBrush($cAsphalt)
        $g.FillEllipse($pinDarkInner, $pinX - $pinR * 0.80, $pinY - $pinR * 0.80, $pinR * 1.60, $pinR * 1.60)
        $pinDarkInner.Dispose()

        $pinPinkCore = New-Object System.Drawing.SolidBrush($cPink)
        $g.FillEllipse($pinPinkCore, $pinX - $pinR * 0.56, $pinY - $pinR * 0.56, $pinR * 1.12, $pinR * 1.12)
        $pinPinkCore.Dispose()

        # 1. Hard Locate Pink offset block shadow behind the S (+offsetX, +offsetY)
        $pinkPath = $sPath.Clone()
        $offShiftX = $size * 0.020 * $scale
        $offShiftY = $size * 0.018 * $scale
        $offMat = New-Object System.Drawing.Drawing2D.Matrix
        $offMat.Translate($offShiftX, $offShiftY)
        $pinkPath.Transform($offMat)
        $offMat.Dispose()

        # Dark outer outline around pink offset so it pops on any surface
        $pinkOuterPen = New-Object System.Drawing.Pen($cAsphalt, ($size * 0.022 * $scale))
        $pinkOuterPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
        $g.DrawPath($pinkOuterPen, $pinkPath)
        $pinkOuterPen.Dispose()

        $pinkGradRect = New-Object System.Drawing.RectangleF($sBounds.X, $sBounds.Y, ($sBounds.Width + $offShiftX * 2), ($sBounds.Height + $offShiftY * 2))
        $pinkBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($pinkGradRect, $cPinkTop, $cPink, 90.0)
        $g.FillPath($pinkBrush, $pinkPath)
        $pinkBrush.Dispose()
        $pinkPath.Dispose()

        # 2. Razor-sharp dark asphalt knockout stroke around the main S
        $knockoutPen = New-Object System.Drawing.Pen($cAsphalt, ($size * 0.024 * $scale))
        $knockoutPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
        $g.DrawPath($knockoutPen, $sPath)
        $knockoutPen.Dispose()

        # 3. Main Sheet White "S" fill (slightly thickened with a white inner-join stroke for extra 900-Black punch)
        $whiteThickPen = New-Object System.Drawing.Pen($cWhite, ($size * 0.005 * $scale))
        $whiteThickPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
        $g.DrawPath($whiteThickPen, $sPath)
        $whiteThickPen.Dispose()

        $whiteBrush = New-Object System.Drawing.SolidBrush($cWhite)
        $g.FillPath($whiteBrush, $sPath)
        $whiteBrush.Dispose()

        # 4. Signature 5-Paint Strip bar directly underneath the S
        $stripW = $size * 0.34 * $scale
        $stripH = $size * 0.030 * $scale
        $stripX = $cx - ($stripW * 0.5) + ($offShiftX * 0.3)
        $stripY = $sBounds.Bottom + ($size * 0.048 * $scale)
        $stripRadius = $stripH * 0.5

        $stripPath = New-RoundedRectPath $stripX $stripY $stripW $stripH $stripRadius

        # Dark outer outline on the paint strip
        $stripOutlinePen = New-Object System.Drawing.Pen($cAsphalt, ($size * 0.014 * $scale))
        $g.DrawPath($stripOutlinePen, $stripPath)
        $stripOutlinePen.Dispose()

        $stripState = $g.Save()
        $g.SetClip($stripPath)
        $bandW = $stripW / 5.0
        for ($i = 0; $i -lt 5; $i++) {
            $bBrush = New-Object System.Drawing.SolidBrush($paints[$i])
            $g.FillRectangle($bBrush, ($stripX + $i * $bandW - 0.5), ($stripY - 1), ($bandW + 1.0), ($stripH + 2))
            $bBrush.Dispose()
        }
        $g.Restore($stripState)

        # Crisp white 2px-style rim around the paint strip
        $stripRimPen = New-Object System.Drawing.Pen((New-Color "#FFFFFF" 235), ($size * 0.005 * $scale))
        $g.DrawPath($stripRimPen, $stripPath)
        $stripRimPen.Dispose()
        $stripPath.Dispose()
    } else {
        # Monochrome version for Android 13+ themed icons: pure white S + underline bar
        $whiteBrush = New-Object System.Drawing.SolidBrush($cWhite)
        $g.FillPath($whiteBrush, $sPath)
        $whiteBrush.Dispose()

        $stripW = $size * 0.30 * $scale
        $stripH = $size * 0.028 * $scale
        $stripX = $cx - ($stripW * 0.5)
        $stripY = $sBounds.Bottom + ($size * 0.045 * $scale)
        $stripPath = New-RoundedRectPath $stripX $stripY $stripW $stripH ($stripH * 0.5)
        $barBrush = New-Object System.Drawing.SolidBrush($cWhite)
        $g.FillPath($barBrush, $stripPath)
        $barBrush.Dispose()
        $stripPath.Dispose()
    }

    if ($showWordmark -and (-not $monochrome)) {
        $wordPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $wordEm = $size * 0.082 * $scale
        $wordY = $sBounds.Bottom + ($size * 0.148 * $scale)
        $wordPath.AddString(
            "SPOTCHECK",
            $fontFamily,
            $fontStyle,
            $wordEm,
            (New-Object System.Drawing.PointF($cx, $wordY)),
            $sf
        )
        $wBounds = $wordPath.GetBounds()
        $wCx = $wBounds.X + ($wBounds.Width * 0.5)
        $wCy = $wBounds.Y + ($wBounds.Height * 0.5)
        $wMat = New-Object System.Drawing.Drawing2D.Matrix
        $wMat.Translate(($cx - $wCx), ($wordY - $wCy))
        $wordPath.Transform($wMat)
        $wMat.Dispose()

        $wOutlinePen = New-Object System.Drawing.Pen($cAsphalt, ($size * 0.012 * $scale))
        $wOutlinePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
        $g.DrawPath($wOutlinePen, $wordPath)
        $wOutlinePen.Dispose()

        $wBrush = New-Object System.Drawing.SolidBrush($cWhite)
        $g.FillPath($wBrush, $wordPath)
        $wBrush.Dispose()
        $wordPath.Dispose()
    }

    $sPath.Dispose()
    $sf.Dispose()
}

function Save-SupersampledPng([int]$finalSize, [string]$outPath, [scriptblock]$drawBlock) {
    $superSize = $finalSize * 2
    $bmpSuper = New-Object System.Drawing.Bitmap($superSize, $superSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gSuper = [System.Drawing.Graphics]::FromImage($bmpSuper)
    Set-HighQuality $gSuper
    & $drawBlock $gSuper $superSize
    $gSuper.Dispose()

    $bmpFinal = New-Object System.Drawing.Bitmap($finalSize, $finalSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gFinal = [System.Drawing.Graphics]::FromImage($bmpFinal)
    Set-HighQuality $gFinal
    $gFinal.DrawImage($bmpSuper, 0, 0, $finalSize, $finalSize)
    $gFinal.Dispose()
    $bmpSuper.Dispose()

    $bmpFinal.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpFinal.Dispose()
    Write-Output "Saved $outPath ($finalSize x $finalSize)"
}

# 1. icon.png (1024x1024 full app icon: deep black background + large S logo)
Save-SupersampledPng 1024 (Join-Path $assetsDir "icon.png") {
    param($g, $sz)
    Draw-AsphaltBackground $g $sz $true
    Draw-ForegroundMark $g $sz 1.34 ($sz * 0.01) $false $false
}

# 2. android-icon-background.png (1024x1024 deep black background with subtle locate radar ring)
Save-SupersampledPng 1024 (Join-Path $assetsDir "android-icon-background.png") {
    param($g, $sz)
    Draw-AsphaltBackground $g $sz $true
}

# 3. android-icon-foreground.png (1024x1024 transparent background, safe-zone centered S logo)
Save-SupersampledPng 1024 (Join-Path $assetsDir "android-icon-foreground.png") {
    param($g, $sz)
    $g.Clear([System.Drawing.Color]::Transparent)
    Draw-ForegroundMark $g $sz 1.06 ($sz * 0.01) $false $false
}

# 4. android-icon-monochrome.png (1024x1024 transparent background, monochrome S logo)
Save-SupersampledPng 1024 (Join-Path $assetsDir "android-icon-monochrome.png") {
    param($g, $sz)
    $g.Clear([System.Drawing.Color]::Transparent)
    Draw-ForegroundMark $g $sz 1.06 ($sz * 0.01) $true $false
}

# 5. splash-icon.png (1024x1024 transparent background, S logo + SPOTCHECK wordmark)
Save-SupersampledPng 1024 (Join-Path $assetsDir "splash-icon.png") {
    param($g, $sz)
    $g.Clear([System.Drawing.Color]::Transparent)
    Draw-ForegroundMark $g $sz 1.08 (-$sz * 0.05) $false $true
}

# 6. favicon.png (192x192)
Save-SupersampledPng 192 (Join-Path $assetsDir "favicon.png") {
    param($g, $sz)
    Draw-AsphaltBackground $g $sz $false
    Draw-ForegroundMark $g $sz 1.50 ($sz * 0.015) $false $false
}

$pfc.Dispose()
Write-Output "All brand PNG assets generated."
