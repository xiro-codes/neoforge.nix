# Neo Forge (Nix Flake)

Nix flake providing a self-contained package, desktop entry, `.frp` replay MIME association, FHS runtime (JavaFX/GTK3, OpenGL/Mesa, ALSA/PulseAudio, libGDX/LWJGL3 for Adventure mode), overlay, and NixOS / Home Manager modules for [Neo Forge](https://github.com/AdrianLopez98/NeoForge).

On first launch, Neo Forge files are seeded into your writable directory (`~/.neoforge/` by default, or `$NEOFORGE_HOME`), keeping your decks, settings, saved games, and downloaded card images intact in `datos/` across updates.

---

## Quick Run

Run directly without installing:

```bash
nix run /path/to/neoforge
```

Pass arguments (e.g. open a `.frp` replay file or run self-checks):

```bash
nix run /path/to/neoforge -- /path/to/replay.frp
nix run /path/to/neoforge -- deckcheck
nix run /path/to/neoforge -- audiocheck
```

---

## Setup Guide

### 1. Add the Flake Input

In your system or Home Manager `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    neoforge = {
      url = "git+file:///home/tod/Desktop/neoforge"; # or github:<you>/neoforge-nix
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### 2A. NixOS Configuration

Import `neoforge.nixosModules.default` in your NixOS configuration:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.neoforge.nixosModules.default
  ];

  programs.neoforge = {
    enable = true;
    # Optional: override where the game kit and datos/ folder live
    # dataDir = "$HOME/.neoforge/";
  };
}
```

### 2B. Home Manager Configuration

Import `neoforge.homeModules.default` in your Home Manager configuration:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.neoforge.homeModules.default
  ];

  programs.neoforge = {
    enable = true;
    # dataDir = "$HOME/.neoforge/";
  };
}
```

### 2C. Overlay / Direct Package

If you prefer adding the package directly to `environment.systemPackages` or `home.packages`:

```nix
# Via flake packages:
environment.systemPackages = [
  inputs.neoforge.packages.${pkgs.system}.default
];

# Or via overlay:
nixpkgs.overlays = [ inputs.neoforge.overlays.default ];
environment.systemPackages = [ pkgs.neoforge ];
```

---

## Updating Upstream Release

To update to a newer Neo Forge release, bump the release URL/version in `flake.nix` and `package.nix` and run:

```bash
nix flake lock --update-input neoforge
```
