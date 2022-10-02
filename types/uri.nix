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

  inherit (regexps.uri) patterns;

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
       comm;
  in {
    name = "${bname}_str_t";
    value = restrict iname ( lib.test patterns."${bname}_p" ) string;
  };

  uri_str_types = let
    patts = [
      "scheme_p" "ipv4_p" "ipv6_p" "hostname_p" "host_p" "user_p" "authority_p"
      "query_p" "abs_path_p" "rel_path_p" "net_path_p" "fragment_p" "param_p"
      "uri_ref_p"
    ];
    generated = builtins.listToAttrs ( map typeFromPatt patts );
  in ( removeAttrs generated ["uri_ref_str_t"] ) // {
    uri_str_t  = generated.uri_ref_str_t // { name = "string[uri]"; };
    path_str_t = let
      ei = with generated; eitherN [
        abs_path_str_t rel_path_str_t net_path_str_t
      ];
    in ei // { name = "string[uri:path]"; };
  };


# ---------------------------------------------------------------------------- #

  # Scheme sub-parts as `<DATA_FORMAT>+<TRANSPORT_LAYER>', e.g. `file+https'.
  # This technically isn't standardized but everyone uses it.
  transport_scheme_t = let
    noPlus = s: ! ( lib.hasInfix "+" s );
    r = restrict "uri:scheme:transport" noPlus uri_str_types.scheme_str_t;
  in r // {
    __functor = self: value:
      r.__functor self ( lib.yank "\\+?([^+]+)" value );
  };

  data_scheme_t = let
    noPlus = s: ! ( lib.hasInfix "+" s );
    r = restrict "uri:scheme:data" noPlus uri_str_types.scheme_str_t;
  in r // {
    __functor = self: value:
      r.__functor self ( lib.yank "([^+]+)\\+?" value );
  };


  scheme_attrs = ( struct "scheme" {
    transport = transport_scheme_t;
    data      = option data_scheme_t;
  } ) // { name = "attrs[schema]"; };

  # The full schema.
  # This accepts a string or attrs, but will repack as attrs in either case.
  scheme_t = let
    ei = either uri_str_types.scheme_str_t scheme_attrs;
  in ei // {
    name = "scheme";
    __functor = self: value: let
      result  = self.checkType value;
      checked = if self.checkToBool result then value else
                throw ( self.toError value result );
      sps = builtins.match "(([^+]+)\\+)?([^+]+)?" value;
    in ( if ( scheme_attrs.check checked ) then checked else scheme_attrs {
      transport = transport_scheme_t ( builtins.elemAt sps 2 );
      data      = data_scheme_t ( builtins.elemAt sps 1 );
    } ) // { __toString = self: "${self.data}+${self.transport}"; };

  };


# ---------------------------------------------------------------------------- #

  url_attrs_t = ( struct "url" {
    scheme    = scheme_t;
    authority = option uri_str_types.authority_str_t;
    path      = uri_str_types.path_str_t;         # FIXME: split to parts
    query     = option uri_str_types.query_str_t; # FIXME: split to params
    fragment  = option uri_str_types.fragment_str_t;
  } ) // { name = "attrs[url]"; };

  url_t = ( either uri_str_types.uri_str_t url_attrs_t ) // { name = "url"; };


# ---------------------------------------------------------------------------- #

in {
  uri_attrs_types = {
    inherit
      scheme_attrs_t
      url_attrs_t
    ;
  };
  inherit
    git_types
    uri_str_types

    transport_scheme_t
    data_scheme_t
    scheme_t
    url_t
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
