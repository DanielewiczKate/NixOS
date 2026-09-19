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
    inetutils
    strace
    efibootmgr
    btrfs-progs
    evtest

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

    # Desktop (Hyprland session)
    hypridle
    hyprlauncher
    waybar
    kitty
    foot
    brightnessctl
    playerctl # used by hyprland.lua media keys
    grim # screenshots
    slurp # region select for grim
    libnotify
    kdePackages.polkit-kde-agent-1
    kdePackages.dolphin
    egl-wayland

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
  ];
}
