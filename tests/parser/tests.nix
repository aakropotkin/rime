# ============================================================================ #
#
# General tests for `parser' routines.
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  tests = {

# ---------------------------------------------------------------------------- #

    testParseRepo = let
      url = "https://github.com/aakropotkin/rime.git";
    in {
      expr = with lib.liburi;
        parseAbsolutePath (
          parseNetworkPath (
            parseHierarchyPart (
              parseAbsoluteUri (
                parseUriRef url
              ).uri.absolute
            ).part.hierarchy
          ).path.network
        ).path.absolute;
      expected = ["aakropotkin" "rime.git"];
    };


# ---------------------------------------------------------------------------- #

    testParseGitRefFT = let
      url = "git+ssh://git@github.com:aakropotkin/rime.git/main" +
            "?dir=bar&shortRev=6666666";
    in {
      expr     = lib.liburi.parseGitRefFT url;
      expected = {
        type = "git";
        url  = "ssh://git@github.com:aakropotkin/rime.git?shortRev=6666666";
        ref  = "main";
        dir  = "bar";
      };
    };


# ---------------------------------------------------------------------------- #

  };  # End Tests


# ---------------------------------------------------------------------------- #

in tests


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
