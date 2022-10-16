# ============================================================================ #
#
# Nix CLI wrapper generator and misc utils for augmenting the use of Nix's
# flake UX patterns.
#
# - URI parser and type checker written in pure Nix.
#   + Allows you to parse URIs from Nix expressions matching Nix's builtin
#     `parseFlakeRef' and `fetchTree' processors.
#   + Allows registries, locks, and flake inputs to be created programmatically
#     without using Nix's CLI directly.
#
# ---------------------------------------------------------------------------- #

{
  description = "A Nix CLI extension kit";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.ak-nix.url  = "github:aakropotkin/ak-nix/main";
  inputs.ak-nix.inputs.nixpkgs.follows = "/nixpkgs";

# ---------------------------------------------------------------------------- #

  outputs = { self, nixpkgs, ak-nix, ... } @ inputs: let
    lib        = ak-nix.lib.extend self.libOverlays.default;
    pkgsForSys = system: nixpkgs.legacyPackages.${system};
  in {  # Begin Outputs

    inherit lib;

# ---------------------------------------------------------------------------- #

    # Pure `lib' extensions.
    # Mostly regex patterns aside from the URI types.
    libOverlays.rime    = import ./lib/overlay.lib.nix;
    libOverlays.default = import ./lib/overlay.lib.nix;
    ytOverlays.rime     = import ./types/overlay.yt.nix;
    ytOverlays.default  = import ./types/overlay.yt.nix;
  
    # Nixpkgs overlay: Builders, Packages, Overrides, etc.
    overlays.pkgs = final: prev: let
      callPackagesWith = auto: prev.lib.callPackagesWith ( final // auto );
      callPackageWith  = auto: prev.lib.callPackageWith ( final // auto );
      callPackages     = callPackagesWith {};
      callPackage      = callPackageWith {};
    in {
      lib = prev.lib.extend self.libOverlays.default;
    };
    overlays.default = self.overlays.pkgs;


# ---------------------------------------------------------------------------- #

    # Installable Packages for Flake CLI.
    packages = lib.eachDefaultSystemMap ( system: let
      pkgsFor = pkgsForSys system;
      testSuite = pkgsFor.callPackages ./tests { inherit lib; };
    in {
      tests = testSuite.checkDrv;
    } );


# ---------------------------------------------------------------------------- #

  };  # End Outputs
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
