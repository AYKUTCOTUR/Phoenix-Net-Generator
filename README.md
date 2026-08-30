# Phoenix Net Generator

[![Version](https://img.shields.io/badge/version-0.4.4-blue.svg)](https://github.com/AYKUTCOTUR/Phoenix-Net-Generator/releases)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](https://github.com/AYKUTCOTUR/Phoenix-Net-Generator/blob/main/LICENSE)
[![Altium](https://img.shields.io/badge/Altium%20Designer-DelphiScript-orange.svg)](https://github.com/AYKUTCOTUR/Phoenix-Net-Generator)

**Engineer-in-the-loop semantic net generation for Altium Designer.**

Phoenix Net Generator is an experimental Altium Designer automation tool that reads component pins, parses multifunction pin names, lets the engineer choose the intended function, previews a structured net name, and generates an organized bank of schematic Net Labels.

> Phoenix is designed to automate repetitive work without making hidden electrical decisions on behalf of the engineer.

## Highlights

- Analyze a schematic component by designator
- Read visible pins directly from the active `.SchDoc`
- Parse multifunction pin names such as `(PCINT6/XTAL1/TOSC1)_PB6`
- Select the intended pin function through the UI
- Generate semantic names such as `U1_SPI1_MISO`, `U1_UART1_TX`, or `U1_CLK_XTAL1`
- Use the component designator, a custom prefix, or no prefix
- Toggle individual pins between **YES** and **NO**
- Type custom function names when the library metadata is insufficient
- Configure wire space before and after the Net Label
- Generate a clean, equal-length label bank with 15 rows per column

## Current Version

**v0.4.4**

Phoenix is currently a working prototype and is under active development. It is not yet a fully autonomous schematic or PCB design system.

## Workflow

```text
Component Designator
        ↓
Analyze Component
        ↓
Read Visible Pins
        ↓
Parse Multifunction Pin Names
        ↓
Engineer Selects Intended Function
        ↓
Generate Semantic Net Name
        ↓
Preview
        ↓
Enable / Disable Individual Pins
        ↓
Generate Net Label Bank
```

## Example: ATmega328P-AU

The example below uses an ATmega328P-AU with multifunction pin names directly from the schematic symbol.

<p align="center">
  <img src="docs/images/01-target-component.png" width="780" alt="ATmega328P-AU target component in Altium Designer">
</p>

<p align="center">
  <em>Example target component in Altium Designer before semantic labeling.</em>
</p>

A library pin such as:

```text
(PCINT6/XTAL1/TOSC1)_PB6

is parsed into selectable functions:

```text
PCINT6
XTAL1
TOSC1
PB6
```

The engineer decides which function is actually used. For example:

```text
XTAL1 → U1_CLK_XTAL1
PB6   → U1_PB6
```

Other built-in semantic examples include:

```text
SCK   → SPI1_SCK
MISO  → SPI1_MISO
MOSI  → SPI1_MOSI
SDA   → I2C1_SDA
SCL   → I2C1_SCL
TXD   → UART1_TX
RXD   → UART1_RX
VCC   → PWR_VCC
AVCC  → PWR_AVCC
AREF  → ADC_AREF
```

## Net Label Bank

The default output-bank geometry is:

| Setting | Default |
| --- | ---: |
| Rows per column | 15 |
| Vertical row pitch | 200 mil |
| Wire margin before label | 200 mil |
| Wire margin after label | 200 mil |
| Column gap | 600 mil |

All generated wires use the same length:

```text
Common Wire Length
=
Widest Generated Net Label
+
Before Margin
+
After Margin
```

The `Before` and `After` margins are user-configurable in mil.

## Screenshots

Project screenshots are stored in `docs/images/`.

<!--
Uncomment these links after final v0.4.4 screenshots are added:

![Phoenix UI](docs/images/phoenix-ui-v0.4.4.png)

![Generated Net Label bank](docs/images/generated-label-bank-v0.4.4.png)
-->

## Installation

See **[docs/installation.md](docs/installation.md)** for the full installation procedure.

Quick start:

1. Download or clone the repository.
2. Open `PhoenixNetGenerator.PrjScr` in Altium Designer.
3. Open the target schematic document (`.SchDoc`).
4. Run the `PhoenixNetGenerator` procedure.

If your Altium version does not automatically associate the Script Form resource, follow the manual form setup described in `docs/installation.md`.

## Usage

See **[docs/usage.md](docs/usage.md)**.

Typical flow:

```text
U1
→ Analyze
→ Review pins
→ Select functions
→ Toggle unused pins to NO
→ Configure prefix
→ Configure wire margins
→ Generate Net Labels
```

## Design Philosophy

Phoenix intentionally separates **device capability** from **design intent**.

A multifunction pin tells us what the silicon *can* do. It does not tell us what the engineer *intends* to do in a specific project.

Phoenix therefore follows an engineer-in-the-loop model:

```text
Software discovers possibilities
        ↓
Software organizes them
        ↓
Engineer defines intent
        ↓
Software generates the result
```

Phoenix also intentionally avoids automatically wiring generated labels to arbitrary component symbols. Symbol geometry varies widely between libraries, and automatic connectivity changes should not be based on uncertain geometric assumptions.

## Supported Semantic Rules

The current prototype includes rules for common functions and selected device families, including:

- GPIO-style MCU pins
- SPI
- I²C
- UART
- clock / crystal signals
- common power pins
- selected RS-232 transceivers
- selected CAN transceivers
- selected RS-485 transceivers

See **[docs/naming-rules.md](docs/naming-rules.md)** for details and limitations.

## Repository Structure

```text
Phoenix-Net-Generator/
├── .github/
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   └── pull_request_template.md
├── docs/
│   ├── images/
│   ├── architecture.md
│   ├── compatibility.md
│   ├── installation.md
│   ├── maintainer-guide.md
│   ├── naming-rules.md
│   ├── roadmap.md
│   ├── testing.md
│   └── usage.md
├── examples/
│   └── README.md
├── src/
│   └── Altium/
│       ├── PhoenixNetGenerator.pas
│       ├── PhoenixNetGeneratorForm.pas
│       └── PhoenixNetGeneratorForm.dfm
├── PhoenixNetGenerator.PrjScr
├── CHANGELOG.md
├── CITATION.cff
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── NOTICE
├── README.md
├── RELEASE_NOTES_v0.4.4.md
├── SECURITY.md
├── THIRD_PARTY_NOTICES.md
└── VERSION
```

## Roadmap

Near-term areas of development include:

- broader component-family recognition
- user-defined naming profiles
- improved pin classification
- persistent configuration
- project-level context
- datasheet-assisted interpretation
- automated validation and conflict detection

Long-term research direction:

- design-intent extraction
- PCB constraint generation
- placement assistance
- routing intelligence
- AI-assisted EDA workflows

See **[docs/roadmap.md](docs/roadmap.md)**.

## Current Limitations

- Pin parsing depends on the quality and structure of schematic-library pin names.
- Semantic rules do not yet cover every IC family or naming convention.
- Interface numbering such as `SPI1` or `UART1` may need user customization in some designs.
- Generated labels are not automatically connected to component pins.
- Compatibility across every Altium Designer release has not yet been validated.
- Generated results must be reviewed by the engineer before use in production designs.

## Contributing

Contributions, bug reports, test cases, and naming-rule proposals are welcome.

Please read **[CONTRIBUTING.md](CONTRIBUTING.md)** before submitting changes.

Useful contributions include:

- pin-name examples from different component libraries
- parser edge cases
- additional transceiver families
- reproducible Altium scripting issues
- UI improvements
- documentation improvements

## Security and Safety

Phoenix modifies schematic documents by creating Altium schematic primitives. Test new releases on a copy of your project and review generated labels before relying on them.

Please see **[SECURITY.md](SECURITY.md)** for vulnerability reporting.


## Author

**Aykut Çotur**  
Senior Hardware / PCB Design Engineer  
GitHub: [@AYKUTCOTUR](https://github.com/AYKUTCOTUR)

Phoenix Net Generator was created and is maintained by Aykut Çotur.

## License

Licensed under the **Apache License 2.0**. See [LICENSE](LICENSE).

## Trademark Notice

Altium and Altium Designer are trademarks or registered trademarks of their respective owner. Phoenix Net Generator is an independent open-source project and is not affiliated with, endorsed by, or sponsored by Altium.

---

**Phoenix Net Generator**  
*Analyze → Parse → Select → Preview → Generate*
