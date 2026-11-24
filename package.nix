{
  pkgs,
  lib ? pkgs.lib,
  version ? "1.0.65",
  kitSrc ? null,
  sha256 ? "sha256-sFGnf3Kz5cQKnwA1E1TJjdlxRcQfmfYXKfkKAD03qGM=",
  kitDir ? "$HOME/.neoforge/",
  ...
}:
let
  kitSource =
    if kitSrc != null then
      kitSrc
    else
      pkgs.fetchurl {
        url = "https://github.com/AdrianLopez98/NeoForge/releases/download/v${version}/NeoForge-linux-x64.tar.gz";
        inherit sha256;
      };

  kitFiles = pkgs.runCommand "neoforge-kit-${version}" { } ''
    mkdir -p "$out/share/neoforge"
    if [ -d "${kitSource}" ]; then
      if [ -d "${kitSource}/NeoForge" ]; then
        cp -a "${kitSource}/NeoForge/." "$out/share/neoforge/"
      else
        cp -a "${kitSource}/." "$out/share/neoforge/"
      fi
    else
      tar -xzf "${kitSource}" -C "$out/share/neoforge" --strip-components=1
    fi
    chmod -R u+w "$out/share/neoforge"
    rm -rf "$out/share/neoforge/datos" "$out/share/neoforge/forge.profile.properties"

    printf "%s\n" "${version}" > "$out/share/neoforge/VERSION.txt"

    if [ -f "$out/share/neoforge/bin/NeoForge" ]; then
      chmod +x "$out/share/neoforge/bin/NeoForge"
    fi
  '';

  xorgLocale = pkgs.runCommand "xorg-locale" { } ''
    mkdir -p $out/share/X11
    ln -s ${pkgs.libx11}/share/X11/locale $out/share/X11/locale
  '';

  fhs = pkgs.buildFHSEnv {
    name = "neoforge-fhs";
    includeClosures = true;
    privateTmp = false;

    targetPkgs =
      pkgs: with pkgs; [
        bash
        coreutils
        findutils
        gawk
        gnugrep
        gnused
        gnutar
        gzip
        unzip
        zip
        which
        procps
        pciutils
        usbutils
        xdg-utils
        zenity
        nettools
        iproute2
        curl
        fontconfig
        noto-fonts
        xorgLocale

        glibc
        stdenv.cc.cc.lib
        zlib
        openssl

        libGL
        libdrm
        libgbm
        udev
        libudev0-shim
        libva
        libvdpau
        vulkan-loader

        alsa-lib
        libpulseaudio
        libusb1
        SDL2

        glib
        gtk3
        pango
        cairo
        atk
        gdk-pixbuf
        freetype

        libx11
        libxcursor
        libxrandr
        libxi
        libxtst
        libxcb
        libxkbcommon
        libxxf86vm
        libxext
        libxfixes
        libxrender
        libxcomposite
        libxdamage
        libxinerama
        libxscrnsaver
        wayland
      ];

    extraBuildCommands = ''
      cp -f $out/usr/{bin,sbin}/ldconfig
    '';

    extraBwrapArgs = [
      "--ro-bind-try /etc/zoneinfo /usr/share/zoneinfo"
    ];

    profile = ''
      export LIBGL_DRIVERS_PATH=${pkgs.mesa}/lib/dri
      export LIBVA_DRIVERS_PATH=${pkgs.mesa}/lib/dri
      export __EGL_VENDOR_LIBRARY_DIRS=${pkgs.mesa}/share/glvnd/egl_vendor.d
      export VDPAU_DRIVER_PATH=/run/opengl-driver/lib/vdpau
      export PATH="/usr/sbin:$PATH"
    '';

    runScript = pkgs.writeShellScript "neoforge-run" ''
      set -e

      KIT_SRC="${kitFiles}/share/neoforge"
      DEFAULT_KIT_DIR="${kitDir}"

      if [ -n "''${NEOFORGE_HOME:-}" ]; then
        KIT_DIR="$NEOFORGE_HOME"
      elif [ -x "./bin/NeoForge" ] && [ -d "./res" ] && [ -d "./lib/app" ]; then
        KIT_DIR="$PWD"
      else
        KIT_DIR="$DEFAULT_KIT_DIR"
      fi

      mkdir -p "$KIT_DIR/datos"

      if [ "$KIT_DIR" != "$PWD" ] || [ ! -x "$KIT_DIR/bin/NeoForge" ]; then
        SRC_VER="$(cat "$KIT_SRC/VERSION.txt" 2>/dev/null || echo "${version}")"
        CUR_VER="$(cat "$KIT_DIR/VERSION.txt" 2>/dev/null || echo "")"
        if [ ! -x "$KIT_DIR/bin/NeoForge" ] || [ "$SRC_VER" != "$CUR_VER" ]; then
          for item in bin lib res AVISOS.txt LICENSE-GPL3.txt README.txt add-to-menu.sh neoforge.png VERSION.txt; do
            if [ -e "$KIT_SRC/$item" ]; then
              rm -rf "$KIT_DIR/$item"
              cp -a "$KIT_SRC/$item" "$KIT_DIR/$item"
            fi
          done
          chmod -R u+w "$KIT_DIR/bin" "$KIT_DIR/lib" "$KIT_DIR/res" 2>/dev/null || true
          chmod +x "$KIT_DIR/bin/NeoForge"
        fi
      fi

      if [ $# -gt 0 ]; then
        case "$1" in
          *.frp|*.FRP)
            if [ -f "$1" ]; then
              FRP_ABS="$(realpath "$1")"
              shift
              cd "$KIT_DIR"
              exec ./bin/NeoForge "$FRP_ABS" "$@"
            fi
            ;;
          ui|deckcheck|audiocheck|adventure|-*)
            cd "$KIT_DIR"
            exec ./bin/NeoForge "$@"
            ;;
          *)
            if [ -f "$1" ] && [ ! -x "$1" ]; then
              ARG_ABS="$(realpath "$1")"
              shift
              cd "$KIT_DIR"
              exec ./bin/NeoForge "$ARG_ABS" "$@"
            fi
            exec "$@"
            ;;
        esac
      fi

      cd "$KIT_DIR"
      exec ./bin/NeoForge
    '';
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "neoforge";
    desktopName = "Neo Forge";
    comment = "Magic: The Gathering Commander against AI";
    exec = "neoforge %f";
    icon = "neoforge";
    terminal = false;
    categories = [
      "Game"
      "CardGame"
    ];
    mimeTypes = [
      "application/x-neoforge-replay"
    ];
    startupWMClass = "NeoForge";
  };

  mimeTypePkg = pkgs.writeTextDir "share/mime/packages/neoforge-replay.xml" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-neoforge-replay">
        <comment>Neo Forge replay</comment>
        <glob pattern="*.frp" weight="80"/>
      </mime-type>
    </mime-info>
  '';
