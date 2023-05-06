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
  description = "A Nix URI toolkit";

  inputs.ak-nix.url      = "github:aakropotkin/ak-nix/main";
  inputs.nixpkgs.follows = "/ak-nix/nixpkgs";

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
    ytOverlays.deps    = ak-nix.ytOverlays.default;
    ytOverlays.rime    = import ./types/overlay.yt.nix;
    ytOverlays.default = nixpkgs.lib.composeExtensions ytOverlays.deps
                                                       ytOverlays.rime;


# ---------------------------------------------------------------------------- #

    # Nixpkgs overlay: Builders, Packages, Overrides, etc.
    overlays.deps = ak-nix.overlays.default;
    overlays.rime = final: prev: let
      checktbs = import ./src/checkTarballPerms.nix {
        inherit (final) lib bash gawk gnugrep gnutar gzip coreutils system;
      };
      urlfi = import ./src/urlFetchInfo.nix {
        inherit (final) lib;
        inherit (checktbs) checkTarballPermsImpure;
      };
    in {
      lib = prev.lib.extend libOverlays.default;
      inherit (checktbs)
        checkTarballPermsDrv
        checkTarballPerms'
        checkTarballPermsPure
        checkTarballPermsImpure
        checkTarballPerms
      ;
      inherit (urlfi)
        urlFetchInfo
      ;
    };
    overlays.default = nixpkgs.lib.composeExtensions overlays.deps
                                                     overlays.rime;


# ---------------------------------------------------------------------------- #

    # Installable Packages for Flake CLI.
    packages = ak-nix.lib.eachDefaultSystemMap ( system: let
      pkgsFor   = nixpkgs.legacyPackages.${system}.extend overlays.default;
      testSuite = pkgsFor.callPackages ./tests {};
      mkScript = path: deps: pkgsFor.writeShellApplication {
        name = baseNameOf path;
        runtimeInputs = deps;
        text = builtins.readFile path;
      };
    in {

      tests = testSuite.checkDrv;

      nix-prefetch-tree = mkScript ./bin/nix-prefetch-tree [
        pkgsFor.nix
        pkgsFor.jq
        pkgsFor.git
        pkgsFor.coreutils
      ];
      json2nix      = mkScript ./bin/json2nix [pkgsFor.nix pkgsFor.coreutils];
      nix2json      = mkScript ./bin/nix2json [pkgsFor.nix pkgsFor.jq];
      nix-serialize = mkScript ./bin/nix-serialize [pkgsFor.nix pkgsFor.jq];
      nix-outputs   = mkScript ./bin/nix-outputs [pkgsFor.nix pkgsFor.gnused];

    } );


# ---------------------------------------------------------------------------- #
 
in {  # Begin Outputs

    inherit overlays libOverlays ytOverlays packages;
    lib = nixpkgs.lib.extend libOverlays.default;
    
# ---------------------------------------------------------------------------- #

    checks = ak-nix.lib.eachDefaultSystemMap ( system: let
      pkgsFor = nixpkgs.legacyPackages.${system}.extend overlays.default;
      lodashFileArgs = {
        type    = "file";
        url     = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
        narHash = "sha256-fn2qMkL7ePPYQyW/x9nvDOl05BDrC7VsfvyfW0xkQyE=";
      };
    in {
      inherit (packages.${system}) tests;
      # TODO: test checkTarballPerms
      tarballPerms = pkgsFor.checkTarballPermsDrv {
        src = builtins.fetchTree lodashFileArgs;
      };
      urlFetchInfo = let
        fi = pkgsFor.urlFetchInfo lodashFileArgs;
        txt = if pkgsFor.lib.inPureEvalMode then "PURE" else
              if builtins.currentSystem != system then "CROSS" else
              ( builtins.toJSON fi );
      in pkgsFor.writeText "urlFetchInfo-test" txt;
    } );


# ---------------------------------------------------------------------------- #

  templates.inputs.path        = ./templates/inputs;
  templates.inputs.description =
    "( inputs.nix ): " +
    "Expose flake inputs to legacy Nix CLI, and non-flake expressions.";


# ---------------------------------------------------------------------------- #

  };  # End Outputs
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
