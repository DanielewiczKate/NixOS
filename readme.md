# NixOS

Flake-based NixOS config that mirrors the Arch Linux desktop
(ASRock X570 Phantom Gaming 4, Ryzen, RTX 2070 SUPER, Hyprland).

```
flake.nix                               # nixosConfigurations.nixos
hosts/nixos/configuration.nix           # system: boot, nvidia, services, desktop, users
hosts/nixos/hardware-configuration.nix
modules/packages.nix                    # environment.systemPackages
UNAVAILABLE.md                          # Arch packages that could not be carried over
```

## Install

1. Partition as on Arch: ESP on `/boot`, btrfs with subvolumes `@`, `@home`, `@nix`, `@log`.
2. `nixos-generate-config --root /mnt --show-hardware-config > hosts/nixos/hardware-configuration.nix`
   (the committed file is hand-written from the Arch disk UUIDs; UUIDs change if you reformat).
3. `nixos-install --flake .#nixos`, then `passwd kate`.
4. Later updates: `sudo nixos-rebuild switch --flake .#nixos`.

## Remote access

SSH and mosh are only reachable over Tailscale. After the first boot, log in at the machine:

```sh
sudo tailscale up   # open the printed URL on any device and sign in
```

With MagicDNS on (admin console → DNS), the machine is reachable as `nixos`.
One mosh connection into a zellij session gives you many tabs, and they keep running after you disconnect.

Add this alias to `~/.bashrc` or `~/.zshrc` on each device you connect **from**:

```sh
alias nx='mosh kate@nixos -- zellij attach -c main'
```

Then reload the shell (`source ~/.bashrc`, or open a new terminal) and run `nx`.
For fish, run `alias --save nx 'mosh kate@nixos -- zellij attach -c main'` instead.

## How Arch pieces map

| Arch                                          | NixOS                                              |
|-----------------------------------------------|----------------------------------------------------|
| `linux`, `linux-firmware`, `amd-ucode`        | `linuxPackages_latest`, `enableRedistributableFirmware` |
| systemd-boot, mkinitcpio `MODULES=(nvidia…)`  | `boot.loader.systemd-boot`, `boot.initrd.kernelModules` |
| `nvidia-open-dkms`, `nvidia-utils`, `libva-nvidia-driver` | `hardware.nvidia.open`, `nvidia-vaapi-driver` |
| `zram-generator`                              | `zramSwap`                                         |
| `/etc/keyd/default.conf`                      | `services.keyd.keyboards.default`                  |
| `ex-vi-compat`                                | `programs.neovim.viAlias/vimAlias`                 |
| `code` (Code - OSS)                           | `vscodium` (settings dir becomes `~/.config/VSCodium`) |
| `libreoffice-fresh`                           | `libreoffice` (nixpkgs dropped the fresh/still split) |
| `ufw`                                         | `networking.firewall`, see `UNAVAILABLE.md`        |

Behaviour changes from Arch:
- `docker` and `tailscaled` were running but not enabled on Arch; they start at boot here.
- `pipewire-pulse` is enabled (it was not installed on Arch).
- Dotfiles (`~/.config/hypr`, `nvim`, `kitty`, …) are not managed here; copy them over as-is.
