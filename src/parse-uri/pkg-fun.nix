# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ stdenv, nix, boost, nlohmann_json }: stdenv.mkDerivation {
  pname             = "nix-parse-uri";
  version           = "0.1.0";
  src               = builtins.path { path = ./.; };
  buildInputs       = [nix nix.dev boost nlohmann_json];
  dontConfigure     = true;
  buildPhase        = ''
    $CC -x c++                      \
        -std=c++17                  \
        -I${nix.dev}/include        \
        -I${boost.dev}/include      \
        -I${nlohmann_json}/include  \
        -L${nix}/lib                \
        -lnixutil                   \
        -lstdc++                    \
        -o "$pname"                 \
        ./main.cc                   \
    ;
  '';
  installPhase = ''
    mkdir -p "$out/bin";
    mv "./$pname" "$out/bin/$pname";
  '';
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
