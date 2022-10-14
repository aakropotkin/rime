# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt = lib.ytypes.Prim // lib.ytypes.Core;
  ut = lib.ytypes.Uri;
  inherit (lib.ytypes.Core) defun either;
  inherit (lib.ytypes.Prim) string;

# ---------------------------------------------------------------------------- #

  # scheme

  UriScheme = {
    name   = "UriScheme";
    isType = defun [yt.any yt.bool] UriScheme.ytype.check;
    ytype  = either ut.Strings.scheme ut.Structs.scheme;
    # Parser
    fromString = lib.liburi.parseScheme;
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
    in defun [( yt.attrs yt.any ) ut.Structs.scheme] inner;
    # Serializer
    toAttrs = let
      inner = x:
        lib.filterAttrs ( _: v: v != null ) ( UriScheme.coerce x );
    in defun [UriScheme.ytype ut.Structs.scheme] inner;
    # Coercer
    coerce = let
      inner = x: let
        t = lib.libtag.verifyTag x;
        s = if builtins.isString x then x else
            if t.isTag && ( t.name == "scheme" ) then t.val else ( x.val or x );
      in if builtins.isString s then UriScheme.fromString s else
         UriScheme.fromAttrs s;
    in defun [( either string ( yt.attrs yt.any ) ) ut.Structs.scheme]
             inner;
    # Object Constructor
    __functor = self: x: {
      _type      = self.name;
      val        = self.coerce x;
      __toString = child: self.toString child.val;
      __serial   = child: self.toAttrs  child.val;
      __vtype    = self.ytype;
    };
  };


# ---------------------------------------------------------------------------- #

  Url = {
    name = "Url";
    isType = defun [yt.any yt.bool] Url.ytype.check;
    ytype = either ut.Strings.uri_ref ut.Structs.url;
    # Writer
    toString = let
      inner = x: let
        auth = if ( x.authority or null ) == null then "" else
               "/${x.authority}";
        # FIXME: query lacks toString
        q = if ( x.query or null ) != null then "?${x.query}" else "";
        frag = if ( x.fragment or null ) == null then "" else
               "#${x.fragment}";
        mp = if ( x.path or null ) == null then "" else x.path;
        fa = "${UriScheme.toString x.scheme}:${auth}${mp}${q}${frag}";
      in if builtins.isString x then x else fa;
    in defun [Url.ytype ut.Strings.uri_ref] inner;
    # Deserializer
    #fromAttrs = a: null;
    # Serializer
    #toAttrs = x: null;

    # Coercer
    # FIXME: use some cleanup shit from the parser to destruct the parsed trees
    coerce = x: if builtins.isString x then Url.fromString x else x;

    # Parser ( already wrapped with type checking )
    fromString = lib.liburi.parseFullUrl;
    # Object Constructor
    __functor = self: x: {
      _type      = self.name;
      val        = self.coerce x;
      __toString = child: self.toString child.val;
      #__serial   = child: self.toAttrs child.val;
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
