# Architecture

Phoenix Net Generator is intentionally divided into conceptual layers.

```text
┌─────────────────────────────────┐
│      Altium Schematic API       │
│ Component / Pin / NetLabel      │
│ Wire / SchDoc access            │
└───────────────┬─────────────────┘
                ↓
┌─────────────────────────────────┐
│        Pin Name Parser          │
│ Normalize symbol strings        │
│ Extract alternate functions     │
└───────────────┬─────────────────┘
                ↓
┌─────────────────────────────────┐
│     Semantic Naming Engine      │
│ SPI / UART / I2C / POWER        │
│ CAN / RS485 / clock / etc.      │
└───────────────┬─────────────────┘
                ↓
┌─────────────────────────────────┐
│    Engineer-in-the-Loop UI      │
│ Function selection              │
│ YES / NO generation             │
│ Prefix configuration            │
│ Net-name preview                │
│ Wire-margin configuration       │
└───────────────┬─────────────────┘
                ↓
┌─────────────────────────────────┐
│       Label Bank Generator      │
│ 15 rows / column                │
│ 200 mil pitch                   │
│ Equal line length               │
│ Text-aware geometry             │
└─────────────────────────────────┘
```

## Key Principle: Capability vs. Intent

A library pin name describes possible silicon functions.

It does not necessarily describe the function selected in the current design.

Phoenix therefore parses available choices but leaves the final selection to the engineer.

## Why Automatic Wiring Is Limited

Automatic label-to-pin wiring across arbitrary symbols requires reliable knowledge of:

- symbol geometry
- pin orientation
- surrounding objects
- library conventions
- intended schematic layout
- user drawing preferences

Phoenix avoids silently changing connectivity based on uncertain geometry. Instead, it generates a predictable label bank that the engineer can review and place.

## Future Architecture

Potential future layers include:

```text
Semantic Net Information
        ↓
Design-Intent Model
        ↓
Constraint Generation
        ↓
Placement Assistance
        ↓
Routing Assistance
```

These are roadmap directions, not current v0.4.4 capabilities.
