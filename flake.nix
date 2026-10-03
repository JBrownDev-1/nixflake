{
  description = "NixOS Flake Configuration";

  inputs = {
    # You can change this to "github:nixos/nixpkgs/nixos-24.05" for stable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      # Replace "myhost" with your actual hostname
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Change if using aarch64-linux (e.g., Raspberry Pi)
        modules = [
          # Import your existing configuration files
          ./hardware-configuration.nix
          ./configuration.nix
        ];
      };
    };
  };
}
