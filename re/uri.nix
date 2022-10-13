# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

let

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
    mark_c       = "_.!~*'()-";       # XXX: be careful with "-" in any `[...]'
    unreserved_c = alnum_c + mark_c;  # XXX: mark_c
    res_ns_c     = ";?:@&=+$,";
    reserved_c   = res_ns_c + "/";
    # These use `escaped_c' and require "pseudo character classes"
    uri_c        = escaped_c + reserved_c + unreserved_c;
    param_c      = escaped_c + ":@&=+$,"  + unreserved_c;  # XXX: mark_c
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
    in "([[]${seg}[]]|${seg})";
    top_label_p    = "[[:alpha:]]([${alnum_c}-]*[[:alnum:]])?";
    domain_label_p = "[[:alnum:]]([${alnum_c}-]*[[:alnum:]])?";
    hostname_p     = "(${domain_label_p}\\.)*${top_label_p}\\.?";
    host_p         = "(${hostname_p}|${ipv4_addr_p}|${ipv6_addr_p})";
    hostport_p     = "${host_p}(:${port_p})?";
    userinfo_p     = "(${escaped_p1}|[;:&=+$,${unreserved_c}])*";
    server_p       = "((${userinfo_p}@)?${hostport_p})?";
    reg_name_p     = "1(${escaped_p1}|[$,;:@&=+${unreserved_c}])*";
    authority_p    = "(${server_p}|${reg_name_p})";
    scheme_p       = "[[:alpha:]][${alnum_c}+.-]*";
    layer_p        = "[[:alpha:]][${alnum_c}.-]*";  # scheme sublayer "()+()"
    rel_segment_p  = "1(${escaped_p1}|[;@&=+$,${unreserved_c}])*";
    rel_path_p     = "${rel_segment_p}(${abs_path_p})?";
    abs_path_p     = "/${path_segments_p}";
    net_path_p     = "//${authority_p}(${abs_path_p})?";
    opaque_part_p  = "${uri_ns_p1}${uri_p1}*";
    hier_part_p    = "(${net_path_p}|${abs_path_p})(\\?${query_p})?";
    rel_uri_p  = "(${net_path_p}|${abs_path_p}|${rel_path_p})(\\?${query_p})?";
    abs_uri_p  = "${scheme_p}:(${hier_part_p}|${opaque_part_p})";
    uri_ref_p  = "(${abs_uri_p}|${rel_uri_p})?(#${fragment_p})?";

    flake_id_p = "[[:alpha:]][${word_c}]*";
  };



# ---------------------------------------------------------------------------- #

in character_classes // pseudo_ccs // patterns
