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
  inherit (libyants) defun string either;

# ---------------------------------------------------------------------------- #

  # scheme

  UriScheme = {
    name   = "UriScheme";
    isType = with libyants; defun [any bool] ( UriScheme.ytype.check );
    ytype  = either ut.Strings.scheme ut.Structs.scheme;
    # Parser
    fromString = lib.parser.parseScheme;
    # Writer
    toString = let
      inner = x:
        if builtins.isString x then x else
        if ( x.data or null ) == null then x.transport else
        "${x.data}+${x.transport}";
    in defun [UriScheme.ytype string] inner;
    # Deserializer
    fromAttrs = let
      inner = a: { inherit (a) transport; data = a.data or null; };
    in defun [( with libyants; attrs any ) ut.Structs.scheme] inner;
    # Serializer
    toAttrs = let
      inner = x:
        lib.filterAttrs ( _: v: v != null ) ( UriScheme.coerceUriScheme x );
    in defun [UriScheme.ytype ut.Structs.scheme] inner;
    # Coercer
    coerceUriScheme = let
      inner = x: let
        t = lib.libtag.verifyTag x;
        s = if builtins.isString x then x else
            if t.isTag && ( t.name == "scheme" ) then t.val else ( x.val or x );

      in if builtins.isString s then UriScheme.fromString s else
         UriScheme.fromAttrs s;
    in defun [( either string ( with libyants; attrs any ) ) ut.Structs.scheme]
             inner;
    # Object Constructor
    __functor = self: x: {
      _type      = self.name;
      val        = self.coerceUriScheme x;
      __toString = child: self.toString child.val;
      __serial   = child: self.toAttrs  child.val;
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
