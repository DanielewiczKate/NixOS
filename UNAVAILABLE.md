# Packages not carried over from Arch

Source: `pacman -Qe` on the Arch install (84 explicit packages), checked against
`nixos-unstable` on 2026-09-19.

## Not available in nixpkgs

| Arch package | Why                                          | Replacement in this config                                    |
|--------------|----------------------------------------------|---------------------------------------------------------------|
| `ufw`        | Not packaged for NixOS                       | `networking.firewall` (ufw was installed but inactive on Arch) |
| `yay-debug`  | Arch-only debug-symbol split package         | None needed                                                   |

## In nixpkgs but not applicable to NixOS

| Arch package  | Why                                                       |
|---------------|-----------------------------------------------------------|
| `yay`         | AUR helper; it needs pacman and the AUR, neither of which NixOS has |
| `mkinitcpio`  | NixOS builds its own initrd (`boot.initrd.*`)             |
| `linux-headers` | Out-of-tree modules are built against `boot.kernelPackages` |

## Excluded on purpose (handled separately)

- `ib-tws` (Interactive Brokers TWS)
- Xilinx Vivado
