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
  in if up == null then null else { inherit (up) type path; } // dir';

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
    r' = if rr == null then {} else
         if yt.Git.rev.check rr then { rev = rr; } else
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

  tryParseGitHubRefURI = s: let
    # "github:([^/]+)/([^/?]+)(/[^?]+)?(\\?(.*))?"
    m = builtins.match RE.github_ref_p s;
  in if m == null then null else {
    type = "github";
    path = ( builtins.head m ) + "/" + ( builtins.elemAt m 1 ) +
           ( if ( builtins.elemAt m 2 ) == null then "" else
             ( builtins.elemAt m 2 ) );
    params = builtins.elemAt m 4;
  };

  # TODO: return type
  parseGitHubRefURI =
    defun [Strings.github_ref ( yt.attrs yt.any )] tryParseGitHubRefURI;


  tryParseGitHubRefFT = url: let
    up = tryParseGitHubRefURI url;
    ps = if up.params == null then {} else lib.liburi.parseQuery up.params;
    # NOTE: `shortRev' is intentionally ignored.
    # That field appears in `sourceInfo' but is not an accepted argument, and is
    # not valid when written in the URL after `.git/<shortRev>'.
    p' = builtins.intersectAttrs { rev = true; ref = true; dir = true; } ps;
    pk = lib.liburi.Query.toString ( removeAttrs ps ["rev" "ref" "dir"] );
    # Handle `REV' in `git+ssh://<HOST>/<OWNER>/<REPO>.git/<REV>?<PARAMS>''
    m  = builtins.match "([^/]+)/([^/]+)(/(.*))?" up.path;
    rr = if ( m == null ) || ( ( builtins.elemAt m 2 ) == null ) then null else
         builtins.elemAt m 3;
    r' = if rr == null then {} else
         if yt.Git.rev.check rr then { rev = rr; } else
         { ref = rr; };
  in if up == null then null else {
    inherit (up) type;
    owner = builtins.head m;
    repo  = builtins.elemAt m 1;
  } // r' // p';


  parseGitHubRefFT =
    defun [Strings.github_ref frs.flake_ref_github] tryParseGitHubRefFT;


# ---------------------------------------------------------------------------- #

  tryParseIndirectRefURI = s: let
    # "flake:([^/]+)(/([^?]+))?(\\?(.*))?"
    m = builtins.match RE.indirect_ref_p s;
  in if m == null then null else {
    type = "indirect";
    path = ( builtins.head m ) +
           ( if ( builtins.elemAt m 1 ) == null then "" else
             ( builtins.elemAt m 1 ) );
    params = builtins.elemAt m 4;
  };

  # TODO: return type
  parseIndirectRefURI =
    defun [Strings.indirect_ref ( yt.attrs yt.any )] tryParseIndirectRefURI;


  tryParseIndirectRefFT = url: let
    m      = builtins.match RE.indirect_ref_p url;
    params = builtins.elemAt m 5;
    ps     = if params == null then {} else lib.liburi.parseQuery params;
    # NOTE: `shortRev' is intentionally ignored.
    # That field appears in `sourceInfo' but is not an accepted argument, and is
    # not valid when written in the URL after `.git/<shortRev>'.
    p' = builtins.intersectAttrs { rev = true; ref = true; dir = true; } ps;
    pk = lib.liburi.Query.toString ( removeAttrs ps ["rev" "ref" "dir"] );
    rr = if ( builtins.elemAt m 2 ) == null then null else builtins.elemAt m 3;
    r' = if rr == null then {} else
         if yt.Git.rev.check rr then { rev = rr; } else
         { ref = rr; };
  in if m == null then null else {
    type = "indirect";
    id   = builtins.elemAt m 1;
  } // r' // p';


  parseIndirectRefFT =
    defun [Strings.indirect_ref frs.flake_ref_indirect] tryParseIndirectRefFT;


# ---------------------------------------------------------------------------- #

  # TODO: tarball, file, sourcehut, mercurial

  typesStrings = {
    indirect  = yt.FlakeRef.Strings.indirect_ref;
    path      = yt.FlakeRef.Strings.path_ref;
    git       = yt.FlakeRef.Strings.git_ref;
    github    = yt.FlakeRef.Strings.github_ref;
    tarball   = yt.FlakeRef.Strings.tarball_ref;
    file      = yt.FlakeRef.Strings.file_ref;
    sourcehut = yt.FlakeRef.Strings.sourcehut_ref;
    mercurial = yt.FlakeRef.Strings.mercurial_ref;
  };


  tryParseFlakeRefFT = url: let
    type = lib.liburi.identifyFlakeRef url;
  in if type == null then null else ( builtins.getAttr type {
    indirect = tryParseIndirectRefFT;
    path     = tryParsePathRefFT;
    git      = tryParseGitRefFT;
    github   = tryParseGitHubRefFT;
    tarball     = u: let
      m      = builtins.match "(tarball\\+)?([^?]+)(\\?(.*))?" u;
      params = builtins.elemAt m 3;
      ps     = if params == null then {} else lib.liburi.parseQuery params;
      p'     = builtins.intersectAttrs { dir = true; } ps;
      pk     = lib.liburi.Query.toString ( removeAttrs ps ["dir"] );
    in {
      type = "tarball";
      url  = ( builtins.elemAt m 1 ) + ( if pk == "" then "" else "?" + pk );
    } // p';
    file = u: let
      m      = builtins.match "(file\\+)?([^?]+)(\\?(.*))?" u;
      params = builtins.elemAt m 3;
      ps     = if params == null then {} else lib.liburi.parseQuery params;
      p'     = builtins.intersectAttrs { dir = true; } ps;
      pk     = lib.liburi.Query.toString ( removeAttrs ps ["dir"] );
    in {
      type = "file";
      url  = ( builtins.elemAt m 1 ) + ( if pk == "" then "" else "?" + pk );
    } // p';
    # TODO
    sourcehut = _: null;
    mercurial = _: null;
  } ) url;

  parseFlakeRefFT =
    defun [( yt.eitherN ( builtins.attrValues typesStrings ) )
           yt.FlakeRef.Structs.flake_ref
          ] tryParseFlakeRefFT;


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

    tryParseGitHubRefURI
    parseGitHubRefURI
    tryParseGitHubRefFT
    parseGitHubRefFT

    tryParseIndirectRefURI
    parseIndirectRefURI
    tryParseIndirectRefFT
    parseIndirectRefFT

    tryParseFlakeRefFT
    parseFlakeRefFT
  ;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
