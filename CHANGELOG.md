# Changelog

All notable changes to Phoenix Net Generator are documented in this file.

The project uses semantic-style versioning while the public API and workflow are still evolving.

## [0.4.4] - 2026-08-30

### Repository / Documentation
- Added a ready-to-open `PhoenixNetGenerator.PrjScr`.
- Added `.github/CODEOWNERS` for project ownership.
- Moved repository-maintenance guidance to `docs/maintainer-guide.md`.
- Simplified the public README installation workflow.
- Added repository metadata to `CITATION.cff`.
- Strengthened source-code authorship headers.

### Added
- Clickable **YES / NO** generation control in the `Use` column.
- User-configurable `Before` wire margin in mil.
- User-configurable `After` wire margin in mil.
- Validation for non-negative integer wire-margin values.

### Changed
- Common wire length is now calculated as:
  `widest generated label + Before + After`.
- Public source comments were cleaned for open-source release.

### Preserved
- 15 entries per column.
- 200 mil vertical pitch.
- 600 mil column gap.
- Equal wire lengths for all generated entries.
- Prefix enable/disable and custom-prefix behavior.
- Engineer-controlled multifunction-pin selection.

## [0.4.3] - 2026-08-30

### Fixed
- Removed direct invocation of a Script Form event handler from the Generate button path to improve DelphiScript compatibility.

## [0.4.2] - 2026-08-30

### Changed
- Migrated the interactive UI to an Altium Delphi Script Form (`.pas` + `.dfm`) architecture.
- Added a small launcher script for the `PhoenixNetGenerator` entry procedure.

## [0.4.1] - 2026-08-30

### Changed
- Introduced Script Form based UI structure.

## [0.4.0] - 2026-08-30

### Added
- Interactive component analysis.
- Multifunction pin parsing.
- Function selection.
- Prefix configuration.
- Net-name preview.

## [0.3.0]

### Added
- Organized lower-left Net Label bank.
- 15 entries per column.
- Equal-length horizontal wires.
- Net Label width measurement.
- 200 mil default label offset.
