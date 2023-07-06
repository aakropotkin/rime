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
    indirect  = yt.FlakeRef.Strings.ref_indirect;
    path      = yt.FlakeRef.Strings.ref_path;
    git       = yt.FlakeRef.Strings.ref_git;
    github    = yt.FlakeRef.Strings.ref_github;
    tarball   = yt.FlakeRef.Strings.ref_tarball;
    file      = yt.FlakeRef.Strings.ref_file;
    sourcehut = yt.FlakeRef.Strings.ref_sourcehut;
    mercurial = yt.FlakeRef.Strings.ref_mercurial;
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
        if lib.test ".*:.*" then "tarball+" + url else "tarball:" + url;
      file = { url, ... }:
        if lib.test ".*:.*" then "file+" + url else "file:" + url;
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
    base = lams.${identifyFlakeRef x} ( removeAttrs x ["dir"] );
  in if ! ( x ? dir ) then base else
     if lib.test ".*\\?.*" base then base + "&dir=" + x.dir else
     base + "?dir=" + x.dir;


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
