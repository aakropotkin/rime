{

  inputs.rime.url = "path:../.";
  inputs.url-testing.url = "github:cweb/url-testing";
  inputs.url-testing.flake = false;

  outputs = { self, rime, url-testing, ...  } @ inputs: {

    inherit (rime) lib;

    data = let
      jsonClean = f: let
        r = {
          "\r" = "";
          "\n" = "";
          "\\\\\\u597D" = "<EVIL>";
        };
        killUni = str: let
          s = builtins.split "(\\\\)u[[:xdigit:]]" str;
          proc = acc: x: if builtins.isList x then acc + "<UNI>" else acc + x;
        in builtins.foldl' proc "" s;
        rep = builtins.replaceStrings ( builtins.attrNames r )
                                      ( builtins.attrValues r );
      in builtins.fromJSON ( rep ( killUni ( builtins.readFile f ) ) );
      urlsFromTest = group: let
        proc = acc: x:
          if ( x ? url ) && ( ! ( self.lib.test ".*<UNI>.*" x.url ) )
          then acc ++ [x.url]
          else acc;
        lst = if builtins.isList group.test then group.test else
              builtins.attrNames group.test;
      in builtins.foldl' proc [] lst;
      allTests = json: let
        proc = acc: x: acc ++ ( urlsFromTest x );
      in builtins.foldl' proc [] json.tests.group;
    in {
      json = {
        remote = jsonClean "${url-testing}/urls.json";
        local  = jsonClean "${url-testing}/urls-local.json";
      };
      urls = builtins.mapAttrs ( _: allTests ) self.data.json;
    };

    testUrl = url: let
      e = builtins.tryEval ( self.lib.ytypes.uri_str_types.uri_t url );
      v = builtins.deepSeq e e;
    in e // { inherit url; };
    testResults = builtins.mapAttrs ( _: map self.testUrl ) self.data.urls;

    groupResults = results: let
      parted = builtins.partition ( x: x.success ) results;
    in {
      valid = map ( x: x.value ) parted.right;
      invalid = map ( x: x.url ) parted.wrong;
    };
    groupedResults = builtins.mapAttrs ( _: self.groupResults )
                                       self.testResults;

  };

}
