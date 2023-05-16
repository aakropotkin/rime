
#include <string>

#include <nix/shared.hh>
#include <nix/eval.hh>
#include <nix/eval-inline.hh>
#include <nix/flake/flake.hh>
#include <nix/store-api.hh>

#include <nlohmann/json.hpp>

  int
main( int argc, char * argv[], char ** envp )
{
  nix::initNix();
  nix::initGC();

  nix::evalSettings.pureEval = false;

  nix::EvalState state( {}, nix::openStore() );

  nix::FlakeRef originalRef =
    nix::parseFlakeRef( argv[1], nix::absPath( "." ) );

  nix::FlakeRef resolvedRef = originalRef.resolve( state.store );
  
  std::cout << resolvedRef.to_string() << std::endl;

  return 0;
}
