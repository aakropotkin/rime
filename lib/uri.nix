# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  inherit (lib.ytypes)
    git_types
    uri_types
    scheme_t
    url_t
  ;

  inherit (lib.regexps.uri) patterns;

# ---------------------------------------------------------------------------- #

  # scheme

  #mkUriScheme = args: let
  #  checked   = scheme_t args;
  #  sps       = builtins.match "(([^+]+)\\+)?([^+]+)?" checked;
  #  asAttrs   =
  #    uri_types.attrs_ts.scheme {
  #      transport = transport_scheme_t ( builtins.elemAt sps 2 );
  #      data      = data_scheme_t ( builtins.elemAt sps 1 );
  #    };
  #in asAttrs // { __toString = self: "${self.data}+${self.transport}"; };


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
    #mkUriScheme
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
