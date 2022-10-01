{

  inputs.rime.url = "path:../.";
  inputs.url-testing.url   = "https://github.com/cweb/url-testing";
  inputs.url-testing.flake = false;

  outputs = { self, rime, url-testing, ...  } @ inputs: {

    inherit (rime) lib;

    data = {
      urls       = self.lib.importJSON "${url-testing}/urls.json";
      urls-local = self.lib.importJSON "${url-testing}/urls-local.json";
    };

  };

}
