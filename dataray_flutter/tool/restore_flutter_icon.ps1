param([string]$FlutterSdkPath = $env:FLUTTER_ROOT)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($FlutterSdkPath)) {
    $flutterCommand = Get-Command flutter -ErrorAction Stop
    $FlutterSdkPath = Split-Path -Parent (Split-Path -Parent $flutterCommand.Source)
}
$templatePath = Join-Path $FlutterSdkPath 'packages/flutter_tools/templates/app'
$androidTemplate = Join-Path $templatePath 'android.tmpl/app/src/main/res'
$iosTemplate = Join-Path $templatePath 'ios.tmpl/Runner/Assets.xcassets'
if (-not (Test-Path -LiteralPath (Join-Path $androidTemplate 'mipmap-mdpi/ic_launcher.png'))) {
    throw 'No se encontraron los iconos originales en el SDK Flutter indicado.'
}
foreach ($density in @('mdpi','hdpi','xhdpi','xxhdpi','xxxhdpi')) {
    Copy-Item -LiteralPath (Join-Path $androidTemplate "mipmap-$density/ic_launcher.png") `
        -Destination (Join-Path $projectPath "android/app/src/main/res/mipmap-$density/ic_launcher.png") -Force
}
# A custom adaptive icon takes precedence over the stock density PNG files.
$adaptiveIcon = Join-Path $projectPath 'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml'
if (Test-Path -LiteralPath $adaptiveIcon) { Remove-Item -LiteralPath $adaptiveIcon -Force }
$iconTarget = Join-Path $projectPath 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
foreach ($source in Get-ChildItem -LiteralPath (Join-Path $iosTemplate 'AppIcon.appiconset') -File) {
    $targetName = $source.Name.Replace('.img.tmpl','')
    Copy-Item -LiteralPath $source.FullName -Destination (Join-Path $iconTarget $targetName) -Force
}
$launchTarget = Join-Path $projectPath 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
foreach ($source in Get-ChildItem -LiteralPath (Join-Path $iosTemplate 'LaunchImage.imageset') -File) {
    if ($source.Name.EndsWith('.img.tmpl')) {
        Copy-Item -LiteralPath $source.FullName -Destination (Join-Path $launchTarget $source.Name.Replace('.img.tmpl','')) -Force
    } elseif ($source.Name -eq 'Contents.json') {
        Copy-Item -LiteralPath $source.FullName -Destination $launchTarget -Force
    }
}
Write-Output 'Iconos predeterminados de Flutter restaurados para Android e iOS.'

