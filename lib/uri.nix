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
    name   = "UriScheme";
    isType = defun [any bool] ( scheme_t.check );

    # string[scheme] -> attrs[scheme]
    # Parser
    fromString = let
      inner = str: let
        splitLayers = builtins.match "(([^+]+)\\+)?([^+]+)?" str;
      in {
        transport = builtins.elemAt splitLayers 2;
        data      = builtins.elemAt splitLayers 1;
      };
    in defun [string Struct.scheme] inner;

    # <attrs|string>[scheme] -> string[scheme]
    # Writer
    toString = let
      inner = x:
        if builtins.isString x then x else
        if ( x.data or null ) == null then x.transport else
        "${x.data}+${x.transport}";
    in defun [scheme_t string] inner;

    # attrs<attrs[scheme]|string[scheme]> -> attrs[scheme](full)
    # Deserializer
    fromAttrs = let
      inner = a:
        if ( a ? scheme ) then UriScheme.mk a.scheme else
        if ( a ? val )    then UriScheme.mk a.val else
        { data = null; } // a;
    in defun [(attrs any) Struct.scheme] inner;

    # <attrs|string>[scheme] -> attrs[scheme](min)
    # Serializer
    toAttrs = let
      inner = x: let
        asAttrs = if builtins.isAttrs x then UriScheme.fromAttrs x else
                  UriScheme.fromString x;
      in lib.filterAttrs ( _: v: v != null ) asAttrs;
    in defun [scheme_t Struct.scheme] inner;

    # <attrs|string>[scheme] -> attrs[scheme](full)
    mk = let
      inner = x: UriScheme.fromAttrs ( UriScheme.toAttrs x );
    in defun [scheme_t Struct.scheme] inner;

    # <attrs|string>[scheme] -> object[UriScheme]
    # "Constructor"
    __functor = self: x: {
      _type      = "UriScheme";
      val        = self.mk x;
      __toString = child: self.toString child.val;
      __serial   = child: self.toAttrs  child.val;
      __vtype    = Struct.scheme;
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
