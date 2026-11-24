{
  description = "Neo Forge installable package, overlay, and modules for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    neoforge = {
      url = "https://github.com/AdrianLopez98/NeoForge/releases/download/v1.0.65/NeoForge-linux-x64.tar.gz";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      neoforge,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      mkPackage =
        pkgs:
        pkgs.callPackage ./package.nix {
          kitSrc = neoforge;
        };
      defaultPkg = mkPackage pkgs;

      overlay = final: prev: {
        neoforge = final.callPackage ./package.nix {
          kitSrc = neoforge;
        };
        neo-forge = final.neoforge;
      };

      mkModule =
        { isHomeManager }:
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.neoforge;
          pkg = pkgs.callPackage ./package.nix {
            kitSrc = neoforge;
            kitDir = cfg.dataDir;
          };
        in
        {
          options.programs.neoforge = {
            enable = lib.mkEnableOption "Neo Forge Magic: The Gathering launcher and FHS runtime";
            package = lib.mkOption {
              type = lib.types.package;
              default = pkg;
              description = "The neoforge package to install.";
            };
            dataDir = lib.mkOption {
              type = lib.types.str;
              default = "$HOME/.neoforge/";
              description = "Writable directory where Neo Forge stores its game files, decks, preferences, saved games, and downloaded card images (datos/).";
            };
          };

          config = lib.mkIf cfg.enable (
            if isHomeManager then
              {
                home.packages = [ cfg.package ];
              }
            else
              {
                environment.systemPackages = [ cfg.package ];
              }
          );
        };
    in
    {
      packages.${system} = {
        default = defaultPkg;
        neoforge = defaultPkg;
        neo-forge = defaultPkg;
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${defaultPkg}/bin/neoforge";
        };
        neoforge = {
          type = "app";
          program = "${defaultPkg}/bin/neoforge";
        };
        neo-forge = {
          type = "app";
          program = "${defaultPkg}/bin/neo-forge";
        };
      };

      devShells.${system}.default = defaultPkg.env;

      overlays = {
        default = overlay;
        neoforge = overlay;
        neo-forge = overlay;
      };

      nixosModules = {
        default = mkModule { isHomeManager = false; };
        neoforge = mkModule { isHomeManager = false; };
        neo-forge = mkModule { isHomeManager = false; };
      };

      homeModules = {
        default = mkModule { isHomeManager = true; };
        neoforge = mkModule { isHomeManager = true; };
        neo-forge = mkModule { isHomeManager = true; };
      };
    };
}
