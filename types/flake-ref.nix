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

    git_owner = let
      chars = lib.test "[a-zA-Z0-9]([a-zA-Z0-9-]*[^-])?";
      # No consecutive hyphens are allowed
      hyphens = s: ! ( lib.test ".*--.*" s );
      len = s: ( builtins.stringLength s ) <= 39;
      cond = s: ( len s ) && ( chars s ) && ( hyphens s );
    in restrict "git:owner" cond string;
  };


# ---------------------------------------------------------------------------- #

  data_scheme = enum "data_scheme" [
    "path" "tarball" "file"
    "git" "github" "gitlab" "mercurial"
    "indirect"
  ];

# ---------------------------------------------------------------------------- #

  Structs = {
    flake-ref = struct "flake-ref" {
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
      owner        = option Strings.git_owner;
      repo         = option string;
      rev          = option yt.Uri.Strings.rev;
      ref          = option string;
    };

    # FIXME: if `type' is not given, you must infer it
    flake-ref-path = let
      cond = x: let
        m    = builtins.match "(path)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        uot  = ( x ? url ) || ( x ? type );
        uop  = ( x ? url ) || ( x ? path );
        nos  = x == ( removeAttrs x ["repo" "owner" "rev" "ref"] );
      in uot && uop && nos && ( type == "path" );
    in restrict "path" cond Structs.flake-ref;

    flake-ref-file = let
      cond = x: let
        m    = builtins.match "(file)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        nos  = x == ( removeAttrs x ["path" "repo" "owner" "rev" "ref"] );
      in ( x ? url ) && nos && ( type == "file" );
    in restrict "file" cond Structs.flake-ref;

    flake-ref-tarball = let
      cond = x: let
        m    = builtins.match "(tarball)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        nos  = x == ( removeAttrs x ["path" "repo" "owner" "rev" "ref"] );
      in ( x ? url ) && nos && ( type == "tarball" );
    in restrict "tarball" cond Structs.flake-ref;

    flake-ref-git = let
      cond = x: let
        m    = builtins.match "(git)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        nos  = ! ( ( x ? owner ) || ( x ? repo ) || ( x ? path ) );
      in ( x ? url ) && ( type == "git" );
    in restrict "git" cond Structs.flake-ref;

    flake-ref-github = let
      cond = x: let
        m    = builtins.match "(github)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        uofs = ( x ? url ) || ( ( x ? owner ) && ( x ? repo ) );
      in uofs && ( ! ( x ? path ) ) && ( type == "github" );
    in restrict "github" cond Structs.flake-ref;

    flake-ref-gitlab = let
      cond = x: let
        m    = builtins.match "(gitlab)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        uofs = ( x ? url ) || ( ( x ? owner ) && ( x ? repo ) );
      in uofs && ( ! ( x ? path ) ) && ( type == "gitlab" );
    in restrict "gitlab" cond Structs.flake-ref;

    # XXX: no idea if this is right
    flake-ref-mercurial = let
      cond = x: let
        m    = builtins.match "(mercurial)(\\+[a-z0-9])?:(.*)" x.url;
        type = x.type or ( builtins.head m );
        uofs = ( x ? url ) || ( ( x ? owner ) && ( x ? repo ) );
      in uofs && ( ! ( x ? path ) ) && ( type == "mercurial" );
    in restrict "mercurial" cond Structs.flake-ref;

  };


# ---------------------------------------------------------------------------- #

in {
  inherit
    data_scheme
    Strings
    Structs
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
