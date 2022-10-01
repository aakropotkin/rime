{

  inputs.rime.url = "path:../.";
  #inputs.url-testing.url = "github:cweb/url-testing";
  #inputs.url-testing.flake = false;

  outputs = { self, rime, ...  } @ inputs: let
    inherit (rime) lib;
    url-testing = toString ./data;
  in with lib.ytypes.uri_str_types; {

    data = let
      urlsFromTest = group: let
        proc = acc: x:
          if ( x ? url ) && ( ! ( lib.test ".*<UNI>.*" x.url ) )
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
        remote = lib.importJSON "${url-testing}/urls.json";
        local  = lib.importJSON "${url-testing}/urls-local.json";
      };
      urls = builtins.mapAttrs ( _: allTests ) self.data.json;
    };

    testUrl = url: let
      e = builtins.tryEval ( uri_t url );
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
