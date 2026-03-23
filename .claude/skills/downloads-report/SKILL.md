---
name: downloads-report
description: Fetch GitHub releases and display download counts per release asset
---

Fetch the GitHub releases for this mod and produce a downloads report.

## Steps

1. Use `WebFetch` to fetch `https://api.github.com/repos/retofel/fs25_usedsalestimeleft/releases`
2. Parse the JSON response. The root is an array of release objects.
3. For each release in the array, extract:
   - The release title from the `name` field
   - The `assets` array — for each asset, extract:
     - The asset filename from the `name` field
     - The download count from the `download_count` field
4. Output a formatted report. For each release, check the number of assets:
   - **If the release has exactly 1 asset:** show only the download count, without the asset name
   - **If the release has more than 1 asset:** list each asset by name with its download count

Format:

```
## Downloads Report

### <release name>
<download_count> downloads

### <release name with multiple assets>
- <asset name>: <download_count> downloads
- <asset name>: <download_count> downloads

**Total downloads: <sum of all download_count values across all assets>**
```

5. Calculate and display the grand total of all `download_count` values across every asset in every release.
