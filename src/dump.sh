#! /usr/bin/env bash
: "${NIX:=nix}";
: "${JQ:=jq}";

# Coerce a flake output to JSON or text.
$NIX eval "$@" --impure --json --apply "
i: let
  lib  = builtin.getFlake \"nixpkgs?dir=lib\";
  filt = k: v: builtins.foldl' ( acc: b: acc && b ) true [
    ( ! ( lib.hasPrefix \"__\" k ) )
    ( ! ( builtins.isFunction v ) )
  ];
  sto = x: y:
    if ( x ? __toString ) || ( builtins.isString x )
    then toString x else y;
  sro = x: y: let
    a = x.__serial x;
    c = lib.mapAttrsRecursive ( lib.filterAttrs filt ) y;
  in if ! ( x ? __serial ) then c else
     if lib.isFunction x.__serial then a else
     x.__serial;
  tss = sto i ( let ma = ( sro i i ); in sto ma ma );
  rsl = if builtins.isString tss then tss else
        builtins.toJSON tss;
in { inherit rsl; }
"|$JQ -r '.rsl';
