# Hand-written from the current Arch layout (lsblk / fstab / lspci).
# After partitioning, REPLACE this file with the output of
#   nixos-generate-config --root /mnt --show-hardware-config
# and keep the btrfs mount options below if you like them.
{ config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];

  # Btrfs on /dev/sda2 with subvolumes. On Arch the layout is @, @home, @log, @pkg
  # (@pkg held the pacman cache). On NixOS, use an @nix subvolume for /nix instead.
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/eb27dcee-5575-429a-9b17-25e9eaf03588";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd:3" "space_cache=v2" "relatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/eb27dcee-5575-429a-9b17-25e9eaf03588";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd:3" "space_cache=v2" "relatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/eb27dcee-5575-429a-9b17-25e9eaf03588";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd:3" "space_cache=v2" "noatime" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/eb27dcee-5575-429a-9b17-25e9eaf03588";
    fsType = "btrfs";
    options = [ "subvol=@log" "compress=zstd:3" "space_cache=v2" "relatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4A46-7E1B";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Swap is zram only (see configuration.nix); no swap partition.
  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
