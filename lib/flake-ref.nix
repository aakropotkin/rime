# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt  = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;
  inherit (yt) defun;
  inherit (yt.FlakeRef) Strings Structs;

# ---------------------------------------------------------------------------- #

  typesEithers = {
    indirect  = yt.FlakeRef.Eithers.flake_ref_indirect;
    path      = yt.FlakeRef.Eithers.flake_ref_path;
    git       = yt.FlakeRef.Eithers.flake_ref_git;
    github    = yt.FlakeRef.Eithers.flake_ref_github;
    tarball   = yt.FlakeRef.Eithers.flake_ref_tarball;
    file      = yt.FlakeRef.Eithers.flake_ref_file;
    sourcehut = yt.FlakeRef.Eithers.flake_ref_sourcehut;
    mercurial = yt.FlakeRef.Eithers.flake_ref_mercurial;
  };

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

  typesStructs = {
    indirect  = yt.FlakeRef.Structs.flake_ref_indirect;
    path      = yt.FlakeRef.Structs.flake_ref_path;
    git       = yt.FlakeRef.Structs.flake_ref_git;
    github    = yt.FlakeRef.Structs.flake_ref_github;
    tarball   = yt.FlakeRef.Structs.flake_ref_tarball;
    file      = yt.FlakeRef.Structs.flake_ref_file;
    sourcehut = yt.FlakeRef.Structs.flake_ref_sourcehut;
    mercurial = yt.FlakeRef.Structs.flake_ref_mercurial;
  };


# ---------------------------------------------------------------------------- #

  # tryIdentifyFlakeRef  Any -> (TYPENAME|null)
  # -------------------------------------------
  tryIdentifyFlakeRef = x: let
    tagged = lib.libtypes.discrDefTypes typesEithers "unknown" x;
    type   = lib.libtag.tagName tagged;
  in if type == "unknown" then null else type;


  # identifyFlakeRef  FLAKE_REF_(STRING|ATTRS) -> TYPENAME
  # ------------------------------------------------------
  identifyFlakeRef =
    defun [( yt.either ( yt.attrs yt.any ) yt.Uri.Strings.uri_ref )
           yt.FlakeRef.Enums.ref_type
          ] tryIdentifyFlakeRef;


# ---------------------------------------------------------------------------- #

  flakeRefAttrsToString = let
    lams = {
      indirect = { id, ref ? null, rev ? null, ... }:
        "flake:" + id + (
          if rev != null then "/" + rev else
          if ref != null then "/" + ref else
          ""
        );
      path = { path, ... }: "path:" + path;
      git  = { url, ref ? null, rev ? null, ... }:
        "git+" + url + (
          if rev != null then "/" + rev else
          if ref != null then "/" + ref else
          ""
        );
      github = { owner, repo, ref ? null, rev ? null, ... }:
        "github:" + owner + "/" +repo + (
          if rev != null then "/" + rev else
          if ref != null then "/" + ref else
          ""
        );
      tarball = { url, ... }:
        if lib.test ".*:.*" url then "tarball+" + url else "tarball:" + url;
      file = { url, ... }:
        if lib.test ".*:.*" url then "file+" + url else "file:" + url;
      sourcehut = { owner, repo, ref ? null, rev ? null, ... }:
        "sourcehut:" + owner + "/" +repo + (
          if rev != null then "/" + rev else
          if ref != null then "/" + ref else
          ""
        );
      mercurial = { url, ref ? null, rev ? null, ... }:
        "hg+" + url + (
          if rev != null then "/" + rev else
          if ref != null then "/" + ref else
          ""
        );
    };
  in x: let
    type  = lib.liburi.identifyFlakeRef x;
    base  = ( builtins.getAttr type lams ) ( removeAttrs x ["dir" "narHash"] );
    keeps = { dir = true; } // ( if builtins.elem type ["file" "tarball"] then {
      narHash = true;
    } else {} );
    qs = lib.liburi.Query.toString ( builtins.intersectAttrs keeps x );
  in if qs == "" then base else
     if lib.test ".*\\?.*" base then base + "&" + qs else base + "?" + qs;


# ---------------------------------------------------------------------------- #

in {
  inherit
    tryIdentifyFlakeRef
    identifyFlakeRef
    flakeRefAttrsToString
  ;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
