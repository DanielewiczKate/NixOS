{
  description = "NixOS configuration mirroring the Arch Linux desktop (ASRock X570 / RTX 2070 SUPER)";

  inputs = {
    # Unstable to stay close to Arch's rolling release (kernel 7.x, Hyprland 0.56, etc.)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/nixos/configuration.nix
      ];
    };
  };
}
