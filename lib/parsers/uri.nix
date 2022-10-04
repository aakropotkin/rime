# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt      = lib.libyants;
  regexps = import ../../re/uri.nix;
  pats    = regexps.patterns;
  ccs     = regexps.character_classes // regexps.pseudo_ccs;
  tpat'   = name: pname: yt.restrict name ( lib.test pats.${pname} ) yt.string;
  tpat    = name: tpat' name "${name}_p";
  ut      = lib.ytypes.Uri;
  uts     = ut.Strings;
  inherit (yt) defun;

# ---------------------------------------------------------------------------- #

  parseUriRef = let
    uri_ref = yt.struct "uri_ref" {
      uri      = ut.Sums.uri;
      fragment = yt.option ( tpat "fragment" );
    };
    inner = str: let
      m = builtins.match "([^#]+)(#(.*))?" str;
    in {
      uri = lib.discr [
        { absolute = uts.abs_uri.check; }  # https://example.com/index.html
        { relative = uts.rel_uri.check; }  # 192.168.88.1/index.html
      ] ( builtins.head m );
      fragment = builtins.elemAt m 2;
    };
  in defun [uts.uri_ref uri_ref] inner;


# ---------------------------------------------------------------------------- #

  parseAbsoluteUri = let
    abs_uri = yt.struct "abs_uri" {
      scheme = uts.scheme;
      part   = yt.sum "part" {
        hierarchy = uts.hier_part;
        opaque    = uts.opaque_part;
      };
    };
    inner = str: let
      m = builtins.match "(${pats.scheme_p}):(.*)" str;
    in {
      scheme = builtins.head m;
      part = lib.discr [
        { hierarchy = uts.hier_part.check; }
        { opaque    = uts.opaque_part.check; }
      ] ( builtins.elemAt m 1 );
    };
  in defun [uts.abs_uri abs_uri] inner;


# ---------------------------------------------------------------------------- #

  parseHierarchyPart = let
    hier_part = yt.struct "hier_part" {
      path = yt.sum "hier_path" {
        absolute = uts.abs_path;
        network  = uts.net_path;
      };
      query = yt.option uts.query;
    };
    inner = str: let
      m = builtins.match "([^?]+)(\\?(.*))?" str;
    in {
      query = builtins.elemAt m 2;
      path = lib.discr [
        { network  = uts.net_path.check; }
        { absolute = uts.abs_path.check; }
      ] ( builtins.head m );
    };
  in defun [uts.hier_part hier_part] inner;


# ---------------------------------------------------------------------------- #

  parseNetworkPath = let
    net_path = yt.struct "net_path" {
      authority = uts.authority;
      path = yt.option ( yt.sum { absolute = uts.abs_path; } );
    };
    inner = str: let
      m = builtins.match "//([^/]+)(/.*)?" str;
      p  = builtins.elemAt m 1;
      pa = if p == null then null else { absolute = p; };
    in {
      authority = builtins.head m;
      path = pa;
    };
  in defun [uts.net_path net_path] inner;


# ---------------------------------------------------------------------------- #

  # NOTE: don't assume "//" implies a network path unless you see an authority.
  # Without context you cannot use "^//.*" vs "^/.*" to distinguish between
  # absolute and network paths, because "https://foo.com////bar" is just as
  # valid as "file:////bar" - without the context of the authority portion you
  # can't know which it is.
  parseAbsolutePath = let
    abs_path = yt.list uts.segment;
    inner = str: let
      segs = builtins.filter builtins.isString ( builtins.split "/" str );
    in builtins.tail segs;
  in defun [uts.abs_path abs_path] inner;


# ---------------------------------------------------------------------------- #

  parseServer = let
    # NOTE: server may be omitted completely, implying localhost.
    # For example, `file:/usr/bar.txt' vs. `file:foo@127.0.0.1/usr/bar.txt'.
    server = yt.struct "server" {
      userinfo = yt.option uts.userinfo;
      hostport = uts.hostport;
    };
    inner = str: let
      m = builtins.match "(([^@]+)@)?([^:]+(:[[:digit:]]*)?)" str;
    in if m == null then null else {
      userinfo = builtins.elemAt m 1;
      hostport = builtins.elemAt m 2;
    };
  in defun [uts.server ( yt.option server )] inner;


# ---------------------------------------------------------------------------- #

  parseHostPort = let
    inner = str: let
      hps = "((${pats.hostname_p})|(${pats.ipv4_addr_p})|${pats.ipv6_addr_p})";
      m = builtins.match "${hps}(:([[:digit:]]*))?" str;
    in {
      host = lib.discr [
        { hostname = uts.hostname.check; }
        { ip_addr  = uts.ip_addr.check; }
      ] ( builtins.head m );
      # Last capture is the port.
      port = builtins.elemAt m ( ( builtins.length m ) - 1 );
    };
  in defun [uts.hostport ( yt.option ut.Structs.hostport )] inner;


# ---------------------------------------------------------------------------- #

  parseScheme = let
    inner = str: let
      m = builtins.match "(([^+]+)\\+)?([^+]+)?" str;
    in {
      transport = builtins.elemAt m 2;
      data      = builtins.elemAt m 1;
    };
  in defun [uts.scheme ut.Structs.scheme] inner;


# ---------------------------------------------------------------------------- #

  parseFullUrl = let
    inner = str: let
      # { fragment, uri.absolute }
      uri_ref = parseUriRef str;
      # { part.hierarchy, scheme : String }
      abs_uri = parseAbsoluteUri uri_ref.uri.absolute;
      # { path.(absolute|network), query : String }
      hier_part = parseHierarchyPart abs_uri.part.hierarchy;
      # { authority, path.absolute }
      net_path  = parseNetworkPath hier_part.path.network;
    in {
      scheme    = parseScheme abs_uri.scheme;
      authority = if ! ( hier_part.path ? network ) then null else
                  net_path.authority;
      path = if hier_part.path ? network then net_path.path.absolute else
             hier_part.path.absolute;
      query = if hier_part.query == null then null else
              parseQuery hier_part.query;
      fragment = uri_ref.fragment;
    };
  in defun [uts.uri_ref ut.Structs.url] inner;


# ---------------------------------------------------------------------------- #

  parseQuery = let
    inner = str: let
      params = builtins.filter builtins.isString ( builtins.split "&" str );
      toKv = p: let
        m = builtins.match "([^=]+)(=([^=]*))?" p;
      in { name  = builtins.head m; value = builtins.elemAt m 2; };
      asAttrs = builtins.listToAttrs ( map toKv params );
    in if str == "" then {} else asAttrs;
  in defun [uts.query ut.Attrs.params] inner;


# ---------------------------------------------------------------------------- #

in {
  inherit
    parseUriRef
    parseAbsoluteUri
    parseHierarchyPart
    parseNetworkPath
    parseAbsolutePath
    parseServer
    parseHostPort
    parseScheme
    parseFullUrl
    parseQuery
  ;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
