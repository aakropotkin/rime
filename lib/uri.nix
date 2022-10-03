# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ ytypes   ? lib.ytypes
, libyants ? lib.libyants
, regexps  ? lib.regexps or ( import ../re/uri.nix )
, lib
, ...
}: let

  pats = lib.regexps.uri.patterns;
  ut   = ytypes.Uri or ( import ../types/uri.nix { inherit lib; } );

# ---------------------------------------------------------------------------- #

  # scheme

  UriScheme = {
    name   = "UriScheme";
    isType = with libyants; defun [any bool] ( UriScheme.ytype.check );
    ytype  = libyants.either ut.Strings.scheme ut.Structs.scheme;
    # Converters.  X.<from>.<to>
    X = lib.libtypes.defXTypes {
      # Type pool for conversions "<from>.<to>" ids.
      inherit (libyants) any;
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

  Url = {
    name = "Url";
    isType = with libyants; defun [any bool] ( Url.ytype.check );
    ytype = libyants.either ut.Strings.uri ut.Structs.url;
    X = ( lib.libtypes.defXTypes {
      inherit (libyants) any;
      string = ut.Strings.uri;
      attrs  = ut.Structs.url;
      this   = Url.ytype;
    } {

      # Writer
      this.string = x: let
        auth = if ( x.authority or null ) == null then "" else
               "/${x.authority}";
        q = if ( x.query or null ) != null then "?${x.query}" else "";
        frag = if ( x.fragment or null ) == null then "" else
               "#${x.fragment}";
        mp = if ( x.path or null ) == null then "" else x.path;
      in "${x.scheme}:${auth}${mp}${q}${frag}";

      # Deserializer
      #attrs.this = a: null;

      # Serializer
      #this.attrs = x: null;

      # Coercer
      #any.this = x: null;
    } ) // {
      # Parser ( already wrapped with type checking )
      string.this = lib.parser.parseFullUrl;
    };
    # Object Constructor
    __functor = self: x: {
      _type      = "Url";
      val        = self.X.any.this x;
      __toString = child: self.X.this.string child.val;
      #__serial   = child: self.X.this.attrs  child.val;
      __vtype    = self.ytype;
    };
  };



# ---------------------------------------------------------------------------- #

in {
  inherit
    UriScheme
    Url
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
