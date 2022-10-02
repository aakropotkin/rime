# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  inherit (lib.regexps.uri) patterns;
  inherit (lib.ytypes.uri)
    String Either Struct
    scheme_t
    url_t
  ;
  yt = lib.libyants;


# ---------------------------------------------------------------------------- #

  # scheme

  UriScheme = with yt; {
    # string[scheme] -> attrs[scheme]
    parse = let
      inner = str: let
        splitLayers = builtins.match "(([^+]+)\\+)?([^+]+)?" str;
      in {
        transport = builtins.elemAt splitLayers 2;
        data      = builtins.elemAt splitLayers 1;
      };
    in defun [string Struct.scheme] inner;

    # <attrs|string>[scheme] -> string
    toString = let
      inner = scheme:
        if builtins.isString scheme then scheme else
        if ( scheme.data or null ) == null then scheme.transport else
        "${scheme.data}+${scheme.transport}";
    in defun [scheme_t string] inner;

    # <attrs|string>[scheme] -> attrs[scheme]
    toAttrs = let
      inner = x: let
        asAttrs = if builtins.isString x then UriScheme.parse x else x;
      in lib.filterAttrs ( _: x: x != null ) asAttrs;
    in defun [scheme_t Struct.scheme] inner;

    # <attrs|string>[scheme] -> object[UriScheme]
    __functor = self: x: {
      _type = "UriScheme";
      val   = self.toAttrs x;
      __toString = child: self.toString child.val;
      __serial   = child: self.toAttrs  child.val;
    };
  };


# ---------------------------------------------------------------------------- #

  #  __toString = self: let
  #    auth = if ( self.authority or null ) == null then "" else
  #           "//${self.authority}";
  #    q = if ( self.query or null ) != null then "?${self.query}" else "";
  #    frag = if ( self.fragment or null ) == null then "" else
  #           "#${self.fragment}";
  #    mp = if ( self.path or null ) == null then "" else self.path;
  #  in "${self.scheme}:${auth}${mp}${q}${frag}";
  #
  #  __functor = self: value: let
  #    result  = self.checkType value;
  #    checked = if self.checkToBool result then value else
  #              throw ( self.toError value result );
  #    sps = builtins.split "(://|[:?#])" checked;
  #    asAttrs = let
  #      auth = let
  #        m = builtins.match "([^/:]+)(/.*)?" ( builtins.elemAt sps 2 );
  #        ma = if ( builtins.head m ) == null then {} else {
  #          authority = uri_str_types.authority_str_t ( builtins.head m );
  #        };
  #        mp = if ( builtins.elemAt m 1 ) == null then {} else {
  #          path = uri_str_types.path_str_t ( builtins.elemAt m 1 );
  #        };
  #      in if ( builtins.elemAt sps 1 ) != ["://"] then {
  #        path = uri_str_types.path_str_t ( builtins.elemAt sps 2 );
  #      } else mp // ma;
  #    in if builtins.isAttrs checked then checked else st {
  #      scheme = uri_str_types.scheme_str_t ( builtins.head sps );
  #    } // auth;
  #    postPath = let
  #      m = builtins.match "[^?#]+(\\?([^#]+))?(#(.*))?" checked;
  #      mq = if ( builtins.head m ) == null then {} else {
  #        query = uri_str_types.query_str_t ( builtins.elemAt m 1 );
  #      };
  #      mf = if ( builtins.elemAt m 2 ) == null then {} else {
  #        query = uri_str_types.query_str_t ( builtins.elemAt m 3 );
  #      };
  #    in if ( builtins.length sps ) < 4 then {} else mq // mf;
  #    url = if builtins.isString checked then checked else __toString asAttrs;
  #  in asAttrs // {
  #    base =lib.yank "([^?]+)(\\?.*)?" url;
  #    inherit __toString url;
  #  };



# ---------------------------------------------------------------------------- #

in {
  inherit
    UriScheme
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
