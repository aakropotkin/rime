
#include <string>

#include <nix/shared.hh>
#include <nix/eval.hh>
#include <nix/eval-inline.hh>
#include <nix/flake/flake.hh>
#include <nix/store-api.hh>

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
