# Compatibility entry point. Custom robot branding is no longer active.
param([string]$FlutterSdkPath = $env:FLUTTER_ROOT)
& (Join-Path $PSScriptRoot 'restore_flutter_icon.ps1') -FlutterSdkPath $FlutterSdkPath
