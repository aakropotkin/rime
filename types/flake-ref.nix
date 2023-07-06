# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ ytypes }: let

  yt = ytypes // ytypes.Core // ytypes.Prim;
  inherit (yt) struct string restrict option enum int;
  lib.test = patt: s: ( builtins.match patt s ) != null;
  RE = import ../re/flake-ref.nix;

# ---------------------------------------------------------------------------- #

  Strings = {
    id = let
      cond = lib.test RE.flake_id_p;
    in restrict "flake:ref:id" cond string;

    indirect_ref = restrict "flake:ref[indirect]" ( lib.test RE.indirect_ref_p )
                            string;

    path_ref = restrict "flake:ref[path]" ( lib.test RE.path_ref_p ) string;
    # NOTE: do not confuse this short name with `Git.Strings.ref'.
    # To lib consumers this isn't ambiguous but in this file you could
    # potentially shoot yourself in the foot.
    git_ref    = restrict "flake:ref[git]" ( lib.test RE.git_ref_p ) string;
    github_ref = restrict "flake:ref[github]" ( lib.test RE.github_ref_p )
                          string;

    tarball_ref = let
      pred = s: let
        m           = builtins.match RE.tarball_ref_p s;
        hasTbPrefix = ( builtins.elemAt m 1 ) != null;
        hasTbSuffix = ( builtins.elemAt m 5 ) != null;
      in ( m != null ) && ( hasTbPrefix || hasTbSuffix );
    in restrict "flake:ref[tarball]" pred string;

    file_ref = let
      pred = s: let
        m             = builtins.match RE.file_ref_p s;
        hasFilePrefix = ( builtins.elemAt m 1 ) != null;
        t             = builtins.match RE.tarball_ref_p s;
        hasTbPrefix   = ( builtins.elemAt t 1 ) != null;
        hasTbSuffix   = ( builtins.elemAt t 5 ) != null;
      in ( m != null ) && ( hasFilePrefix || ( ! hasTbSuffix ) );
    in restrict "flake:ref[file]" pred string;


    sourcehut_ref =
      restrict "flake:ref[sourcehut]" ( lib.test "sourcehut:.*" ) string;

    mercurial_ref = restrict "flake:ref[mercurial]" ( lib.test "hg:.*" ) string;

  };


# ---------------------------------------------------------------------------- #

  # Data layer from scheme: `<DATA>+<TRANSPORT>:...'
  data_scheme = enum "flake:ref:scheme:data" [
    "path"     # directory
    "tarball"  # zip, tar, tgz, tar.gz, tar.xz, tar.bz, tar.zst
    "file"     # regular file
    "git"      # dir-like with `.git/'
    "hg"       # Mercurial
    "flake"    # flake alias
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

  Structs = {
    flake_ref = struct "flake:ref" {
      # must be inferred if omitted
      type         = option ( yt.either data_scheme ref_type );
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
        m    = builtins.match "(github):(.*)" x.url;
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
        m    = builtins.match RE.indirect_ref_p x.url;
        type = x.type or ( if m != null then "indirect" else null );
        nos  = x == ( removeAttrs x ["path" "repo" "owner" "rev"] );
        uofs = ( x ? url ) || ( x ? id ) || ( x ? follows );
        tofl = ( x ? follows ) || ( type == "indirect" );
      in uofs  && tofl;
    in restrict "indirect" cond Structs.flake_ref;

  };


# ---------------------------------------------------------------------------- #

  Eithers = {
    flake_ref_indirect =
      yt.either Strings.indirect_ref Structs.flake_ref_indirect;
    flake_ref_sourcehut =
      yt.either Strings.sourcehut_ref Structs.flake_ref_sourcehut;
    flake_ref_mercurial =
      yt.either Strings.mercurial_ref Structs.flake_ref_mercurial;
    flake_ref_path    = yt.either Strings.path_ref Structs.flake_ref_path;
    flake_ref_git     = yt.either Strings.git_ref Structs.flake_ref_git;
    flake_ref_github  = yt.either Strings.github_ref Structs.flake_ref_github;
    flake_ref_tarball = yt.either Strings.tarball_ref Structs.flake_ref_tarball;
    flake_ref_file    = yt.either Strings.file_ref Structs.flake_ref_file;
  };


# ---------------------------------------------------------------------------- #

in {
  inherit Strings Structs RE Eithers;
  Enums = { inherit data_scheme ref_type; };
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
