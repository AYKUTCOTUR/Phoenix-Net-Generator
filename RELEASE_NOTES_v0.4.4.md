# Phoenix Net Generator v0.4.4

## Highlights

This release improves engineer control over generated schematic labels.

### Interactive pin generation

The `Use` column can now be toggled directly:

```text
YES ↔ NO
```

Pins marked `NO` are excluded from Net Label generation.

### Adjustable wire margins

Two user-configurable values are available:

```text
Before = 200 mil
After  = 200 mil
```

Common wire length is calculated as:

```text
Widest Generated Net Label + Before + After
```

All generated wires remain equal in length.

## Existing v0.4 Features

- component analysis by designator
- visible-pin extraction
- multifunction pin parsing
- engineer-controlled function selection
- semantic naming
- configurable prefix
- live preview
- custom function entry
- organized 15-row label-bank layout

## Upgrade

Replace the three Altium source files with the v0.4.4 files under `src/Altium/`.

Review `docs/installation.md` before upgrading from early dynamic-form prototypes.

## Safety

Use version control or a copy of your schematic when testing. Review generated Net Labels before relying on them in a production design.

## Easier Installation

The repository now includes a ready-to-open:

```text
PhoenixNetGenerator.PrjScr
```

Open the Script Project in Altium Designer, open the target schematic, and run `PhoenixNetGenerator`.
