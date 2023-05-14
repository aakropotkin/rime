
#include <cstddef>
#include <iostream>
#include <string>
#include <nix/url.hh>
#include <nlohmann/json.hpp>

  int
main( int argc, char * argv[], char ** envp )
{
  for ( int i = 1; i < argc; i++ )
    {
      nix::ParsedURL       url    = nix::parseURL( argv[i] );
      nix::ParsedUrlScheme scheme = nix::parseUrlScheme( url.scheme );
      auto                 res    = nlohmann::json::object();
    
      res["base"]      = url.base;
      res["scheme"]    = url.scheme;
      res["authority"] = url.authority.value_or( "" );
      res["path"]      = url.path;
      res["fragment"]  = url.fragment;
      res["query"]     = nlohmann::json::object();
    
      for ( const auto & e : url.query )
        {
          res["query"][e.first] = e.second;
        }
    
      res["application-layer"] = scheme.application.value_or( "" );
      res["translport-layer"]  = scheme.transport;
      std::cout << res.dump() << std::endl;
    }
  return 0;
}
