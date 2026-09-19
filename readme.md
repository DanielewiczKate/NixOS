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

Target: the 500 GB NVMe (`nvme0n1`, WDC WDS500G2B0C). **This erases Windows on it.**
Arch stays untouched on the 1 TB hard disk (`sda`) until you retire it (see the last section).

Every block below is meant to be copied and pasted as-is. Run them in order.

### 0. Before you start (on Arch / Windows)

- Copy anything you want to keep off Windows. The whole NVMe gets wiped.
- Make sure this repo is pushed to GitHub. The installer clones it from there.
- Flash the **minimal** ISO for nixos-unstable to a USB stick (already done if `lsblk` shows `nixos-minimal`):

  ```sh
  curl -LO https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso
  lsblk -o NAME,SIZE,MODEL        # find the USB stick, e.g. sdc. NOT sda/sdb (hard disks)
  sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sdX bs=4M status=progress oflag=sync
  ```

- **Shut down and unplug the SATA cables of both hard disks** (`sda` Arch, `sdb` "New Volume").
  Then the installer can only see the NVMe, so there is nothing else to erase by mistake.
  Plug them back in after the install.
- In the BIOS (**F2** or **Del** at power-on), **disable Secure Boot** (the NixOS ISO isn't signed for it).

### 1. Boot the installer

Plug in the USB stick, press **F11** at power-on and pick the USB stick (the `UEFI:` entry).
It logs you in as `nixos`. Become root:

```sh
sudo -i
```

### 2. Get online

Ethernet connects on its own. For Wi-Fi, run `nmtui` → "Activate a connection".
If `nmtui` is not found, use this instead (replace the name and password):

```sh
systemctl start wpa_supplicant
wpa_cli <<'EOF'
add_network 0
set_network 0 ssid "YOUR-WIFI-NAME"
set_network 0 psk "YOUR-WIFI-PASSWORD"
enable_network 0
EOF
```

Check that it works:

```sh
ping -c 3 nixos.org
```

### 3. Pick the disk

```sh
lsblk -o NAME,SIZE,MODEL
```

You should see `nvme0n1  465.8G  WDC WDS500G2B0C-00PXH0` (plus the USB stick).
If the hard disks show up, stop and unplug them. Then:

```sh
DISK=/dev/nvme0n1
lsblk -dno MODEL,SIZE $DISK    # must print WDC WDS500G2B0C-00PXH0  465.8G
```

`DISK` only lives in this shell. If you close it or reboot, run `DISK=/dev/nvme0n1` again.

### 4. Partition and format (erases the NVMe)

1 GiB boot partition (ESP) + the rest as btrfs:

```sh
wipefs -a $DISK
parted -s $DISK -- mklabel gpt
parted -s $DISK -- mkpart ESP fat32 1MiB 1GiB
parted -s $DISK -- set 1 esp on
parted -s $DISK -- mkpart nixos btrfs 1GiB 100%
udevadm settle

mkfs.fat -F32 -n BOOT ${DISK}p1
mkfs.btrfs -f -L nixos ${DISK}p2
```

Create the btrfs subvolumes (same layout as Arch, with `@nix` instead of `@pkg`):

```sh
mount ${DISK}p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
umount /mnt
```

### 5. Mount everything under /mnt

```sh
mount -o subvol=@,compress=zstd:3 ${DISK}p2 /mnt
mkdir -p /mnt/boot /mnt/home /mnt/nix /mnt/var/log
mount -o subvol=@home,compress=zstd:3 ${DISK}p2 /mnt/home
mount -o subvol=@nix,compress=zstd:3,noatime ${DISK}p2 /mnt/nix
mount -o subvol=@log,compress=zstd:3 ${DISK}p2 /mnt/var/log
mount -o fmask=0077,dmask=0077 ${DISK}p1 /mnt/boot
```

Check (you should see `/mnt`, `/mnt/boot`, `/mnt/home`, `/mnt/nix`, `/mnt/var/log`):

```sh
findmnt -R /mnt
```

If you reboot the installer before finishing, you don't need to repeat step 4.
Run `sudo -i`, `DISK=/dev/nvme0n1`, then this step again.

### 6. Get the config and generate the hardware file

```sh
nix-shell -p git
```

That opens a shell with `git`. Inside it:

```sh
mkdir -p /mnt/home/kate/src/repos
git clone https://github.com/DanielewiczKate/NixOS.git /mnt/home/kate/src/repos/NixOS
cd /mnt/home/kate/src/repos/NixOS
nixos-generate-config --root /mnt --show-hardware-config > hosts/nixos/hardware-configuration.nix
```

The generated file uses the new disk's UUIDs and the subvolumes you mounted.
Compression and `noatime` are set in `configuration.nix`, so you don't need to edit it. Check it:

```sh
cat hosts/nixos/hardware-configuration.nix
```

You should see `fileSystems` entries for `/`, `/boot`, `/home`, `/nix` and `/var/log`, all
on the NVMe, and nothing mentioning `sda`.

### 7. Install

This downloads and builds everything (takes a while):

```sh
nixos-install --flake /mnt/home/kate/src/repos/NixOS#nixos
```

At the end it asks for a **root** password. Set one (useful for recovery).
Then set **your** password and give the repo to your user:

```sh
nixos-enter --root /mnt -c 'passwd kate'
nixos-enter --root /mnt -c 'chown -R kate:users /home/kate'
```

If `nixos-install` fails partway, fix the problem and run it again. It picks up where it left off.

### 8. Reboot

```sh
exit          # leave the nix-shell
cd /
umount -R /mnt
reboot
```

Pull the USB stick out when the screen goes black. It boots straight into NixOS.
Shut down and plug the hard disks back in whenever you like.

## After the first boot

Log in as `kate` on the TTY (Caps Lock is already Escape).

### Network

Ethernet connects on its own. For Wi-Fi:

```sh
nmtui
```

### Tailscale

```sh
sudo tailscale up
```

Open the printed URL on any device and sign in. In the admin console, delete the old `archlinux`
machine when you no longer need it, and consider "Disable key expiry" on `nixos` (the "…" menu).

### Copy your files from Arch

With the Arch hard disk plugged in (it's `sda2`; check with `lsblk -f`), mount it **read-only**:

```sh
sudo mkdir -p /mnt/arch
sudo mount -o ro,subvol=@home /dev/sda2 /mnt/arch
ls /mnt/arch/kate
```

Copy what you need, for example:

```sh
mkdir -p ~/.config
cp -a /mnt/arch/kate/.config/{hypr,nvim,kitty,foot,waybar,yazi} ~/.config/
cp -a /mnt/arch/kate/.ssh ~/
cp -a /mnt/arch/kate/.gitconfig ~/
sudo chown -R kate:users ~
```

`cp` prints an error for any folder in the list that doesn't exist. That's harmless.
When done:

```sh
sudo umount /mnt/arch
```

Don't add the Arch disk to the config as a `fileSystems` entry. NixOS would then wait for
it at every boot and hang once you format it.

### Commit the new hardware file

```sh
cd ~/src/repos/NixOS
gh auth login
git add hosts/nixos/hardware-configuration.nix
git commit -m "hardware-configuration for the NVMe install"
git push
```

### Updating later

```sh
cd ~/src/repos/NixOS
nix flake update                                   # optional: newer packages
nixos-rebuild switch --sudo --flake .#nixos        # asks for your password
```

## Booting Arch while both are installed

NixOS is the default. To boot Arch, press **F11** at power-on and pick the entry on the
hard disk (ST1000LM024). Both may be called "Linux Boot Manager". The menu shows the disk.

## Retiring the Arch disk

Once NixOS has everything you need:

1. Check that NixOS doesn't use the hard disk. This should print nothing:

   ```sh
   grep -n sda ~/src/repos/NixOS/hosts/nixos/hardware-configuration.nix
   ```

   And every UUID in that file should appear under `nvme0n1` in `lsblk -f`.
2. Make sure everything is copied: `~` (dotfiles, `~/.ssh`, projects). Also copy
   `/var/lib/tailscale/tailscaled.state` if you want to keep the old Tailscale machine.
3. Test: shut down, unplug the Arch disk, boot NixOS a couple of times. If all is well, plug it back in.
4. Format it (check the name first, it should be the 931.5G ST1000LM024):

   ```sh
   lsblk -o NAME,SIZE,MODEL
   sudo wipefs -a /dev/sda
   sudo mkfs.btrfs -f -L data /dev/sda
   ```

5. Remove Arch's old boot entry (the one whose path points at the hard disk):

   ```sh
   efibootmgr -v
   sudo efibootmgr -b XXXX -B     # XXXX = the Boot number of the Arch entry
   ```

## Remote access

SSH and mosh are only reachable over Tailscale (log in with `sudo tailscale up`, see above).

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
