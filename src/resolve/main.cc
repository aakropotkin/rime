
#include <iostream>
#include <cstdlib>
#include <cstring>
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

  bool isJSONArg = strchr( argv[1], '{' ) != nullptr;

  nlohmann::json rawInput =
    isJSONArg ? nlohmann::json::parse( argv[1] ) : argv[1];

  try
    {
      nix::FlakeRef originalRef =
        isJSONArg ? nix::FlakeRef::fromAttrs(
                      nix::fetchers::jsonToAttrs( rawInput )
                    )
                  : nix::parseFlakeRef( argv[1], nix::absPath( "." ) );

      nix::FlakeRef resolvedRef = originalRef.resolve( state.store );

      nlohmann::json j = nlohmann::json {
        { "input", std::move( rawInput ) }
      , { "originalRef", {
          { "string", originalRef.to_string() }
        , { "attrs",  nix::fetchers::attrsToJSON( originalRef.toAttrs() ) }
        } }
      , { "resolvedRef", nlohmann::json {
          { "string", resolvedRef.to_string() }
        , { "attrs",  nix::fetchers::attrsToJSON( resolvedRef.toAttrs() ) }
        } }
      };

      std::cout << j.dump() << std::endl;
    }
  catch( std::exception & e )
    {
      std::cerr << e.what() << std::endl;
      return EXIT_FAILURE;
    }

  return EXIT_SUCCESS;
}
