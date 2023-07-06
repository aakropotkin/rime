# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

let

  flake_id_p = "[a-zA-Z][a-zA-Z0-9_-]*";

  tarball_suffixes_p = "(zip|tar|tgz|tar.gz|tar.xz|tar.bz2|tar.zst)";

in {

  inherit flake_id_p tarball_suffixes_p;

  path_ref_p = "(path:)?([^:?]*)(\\?(.*))?";
  git_ref_p  = "(git(\\+(https?|ssh|git|file))?):(//[^/]+)?(/[^?]+)(\\?(.*))?";

  indirect_ref_p = "(flake:)?(${flake_id_p})(/([^?]+))?(\\?(.*))?";
  github_ref_p   = "github:([^/]+)/([^/?]+)(/[^?]+)?(\\?(.*))?";

  tarball_ref_p = "((tarball\\+)?(https?|file)?):(([^?]+)" +
                  tarball_suffixes_p + "|([^?]+))(\\?(.*))?";

  file_ref_p = "((file\\+)?(https?|file)?):([^?]+)(\\?(.*))?";

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
