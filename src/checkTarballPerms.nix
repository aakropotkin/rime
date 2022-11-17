# ============================================================================ #

{ lib, runCommandNoCC }: let

# ---------------------------------------------------------------------------- #

  checkTarballPermsDrv = {
    src
  , name ? lib.libstr.nameFromTarballUrl ( lib.baseName' src )
  }: runCommandNoCC "check-perms--${name}" {
    inherit src;
    outputs = ["out" "perms"];
    passthru.bname = name;
  } ''
    tar tzvf "$src"|awk '{ print $1, $2, $4, $5, $6; }' > "$perms";
    if grep '^d..-' "$perms"; then
      printf FAIL > "$out";
    else
      printf PASS > "$out";
    fi
  '';


# ---------------------------------------------------------------------------- #

  checkTarballPerms' = { pure ? lib.inPureEvalMode }: {
    __functionMeta = {
      name = "checkTarballPerms";
      from = "rime#util";
      properties = {
        inherit pure;
        ifd = true;
        funkT = "pargs-std";  # required with `stdProcessArgsFunctor'.
      };
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
Ex: checkTarballPerms { url = "https://example.com/foo.tgz; narHash = ..; }
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
        if pure then { url = lib.ytypes.Strings.tarball_url x; } else
        throw "(${loc}): In pure mode you must pass attrs args with `narHash'.";
      fromUrl = let
        nh' = if asAttrs ? narHash then { inherit (asAttrs) narHash; } else {};
      in {
        name = asAttrs.name or ( lib.libstr.nameFromTarballUrl asAttrs.url );
        src  = builtins.fetchTree ( {
          type = "file";
          inherit (asAttrs) url;
        } // nh' );
      };
      rough = self.__thunk // ( if asAttrs ? x then asAttrs else fromUrl );
    in {
      drvArgs = lib.canPassStrict rough.checker rough;
      inherit (rough) checker;
    };

    __innerFunction = args: let
      checked = args.checker args.drvArgs;
      result  = lib.fileContents checked.outPath;
    in {
      inherit (checked) name;
      dirPermsSet = result == "PASS";
      __toString  = self: "${self.name}: ${result}";
      passthru = {
        inherit checked;
        perms = lib.fileContents checked.perms.outPath;
      } // ( if args ? url then { inherit (args) url; } else {} );
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
