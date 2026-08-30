# Installation

Phoenix Net Generator runs as an Altium Designer DelphiScript project.

## Recommended Installation

1. Download or clone the repository.
2. Open:

   ```text
   PhoenixNetGenerator.PrjScr
   ```

   in Altium Designer.

3. Confirm the Script Project contains:

   ```text
   src/Altium/PhoenixNetGenerator.pas
   src/Altium/PhoenixNetGeneratorForm.pas
   src/Altium/PhoenixNetGeneratorForm.dfm
   ```

4. Open the schematic document (`.SchDoc`) you want to work with.
5. Use **File → Run Script**.
6. Run:

   ```text
   PhoenixNetGenerator
   ```

## Manual Script Form Setup

If your Altium Designer version does not correctly associate the supplied Script Form:

1. Create or open a Script Project (`.PrjScr`).
2. Add `src/Altium/PhoenixNetGenerator.pas`.
3. Add a new **Delphi Script Form**.
4. Save it as:

   ```text
   PhoenixNetGeneratorForm.pas
   ```

5. Ensure the matching form resource is named:

   ```text
   PhoenixNetGeneratorForm.dfm
   ```

6. Replace the generated form source and DFM content with the repository files.
7. Save the Script Project and reopen it if Altium retains stale script state.

## First Validation

Use a known component such as `U1`.

1. Enter the designator.
2. Click **Analyze**.
3. Confirm that the part name and visible-pin count are detected.
4. Select a multifunction pin.
5. Verify that the function selector lists the expected alternatives.
6. Toggle one `Use` entry from `YES` to `NO`.
7. Set `Before` and `After` margins.
8. Generate the Net Label bank.
9. Confirm that disabled pins are skipped.

## Safe Testing

Phoenix creates schematic primitives in the active schematic document. Test new releases on a copy of your project or under version control, and review generated Net Labels before production use.

## Repository

Project home: https://github.com/AYKUTCOTUR/Phoenix-Net-Generator
