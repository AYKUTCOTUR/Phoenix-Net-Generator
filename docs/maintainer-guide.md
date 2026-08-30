# Maintainer Guide

This document is intended for the project maintainer and is not required for normal Phoenix installation.

## Repository

- Repository: `https://github.com/AYKUTCOTUR/Phoenix-Net-Generator`
- Maintainer: **Aykut Çotur** (`@AYKUTCOTUR`)
- Current release line: `v0.4.x`

## Recommended GitHub Topics

```text
altium-designer
pcb-design
eda
electronics
hardware
delphiscript
schematic
design-automation
embedded-systems
open-source-hardware-tools
```

## Release Procedure

1. Run the checklist in `docs/testing.md`.
2. Confirm the working tree contains no private design files or credentials.
3. Update `VERSION`.
4. Update `CHANGELOG.md`.
5. Update release notes.
6. Confirm `PhoenixNetGenerator.PrjScr` references the current source files.
7. Add sanitized screenshots under `docs/images/`.
8. Commit the release candidate.
9. Create a tag such as `v0.4.4`.
10. Publish the GitHub Release.

## Screenshot Privacy Checklist

Before publishing screenshots, verify that they do not show:

- customer or employer project names
- confidential schematic content
- email addresses
- local file-system paths
- license identifiers
- serial numbers
- API keys, passwords, or tokens
- private repository names

## Branch Protection

When external contributions begin, consider enabling:

- pull request required before merge
- conversation resolution required
- no force pushes to `main`
- no deletion of `main`

## Public / Private Workflow

It is reasonable to keep the repository private while preparing a release candidate. Before changing visibility to Public, complete the testing and privacy checks above.
