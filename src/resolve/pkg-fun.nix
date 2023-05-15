# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ stdenv, nix, boost, nlohmann_json, pkg-config }: stdenv.mkDerivation {
  pname   = "resolve";
  version = "0.1.0";
  src     = builtins.path {
    path   = ./.;
    filter = name: type: ! ( builtins.elem ( baseNameOf name ) [
      "result" "result-dev" "result-man" "result-info" "result-lib" "result-bin"
      ".gitignore"
      "Makefile"
    ] );
  };
  nativeBuildInputs     = [pkg-config];
  buildInputs           = [nix.dev boost nlohmann_json];
  dontConfigure         = true;
  buildPhase            = ''
    $CXX                                                                       \
      -I${nix.dev}/include                                                     \
      -I${nix.dev}/include/nix                                                 \
      -I${boost.dev}/include                                                   \
      -I${nlohmann_json}/include                                               \
      -include ${nix.dev}/include/nix/config.h                                 \
      $(pkg-config --libs --cflags nix-main nix-store nix-expr)                \
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