in
pkgs.symlinkJoin {
  name = "neoforge-${version}";
  pname = "neoforge";
  inherit version;

  paths = [
    desktopItem
    mimeTypePkg
  ];

  postBuild = ''
    mkdir -p "$out/bin" "$out/share/icons/hicolor/256x256/apps" "$out/share/pixmaps"
    ln -s "${fhs}/bin/neoforge-fhs" "$out/bin/neoforge"
    ln -s "${fhs}/bin/neoforge-fhs" "$out/bin/neo-forge"
    ln -s "${fhs}/bin/neoforge-fhs" "$out/bin/NeoForge"
    if [ -f "${kitFiles}/share/neoforge/neoforge.png" ]; then
      ln -s "${kitFiles}/share/neoforge/neoforge.png" "$out/share/icons/hicolor/256x256/apps/neoforge.png"
      ln -s "${kitFiles}/share/neoforge/neoforge.png" "$out/share/pixmaps/neoforge.png"
    fi
  '';

  passthru = {
    inherit fhs kitFiles;
    env = fhs.env;
  };

  meta = with lib; {
    description = "Play Magic: The Gathering against AI (Commander, Standard, Brawl, Draft, Sealed, Quest, Ascent)";
    homepage = "https://github.com/AdrianLopez98/NeoForge";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "neoforge";
  };
}
