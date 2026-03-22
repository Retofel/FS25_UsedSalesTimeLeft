---
name: package-mod
description: Package the mod into a zip file in release_history/temp/
disable-model-invocation: true
---

Create a zip archive of the mod by following these steps:

1. Remove `release_history/temp/FS25_UsedSalesTimeLeft.zip` if it already exists
2. Zip **only** the contents of the `FS25_UsedSalesTimeLeft/` subfolder (relative to the project root). The files (`modDesc.xml`, `scripts/`, `icon_UsedSalesTimeLeft.dds`) must be at the **root** of the zip — not nested inside a subfolder. Do NOT include project root files like README.md, LICENSE, examples/, etc.
3. Save the zip to `release_history/temp/FS25_UsedSalesTimeLeft.zip` (relative to project root)
4. Report the resulting file size and list the zip contents

Use PowerShell via bash (this is a Windows environment):
```bash
powershell -Command "Remove-Item -Path 'release_history/temp/FS25_UsedSalesTimeLeft.zip' -ErrorAction SilentlyContinue; Compress-Archive -Path 'FS25_UsedSalesTimeLeft/*' -DestinationPath 'release_history/temp/FS25_UsedSalesTimeLeft.zip' -Force"
```

Then verify by listing the zip contents and file size:
```bash
powershell -Command "Get-Item 'release_history/temp/FS25_UsedSalesTimeLeft.zip' | Select-Object Name, @{N='Size (KB)';E={[math]::Round(\$_.Length/1KB,1)}}; Write-Host ''; Write-Host 'Contents:'; Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path 'release_history/temp/FS25_UsedSalesTimeLeft.zip')).Entries | ForEach-Object { \$_.FullName }"
```
