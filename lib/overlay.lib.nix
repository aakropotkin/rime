# ============================================================================ #
#
# Nixpkgs `lib' extensions.
# Depends on `nixpkgs.lib' and `ak-nix.lib' routines.
#
# ---------------------------------------------------------------------------- #

final: prev: let

# ---------------------------------------------------------------------------- #

  callLibWith = { lib ? final, ... } @ autoArgs: x: let
    f    = if prev.isFunction x then x else import x;
    args = builtins.intersectAttrs ( builtins.functionArgs f )
                                   ( { inherit lib; } // autoArgs );
  in f args;
  callLib      = callLibWith {};
  callLibsWith = autoArgs:
    builtins.foldl' ( acc: x: acc // ( callLibWith autoArgs x ) ) {};
  callLibs = callLibsWith {};


# ---------------------------------------------------------------------------- #

in {

  liburi = callLibs [
    ./uri.nix ./parsers/uri.nix ./parsers/flake-ref.nix ./flake-ref.nix
  ];
  libgit     = callLib  ./git.nix;
  libresolve = callLib ./resolve.nix;

  ytypes = prev.ytypes.extend ( import ../types/overlay.yt.nix );

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
