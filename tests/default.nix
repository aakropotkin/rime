# ============================================================================ #
#
# Provides sane defaults for running this set of tests.
# This is likely not the "ideal" way to utilize the test suite, but for someone
# who is consuming your project and knows nothing about it - this file should
# allow them to simply run `nix build -f .' to see if the test suite passes.
#
# ---------------------------------------------------------------------------- #

{ lib       ? rime.lib or nixpkgs.lib
, pkgsFor   ? ( rime.legacyPackages or nixpkgs.legacyPackages ).${system}
, writeText ? pkgsFor.writeText
, system    ? builtins.currentSystem
, rime      ? builtins.getFlake ( toString ../. )
, nixpkgs   ? builtins.getFlake "nixpkgs"

# Options
, keepFailed ? false  # Useful if you run the test explicitly.
, doTrace    ? true   # We want this disabled for `nix flake check'
, ...
} @ args: let

# ---------------------------------------------------------------------------- #

    data = let
      urlsFromTest = group: let
        proc = acc: x: if ( x ? url ) then acc ++ [x.url] else acc;
        lst = if builtins.isList group.test then group.test else
              builtins.attrNames group.test;
      in builtins.foldl' proc [] lst;
      allTests = json: let
        proc = acc: x: acc ++ ( urlsFromTest x );
      in builtins.foldl' proc [] ( builtins.attrValues json );
    in {
      json = {
        remote = lib.importJSON ./data/remote.json;
        local  = lib.importJSON ./data/local.json;
      };
      urls = builtins.mapAttrs ( _: allTests ) data.json;
    };


# ---------------------------------------------------------------------------- #

  # Used to import test files.
  autoArgs = { inherit lib pkgsFor writeText; } // args;

  tests = let
    testsFrom = file: let
      fn    = import file;
      fargs = builtins.functionArgs fn;
      ts    = fn ( builtins.intersectAttrs fargs autoArgs );
    in assert builtins.isAttrs ts;
       ts.tests or ts;
  in builtins.foldl' ( ts: file: ts // ( testsFrom file ) ) {} [
    ./parser
  ];

# ---------------------------------------------------------------------------- #

  # We need `check' and `checkerDrv' to use different `checker' functions which
  # is why we have explicitly provided an alternative `check' as a part
  # of `mkCheckerDrv'.
  harness = let
    name = "all-tests";
  in lib.libdbg.mkTestHarness {
    inherit name keepFailed tests writeText;
    mkCheckerDrv = args: lib.libdbg.mkCheckerDrv {
      inherit name keepFailed writeText;
      check = lib.libdbg.checkerReport name harness.run;
    };
    checker = name: run: let
      msg = lib.libdbg.checkerMsg name run;
      rsl = lib.libdbg.checkerDefault name run;
    in if doTrace then builtins.trace msg rsl else rsl;
  };


# ---------------------------------------------------------------------------- #

in harness


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
