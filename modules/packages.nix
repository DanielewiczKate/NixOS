# User-facing packages from `pacman -Qe` on Arch.
# Packages that are provided by a NixOS module (hyprland, firefox, neovim, docker,
# fonts, drivers, ...) live in configuration.nix instead.
# See ../UNAVAILABLE.md for what could not be carried over.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base / base-devel
    gcc
    gnumake
    binutils
    pkg-config
    autoconf
    automake
    libtool
    patch
    file
    which
    less
    unzip
    zip
    inetutils
    strace
    efibootmgr
    btrfs-progs
    evtest
    valgrind
    man-pages # manpages-dev: syscalls (section 2)
    man-pages-posix # manpages-dev: POSIX library calls (section 3p)

    # CLI
    bat
    btop
    htop
    ripgrep
    zellij
    tree
    yazi
    git
    gh
    cmake
    tree-sitter
    nodejs # npm
    (python3.withPackages (ps: [ ps.pygobject3 ps.setuptools ]))
    libpq # postgresql-libs
    docker-compose
    ncurses5 # ncurses5-compat-libs
    claude-code

    # Desktop (Hyprland session)
    hypridle
    hyprlauncher
    waybar
    kitty
    foot
    xterm
    brightnessctl
    playerctl # used by hyprland.lua media keys
    grim # screenshots
    slurp # region select for grim
    wl-clipboard # wl-copy, used by hypr/scripts/snip to put screenshots on the clipboard
    libnotify
    kdePackages.polkit-kde-agent-1
    kdePackages.dolphin
    egl-wayland
    adwaita-icon-theme # standard arrow cursor (XCURSOR_THEME=Adwaita in hyprland.lua)

    # Apps
    vscodium # Arch `code` is the open-source "Code - OSS" build
    dbeaver-bin
    obsidian
    libreoffice
    freecad
    zim

    # HDL / EDA
    iverilog
    verilator
    gtkwave

    # SDR (RTL-SDR Blog V3; rtl-sdr-blog itself comes from hardware.rtl-sdr.enable)
    # gnuradio needs gr-osmosdr to see the dongle -- plain gnuradio has no RTL source block.
    (gnuradio.override { extraPackages = [ gnuradioPackages.osmosdr ]; })
    gqrx          # GNU Radio based waterfall receiver
    sdrpp         # SDR++, lighter-weight alternative to gqrx
    rtl_433       # 433/868/915 MHz ISM sensors (weather stations, TPMS, doorbells)
    multimon-ng   # POCSAG/FLEX pager + AFSK/APRS decoding, fed from rtl_fm
    dump1090-fa   # 1090 MHz ADS-B aircraft, with a web map on localhost:8080 when run with --net
    inspectrum    # offline analysis of IQ captures from rtl_sdr
    sdrangel      # all-in-one: tune + demod + live Morse/RTTY/FT8/etc decode, no audio routing needed
    gpredict      # satellite pass prediction/tracking (az/el vs time, live TLE updates)

    # LSP servers for nvim (Mason installs them on non-NixOS machines)
    pyright
    clang-tools # clangd
    ltex-ls
    markdown-oxide
    verible # verible-verilog-ls
  ];
}
