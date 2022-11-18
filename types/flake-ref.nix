# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ ytypes }: let

  yt = ytypes // ytypes.Core // ytypes.Prim;
  inherit (yt) struct string restrict option enum int;
  lib.test = patt: s: ( builtins.match patt s ) != null;

# ---------------------------------------------------------------------------- #

  Strings = {
    id = let
      cond = lib.test "[a-zA-Z][a-zA-Z0-9_-]*";
    in restrict "flake:ref:id" cond string;

    path_ref = restrict "flake:ref[path]" ( lib.test path_ref_p ) string;
    # NOTE: do not confuse this short name with `Git.Strings.ref'.
    # To lib consumers this isn't ambiguous but in this file you could
    # potentially shoot yourself in the foot.
    git_ref = restrict "flake:ref[git]" ( lib.test git_ref_p ) string;
  };


# ---------------------------------------------------------------------------- #

  # Data layer from scheme: `<DATA>+<TRANSPORT>:...'
  data_scheme = enum "flake:ref:scheme:data" [
    "path"     # directory
    "tarball"  # zip, tar, tgz, tar.gz, tar.xz, tar.bz, tar.zst
    "file"     # regular file
    "git"      # dir-like with `.git/'
    "hg"       # Mercurial
  ];

  # Allowed to appear in a `type = <REF-TYPE>;' for a flake input.
  ref_type = enum "flake:ref:type" [
    "path" "tarball" "file"
    "git" "github" "sourcehut"
    "mercurial"
    "indirect"
  ];


# ---------------------------------------------------------------------------- #

  ref_attrs_any = {
    dir     = option string;  # Not actually a path.
    narHash = option yt.Strings.sha256_sri;
  };

  ref_attrs_common = {
   rev = option yt.Git.Strings.rev;
   ref = option yt.Git.Strings.ref;
  };

  ref_attrs_locked = {
    revCount     = int; # Git/Mercurial
    lastModified = int; # Any
  };


# ---------------------------------------------------------------------------- #

  # Allowed to be an absolute or relative path.
  path_ref_p = "(path:)?([^:?]*)(\\?(.*))?";
  tryParsePathRef = s: let
    m = builtins.match path_ref_p s;
    p = builtins.elemAt m 1;
  in if m == null then null else {
    type   = "path";
    path   = if p == "" then "." else if p == "./." then "." else p;
    params = builtins.elemAt m 3;
  };

  # FIXME: return type
  parsePathRef =
    yt.defun [Strings.path_ref ( yt.attrs yt.any )] tryParsePathRef;


# ---------------------------------------------------------------------------- #

  # A rough parse largely aimed at identifying the scheme.
  git_ref_p = "(git(\\+(https?|ssh|git|file))?):(//[^/]+)?(/[^?]+)(\\?(.*))?";
  tryParseGitRef = s: let
    m  = builtins.match git_ref_p s;
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

  # FIXME: return type
  parseGitRef =
    yt.defun [Strings.git_ref ( yt.attrs yt.any )] tryParseGitRef;


# ---------------------------------------------------------------------------- #

  Structs = {
    flake_ref = struct "flake:ref" {
      type         = option data_scheme;  # must be inferred if omitted
      id           = option Strings.id;
      dir          = option string;  # Not actually a path.
      narHash      = option yt.Strings.sha256_sri;
      lastModified = option int;
      follows      = option string;   # NOTE: valid for any type
      flake        = option yt.bool;  # defaults to `true'.
      url          = option yt.Uri.Strings.uri_ref;
      # Dependent on `type'
      path         = option string;  # Again, not really a path.
      owner        = option yt.Git.Strings.owner;
      repo         = option string;
      rev          = option yt.Git.Strings.rev;
      ref          = option string;
    };

    # FIXME: if `type' is not given, you must infer it
    flake_ref_path = let
      cond = x: let
        m    = builtins.match "(path)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        uot  = ( x ? url ) || ( x ? type );
        uop  = ( x ? url ) || ( x ? path );
        nos  = x == ( removeAttrs x ["repo" "owner" "rev" "ref"] );
      in uot && uop && nos && ( type == "path" );
    in restrict "path" cond Structs.flake_ref;

    flake_ref_file = let
      cond = x: let
        m    = builtins.match "(file)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        nos  = x == ( removeAttrs x ["path" "repo" "owner" "rev" "ref"] );
      in ( x ? url ) && nos && ( type == "file" );
    in restrict "file" cond Structs.flake_ref;

    flake_ref_tarball = let
      cond = x: let
        m    = builtins.match "(tarball)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        nos  = x == ( removeAttrs x ["path" "repo" "owner" "rev" "ref"] );
      in ( x ? url ) && nos && ( type == "tarball" );
    in restrict "tarball" cond Structs.flake_ref;

    flake_ref_git = let
      cond = x: let
        m    = builtins.match "(git)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        nos  = ! ( ( x ? owner ) || ( x ? repo ) || ( x ? path ) );
      in ( x ? url ) && ( type == "git" );
    in restrict "git" cond Structs.flake_ref;

    # FIXME: `rev-or-ref' differs from `git' requirement
    flake_ref_github = let
      cond = x: let
        m    = builtins.match "(github)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        uofs = ( x ? url ) || ( ( x ? owner ) && ( x ? repo ) );
      in uofs && ( ! ( x ? path ) ) && ( type == "github" );
    in restrict "github" cond Structs.flake_ref;

    flake_ref_sourcehut = let
      cond = x: let
        m    = builtins.match "(sourcehut):(.*)" x.url;
        type = x.type or ( builtins.head m );
        uofs = ( x ? url ) || ( ( x ? owner ) && ( x ? repo ) );
      in uofs && ( ! ( x ? path ) ) && ( type == "sourcehut" );
    in restrict "sourcehut" cond Structs.flake_ref;

    flake_ref_mercurial = let
      cond = x: let
        m    = builtins.match "(hg)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( assert ( builtins.head m ) == "hg"; "mercurial" );
        uofs = ( x ? url ) || ( ( x ? owner ) && ( x ? repo ) );
      in uofs && ( ! ( x ? path ) ) && ( type == "mercurial" );
    in restrict "mercurial" cond Structs.flake_ref;

    flake_ref_indirect = let
      cond = x: let
        m    = builtins.match "(indirect)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        nos  = x == ( removeAttrs x ["path" "repo" "owner" "rev"] );
        uofs = ( x ? url ) || ( x ? id ) || ( x ? follows );
        tofl = ( x ? follows ) || ( type == "indirect" );
      in uofs  && tofl;
    in restrict "indirect" cond Structs.flake_ref;

  };


# ---------------------------------------------------------------------------- #

in {
  inherit Strings Structs;
  Enums = { inherit data_scheme ref_type; };
  # FIXME: move to lib
  RE = { inherit path_ref_p git_ref_p; };
  inherit
    tryParsePathRef
    parsePathRef
    tryParseGitRef
    parseGitRef
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
