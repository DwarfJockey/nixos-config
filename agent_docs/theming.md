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
- **Opacity:** reads `config.stylix.opacity` and applies `.desktop` to the Noctalia bar
  (`bar.main.background_opacity`) and `.popups` to the niri `^noctalia-` panels/popups
  layer-rule.

## niri (target-driven, one override)

niri is themed by niri-flake's own `stylix.targets.niri` (border active = base0D /
inactive = base03, plus the niri cursor). `desktop.nix` overrides only the border width
(`layout.border.width = 1`, thinner than niri's default 4) and otherwise leaves `border`
colors / `focus-ring` target-driven.

## Shadows (split by surface type)

- **niri owns shadows for windows and the bar**, where the surface hugs its visible
  content. niri's three presets (`baseShadow`/`activeShadow`/`popupShadow` in `desktop.nix`)
  approximate Material-3 elevation Levels 1/3/5 — a single drop shadow each, since niri
  can't layer umbra/penumbra/ambient — applied to tiled/active/floating windows and the
  `^noctalia-bar` layer-rule.
- **Noctalia draws its own shadows for its popups/panels** (`shell.shadow.alpha = 0.55`,
  `shell.panel.shadow = true`; color from the palette's `mShadow` = base00): niri can't clip
  a layer-surface shadow to a *floating popup's* visible card (it shadows the whole surface
  including invisible margins), so the `^noctalia-` popup layer-rule carries no niri shadow —
  only opacity and corner-radius.
- The bar's own Noctalia shadows stay off (`bar.main.shadow`/`contact_shadow` = false), as
  does `dock.shadow`.

## Targets that keep their own theming

- **nixvim** — Stylix only targets vanilla `programs.neovim`; nixvim uses its default
  colorscheme.
- **Claude Code** — `theme = "dark"`.
