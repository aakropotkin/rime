# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  pats = lib.regexps.uri.patterns;
  ut   = lib.ytypes.Uri;
  yt   = lib.libyants;

# ---------------------------------------------------------------------------- #

  # scheme

  UriScheme = {
    name   = "UriScheme";
    isType = with yt; defun [any bool] ( UriScheme.ytype.check );
    ytype  = yt.either ut.Strings.scheme ut.Structs.scheme;
    # Converters.  X.<from>.<to>
    X = lib.libtypes.defXTypes {
      # Type pool for conversions "<from>.<to>" ids.
      inherit (yt) any;
      string = ut.String.scheme;
      attrs  = ut.Struct.scheme;
      this   = UriScheme.ytype;
    } {
      # Parser
      string.this = str: let
        splitLayers = builtins.match "(([^+]+)\\+)?([^+]+)?" str;
      in {
        transport = builtins.elemAt splitLayers 2;
        data      = builtins.elemAt splitLayers 1;
      };
      # Writer
      this.string = x:
        if builtins.isString x then x else
        if ( x.data or null ) == null then x.transport else
        "${x.data}+${x.transport}";
      # Deserializer
      attrs.this = a: let
        scheme = a.scheme or a;
        full = if a ? transport then a else
               if scheme ? transport then scheme else
               assert builtins.isString scheme; UriScheme.X.string.this scheme;
      in { inherit (full) transport; data = full.data or null; };
      # Serializer
      this.attrs = x: let
        asAttrs = if builtins.isAttrs x then UriScheme.X.attrs.this x else
                  UriScheme.X.string.this x;
      in lib.filterAttrs ( _: v: v != null ) asAttrs;
      # Coercer
      any.this = x: UriScheme.X.attrs.this ( UriScheme.X.this.attrs x );
    };
    # Object Constructor
    __functor = self: x: {
      _type      = "UriScheme";
      val        = self.X.any.this x;
      __toString = child: self.X.this.string child.val;
      __serial   = child: self.X.this.attrs  child.val;
      __vtype    = self.ytype;
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
