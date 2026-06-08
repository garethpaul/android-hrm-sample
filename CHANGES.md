# Changes

## 2026-06-08

- Added a repository changelog and expanded the documented Android verification
  gate to include lint, Gradle check, and debug assembly.
- Cleaned Android lint findings by making backup behavior explicit, fixing
  device-row inflation, moving visible UI text into string resources, and using
  `sp` for text sizes.
- Removed unused template strings and dimensions, moved the single 9-patch tile
  asset to `drawable-nodpi`, and documented the narrow legacy lint baseline.
