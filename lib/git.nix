# ============================================================================ #
#
# Git parsers
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;

# ---------------------------------------------------------------------------- #

  # Non-strict
  tryParseRef = x: let
    sp = builtins.split "/" x;
    st = builtins.filter builtins.isString sp;
    ok = builtins.all yt.Git.Strings.ref_component.check st;
  in if ok then st else null;

  parseRef =
    yt.defun [yt.Git.Eithers.ref ( yt.list yt.Git.Strings.ref_component )]
             tryParseRef;


# ---------------------------------------------------------------------------- #

  # Must include at least two component.
  # This is the "real" requirement.
  isRefStrict = Strings.ref_strict.check;

  # Leading component may be omitted, and is assumed to be `head'.
  isRef = Eithers.ref.check;


# ---------------------------------------------------------------------------- #

in {

  inherit
    tryParseRef
    parseRef
    isRefStrict
    isRef
  ;

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
