# Contributing to Phoenix Net Generator

Thank you for considering a contribution.

Phoenix is an engineer-in-the-loop EDA automation project. Changes should prioritize predictable behavior, reviewability, and preservation of electrical design intent.

## Ways to Contribute

Useful contributions include:

- parser fixes for real library pin names
- support for additional IC families
- semantic naming-rule improvements
- reproducible Altium scripting bug reports
- UI improvements
- documentation
- example pin datasets
- compatibility testing

## Before Opening a Pull Request

1. Open or reference an issue for substantial behavioral changes.
2. Keep pull requests focused on one problem.
3. Avoid unrelated formatting changes.
4. Do not introduce automatic electrical decisions without a clear review mechanism.
5. Preserve backward-compatible output when practical.
6. Update documentation and `CHANGELOG.md` when behavior changes.

## Coding Guidelines

The Altium implementation is DelphiScript.

Please:

- prefer clear, explicit control flow
- keep parser logic separate from schematic-object generation
- avoid unnecessary dependencies
- validate user-entered numeric data
- avoid silently changing existing schematic connectivity
- keep new naming rules deterministic and explainable
- document assumptions for device-family-specific rules

## Testing

At minimum, test:

- component discovery by designator
- visible-pin extraction
- multifunction pin parsing
- function selection
- custom function entry
- prefix enabled / disabled
- custom prefix
- YES / NO pin generation
- Before / After wire margins
- equal-length bank generation
- repeated generation / conflict behavior

When reporting a parser issue, include the exact original library pin name, for example:

```text
(PCINT6/XTAL1/TOSC1)_PB6
```

and the expected selectable options.

## Pull Request Checklist

- [ ] The change has a clear purpose.
- [ ] Existing behavior was not unintentionally changed.
- [ ] New user-visible behavior is documented.
- [ ] The relevant changelog entry is included when appropriate.
- [ ] No private project data, proprietary library content, credentials, or confidential design information is included.
- [ ] Generated net names were reviewed for electrical ambiguity.

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
