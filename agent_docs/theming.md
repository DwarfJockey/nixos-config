# Theming

How this repo drives its system-wide look. Referenced from `CLAUDE.md`. To turn off a
misbehaving target: `stylix.targets.<name>.enable = false`.

## Stylix (the source of truth)

Stylix (NixOS module, configured in `modules/nixos/theming.nix`) owns system-wide theming
from a single base16 scheme — an inline "Framework Anodized" palette (`base16Scheme` set
as an attrset of `base00`..`base0F`), `polarity = "dark"` — driving colors, fonts, cursor
(phinger-dark), icons (Papirus-Dark), and window opacity
(`stylix.opacity.desktop`/`popups`).

With `autoEnable` on, Stylix themes every installed native target (GTK, Qt, console/TTY,
Ghostty, nushell, starship, Zen, …). Home Manager is a NixOS module, so its Stylix targets
auto-inherit the system scheme (`desktop.nix` just sets `gtk.enable`/`qt.enable` and leaves
Ghostty's theme/font to Stylix).

A few things have no Stylix target and are bridged manually, below.

## Noctalia (manual bridge)

Stylix ships a `noctalia` target (`stylix.targets.noctalia`) that also writes
`programs.noctalia`, but it points the wallpaper at the raw `stylix.image` (this repo wants
the recolored+dimmed `themedWallpaper`) and doesn't bridge the bar opacity. So `desktop.nix`
disables it (`stylix.targets.noctalia.enable = false`) and instead:

- **Palette:** builds a `customPalettes.Stylix` palette from `config.lib.stylix.colors`,
  selected with `theme = { source = "custom"; custom_palette = "Stylix"; mode = "dark"; }`.
- **Opacity:** reads `config.stylix.opacity` and applies `.desktop` to both Noctalia bars
  (`bar.main`/`bar.bottom`'s `background_opacity`). `.popups` has no consumer — Umbriel
  layer rules carry blur but no opacity key, so Noctalia's own `shell.panel.transparency_mode
  = "glass"` is what makes panels translucent.

## Umbriel (manual bridge, every colour)

Umbriel has no Stylix target at all (niri got one from niri-flake), so
`modules/home-manager/desktop/umbriel.nix` maps base16 by hand. The slot choices follow
Noctalia's own `assets/templates/umbriel/umbriel.toml`:

- `[colors]` — the compositor's *own* surfaces (keybind cheatsheet, config-error banner):
  `background` = base00+`F0`, `text_primary` = base05, `text_muted` = base04,
  `accent_primary` = base0D, `accent_secondary` = base0E, `warning` = base0A,
  `error` = base08.
- `[appearance]` — `border_focused` = base0D / `border_unfocused` = base03 (reproducing what
  `stylix.targets.niri` used to set), `outer_border_color`/`backdrop_color` = base00,
  `insert_hint_color` = base0C+`80`, scratchpad borders base0C/base02. Geometry is a manual
  override too: `border_width = 1` (Umbriel's default is 2) and `corner_radius = 15`.
- `[overview]` — `background_tint` = base00+`30`, `workspace_background` = base00+`44`.
- `[input.cursor]` — `theme`/`size` from `config.stylix.cursor`.

Blur is native (`appearance.blur.enabled` plus a `^noctalia-…` `[[layer_rule]]`), replacing
the raw-KDL `background-effect` block niri needed.

## Shadows (split by surface type)

- **Umbriel owns window shadows — one, globally.** `[appearance.shadow]` (softness 8,
  offset 0/3, `#0000004D`) is roughly the old niri `activeShadow`, i.e. Material-3 elevation
  L3. niri had three presets for tiled/active/floating; Umbriel draws a single shadow for
  every window, so the L1/L5 variants are gone.
- **Noctalia draws its own shadows for every surface it owns** — bars, dock, popups, panels
  (`shell.shadow.alpha = 0.55`, `shell.panel.shadow = true`, `bar.*.shadow = true`,
  `dock.shadow = true`; color from the palette's `mShadow` = base00). Umbriel's shadow does
  not apply to layer surfaces, so this is the only shadow those surfaces get.
- `bar.main.contact_shadow` stays false.

## Targets that keep their own theming

- **nixvim** — Stylix only targets vanilla `programs.neovim`; nixvim uses its default
  colorscheme.
- **Claude Code** — `theme = "dark"`.
