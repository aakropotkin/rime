# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  inherit (lib.libyants)
    any attrs bool defun drv either eitherN enum float function int list option
    path restrict string struct sum type unit
  ;

  inherit (lib.regexps.uri) patterns;

# ---------------------------------------------------------------------------- #

  git_types = with patterns; {
    rev = restrict "git:rev" ( lib.test git_rev_p ) string;
    # A git ref, such as "git:<OWNER>/<REPO>/release-v1"
    ref = let
      cond = s:
        ( lib.test patterns.maybe_git_ref_p s ) &&
        ( ! ( lib.test patterns.bad_git_ref_p s ) );
    in restrict "git:ref" cond string;
  };


# ---------------------------------------------------------------------------- #

  typeFromPatt = pname: let
    bname = lib.yank "(.*)_p" pname;
    iname = let
      comm = "uri:${bname}";
      paths = "uri:path:${lib.yank "([^_]+)_.*" bname}";
      addr  = "uri:address:${bname}";
    in if lib.hasSuffix "_path" bname then paths else
       if lib.hasPrefix "ipv" bname then addr else
       if bname == "uri_ref" then "uri" else
       if bname == "layer" then "uri:scheme:layer" else
       comm;
  in {
    name  = bname;
    value = restrict iname ( lib.test patterns."${bname}_p" ) string;
  };

  string_ts = let
    patts = [
      "scheme_p" "ipv4_p" "ipv6_p" "hostname_p" "host_p" "user_p" "authority_p"
      "query_p" "abs_path_p" "rel_path_p" "net_path_p" "fragment_p" "param_p"
      "uri_ref_p" "layer_p"
    ];
    generated = builtins.listToAttrs ( map typeFromPatt patts );
  in ( removeAttrs generated ["uri_ref"] ) // {
    uri  = generated.uri_ref;
    path = let
      ei = with generated; eitherN [abs_path rel_path net_path];
    in ei // { name = "string[uri:path]"; };
  };


# ---------------------------------------------------------------------------- #

  attrs_ts = rec {

    scheme = let
      # Scheme sub-parts as `<DATA_FORMAT>+<TRANSPORT_LAYER>', e.g. `file+https'
      # This technically isn't standardized but everyone uses it.
    in struct "scheme" {
      transport = string_ts.layer;
      data      = option string_ts.layer;
    };

    url = struct "url" {
      inherit scheme;
      inherit (string_ts) path;
      authority = option string_ts.authority;
      query     = option string_ts.query;
      fragment  = option string_ts.fragment;
    };

  };


# ---------------------------------------------------------------------------- #

  # Eithers

  url_t = ( either string_ts.url attrs_ts.uri ) // { name = "url"; };

  scheme_t = ( either string_ts.scheme attrs_ts.scheme ) // {
    name = "scheme";
  };


# ---------------------------------------------------------------------------- #

in {
  inherit
    git_types
  ;
  uri_types = {
    inherit
      attrs_ts
      string_ts
      url_t
      scheme_t
    ;
  };
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
