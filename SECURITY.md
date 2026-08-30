# Security Policy

## Supported Version

Security fixes are currently targeted at the latest published release.

| Version | Supported |
| --- | --- |
| 0.4.x | Yes |
| < 0.4 | No |

## Reporting a Security Issue

Please do **not** publish credentials, proprietary design files, or confidential project data in a public issue.

If the repository owner has enabled GitHub Private Vulnerability Reporting, use that feature for security-sensitive reports. Otherwise, open a minimal public issue requesting a private contact channel without including exploit details or confidential data.

## Scope

Examples of relevant issues include:

- unexpected modification or deletion of schematic objects
- unsafe file handling
- execution of unintended script content
- injection through unvalidated external input
- behavior that could silently alter electrical connectivity

Phoenix is an engineering automation tool. Users should test new versions on a copy of a design and review all generated schematic content before production use.
