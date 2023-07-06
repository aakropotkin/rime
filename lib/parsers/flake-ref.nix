# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt  = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;
  frs = yt.FlakeRef.Structs;
  RE  = import ../../re/flake-ref.nix;
  inherit (yt) defun;
  inherit (yt.FlakeRef) Strings;

# ---------------------------------------------------------------------------- #

  # Allowed to be an absolute or relative path.
  tryParsePathRefURI = s: let
    # "(path:)?([^:?]*)(\\?(.*))?"
    m = builtins.match RE.path_ref_p s;
    p = builtins.elemAt m 1;
  in if m == null then null else {
    type   = "path";
    path   = if p == "" then "." else if p == "./." then "." else p;
    params = builtins.elemAt m 3;
  };

  # TODO: return type
  parsePathRefURI =
    defun [Strings.path_ref ( yt.attrs yt.any )] tryParsePathRefURI;


  # Parse a path ref as `builtins.fetchTree' args.
  tryParsePathRefFT = url: let
    up   = tryParsePathRefURI url;
    ps   = if up.params == null then {} else lib.liburi.parseQuery up.params;
    dir' = if ps ? dir then { inherit (ps) dir; } else {};
  in if up == null then null else {
    inherit url;
    inherit (up) type path;
  } // dir';

  parsePathRefFT =
    defun [Strings.path_ref frs.flake_ref_path] tryParsePathRefFT;


# ---------------------------------------------------------------------------- #

  # A rough parse largely aimed at identifying the scheme.
  tryParseGitRefURI = s: let
    # "(git(\\+(https?|ssh|git|file))?):(//[^/]+)?(/[^?]+)(\\?(.*))?"
    m  = builtins.match RE.git_ref_p s;
    u  = lib.test "git://[^@]+@.*" s;
    t  = builtins.elemAt m 2;
    tf = if u then "ssh" else "https";
  in if m == null then null else {
    type      = "git";
    transport = if ( t == null ) then tf else t;
    server    = builtins.elemAt m 3;
    path      = builtins.elemAt m 4;
    params    = builtins.elemAt m 6;
  };

  # TODO: return type
  parseGitRefURI =
    defun [Strings.git_ref ( yt.attrs yt.any )] tryParseGitRefURI;


  tryParseGitRefFT = url: let
    up = tryParseGitRefURI url;
    ps = if up.params == null then {} else lib.liburi.parseQuery up.params;
    # NOTE: `shortRev' is intentionally ignored.
    # That field appears in `sourceInfo' but is not an accepted argument, and is
    # not valid when written in the URL after `.git/<shortRev>'.
    p' = builtins.intersectAttrs { rev = true; ref = true; dir = true; } ps;
    pk = lib.liburi.Query.toString ( removeAttrs ps ["rev" "ref" "dir"] );
    # Handle `REV' in `git+ssh://<HOST>/<OWNER>/<REPO>.git/<REV>?<PARAMS>''
    m  = builtins.match "(.*.git)(/(.*))?" up.path;
    rr = if ( m == null ) || ( ( builtins.elemAt m 2 ) == null ) then null else
         builtins.elemAt m 2;
    r'    = if rr == null then {} else
            if yt.Git.rev.check rr       then { rev = rr; } else
            if yt.Git.short_rev.check rr then { rev = rr; } else
            { ref = rr; };
  in if up == null then null else {
    inherit (up) type;
    url = up.transport + ":" + up.server +
          ( if m == null then up.path else builtins.head m ) +
          ( if pk == "" then "" else "?" + pk );
  } // r' // p';


  parseGitRefFT =
    defun [Strings.git_ref frs.flake_ref_git] tryParseGitRefFT;


# ---------------------------------------------------------------------------- #

in {
  inherit
    tryParsePathRefURI
    parsePathRefURI
    tryParsePathRefFT
    parsePathRefFT


    tryParseGitRefURI
    parseGitRefURI
    tryParseGitRefFT
    parseGitRefFT
  ;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
