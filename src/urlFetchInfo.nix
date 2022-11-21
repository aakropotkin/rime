# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib, checkTarballPermsImpure }: let

  yt = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;

# ---------------------------------------------------------------------------- #

  urlFetchInfo = checkTarballPermsImpure // {
    __functionMeta = let
      prev = checkTarballPermsImpure.__functionMeta;
    in prev // {
      name      = "urlFetchInfo";
      signature = let
        withUrl = yt.restrict "with:url" ( x: x ? url ) ( yt.attrs yt.any );
        fetchInfoUrl = yt.struct "fetchInfo:url" {
          type    = yt.enum ["file" "tarball"];
          url     = yt.Uri.uri_ref;
          narHash = yt.Hash.nar_hash;
        };
      in [( yt.either yt.Uri.uri_ref withUrl ) fetchInfoUrl];
      doc = ''
urlFetchInfo :: ( string[uri_ref] | { url, ... } ) -> { url, type, narHash }
XXX: System Dependent IFD ( by `checkTarballPermsImpure' inner function )

Given a url, determine if Nix is able to use `builtins' to untar the file, and
return a `builtins.fetchTree' argset of `type = "tarball"' if we can, or
`type = "file"' if we can't.
In either case also return the `narHash' required to refetch the file as a
"locked"/"pure" operation.
      '';
    };

    __functionArgs = {
      url     = false;
      checker = true;
      narHash = true;
    };

    __innerFunction = args: let
      checked = args.checker args.drvArgs;
      result  = lib.fileContents checked.outPath;
      unlocked = {
        inherit (args.all) url;
        type = if result == "PASS" then "tarball" else "file";
      };
    in unlocked // {
      narHash = if unlocked.type == "file" then args.all.src.narHash else
                ( builtins.fetchTree unlocked ).narHash;
    };

  };


# ---------------------------------------------------------------------------- #

in {

  inherit urlFetchInfo;

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
