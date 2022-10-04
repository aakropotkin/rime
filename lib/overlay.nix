# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

final: prev: let

# ---------------------------------------------------------------------------- #

  callLibWith = { lib ? final, ... } @ autoArgs: x: let
    f = if prev.isFunction x then x else import x;
    args = builtins.intersectAttrs ( builtins.functionArgs f )
                                    ( { inherit lib; } // autoArgs );
  in f args;
  callLib = callLibWith {};
  callLibsWith = autoArgs: lst:
    builtins.foldl' ( acc: x: acc // ( callLibWith autoArgs x ) ) {} lst;
  callLibs = callLibsWith {};


# ---------------------------------------------------------------------------- #

in {

  liburi = callLibs [./uri.nix ./parsers/uri.nix];

  ytypes = builtins.foldl' ( a: b: a // b ) ( prev.ytypes or {} ) [
    ( callLib ../types/uri.nix )
  ];

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
