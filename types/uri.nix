# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  inherit (lib.libyants)
    any attrs bool defun drv either eitherN enum float function int list option
    restrict string struct sum type unit
  ;

  pats  = lib.regexps.uri.patterns;
  tpat' = name: pname: restrict name ( lib.test pats.${pname} ) string;
  tpat  = name: tpat' name "${name}_p";

# ---------------------------------------------------------------------------- #

  rev = tpat' "rev" "git_rev_p";
  # A git ref, such as "git:<OWNER>/<REPO>/release-v1"
  ref = let
    cond = s: ( lib.test pats.maybe_git_ref_p s ) &&
              ( ! ( lib.test pats.bad_git_ref_p s ) );
  in restrict "ref" cond string;


# ---------------------------------------------------------------------------- #

  # Scheme sub-parts as `<DATA_FORMAT>+<TRANSPORT_LAYER>', e.g. `file+https'
  # This technically isn't standardized but everyone uses it.
  scheme = struct "scheme" {
    transport = tpat "layer";
    data      = option ( tpat "layer" );
  };

  path = eitherN ( map ( n: tpat' n "${n}_path_p" ) ["abs" "rel" "net" ] );

  url = struct "url" {
    inherit scheme path;
    authority = option ( tpat "authority" );
    query     = option ( tpat "query" );
    fragment  = option ( tpat "fragment" );
  };


# ---------------------------------------------------------------------------- #

  # Eithers

  url_t    = either url ( tpat' "url" "uri_ref_p" );
  scheme_t = either scheme ( tpat "scheme" );


# ---------------------------------------------------------------------------- #

in {
  String = { inherit rev ref path; };
  Struct = { inherit scheme url; };
  Either = { url = url_t; scheme = scheme_t; };
  inherit url_t scheme_t;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
