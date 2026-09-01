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

- **Palette:** builds a `customPalettes.Stylix` palette from the shared colour roles in
  `modules/colors.nix` — the greeter renders the same ones — renaming each key into
  Noctalia's own spelling (`on_surface_variant` → `mOnSurfaceVariant`), and selects it with
  `theme = { source = "custom"; custom_palette = "Stylix"; mode = "dark"; }`. The palette's
  `terminal` block is a parse gate, not decoration: Noctalia rejects a whole palette mode
  that lacks one and silently falls back to its builtin scheme, so it stays even though
  nothing here reads terminal tokens.
- **Opacity:** reads `config.stylix.opacity` and applies `.desktop` to both Noctalia bars
  (`bar.top`/`bar.bottom`'s `background_opacity`). `.popups` has no consumer — Umbriel
  layer rules carry blur but no opacity key, so Noctalia's own `shell.panel.transparency_mode
  = "glass"` is what makes panels translucent.
- **Bar geometry:** derived from adw-gtk3, not tuned by eye — `thickness = 36` is
  `headerbar.default-decoration { min-height: 36px }` (adw's compact headerbar, picked over
  the standard 46px for vertical budget: two bars cost 72px of a 752px logical screen rather
  than 92px), and `padding = 6` is `headerbar { padding: 0 6px }`. `widget_spacing` is 0
  rather than GtkHeaderBar's 6: the capsule padding is the gap, and the two places that
  still want a wider one get an explicit `spacer` widget. `radius = 15` and
  `border_width = 1.0` already matched `popover.background`'s radius and the headerbar's
  `border-width: 0 0 1px`. Both sides are logical pixels — Noctalia's `thickness` reaches
  `zwlr_layer_surface_v1_set_size` unscaled — so they compare directly despite the 2x panel.
  `capsule_radius = 9` is adw's own button radius (`button { border-radius: 9px }`); the
  capsules carry that geometry with `capsule_opacity = 0.0`, so widgets keep the padding
  without drawing a fill — bar the launcher and session, which override to 1.0 for their
  accent fills.
- **adw-gtk3 composites:** three palette slots are computed rather than mapped to a base16
  slot, so the shell's chrome matches the GTK theme sitting next to it.
  `mOutline = over base05 base00 0.15` (`#363432`) is adw-gtk3's `@borders`,
  `mix(currentColor, @window_bg_color, 0.85)`; base03 (`#5e5952`) read far brighter than
  every GTK window on screen. `mHover = over base05 base01 0.08` (`#33322f`) is its neutral
  hover, `alpha(currentColor, 0.07-0.1)` over the card background — Noctalia's default and
  Stylix's own target both put base0C *teal* there; `mTertiary` is the same neutral lift for
  the same reason. `mOnHover` and `mOnTertiary` follow to base05, since they are the label
  drawn on that fill. `over` and the roles themselves come from `modules/colors.nix`.
  **Why a blend and not an 8-digit colour:** Noctalia's palette JSON parses alpha and then
  masks it off (`token & 0x00FFFFFF`, its `src/theme/fixed_palette.cpp`), so a composite has
  to be precomputed to reach it. Config-side `ColorSpec` keys *do* keep alpha through
  `resolveColorSpec`, so `#RRGGBBAA` works there — but with `mOutline` correct, the bars
  inherit the right hairline from the Outline role and need no per-bar `border` key.
  `modules/nixos/greeter.nix` takes them from the same place.
- **Accent:** `mPrimary` is base09, the Framework orange (`#ff5f1f`), where Stylix's own
  noctalia target maps base0D. The accent *role* moves; the base16 slots don't — base0D
  stays the blue that terminals and syntax highlighting use. GTK apps keep a blue accent on
  purpose: Stylix hardcodes base0D into `accent_color`/`accent_bg_color` in its
  `modules/gtk/gtk.css.mustache`, so a window's own buttons and selected rows stay blue while
  the shell chrome and the focus ring around that window read orange. To change that too,
  `stylix.targets.gtk.extraCss` is appended after the template, so a later `@define-color`
  wins without touching the scheme. `modules/nixos/greeter.nix` and Umbriel's
  `accent_primary` follow the shell to base09.

## Umbriel (manual bridge, every colour)

Umbriel has no Stylix target at all (niri got one from niri-flake), so
`modules/home-manager/desktop/umbriel.nix` maps base16 by hand. The slot choices follow
Noctalia's own `assets/templates/umbriel/umbriel.toml`:

- `[colors]` — the compositor's *own* surfaces (keybind cheatsheet, config-error banner):
  `background` = base00+`F0`, `text_primary` = base05, `text_muted` = base04,
  `accent_primary` = base09, `accent_secondary` = base0E, `warning` = base0A,
  `error` = base08.
- `[appearance]` — the window borders are **composites**, not slots:
  `border_focused = over base0E base00 0.85` (`#a592d0`, the secondary accent pulled 15%
  toward the background — the orange `mPrimary` stays the shell's alone) and `border_unfocused = over base05 base00 0.15` (`#363432` — the same value
  Noctalia's `mOutline` computes and GTK's `@borders` resolves to, so every hairline on
  screen is one colour). They no longer reproduce what `stylix.targets.niri` set. The
  unfocused edge is deliberately faint; the drop shadow is what separates the window from
  the wallpaper, as in adw-gtk3. Precomputed rather than `#RRGGBBAA` — which Umbriel would
  accept — so a border doesn't tint with the wallpaper behind it.
  `outer_border_color`/`backdrop_color` = base00, `insert_hint_color` = base0C+`80`,
  scratchpad borders base0C/base02 (the scratchpad's own signal, deliberately not the
  accent). Geometry is a manual override too: `border_width = 1` (Umbriel's default is 2)
  and `corner_radius = 15`.

  `corner_radius` does not reach Zen — every other client here rounds, Zen alone shows the
  outline over square content. Two separate scene nodes carry a window's rounding and only
  one of them is the client's pixels: `applyBorderRing` (`src/scene/border_rect.cpp:9`)
  draws the outline as a `wlr_scene_rect` sized to the window geometry, so it rounds
  whatever the client does, while `View::applyCornerRadii` (`src/view/view.cpp:888`) rounds
  exactly one buffer — the one whose scene surface *is* the toplevel's own `wl_surface` —
  because "subsurfaces are separate scene buffers". Gecko paints the browser into a
  `MozContainer` `wl_subsurface`, which is skipped. Zen cannot compensate from its own side:
  adw-gtk3 gives `decoration` a `15px 15px 0 0` radius (which is where the 15 came from),
  but Umbriel marks every mapped window tiled on all four edges (`src/view/view.cpp:1456`,
  `:1991`) and Gecko drops CSD rounding while tiled. `widget.gtk.rounded-bottom-corners.enabled`
  was tried and is inert for that reason — the tiled state suppresses the rounding before
  the pref is consulted — so it is deliberately *not* set in `desktop/browser.nix`. The
  discriminating control, if this is ever revisited: run Zen with `MOZ_ENABLE_WAYLAND=0`,
  which arrives through xwayland-satellite as an ordinary single-surface `xdg_toplevel`.
  Upstream has no issue tracker to cite — Umbriel keeps GitHub issues, discussions and the
  wiki disabled and takes reports on Discord (`discord.noctalia.dev`, README:205).
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
  (`shell.shadow.alpha = 0.35`, `shell.panel.shadow = true`, `bar.*.shadow = true`,
  `dock.shadow = true`; color from the palette's `mShadow` = base00). Umbriel's shadow does
  not apply to layer surfaces, so this is the only shadow those surfaces get.
- `bar.top.contact_shadow` stays false.

## Claude Code (manual bridge)

`home/default.nix` writes `~/.claude/themes/base16.json` as a `home.file`, and the
`home.activation.claudeSettings` hook merges `theme = "custom:base16"` into
`~/.claude/settings.json` (a real file, not a store symlink, so `/model` and `/effort` can
still write it).

The theme is generated with `base = "dark-ansi"`, which resolves every colour it is *not*
given through the terminal's own ANSI palette — already base16, because Stylix themes
Ghostty. So the overrides are only the slots those 16 colours cannot reach: `claude` and
`fastMode` = base09, `claudeShimmer` = base0A, `promptBorder` = base03, and the six diff
colours. The diff *backgrounds* have no base16 slot at all — `dark-ansi` would draw them as
full-brightness `ansi:green`/`ansi:red` behind base05 text — so they are blends over base00
at 22% (row), 12% (dimmed) and 45% (word), through the same `over` the other bridges use.

## Polkit agent (Stylix side effect)

`modules/nixos/theming.nix` runs a `systemd.user.services.polkit-agent`
(`pkgs.mate.mate-polkit`) rather than the more common `polkit-kde-agent`. That's not a
Noctalia-vs-KDE aesthetic call — it's forced by Stylix. `stylix.targets.qt` exports
`QT_STYLE_OVERRIDE=kvantum` into the session; Kvantum is a *widget* style with no QML module,
and a Qt/QML polkit agent (niri-flake's old `niri-flake-polkit.service`, running
`polkit-kde-agent`) fed that variable to its QML engine as a Quick Controls style and
segfaulted before drawing a dialog — every privilege prompt failed silently. mate-polkit is
GTK, so it never reads `QT_STYLE_OVERRIDE` and the failure mode can't recur. Any future swap
of the agent package must stay GTK-based, or explicitly `UnsetEnvironment = [
"QT_STYLE_OVERRIDE" ]` in its unit the way niri-flake did.

## Targets that keep their own theming

- **nixvim** — Stylix only targets vanilla `programs.neovim`; nixvim uses its default
  colorscheme.
