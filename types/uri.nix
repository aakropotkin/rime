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

# ---------------------------------------------------------------------------- #

  # Character Classes Enumerated
  character_classes = rec {
    digit_c      = "0123456789";
    upper_c      = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    lower_c      = "abcdefghijklmnopqrstuvwxyz";
    alpha_c      = lower_c + upper_c;
    alnum_c      = alpha_c + digit_c;
    word_c       = alnum_c + "-";
    hex_c        = digit_c + "abcdefABCDEF";
    escaped_c    = "%" + hex_c;
    mark_c       = "_.!~*'()-";  # XXX: be carful with the "-" in any `[...]'
    unreserved_c = alnum_c + mark_c;  # XXX: mark_c
    reserved_c   = ";/?:@&=+$,";
    uri_c        = reserved_c + escaped_c + unreserved_c;
    param_c      = escaped_c + ":@&=+$," + unreserved_c;  # XXX: mark_c
  };

  # Pseudo Character Classes
  pseudo_ccs = with character_classes; rec {
    escaped_p1 = "%[[:xdigit:]][[:xdigit:]]";
    param_p1   = "(${escaped_p1}|[:@&=+$,${unreserved_c}])";
    uri_p1     = "([${reserved_c}${unreserved_c}]|${escaped_p1})";
    uri_ns_p1  = "(${escaped_p1}|[${unreserved_c};?:@&=+$,])";
  };

  # Patterns
  patterns = with character_classes; with pseudo_ccs; rec {
    fragment_p      = "${uri_p1}*";
    query_p         = "${uri_p1}*";
    param_p         = "${param_p1}*";
    segment_p       = "${param_p1}*(;${param_p})*";
    path_segments_p = "${segment_p}(/${segment_p})*";
    port_p          = "[[:digit:]]*";
    ipv4_addr_p     = let
      seg = "([1-9][[:digit:]]?[[:digit:]]?|0)";
    in builtins.concatStringsSep "\\." [seg seg seg seg];
    ipv6_addr_p = let
      seg = "[0-9a-fA-F:]+(%[${word_c}]+)?";
    in "([[]${seg}[]]|${seg})?";
    top_label_p    = "[[:alpha:]]([${alnum_c}-]*[[:alnum:]])?";
    domain_label_p = "[[:alnum:]]([${alnum_c}-]*[[:alnum:]])?";
    hostname_p     = "(${domain_label_p}\\.)*${top_label_p}\\.?";
    host_p         = "(${hostname_p}|${ipv4_addr_p})";
    hostport_p     = "${host_p}(:${port_p})?";
    userinfo_p     = "(${escaped_p1}|[;:&=+$,${unreserved_c}])*";
    server_p       = "((${userinfo_p}@)?${hostport_p})?";
    reg_name_p     = "1(${escaped_p1}|[$,;:@&=+${unreserved_c}])*";
    authority_p    = "(${server_p}|${reg_name_p})";
    scheme_p       = "[[:alpha:]][${alnum_c}+.-]*";
    rel_segment_p  = "1(${escaped_p1}|[;@&=+$,${unreserved_c}])*";
    rel_path_p     = "${rel_segment_p}(${abs_path_p})?";
    abs_path_p     = "/${path_segments_p}";
    net_path_p     = "//${authority_p}(${abs_path_p})?";
    opaque_part_p  = "${uri_ns_p1}([${uri_c}])*";
    hier_part_p    = "(${net_path_p}|${abs_path_p})(\\?${query_p})?";
    rel_uri_p  = "(${net_path_p}|${abs_path_p}|${rel_path_p})(\\?${query_p})?";
    abs_uri_p  = "${scheme_p}:(${hier_part_p}|${opaque_part_p})";
    uri_ref_p  = "(${abs_uri_p}|${rel_uri_p})?(#${fragment_p})?";

    flake_id_p = "[[:alpha:]][${word_c}]*";

    git_rev_p      = "[[:xdigit:]]\{40\}";
    # Refs matching this pattern fail
    bad_git_ref_p = let
      parts = builtins.concatStringsSep "|" [
        "//" "/\\." "\\.\\." "[[:cntrl:]]" "[[:space:]]" "[:?^~[]"
        "\\\\" "\\*" "\\.lock/" "@\\{"
      ];
    in builtins.concatStringsSep "|" [
      "[./].*" ".*\\.lock" ".*[/.]" "@" "" ".*(${parts}).*"
    ];
    # Git Revs must match this, and not match `bad_git_ref_p'
    maybe_git_ref_p = "[[:alnum:]][a-zA-Z0-9_.\\/-]*";
  };


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


  # The full schema.
  # This accepts a string or attrs, but will repack as attrs in either case.
  scheme_t = let
    scheme_attrs = ( struct "scheme" {
      transport = transport_scheme_t;
      data      = option data_scheme_t;
    } ) // { name = "attrs[schema]"; };
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

  url_t = let
    st = ( struct "url" {
      # scheme
      # + ":"
      # + (authority ? "//" + *authority : "")
      # + path
      # + (query.empty() ? "" : "?" + encodeQuery(query))
      # + (fragment.empty() ? "" : "#" + percentEncode(fragment));
      scheme    = scheme_t;
      authority = option uri_str_types.authority_str_t;
      path      = option uri_str_types.path_str_t;  # FIXME: split to parts
      query     = option uri_str_types.query_str_t; # FIXME: split to params
      fragment  = option uri_str_types.fragment_str_t;
      # Meta: Extra fields.
      url = option uri_str_types.uri_str_t;  # full uri string.
      # This is everything before the query part: scheme + auth + path
      base = option string;
    } ) // { name = "attrs[url]"; };
    # FIXME: prelly fucked.
    __toString = self: let
      auth = if ( self.authority or null ) == null then "" else
             "//${self.authority}";
      q = if ( self.query or null ) != null then "?${self.query}" else "";
      frag = if ( self.fragment or null ) == null then "" else
             "#${self.fragment}";
      mp = if ( self.path or null ) == null then "" else self.path;
    in "${self.scheme}:${auth}${mp}${q}${frag}";
    # Either
    ei = either uri_str_types.uri_str_t st;
  in ei // {
    name = "url";
    __functor = self: value: let
      result  = self.checkType value;
      checked = if self.checkToBool result then value else
                throw ( self.toError value result );
      sps = builtins.split "(://|[:?#])" checked;
      # FIXME: path is using authority if the path is empty.
      asAttrs = let
        auth = let
          m = builtins.match "([^/:]+)(/.*)?" ( builtins.elemAt sps 2 );
          ma = if ( builtins.head m ) == null then {} else {
            authority = uri_str_types.authority_str_t ( builtins.head m );
          };
          mp = if ( builtins.elemAt m 1 ) == null then {} else {
            path = uri_str_types.path_str_t ( builtins.elemAt m 1 );
          };
        in if ( builtins.elemAt sps 1 ) != ["://"] then {
          path = uri_str_types.path_str_t ( builtins.elemAt sps 2 );
        } else mp // ma;
      in if builtins.isAttrs checked then checked else st {
        scheme = uri_str_types.scheme_str_t ( builtins.head sps );
      } // auth;
      postPath = let
        m = builtins.match "[^?#]+(\\?([^#]+))?(#(.*))?" checked;
        mq = if ( builtins.head m ) == null then {} else {
          query = uri_str_types.query_str_t ( builtins.elemAt m 1 );
        };
        mf = if ( builtins.elemAt m 2 ) == null then {} else {
          query = uri_str_types.query_str_t ( builtins.elemAt m 3 );
        };
      in if ( builtins.length sps ) < 4 then {} else mq // mf;
      url = if builtins.isString checked then checked else __toString asAttrs;
    in asAttrs // {
      base =lib.yank "([^?]+)(\\?.*)?" url;
      inherit __toString url;
    };
  };


# ---------------------------------------------------------------------------- #

in {
  inherit
    character_classes
    pseudo_ccs
    patterns
  ;
  ytypes = {
    inherit
      git_types
      uri_str_types
      scheme_t
      url_t
    ;
  };
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
