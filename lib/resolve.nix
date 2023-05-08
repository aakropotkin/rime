# ============================================================================ #
#
# Resolve URIs in a set of inputs.
# Inputs are expected to be flake-ref style attrsets accepted by `fetchTree'.
#
# It is recommended to use `lib.libflake.registryFlakeRefs' {}' as a sane
# default set of inputs.
#
#
# ---------------------------------------------------------------------------- #
#
# Example `inputs':
#   {
#     nixpkgs          = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; };
#     nixpkgs-stable   = { type = "indirect"; id = "nixpkgs"; ref = "22.11"; };
#     nixpkgs-unstable = { type = "indirect"; id = "nixpkgs"; };
#   }
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  yt = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;

# ---------------------------------------------------------------------------- #

  # TODO: I kind of hate this.
  # You should separate the `follows' and resolution of indirect flake refs
  # into a separate helper.
  # As written the handling of `revOrRef' is ugly.
  resolveInput = inputs: uri: let
    parsed    = lib.liburi.parseFullUrl uri;
    isAlias   = builtins.elem parsed.scheme.transport ["flake" "indirect"];
    fromAlias = let
      isHier = dirOf parsed.path != ".";
      fpart  = if isHier then dirOf parsed.path else parsed.path;
      m      = builtins.match "[^/]+/([^/]+)(/.*)?" parsed.path;
      ref    = if m == null then null else builtins.head m;
      idf    = if ref == null then fpart else
               if inputs ? "${fpart}/${ref}" then "${fpart}/${ref}" else
               fpart;
      nref = if m == null then null else
             if idf == fpart then lib.yank "[^/]+/(.*)" parsed.path else
             builtins.elemAt m 1;
      inp  = inputs.${idf};
      ref' = if nref == null then {} else
             if yt.Git.rev.check nref then { rev = nref; } else
             if yt.Git.short_rev.check nref then { shortRev = nref; } else
             { ref = nref; };
    in ( if inp.type != "indirect" then inp else resolveInput inputs (
      if inp ? ref then "indirect:${inp.id}/${inp.ref}" else
      "indirect:${inp.id}"
    ) ) // ref';
    fromGitHub = let
      m   = builtins.match "([^/]+)/([^/]+)(/(.*))?" parsed.path;
      rr  = builtins.elemAt m 3;
      rr' = if rr == null then {} else
            if yt.Git.rev.check rr then { rev = rr; } else
            if yt.Git.short_rev.check rr then { shortRev = rr; } else
            { ref = rr; };
    in {
      type  = "github";
      owner = builtins.head m;
      repo  = builtins.elemAt m 1;
    } // rr';
    fromParsed = {
      type = if
        ( parsed.scheme.data or null ) == null then parsed.scheme.transport else
        parsed.scheme.data + "+" + parsed.scheme.transport;
      url = lib.yankN 1 "([^:+]+\\+)?([^:+]*:.*)" uri;
    };
  in if isAlias then fromAlias else
     if parsed.scheme.transport == "github" then fromGitHub else
     fromParsed;


# ---------------------------------------------------------------------------- #

in {

  inherit resolveInput;

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
