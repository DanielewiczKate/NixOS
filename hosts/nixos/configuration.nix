{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/packages.nix
  ];

  # ---------------------------------------------------------------- Nix
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.config.allowUnfree = true; # nvidia, obsidian

  # ---------------------------------------------------------------- Boot
  # Arch: systemd-boot, `linux` (mainline 7.x) kernel, mkinitcpio with early nvidia KMS
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "zswap.enabled=0" "nvidia_drm.fbdev=1" ];
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  # btrfs mount options, merged with the generated `subvol=` options in hardware-configuration.nix
  fileSystems."/".options = [ "compress=zstd:3" ];
  fileSystems."/home".options = [ "compress=zstd:3" ];
  fileSystems."/nix".options = [ "compress=zstd:3" "noatime" ];
  fileSystems."/var/log".options = [ "compress=zstd:3" ];

  # zram-generator: zram0 with zstd, no disk swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # ---------------------------------------------------------------- Hardware
  hardware.enableRedistributableFirmware = true; # linux-firmware, amd-ucode

  # nvidia-open-dkms + nvidia-utils + egl-wayland + libva-nvidia-driver (RTX 2070 SUPER, Turing)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.nvidia-vaapi-driver ];
  };
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = false;
    # Arch tracks the newest driver; swap to `.stable` if `.latest` misbehaves.
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # bluez + bluez-utils
  hardware.bluetooth.enable = true;

  # ---------------------------------------------------------------- Networking
  networking.hostName = "nixos"; # also the Tailscale machine name (ssh kate@nixos via MagicDNS)
  networking.networkmanager.enable = true; # NetworkManager (+ wpa_supplicant backend)

  # ufw is not packaged for NixOS; it was installed but inactive on Arch.
  # The native NixOS firewall replaces it. KDE Connect opens its own ports;
  # SSH and mosh are only reachable over Tailscale.
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  services.tailscale.enable = true;

  # ---------------------------------------------------------------- Locale / time
  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    keyMap = "us";
    font = "default8x16";
  };

  # ---------------------------------------------------------------- Users
  users.users.kate = {
    isNormalUser = true;
    description = "Kate Danielewicz";
    extraGroups = [ "wheel" "docker" "networkmanager" "video" "input" ];
    shell = pkgs.bashInteractive;
  };
  security.sudo.enable = true;

  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # ---------------------------------------------------------------- Services
  services.openssh = {
    enable = true; # sshd (defaults match Arch: keys + password via PAM)
    openFirewall = false; # reachable only via tailscale0 (trusted)
  };
  services.timesyncd.enable = true;
  services.power-profiles-daemon.enable = true;

  # keyd: /etc/keyd/default.conf
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        rightcontrol = "rightshift";
        capslock = "escape";
        escape = "capslock";
        rightalt = "enter";
      };
    };
  };

  # docker + docker-compose (was started manually on Arch; enabled here)
  virtualisation.docker.enable = true;

  # PipeWire + WirePlumber + pipewire-jack
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    jack.enable = true;
    pulse.enable = true; # not installed on Arch, but most apps expect it on NixOS
    wireplumber.enable = true;
  };

  # ---------------------------------------------------------------- Desktop
  # Hyprland is launched from the TTY (no display manager on Arch either).
  programs.hyprland.enable = true; # includes xdg-desktop-portal-hyprland
  programs.hyprlock.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  security.polkit.enable = true;

  programs.firefox.enable = true;
  programs.kdeconnect.enable = true; # opens 1714-1764 tcp/udp
  programs.mosh = {
    enable = true;
    openFirewall = false; # 60000-61000/udp reachable only via tailscale0
  };
  programs.dconf.enable = true;

  # neovim + ex-vi-compat (vi/vim -> nvim)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    dejavu_fonts
    liberation_ttf
    ubuntu-classic
    nerd-fonts.hack # ttf-hack-nerd (used by waybar)
    nerd-fonts.symbols-only # waybar style.css falls back to "Symbols Nerd Font"
  ];

  system.stateVersion = "26.05";
}
