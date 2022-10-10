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

  scheme_type = enum ["path" "tarball" "file" "git" "indirect"];


# ---------------------------------------------------------------------------- #

  Structs = {
    flake-ref = struct "flake-ref" {
      type         = scheme_type;
      id           = option Strings.id;
      ref          = option string;
      url          = option yt.Uri.Strings.uri_ref;
      path         = option string;  # Again, not really a path.
      owner        = option Strings.git_owner;
      repo         = option string;
      rev          = option yt.Uri.Strings.rev;
      dir          = option string;  # Not actually a path.
      narHash      = option yt.Strings.sha256_sri;
      lastModified = option int;
    };
  };


# ---------------------------------------------------------------------------- #

in {
  inherit
    scheme_types
    Strings
    Structs
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
