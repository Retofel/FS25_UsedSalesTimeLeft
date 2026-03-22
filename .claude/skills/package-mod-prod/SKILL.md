---
name: package-mod-prod
description: Ensure debug is off, then package the mod into a zip file for production release
---

Package the mod for production release by following these steps:

## Step 1: Disable debug logging

1. Read `FS25_UsedSalesTimeLeft/scripts/UsedSalesTimeLeft.lua`
2. Check if `IS_DEBUG` is set to `true`. If so, change it to `false` and confirm the change was made. If it's already `false`, report that no change was needed.

## Step 2: Package the mod

Invoke the `/package-mod` skill using the Skill tool to handle the packaging.
