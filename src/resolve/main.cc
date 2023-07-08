
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

  nlohmann::json       rawInput      = nlohmann::json();
  nix::fetchers::Input originalInput;

  // TODO: handle `baseDir'

  try
    {
      rawInput = nlohmann::json::parse( argv[1] );
      originalInput = nix::fetchers::Input::fromAttrs(
        nix::fetchers::jsonToAttrs( rawInput )
      );
    }
  catch( nix::BadURL & b )
    {
      try
        {
          originalInput = nix::parseFlakeRef(
            rawInput, nix::absPath( "." )
          ).input;
        }
      catch( nix::BadURL & b )
        {
          std::cerr << b.what() << std::endl;
          throw b;
        }
    }
  catch( ... )
    {
      rawInput = argv[1];
      try
        {
          originalInput = nix::fetchers::Input::fromURL( rawInput );
        }
      catch( nix::BadURL & b )
        {
          try
            {
              originalInput = nix::parseFlakeRef(
                rawInput, nix::absPath( "." )
              ).input;
            }
          catch( nix::BadURL & b )
            {
              std::cerr << b.what() << std::endl;
              throw b;
            }
        }
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

  nix::FlakeRef originalRef = nix::parseFlakeRef(
    originalInput.to_string(), nix::absPath( "." )
  );
  nix::FlakeRef resolvedRef = originalRef.resolve( state.store );

  nlohmann::json j = nlohmann::json {
    { "input", std::move( rawInput ) }
  , { "originalRef", {
      { "string", originalInput.to_string() }
    , { "attrs",  nix::fetchers::attrsToJSON( originalInput.toAttrs() ) }
    } }
  , { "resolvedRef", nlohmann::json {
      { "string", resolvedRef.to_string() }
    , { "attrs",  nix::fetchers::attrsToJSON( resolvedRef.toAttrs() ) }
    } }
  };

  std::cout << j.dump() << std::endl;

  return 0;
}
