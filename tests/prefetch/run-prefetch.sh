#! /usr/bin/env bash

set -eu;

: "${NIX:=nix}";
: "${REALPATH:=realpath}";
: "${JQ:=jq}";
: "${FLAKE_REF:=$( $REALPATH "${BASH_SOURCE[0]%/*}/../.."; )}";
: "${NIX_PREFETCH_TREE:=$NIX run "$FLAKE_REF\#nix-prefetch-tree" --}";

: "${URL:=${1:?}}";
: "${EXPECT_TYPE:=${2:?}}";


_es=0;
TYPE="$(
  {
    $NIX_PREFETCH_TREE -K "$URL"||echo '{ "type": "FAIL" }';
  }|$JQ -r '.type';
)";
case "$TYPE" in
  $EXPECT_TYPE) echo "PASS"; _es=0; ;;
  *)
    echo "FAIL";
    echo "Expected type '$EXPECT_TYPE', got '$TYPE'" >&2;
    _es=1;
  ;;
esac
exit "$_es";
