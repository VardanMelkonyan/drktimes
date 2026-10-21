# Develop mode: visual design

The visual design for Develop mode (Part 1). It was made in Claude Design from
the brief in
`docs/superpowers/specs/2026-10-21-film-development-timer-design-prompt.md`.
Behaviour is defined in `specs/001-film-develop-timer/spec.md`, and the spec
wins where the two differ.

- **Live canvas:** https://claude.ai/code/artifact/afe4c863-4061-4736-ba70-8d8aaa66cb3e
- **Snapshot:** 2026-10-21, canvas version `1792605410-6237`

## Files

- `canvas.json`: the canvas index. It holds every artboard's title and
  layout, grouped into rows.
- `drk.css`: the shared visual system. It contains the colour tokens for the
  light, dark and safelight-red themes, the type scale, the controls, the
  session-state chips and the tank glyphs. This is the source for the app's
  theme.
- `Main.dc.html`: the visual-system sheet (type, spacing, tokens, state
  vocabulary, tank identity, components).
- One `*.dc.html` per screen or state (390×844 phone frames; scrolling screens
  are taller).

These are Claude Design canvas pages. They load a canvas runtime
(`support.js`) that isn't in this repo, so view them through the live canvas
link. Read the HTML/CSS here for exact values.

## Key choices in the design

- One typeface: **JetBrains Mono**, with tabular numerals.
- **Dark** is the default theme. There are also **light** and **safelight
  red**; in red, green and blue are always 0.
- Session states are told apart by chip shape, line style and numeral weight
  (800 = act, 700 = running, 300 = rest), never by hue alone.
- Tank identity is carried by a glyph (circle, triangle, square), the tank
  number and a sound pitch. Hue is extra.
- Flat surfaces only: 3 px radius, no blur, no shadows. Touch targets are
  44 / 72 / 112 px, the largest for knuckle presses during a session.

## Not covered in the design (build with the existing visual system)

- A label for times inherited from a rebranded film, including the
  "reported, not confirmed" variant (FR-013).
- The Android-only "volume button as Next" switch in Settings (FR-043).
- Each step's how-to text on the session screen (FR-035).
- How a datasheet time range is shown, with its midpoint default (FR-011).
- Hiding or removing an imported recipe (FR-059).

The Combination artboard shows a datasheet time for Tri-X in Rodinal. That is
sample content only; the dataset has no such row.
