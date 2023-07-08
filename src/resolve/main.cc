
#include <string>
#include <optional>

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

  nlohmann::json input = nlohmann::json();
  std::optional<nix::FlakeRef> originalRef = std::nullopt;

  try
    {
      input = nlohmann::json::parse( argv[1] );
      originalRef = nix::FlakeRef::fromAttrs(
        nix::fetchers::jsonToAttrs( input )
      );
    }
  catch( ... )
    {
      input       = argv[1];
      originalRef = nix::parseFlakeRef( argv[1], nix::absPath( "." ) );
    }

  /**
   * {
   *   "input":  <STR|ATTRS>
   * , "originalRef": {
   *     "string": <STR>
   *   , "attrs":  <ATTRS>
   *   }
   * , "resolvedRef": {
   *     "string": <STR>
   *   , "attrs":  <ATTRS>
   *   }
   * }
   */

  nix::FlakeRef resolvedRef = originalRef.value().resolve( state.store );

  nlohmann::json j = {
    { "input", std::move( input ) }
  , { "originalRef", nlohmann::json {
      { "string", originalRef.value().to_string() }
    , { "attrs",  nix::fetchers::attrsToJSON( originalRef.value().toAttrs() ) }
    } }
  , { "resolvedRef", nlohmann::json {
      { "string", resolvedRef.to_string() }
    , { "attrs",  nix::fetchers::attrsToJSON( resolvedRef.toAttrs() ) }
    } }
  };

  std::cout << j.dump() << std::endl;

  return 0;
}
