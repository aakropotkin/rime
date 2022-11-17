#! /usr/bin/env bash
set -eu;

: "${NIX:=nix}";
: "${NIX_FLAGS:=--no-warn-dirty}"
: "${REALPATH:=realpath}";
: "${JQ:=jq}";
: "${FLAKE_REF:=$( $REALPATH "${BASH_SOURCE[0]%/*}/../.."; )}";
if test -z "${NIX_PREFETCH_TREE:-}"; then
  NIX_PREFETCH_TREE="$NIX $NIX_FLAGS run $FLAKE_REF#nix-prefetch-tree --";
fi

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
