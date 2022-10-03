# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{

  description = "Tests for rime";

  inputs.rime.url = "path:../.";
  inputs.ak-nix.follows = "rime/ak-nix";

# ---------------------------------------------------------------------------- #

  outputs = { self, ak-nix, ...  } @ inputs: let
    tdir = "${inputs.rime or ( toString ../. )}/tests";
    lib = ak-nix.lib.extend ( final: prev: {
      regexps = ( prev.regexps or {} ) // {
        uri = import "${tdir}/../re/uri.nix";
      };
      ytypes = ( prev.ytypes or {} ) //
               ( import "${tdir}/../types/uri.nix" { lib = final; } );
    } );
    url-testing = toString ./data;
    # FIXME:
    checkUrl = x: x;
  in {

    inherit lib;

# ---------------------------------------------------------------------------- #

    data = let
      urlsFromTest = group: let
        proc = acc: x: if ( x ? url ) then acc ++ [x.url] else acc;
        lst = if builtins.isList group.test then group.test else
              builtins.attrNames group.test;
      in builtins.foldl' proc [] lst;
      allTests = json: let
        proc = acc: x: acc ++ ( urlsFromTest x );
      in builtins.foldl' proc [] ( builtins.attrValues json );
    in {
      json = {
        remote = lib.importJSON "${url-testing}/remote.json";
        local  = lib.importJSON "${url-testing}/local.json";
      };
      urls = builtins.mapAttrs ( _: allTests ) self.data.json;
    };


# ---------------------------------------------------------------------------- #

    testUrl = url: let
      e = builtins.tryEval ( checkUrl url );
      v = builtins.deepSeq e e;
    in e // { inherit url; };
    testResults = builtins.mapAttrs ( _: map self.testUrl ) self.data.urls;


# ---------------------------------------------------------------------------- #

    groupResults = results: let
      parted = builtins.partition ( x: x.success ) results;
    in {
      valid   = map ( x: x.value ) parted.right;
      invalid = map ( x: x.url ) parted.wrong;
    };
    groupedResults = builtins.mapAttrs ( _: self.groupResults )
                                       self.testResults;


# ---------------------------------------------------------------------------- #

    extraTests = builtins.mapAttrs ( _: t: assert t.expr == t.expected; t ) {
      testUri_t = {
        expr     = checkUrl "https://google.com";
        expected = "https://google.com";
      };
      testParseRepo = let
        repo = "https://github.com/aakropotkin/rime.git";
      in {
        expr = with lib.parser;
          parseAbsolutePath (
            parseNetworkPath (
              parseHierarchyPart (
                parseAbsoluteUri (
                  parseUriRef url
                ).uri.absolute
              ).part.hierarchy
            ).path.network
          ).path.absolute;
        expected = ["aakropotkin" "rime.git"];
      };
    };


# ---------------------------------------------------------------------------- #

    packages = lib.eachDefaultSystemMap ( system: let
      pkgsFor = ak-nix.inputs.nixpkgs.legacyPackages.${system};
    in {
      tests = let
        extra = builtins.deepSeq self.extraTests;
        drv   = pkgsFor.writeText "results.json"
                ( lib.generators.toPretty {} self.groupedResults );
      in extra drv;
    } );


# ---------------------------------------------------------------------------- #

  };  # End Outputs

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
