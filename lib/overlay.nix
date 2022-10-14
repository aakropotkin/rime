# ============================================================================ #
#
#
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

  liburi = callLibs [./uri.nix ./parsers/uri.nix];

  ytypes = prev.ytypes.extend ( import ../types/overlay.nix );

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
