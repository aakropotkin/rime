
#include <cstddef>
#include <iostream>
#include <string>

#include <nix/url.hh>
#include <nix/shared.hh>
#include <nix/eval.hh>
#include <nix/eval-inline.hh>
#include <nix/flake/flake.hh>
#include <nix/get-drvs.hh>
#include <nix/store-api.hh>
#include <nix/derivations.hh>
#include <nix/outputs-spec.hh>
#include <nix/attr-path.hh>
#include <nix/fetchers.hh>
#include <nix/registry.hh>
#include <nix/eval-cache.hh>
#include <nix/markdown.hh>
#include <nix/command.hh>
#include <nix/store-api.hh>
#include <nix/local-fs-store.hh>
#include <nix/nixexpr.hh>

#include <nlohmann/json.hpp>

using namespace nix;

  int
main( int argc, char * argv[], char ** envp )
{
  initNix();
  initGC();

  evalSettings.pureEval = false;

  EvalState state( {}, openStore() );

  auto originalRef = parseFlakeRef( argv[1], absPath( "." ) );
  auto resolvedRef = originalRef.resolve( state.store );
  
  std::cout << resolvedRef.to_string() << std::endl;

  return 0;
}
