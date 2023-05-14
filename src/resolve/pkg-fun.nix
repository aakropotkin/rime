# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ stdenv, bash, nix, boost, nlohmann_json }: stdenv.mkDerivation {
  pname                 = "resolve";
  version               = "0.1.0";
  src                   = builtins.path { path = ./.; };
  buildInputs           = [nix nix.dev boost nlohmann_json];
  propagatedBuildInputs = [bash nix];
  dontConfigure         = true;
  libExt                = stdenv.hostPlatform.extensions.sharedLibrary;
  buildPhase            = ''
    $CC                                                                        \
      -x c++                                                                   \
      -std=c++17                                                               \
      -I${nix.dev}/include                                                     \
      -I${nix.dev}/include/nix                                                 \
      -I${boost.dev}/include                                                   \
      -I${nlohmann_json}/include                                               \
      -L${nix}/lib                                                             \
      -lnixutil                                                                \
      -lnixstore                                                               \
      -lnixcmd                                                                 \
      -lnixexpr                                                                \
      -lnixmain                                                                \
      -lstdc++                                                                 \
      -include ${nix.dev}/include/nix/config.h                                 \
      -o "$pname"                                                              \
      ${if stdenv.isDarwin then "-undefined suppress -flat_namespace" else ""} \
      ./main.cc                                                                \
    ;
  '';
  installPhase = ''
    mkdir -p "$out/bin";
    mv -- "./$pname" "$out/bin/$pname";
  '';
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
