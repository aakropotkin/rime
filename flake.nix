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

# ---------------------------------------------------------------------------- #

    # Pure `lib' extensions.
    # Mostly regex patterns aside from the URI types.
    libOverlays.deps    = ak-nix.libOverlays.default;
    libOverlays.rime    = import ./lib/overlay.lib.nix;
    libOverlays.default = nixpkgs.lib.composeExtensions libOverlays.deps
                                                        libOverlays.rime;

    # type extensions provided standale.
    # NOTE: these are included in `libOverlays` already 
    # and the only reason to pay attention to use these is for deep overrides. 
    # Practically speaking you should ignore these unless you were in a
    # situation where you were considering vendoring a copy of the typedefs
    # in another project.
    ytOverlays.deps    = ak-nix ytOverlays.default;
    ytOverlays.rime    = import ./types/overlay.yt.nix;
    ytOverlays.default = nixpkgs.lib.composeExtensions ytOverlays.deps
                                                       ytOverlays.rime;


# ---------------------------------------------------------------------------- #

    # Nixpkgs overlay: Builders, Packages, Overrides, etc.
    overlays.rime = final: prev: {
      lib = prev.lib.extend libOverlays.default;
    };
    overlays.deps    = ak-nix.overlays.default;
    overlays.default = lib.composeExtensions overlays.deps overlays.rime;


# ---------------------------------------------------------------------------- #
 
in {  # Begin Outputs

    inherit overlays libOverlays ytOverlays;
    
# ---------------------------------------------------------------------------- #

    # Installable Packages for Flake CLI.
    packages = lib.eachDefaultSystemMap ( system: let
      pkgsFor   = nixpkgs.legacyPackages.${system}.extend overlays.rime;
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
