# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib, bash, coreutils, gnutar, gzip, gawk, gnugrep, system }: let

  yt = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;

# ---------------------------------------------------------------------------- #

  # TODO: use a raw derivation
  checkTarballPermsDrv = {
    src
  , name ? let
      parsed   = lib.libstr.nameFromTarballUrl ( lib.baseName' src );
    in if yt.FS.Strings.store_filename.check parsed then parsed else "source"
  }: lib.lazyDerivation {
    derivation = derivation {
      name = "check-perms--${name}";
      PATH = "${gzip}/bin";
      TAR  = "${gnutar}/bin/tar";
      AWK  = "${gawk}/bin/awk";
      GREP = "${gnugrep}/bin/grep";
      CAT  = "${coreutils}/bin/cat";
      outputs = ["out"];
      inherit src system;
      builder = "${bash}/bin/bash";
      args = ["-c" ''
        $TAR tzvf "$src"|$AWK '{ print $1, $2, $4, $5, $6; }' > ./perms;
        if $GREP '^d..-' ./perms; then
          printf FAIL > "$out";
        else
          printf PASS > "$out";
        fi
        echo '---' >> "$out";
        $CAT ./perms >> "$out";
      ''];
      preferLocalBuild = true;
      allowSubstitutes = ( builtins.currentSystem or null ) != system;
    };
    passthru.bname = name;
  };


# ---------------------------------------------------------------------------- #

  checkTarballPerms' = { pure ? lib.inPureEvalMode }: {
    __functionMeta = {
      name = "checkTarballPerms";
      from = "rime#util";
      properties = {
        inherit pure;
        ifd   = true;
        funkT = "pargs-std";  # required with `stdProcessArgsFunctor'.
      };
      signature = let
        arg0_fields = {
          src     = yt.Typeclasses.store_pathlike;
          url     = yt.Uri.Strings.uri_ref;
          name    = yt.option yt.FS.Strings.store_filename;
          checker = yt.option yt.function;
          narHash = yt.Hash.nar_hash;
        };
        withSrc = yt.struct ( lib.applyFields {
          url     = yt.option;
          narHash = yt.option;
        } arg0_fields );
        withUrl =
          yt.struct ( lib.applyFields { src = yt.option; } arg0_fields );
        arg0 = yt.either withSrc withUrl;
      in [arg0 ( yt.attrs yt.any )];
      doc = let
        pi = if pure then "pure" else "impure";
        pq = if pure then "" else "?";
        at = "{ name?, checker?, ( src | url, narHash${pq} ) }";
        ap = if pure then at else "( ${at} | string[tarball_url] )";
      in ''
checkTarballPerms[${pi}] :: ${ap} -> { dirPermsSet, name, passthru, __toString }
XXX: System Dependent IFD.

Check a tarball file to see if it has properly set directory permission bits.

In impure mode you may omit `narHash' when calling with `url', and you may also
pass a url as a string as you would with `builtins.fetchurl'.

This routine uses system dependant "import from derivation" ( IFD ), and it is
strongly recommended that you cache the results of this operation declaratively.

Ex: checkTarballPerms { src = ./foo.tgz; } => { dirPermsSet = true, ... }
Ex: checkTarballPerms { url = "https://example.com/foo.tgz; narHash = ...; }
      '';
    };

    __functionArgs = ( lib.functionArgs checkTarballPermsDrv ) // {
      url     = true;
      narHash = true;
      checker = true;
    };

    __thunk.checker = checkTarballPermsDrv;

    __processArgs = self: x: let
      loc = "${self.__functionMeta.from}.${self.__functionMeta.name}";
      asAttrs =
        if builtins.isAttrs x then x else
        if ! pure then { url = lib.ytypes.Uri.Strings.uri_ref x; } else
        throw "(${loc}): In pure mode you must pass attrs args with `narHash'.";
      fromUrl = let
        nh' = if asAttrs ? narHash then { inherit (asAttrs) narHash; } else {};
      in {
        name = let
          parsed   = lib.libstr.nameFromTarballUrl asAttrs.url;
          fallback = if yt.FS.Strings.store_filename.check parsed then parsed
                                                                  else "source";
        in asAttrs.name or fallback;
        src  = builtins.fetchTree ( {
          type = "file";
          inherit (asAttrs) url;
        } // nh' );
        inherit (asAttrs) url;
      };
      rough = self.__thunk // ( if asAttrs ? x then asAttrs else fromUrl );
    in {
      all     = rough;
      drvArgs = lib.canPassStrict rough.checker rough;
      inherit (rough) checker;
    };

    __innerFunction = args: let
      checked = args.checker args.drvArgs;
      result  = builtins.substring 0 5 ( builtins.readFile checked.outPath );
      url'    = if args.all ? url then { inherit (args.all) url; } else {};
      nh' = if args.all ? narHash then { inherit (args.all) narHash; } else {};
    in {
      inherit (checked) name;
      dirPermsSet = ( builtins.substring 0 4 result ) == "PASS";
      __toString  = self: let
        msg = if self.dirPermsSet then "PASS" else "FAIL";
      in "${self.name}: ${msg}";
      passthru = url' // nh' // {
        perms = lib.fileContents checked.perms.outPath;
        inherit checked;
        inherit (args) all;
      } ;
    };

    __functor = lib.libfunk.stdProcessArgsFunctor;

  };  # End checkTarballPerms'


# ---------------------------------------------------------------------------- #

in {

  inherit checkTarballPermsDrv checkTarballPerms';

  checkTarballPermsPure   = checkTarballPerms' { pure = true; };
  checkTarballPermsImpure = checkTarballPerms' { pure = false; };
  checkTarballPerms       = checkTarballPerms' {};

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
