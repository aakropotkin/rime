# ============================================================================ #
#
# Nix CLI wrapper generator.
#
# ---------------------------------------------------------------------------- #

{
  description = "A dank starter flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.ak-nix.url  = "github:aakropotkin/ak-nix/main";
  inputs.ak-nix.inputs.nixpkgs.follows = "/nixpkgs";

# ---------------------------------------------------------------------------- #

  outputs = { self, nixpkgs, ak-nix, ... } @ inputs: let
    lib = ak-nix.lib.extend self.overlays.lib;
    pkgsForSys = system: nixpkgs.legacyPackages.${system};
  in {  # Begin Outputs

    inherit lib;

# ---------------------------------------------------------------------------- #

    # Pure `lib' extensions.
    overlays.lib = final: prev: {
      ytypes = ( prev.ytypes or {} ) // ( import ./types/uri.nix {
        lib = final;
      } );
    };
    # Nixpkgs overlay: Builders, Packages, Overrides, etc.
    overlays.pkgs = final: prev: let
      callPackagesWith = auto: prev.lib.callPackagesWith ( final // auto );
      callPackageWith  = auto: prev.lib.callPackageWith ( final // auto );
      callPackages     = callPackagesWith {};
      callPackage      = callPackageWith {};
    in {
      lib = prev.lib.extend self.overlays.lib;
    };
    overlays.default = self.overlays.pkgs;


# ---------------------------------------------------------------------------- #

    # Installable Packages for Flake CLI.
    packages = lib.eachDefaultSystemMap ( system: let
      pkgsFor = pkgsForSys system;
    in {
    } );


# ---------------------------------------------------------------------------- #

  };  # End Outputs
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
